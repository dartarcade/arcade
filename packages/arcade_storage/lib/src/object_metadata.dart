/// Metadata about a storage object
class ObjectMetadata {
  /// The size of the object in bytes
  final int size;

  /// The ETag of the object
  final String? etag;

  /// The last modified date of the object
  final DateTime? lastModified;

  /// The content type of the object
  final String? contentType;

  /// Additional metadata as key-value pairs
  final Map<String, String?>? metaData;

  const ObjectMetadata({
    required this.size,
    this.etag,
    this.lastModified,
    this.contentType,
    this.metaData,
  });
}
