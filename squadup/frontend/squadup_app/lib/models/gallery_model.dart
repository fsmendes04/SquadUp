class Gallery {
  final String id;
  final String groupId;
  final String eventName;
  final String location;
  final String date;
  final List<String> images;
  final String createdAt;
  final String? updatedAt;

  Gallery({
    required this.id,
    required this.groupId,
    required this.eventName,
    required this.location,
    required this.date,
    required this.images,
    required this.createdAt,
    this.updatedAt,
  });

  factory Gallery.fromJson(Map<String, dynamic> json) {
    return Gallery(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      eventName: json['event_name'] as String,
      location: json['location'] as String,
      date: json['date'] as String,
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'event_name': eventName,
      'location': location,
      'date': date,
      'images': images,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
