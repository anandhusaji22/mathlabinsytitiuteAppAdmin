class SliderImageModel {
  int? imagesId;
  String? images;
  String? imageUrl;
  String? title;
  String? shortDescription;
  int? displayOrder;

  SliderImageModel({
    this.imagesId,
    this.images,
    this.imageUrl,
    this.title,
    this.shortDescription,
    this.displayOrder,
  });

  SliderImageModel.fromJson(Map<String, dynamic> json) {
    imagesId = json['images_id'];
    images = json['images'];
    imageUrl = json['image_url'];
    title = json['title'];
    shortDescription = json['short_description'];
    displayOrder = json['display_order'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['images_id'] = imagesId;
    data['images'] = images;
    data['image_url'] = imageUrl;
    data['title'] = title;
    data['short_description'] = shortDescription;
    data['display_order'] = displayOrder;
    return data;
  }

  String get displayImageUrl => (imageUrl != null && imageUrl!.isNotEmpty)
      ? imageUrl!
      : (images != null && images!.startsWith('http'))
          ? images!
          : '';
}

