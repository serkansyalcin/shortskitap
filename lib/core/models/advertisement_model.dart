class AdvertisementModel {
  final int id;
  final String title;
  final String? imageUrl;
  final String? linkUrl;
  final String position;

  const AdvertisementModel({
    required this.id,
    required this.title,
    this.imageUrl,
    this.linkUrl,
    required this.position,
  });

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementModel(
      id:       json['id'] as int,
      title:    json['title'] as String,
      imageUrl: json['image_url'] as String?,
      linkUrl:  json['link_url'] as String?,
      position: json['position'] as String? ?? 'reader_banner',
    );
  }
}
