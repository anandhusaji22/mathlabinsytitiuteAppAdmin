class PopularCourseModel {
  int? popularCourseId;
  List<int>? courses;

  PopularCourseModel({this.popularCourseId, this.courses});

  PopularCourseModel.fromJson(Map<String, dynamic> json) {
    popularCourseId = json['popular_course_id'] is int 
        ? json['popular_course_id'] 
        : (json['popular_course_id'] is String 
            ? int.tryParse(json['popular_course_id']) 
            : null);
    if (json['course'] != null) {
      courses = [];
      if (json['course'] is List) {
        json['course'].forEach((v) {
          if (v is int) {
            courses!.add(v);
          } else if (v is String) {
            int? parsed = int.tryParse(v);
            if (parsed != null) courses!.add(parsed);
          } else if (v is Map) {
            dynamic courseId = v['course_unique_id'] ?? v['id'];
            if (courseId is int) {
              courses!.add(courseId);
            } else if (courseId is String) {
              int? parsed = int.tryParse(courseId);
              if (parsed != null) courses!.add(parsed);
            }
          }
        });
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['popular_course_id'] = this.popularCourseId;
    data['course'] = this.courses;
    return data;
  }
}

