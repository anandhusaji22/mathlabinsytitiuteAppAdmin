class AccessTypeModel {
  int? id;
  String? accessType;

  AccessTypeModel({this.id, this.accessType});

  AccessTypeModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    accessType = json['access_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['access_type'] = this.accessType;
    return data;
  }
}

