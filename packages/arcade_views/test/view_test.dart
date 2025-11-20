import 'dart:io';

import 'package:arcade_config/arcade_config.dart';
import 'package:arcade_views/arcade_views.dart';
import 'package:test/test.dart';

void main() {
  group('view', () {
    tearDown(() {
      ArcadeConfiguration.override(viewsDirectory: Directory('views'));
    });

    test('should return a string', () {
      final result = view('index');
      expect(result, isA<String>());
    });

    test('should return a string with data', () {
      final result = view('john', {'name': 'John'});
      expect(result, isA<String>());
      expect(result, contains('John'));
    });

    test('should throw an exception if the views directory does not exist', () {
      ArcadeConfiguration.override(viewsDirectory: Directory('nonexistent'));
      expect(() => view('index'), throwsException);
    });

    test('should throw an exception if the view file does not exist', () {
      expect(() => view('nonexistent'), throwsException);
    });
  });

  group('nested views', () {
    test('should return a string for nested views', () {
      final result = view('nested/index');
      expect(result, isA<String>());
    });

    test('should return a string with data for nested views', () {
      final result = view('nested/john', {'name': 'John'});
      expect(result, isA<String>());
      expect(result, contains('John'));
    });

    test(
      'should throw an exception if the nested view file does not exist',
      () {
        expect(() => view('nested/nonexistent'), throwsException);
      },
    );
  });

  group('inheritance', () {
    test('should return a string for inheritance', () {
      final result = view('inheritance', {'name': '_'});
      expect(result, isA<String>());
    });

    test('should return a string with data for inheritance', () {
      final result = view('inheritance', {'name': 'John'});
      expect(result, isA<String>());
      expect(result, contains('John'));
    });
  });
}
