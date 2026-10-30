class PdfResource {
  final String id;
  final String title;
  final String subjectName;
  final String? unitName;
  final String url;
  final String? fileSize;

  PdfResource({
    required this.id,
    required this.title,
    required this.subjectName,
    this.unitName,
    required this.url,
    this.fileSize,
  });

  factory PdfResource.fromJson(Map<String, dynamic> json) => PdfResource(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Study Material',
        subjectName: json['subjectName'] ?? '',
        unitName: json['unitName'],
        url: json['url'] ?? '',
        fileSize: json['fileSize'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subjectName': subjectName,
        'unitName': unitName,
        'url': url,
        'fileSize': fileSize,
      };
}
