class QuestionTypeModel {
  int? id;
  String? questionType;
  String? slugQuestionType;

  QuestionTypeModel({this.id, this.questionType, this.slugQuestionType});

  QuestionTypeModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    questionType = json['question_type'];
    slugQuestionType = json['slug_question_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['question_type'] = this.questionType;
    data['slug_question_type'] = this.slugQuestionType;
    return data;
  }
}

