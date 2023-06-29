import 'dart:io';

import 'package:dartseid/dartseid.dart';
import 'package:dartseid_views/dartseid_views.dart';
import 'package:test/test.dart';

void main() {
  group('view', () {
    tearDown(() {
      DartseidConfiguration.viewsDirectory = Directory('views');
    });

    test('should return a string', () async {
      final result = view('index');
      expect(result, isA<String>());
    });

    test('should return a string with data', () async {
      final result = view('john', {'name': 'John'});
      expect(result, isA<String>());
      expect(result, contains('John'));
    });

    test('should throw an exception if the views directory does not exist',
        () async {
      DartseidConfiguration.viewsDirectory = Directory('nonexistent');
      expect(() => view('index'), throwsException);
    });

    test('should throw an exception if the view file does not exist', () async {
      expect(() => view('nonexistent'), throwsException);
    });
  });

  group('nested views', () {
    test('should return a string for nested views', () async {
      final result = view('nested/index');
      expect(result, isA<String>());
    });

    test('should return a string with data for nested views', () async {
      final result = view('nested/john', {'name': 'John'});
      expect(result, isA<String>());
      expect(result, contains('John'));
    });

    test('should throw an exception if the nested view file does not exist',
        () async {
      expect(() => view('nested/nonexistent'), throwsException);
    });
  });

  group('partials', () {
    test('should return a string for partials', () async {
      final result = view('partial', {'name': '_'});
      expect(result, isA<String>());
    });

    test('should return a string with data for partials', () async {
      final result = view('partial', {'name': 'John'});
      expect(result, isA<String>());
      expect(result, contains('John'));
    });

    test('partials should be relative', () {
      final result = view('nested/partial');
      expect(result, isA<String>());
      expect(result, contains('Partial'));
    });
  });
}
