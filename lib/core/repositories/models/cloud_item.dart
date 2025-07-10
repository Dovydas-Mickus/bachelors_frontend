class CloudItem {
  final String name;
  final bool isDirectory;
  final int? size;

  CloudItem({required this.name, required this.isDirectory, this.size});

  factory CloudItem.fromJson(Map<String, dynamic> json) {
    return CloudItem(
      name: json['name'],
      isDirectory: json['is_directory'],
      size: json['size'],
    );
  }
}
