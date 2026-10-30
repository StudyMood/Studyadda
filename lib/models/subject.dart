import 'unit.dart';

class CourseSubject {
  final String name;
  final List<CourseUnit> units;

  CourseSubject({
    required this.name,
    required this.units,
  });

  int get totalVideos => units.fold(0, (sum, unit) => sum + unit.videos.length);

  factory CourseSubject.fromJson(Map<String, dynamic> json) {
    var rawList = json['u'] as List? ?? json['units'] as List? ?? [];
    List<CourseUnit> uList = rawList
        .map((item) => CourseUnit.fromJson(item as Map<String, dynamic>))
        .toList();
    return CourseSubject(
      name: json['n'] ?? json['name'] ?? 'Subject',
      units: uList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'units': units.map((u) => u.toJson()).toList(),
    };
  }
}
