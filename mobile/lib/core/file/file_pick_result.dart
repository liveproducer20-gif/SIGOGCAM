class FilePickResult {
  final String name;
  final String? previewUrl;
  final String? dataUrl;
  final String? mimeType;
  final int? size;

  const FilePickResult({
    required this.name,
    this.previewUrl,
    this.dataUrl,
    this.mimeType,
    this.size,
  });
}
