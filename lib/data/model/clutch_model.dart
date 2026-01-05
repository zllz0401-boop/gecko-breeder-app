import 'package:cloud_firestore/cloud_firestore.dart';

class Clutch {
  final String id;
  final String pairingId; // 어느 커플의 알인지
  final int order; // 산란 차수 (1차, 2차...)
  final DateTime layDate; // 산란일
  final int eggCount; // 알 개수
  final String? memo; // 비고 (유정란/무정란 등)

  Clutch({
    required this.id,
    required this.pairingId,
    required this.order,
    required this.layDate,
    required this.eggCount,
    this.memo,
  });

  factory Clutch.fromJson(Map<String, dynamic> json, String docId) {
    return Clutch(
      id: docId,
      pairingId: json['pairingId'] ?? '',
      order: json['order'] ?? 1,
      layDate: (json['layDate'] as Timestamp).toDate(),
      eggCount: json['eggCount'] ?? 2,
      memo: json['memo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pairingId': pairingId,
      'order': order,
      'layDate': Timestamp.fromDate(layDate),
      'eggCount': eggCount,
      'memo': memo,
    };
  }
}
