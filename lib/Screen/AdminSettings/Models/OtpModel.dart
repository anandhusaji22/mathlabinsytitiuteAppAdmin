class OtpModel {
  int? id;
  String? username;
  String? otp;
  bool? otpValidated;

  OtpModel({this.id, this.username, this.otp, this.otpValidated});

  OtpModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['user'] is String ? json['user'] : json['user']?['username'];
    otp = json['otp'];
    otpValidated = json['otp_validated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['username'] = this.username;
    data['otp'] = this.otp;
    data['otp_validated'] = this.otpValidated;
    return data;
  }
}

