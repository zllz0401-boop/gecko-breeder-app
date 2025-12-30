import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoModel {
  final String id;
  final String photoUrl;
  final DateTime uploadedAt;

  PhotoModel({
    required this.id,
    required this.photoUrl,
    required this.uploadedAt,
  });

  // DB -> 앱
  factory PhotoModel.fromJson(Map<String, dynamic> json, String docId) {
    return PhotoModel(
      id: docId,
      photoUrl: json['photoUrl'] ?? '',
      uploadedAt: (json['uploadedAt'] as Timestamp).toDate(),
    );
  }

  // 앱 -> DB
  Map<String, dynamic> toJson() {
    return {
      'photoUrl': photoUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}
