class FilePickResult {
  final String name;
  final String? previewUrl;
  final String? dataUrl;

  const FilePickResult({
    required this.name,
    this.previewUrl,
    this.dataUrl,
  });
}
