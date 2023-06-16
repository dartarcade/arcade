import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

  Future<Map<String, dynamic>> json() async {
    final body = await _body;
    final bodyString = String.fromCharCodes(body.expand((e) => e));
    return jsonDecode(bodyString);
  }

  Future<T> parseJsonAs<T>(T Function(Map<String, dynamic> json) converter) async {
    final body = await _body;
    final bodyString = String.fromCharCodes(body.expand((e) => e));
    return converter(jsonDecode(bodyString));
  }

  Future<String> body() async {
    final body = await _body;
    return String.fromCharCodes(body.expand((e) => e));
  }
}
