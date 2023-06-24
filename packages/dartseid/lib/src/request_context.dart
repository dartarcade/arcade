import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartseid/src/body_parse_result.dart';
import 'package:dartseid/src/helpers/request_helpers.dart';
import 'package:dartseid/src/helpers/route_helpers.dart';
import 'package:dartseid/src/route.dart';

class RequestContext {
  late final HttpRequest _request;
  late final BaseRoute _route;
  late final String _path;
  late final HttpMethod _method;
  late final HttpHeaders _headers;
  late final Map<String, String> _pathParameters;
  late final Map<String, String> _queryParameters;

  RequestContext({
    required BaseRoute route,
    required HttpRequest request,
  }) {
    final HttpRequest(uri: uri, method: methodString) = request;

    final method = getHttpMethod(methodString)!;

    final pathParameters = makePathParameters(route, uri);

    _request = request;
    _route = route;
    _path = request.uri.path;
    _method = method;
    _headers = request.headers;
    _pathParameters = pathParameters;
    _queryParameters = request.uri.queryParameters;
  }

  HttpRequest get rawRequest => _request;

  Future<List<Uint8List>> get rawBody => _request.toList();

  BaseRoute get route => _route;

  String get path => _path;

  HttpMethod get method => _method;

  HttpHeaders get headers => _headers;

  Map<String, String> get pathParameters => _pathParameters;

  Map<String, String> get queryParameters => _queryParameters;

  Future<String> body() async {
    final body = await rawBody;
    return String.fromCharCodes(body.expand((e) => e));
  }

  /// Parses the body as JSON map
  Future<BodyParseResult<Map<String, dynamic>>> jsonMap() async {
    try {
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
}
