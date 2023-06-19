import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartseid/src/body_parse_result.dart';
import 'package:dartseid/src/route.dart';

class RequestContext {
  final String _path;
  final HttpMethod _method;
  final HttpHeaders _headers;
  final Map<String, String> _pathParameters;
  final Map<String, String> _queryParameters;
  final Future<List<Uint8List>> _body;

  RequestContext({
    required String path,
    required HttpMethod method,
    required HttpHeaders headers,
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    required Future<List<Uint8List>> body,
  })  : _path = path,
        _method = method,
        _headers = headers,
        _pathParameters = pathParameters,
        _queryParameters = queryParameters,
        _body = body;

  String get path => _path;

  HttpMethod get method => _method;

  HttpHeaders get headers => _headers;

  Map<String, String> get pathParameters => _pathParameters;

  Map<String, String> get queryParameters => _queryParameters;

  Future<List<Uint8List>> get rawBody => _body;

  Future<String> body() async {
    final body = await _body;
    return String.fromCharCodes(body.expand((e) => e));
  }

  /// Parses the body as JSON map
  Future<BodyParseResult<Map<String, dynamic>>> jsonMap() async {
    try {
      return BodyParseSuccess(jsonDecode(await body()));
    } catch (e) {
      return BodyParseFailure(e);
    }
  }

  /// Parses the body as JSON list
  Future<BodyParseResult<List<dynamic>>> jsonList() async {
    try {
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
}
