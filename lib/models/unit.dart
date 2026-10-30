import 'video_lecture.dart';

class CourseUnit {
  final String name;
  final List<VideoLecture> videos;

  CourseUnit({
    required this.name,
    required this.videos,
  });

  factory CourseUnit.fromJson(Map<String, dynamic> json) {
    var rawList = json['v'] as List? ?? json['videos'] as List? ?? [];
    List<VideoLecture> vList = rawList
        .map((item) => VideoLecture.fromJson(item as Map<String, dynamic>))
        .toList();
    return CourseUnit(
      name: json['n'] ?? json['name'] ?? 'Unit',
      videos: vList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'videos': videos.map((v) => v.toJson()).toList(),
    };
  }
}
