/// Information about a storage bucket
class BucketInfo {
  /// The name of the bucket
  final String name;

  /// The creation date of the bucket
  final DateTime? creationDate;

  const BucketInfo({required this.name, this.creationDate});
}
