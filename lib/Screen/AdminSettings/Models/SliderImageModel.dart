class SliderImageModel {
  int? imagesId;
  String? images;

  SliderImageModel({this.imagesId, this.images});

  SliderImageModel.fromJson(Map<String, dynamic> json) {
    imagesId = json['images_id'];
    images = json['images'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['images_id'] = this.imagesId;
    data['images'] = this.images;
    return data;
  }
}

