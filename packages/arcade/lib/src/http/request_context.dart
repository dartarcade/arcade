import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:arcade/arcade.dart';
import 'package:arcade/src/helpers/request_helpers.dart';
import 'package:arcade/src/helpers/route_helpers.dart';
import 'package:arcade/src/http/form_data.dart';
import 'package:arcade_logger/arcade_logger.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:string_scanner/string_scanner.dart';

class RequestContext {
  late final HttpRequest _request;
  late final BaseRoute _route;
  late final String _path;
  late final HttpMethod _method;
  late final HttpHeaders _requestHeaders;
  late final HttpHeaders _responseHeaders;
  late final Map<String, String> _pathParameters;
  late final Map<String, String> _queryParameters;
  late final List<File> _files;

  RequestContext({required BaseRoute route, required HttpRequest request}) {
    final HttpRequest(uri: uri, method: methodString) = request;

    final method = getHttpMethod(methodString)!;

    final pathParameters = makePathParameters(route, uri);

    _request = request;
    _route = route;
    _path = request.uri.path;
    _method = method;
    _requestHeaders = request.headers;
    _responseHeaders = request.response.headers;
    _pathParameters = pathParameters;
    _queryParameters = request.uri.queryParameters;
  }

  HttpRequest get rawRequest => _request;

  Future<List<Uint8List>> get rawBody => _request.toList();

  BaseRoute get route => _route;

  String get path => _path;

  HttpMethod get method => _method;

  HttpHeaders get requestHeaders => _requestHeaders;

  HttpHeaders get responseHeaders => _responseHeaders;

  Map<String, String> get pathParameters => _pathParameters;

  Map<String, String> get queryParameters => _queryParameters;

  List<File> get files => _files;

  int get statusCode => _request.response.statusCode;

  set statusCode(int value) => _request.response.statusCode = value;

  Future<String> body() async {
    final body = await rawBody;
    return String.fromCharCodes(body.expand((e) => e));
  }

  /// Parses the body as JSON map
  Future<BodyParseResult<Map<String, dynamic>>> jsonMap() async {
    try {
      final contentType = requestHeaders.contentType;
      if (contentType == null) {
        return const BodyParseFailure(
          HttpException('Content-Type header is not set'),
        );
      }

      if (contentType.subType == 'x-www-form-urlencoded') {
        return BodyParseSuccess(await _parseUrlEncoded());
      }

      // default to JSON
      // ignore: argument_type_not_assignable
      return BodyParseSuccess(jsonDecode(await body()));
    } catch (e) {
      return BodyParseFailure(e);
    }
  }

  /// Parses the body as JSON list
  Future<BodyParseResult<List<dynamic>>> jsonList() async {
    try {
      // ignore: argument_type_not_assignable
      return BodyParseSuccess(jsonDecode(await body()));
    } catch (e) {
      return BodyParseFailure(e);
    }
  }

  /// Parses body as JSON map and converts it to the given type
  Future<BodyParseResult<T>> parseJsonAs<T>(
    T Function(Map<String, dynamic> json) converter,
  ) async {
    return switch (await jsonMap()) {
      BodyParseSuccess(value: final json) => BodyParseSuccess(converter(json)),
      BodyParseFailure(error: final error) => BodyParseFailure(error),
    };
  }

  // Parsed body as FormData
  Future<BodyParseResult<FormData>> formData() async {
    try {
      final contentType = requestHeaders.contentType;
      if (contentType == null) {
        return const BodyParseFailure(
          BadRequestException(message: 'Content-Type header is not set'),
        );
      }

      if (contentType.subType != 'form-data') {
        return const BodyParseFailure(
          BadRequestException(
            message: 'Content-Type is not multipart/form-data',
          ),
        );
      }

      final boundary = contentType.parameters['boundary'];
      if (boundary == null) {
        return const BodyParseFailure(
          BadRequestException(
            message: 'Content-Type header is missing boundary',
          ),
        );
      }

      final formData = await _parseFormData(await rawBody, boundary);
      return BodyParseSuccess(formData);
    } catch (e, s) {
      Logger.root.error('$e\n$s');
      return BodyParseFailure(e);
    }
  }

  Future<Map<String, dynamic>> _parseUrlEncoded() async {
    final s = await body();
    final map = <String, dynamic>{};
    for (final pair in s.split('&')) {
      final parts = pair.split('=');
      final key = Uri.decodeQueryComponent(parts[0]);
      final value = Uri.decodeQueryComponent(parts[1]);
      map[key] = value;
    }
    return map;
  }

  Future<FormData> _parseFormData(List<Uint8List> body, String boundary) async {
    final Map<String, String> data = {};
    final List<File> files = [];

    final bodyBytes = Stream.fromIterable(body);

    final parts = MimeMultipartTransformer(boundary).bind(bodyBytes);
    await for (final part in parts) {
      final contentDisposition = part.headers['content-disposition'];
      if (contentDisposition == null) {
        continue;
      }

      final contentDispositionType = _parseFormDataContentDisposition(
        contentDisposition,
      );
      if (contentDispositionType == null) {
        continue;
      }

      final name = contentDispositionType['name'];
      if (name == null) {
        continue;
      }

      final filename = contentDispositionType['filename'];
      if (filename == null) {
        final value = await utf8.decodeStream(part);
        data[name] = value;
      } else {
        // Generate a random filename
        final random = Random.secure();
        final randomString = List.generate(
          10,
          (_) => random.nextInt(33) + 89,
        ).join();
        final newFileName = '$randomString-$filename';
        final file = File(join('uploads', newFileName));
        await file.create(recursive: true);
        await file.writeAsBytes(await part.expand((e) => e).toList());
        files.add(file);
      }
    }

    return FormData(data, files);
  }

  // Below code taken from [shelf_multipart](https://github.com/simolus3/goodies.dart/blob/7e910ff9d9cc52848293172bc45451e791693c5a/shelf_multipart/lib/form_data.dart#L63)
  final _token = RegExp(r'[^()<>@,;:"\\/[\]?={} \t\x00-\x1F\x7F]+');
  final _whitespace = RegExp(r'(?:(?:\r\n)?[ \t]+)*');
  final _quotedString = RegExp(r'"(?:[^"\x00-\x1F\x7F]|\\.)*"');
  final _quotedPair = RegExp(r'\\(.)');

  /// Parses a `content-disposition: form-data; arg1="val1"; ...` header.
  Map<String, String>? _parseFormDataContentDisposition(String header) {
    final scanner = StringScanner(header);

    scanner
      ..scan(_whitespace)
      ..expect(_token);
    if (scanner.lastMatch![0] != 'form-data') return null;

    final params = <String, String>{};

    while (scanner.scan(';')) {
      scanner
        ..scan(_whitespace)
        ..scan(_token);
      final key = scanner.lastMatch![0]!;
      scanner.expect('=');

      String value;
      if (scanner.scan(_token)) {
        value = scanner.lastMatch![0]!;
      } else {
        scanner.expect(_quotedString, name: 'quoted string');
        final string = scanner.lastMatch![0]!;

        value = string
            .substring(1, string.length - 1)
            .replaceAllMapped(_quotedPair, (match) => match[1]!);
      }

      scanner.scan(_whitespace);
      params[key] = value;
    }

    scanner.expectDone();
    return params;
  }
}
