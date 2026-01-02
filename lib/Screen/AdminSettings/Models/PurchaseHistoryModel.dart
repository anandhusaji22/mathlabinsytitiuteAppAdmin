class PurchaseHistoryModel {
  int? id;
  String? username;
  String? courseName;
  String? examName;
  String? dateOfPurchase;
  String? expirationDate;
  double? orderAmount;
  String? orderPaymentId;
  bool? isPaid;

  PurchaseHistoryModel({
    this.id,
    this.username,
    this.courseName,
    this.examName,
    this.dateOfPurchase,
    this.expirationDate,
    this.orderAmount,
    this.orderPaymentId,
    this.isPaid,
  });

  PurchaseHistoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['user_profile'] is String 
        ? json['user_profile'] 
        : json['user_profile']?['user']?['username'];
    courseName = json['course'] is String 
        ? json['course'] 
        : json['course']?['field_of_study'];
    examName = json['exam'] is String 
        ? json['exam'] 
        : json['exam']?['exam_name'];
    dateOfPurchase = json['date_of_purchase'];
    expirationDate = json['expiration_date'];
    orderAmount = json['order_amount']?.toDouble();
    orderPaymentId = json['order_payment_id'];
    isPaid = json['isPaid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['username'] = this.username;
    data['course_name'] = this.courseName;
    data['exam_name'] = this.examName;
    data['date_of_purchase'] = this.dateOfPurchase;
    data['expiration_date'] = this.expirationDate;
    data['order_amount'] = this.orderAmount;
    data['order_payment_id'] = this.orderPaymentId;
    data['isPaid'] = this.isPaid;
    return data;
  }
}

