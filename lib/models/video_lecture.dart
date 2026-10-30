class VideoLecture {
  final String key;
  final String title;
  final int? lectureNumber;
  final String? tags;
  final String? appKey;
  final String? encryptedId;
  String? resolvedUrl;

  VideoLecture({
    required this.key,
    required this.title,
    this.lectureNumber,
    this.tags,
    this.appKey,
    this.encryptedId,
    this.resolvedUrl,
  });

  factory VideoLecture.fromJson(Map<String, dynamic> json) {
    return VideoLecture(
      key: json['k'] ?? json['key'] ?? '',
      title: json['t'] ?? json['title'] ?? 'Lecture',
      lectureNumber: json['l'] != null ? int.tryParse(json['l'].toString()) : null,
      tags: json['g'] ?? json['tags'],
      appKey: json['y'] ?? json['appKey'],
      encryptedId: json['x'] ?? json['encryptedId'],
      resolvedUrl: json['url'] ?? json['resolvedUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'lectureNumber': lectureNumber,
      'tags': tags,
      'appKey': appKey,
      'encryptedId': encryptedId,
      'resolvedUrl': resolvedUrl,
    };
  }
}
