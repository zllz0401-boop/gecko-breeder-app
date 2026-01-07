import 'package:cloud_firestore/cloud_firestore.dart';

class Clutch {
  final String id;
  final String pairingId;
  final int order;
  final DateTime layDate;
  final int eggCount;
  final String? memo;
  final double? incubationTemp; // ★ 추가됨: 보관 온도
  final DateTime? createdAt;

  Clutch({
    required this.id,
    required this.pairingId,
    required this.order,
    required this.layDate,
    required this.eggCount,
    this.memo,
    this.incubationTemp, // ★ 추가됨
    this.createdAt,
  });

  factory Clutch.fromJson(Map<String, dynamic> json, String id) {
    return Clutch(
      id: id,
      pairingId: json['pairingId'] ?? '',
      order: json['order'] ?? 1,
      layDate: (json['layDate'] as Timestamp).toDate(),
      eggCount: json['eggCount'] ?? 0,
      memo: json['memo'],
      // ★ 추가됨: Firestore에서 온도 가져오기 (없으면 null)
      incubationTemp: json['incubationTemp'] != null
          ? (json['incubationTemp'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pairingId': pairingId,
      'order': order,
      'layDate': Timestamp.fromDate(layDate),
      'eggCount': eggCount,
      'memo': memo,
      'incubationTemp': incubationTemp, // ★ 추가됨
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
