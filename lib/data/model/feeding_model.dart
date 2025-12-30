import 'package:cloud_firestore/cloud_firestore.dart';

class FeedingRecord {
  final String id;
  final DateTime date; // 급여 날짜
  final String foodType; // 먹이 종류 (귀뚜라미, 밀웜 등)
  final String amount; // 급여량 (2마리, 소량 등)
  final String? memo; // 특이사항 (거식, 칼슘제 등)

  FeedingRecord({
    required this.id,
    required this.date,
    required this.foodType,
    required this.amount,
    this.memo,
  });

  // DB -> 앱 (가져오기)
  factory FeedingRecord.fromJson(Map<String, dynamic> json, String docId) {
    return FeedingRecord(
      id: docId,
      date: (json['date'] as Timestamp).toDate(),
      foodType: json['foodType'] ?? '',
      amount: json['amount'] ?? '',
      memo: json['memo'] ?? '',
    );
  }

  // 앱 -> DB (저장하기)
  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'foodType': foodType,
      'amount': amount,
      'memo': memo,
    };
  }
}
