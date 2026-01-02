class UserResponseModel {
  int? id;
  String? username;
  String? examId;
  String? examName;
  Map<String, dynamic>? response;
  int? qualifyScore;
  String? timeTaken;
  String? marksScored;
  String? totalScored;

  UserResponseModel({
    this.id,
    this.username,
    this.examId,
    this.examName,
    this.response,
    this.qualifyScore,
    this.timeTaken,
    this.marksScored,
    this.totalScored,
  });

  UserResponseModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['user'] is String ? json['user'] : json['user']?['username'];
    examId = json['exam_id'];
    examName = json['exam_name'];
    response = json['response'] is Map ? json['response'] : null;
    qualifyScore = json['qualify_score'];
    timeTaken = json['time_taken'];
    marksScored = json['marks_scored'];
    totalScored = json['total_scored'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['username'] = this.username;
    data['exam_id'] = this.examId;
    data['exam_name'] = this.examName;
    data['response'] = this.response;
    data['qualify_score'] = this.qualifyScore;
    data['time_taken'] = this.timeTaken;
    data['marks_scored'] = this.marksScored;
    data['total_scored'] = this.totalScored;
    return data;
  }
}

