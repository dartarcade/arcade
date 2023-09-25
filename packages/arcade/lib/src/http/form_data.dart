import 'dart:io';

class FormData {
  final Map<String, String> _data;
  final List<File> _files;

  FormData(this._data, this._files);

  Map<String, String> get data => _data;

  List<File> get files => _files;
}
