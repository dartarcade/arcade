/// Information about a storage object
class ObjectInfo {
  /// The name/key of the object
  final String name;

  /// The size of the object in bytes
  final int size;

  /// The last modified date of the object
  final DateTime? lastModified;

  /// The ETag of the object
  final String? etag;

  const ObjectInfo({
    required this.name,
    required this.size,
    this.lastModified,
    this.etag,
  });
}
