import 'package:cloud_firestore/cloud_firestore.dart';

class LogRecord {
  final String id;
  final DateTime date;

  // 선택적 입력값들 (입력 안 하면 null)
  final String? foodType; // 먹이 종류
  final String? foodAmount; // 먹이 양
  final double? weight; // 무게
  final String? note; // 비고 (탈피 등)

  LogRecord({
    required this.id,
    required this.date,
    this.foodType,
    this.foodAmount,
    this.weight,
    this.note,
  });

  // DB -> 앱
  factory LogRecord.fromJson(Map<String, dynamic> json, String docId) {
    return LogRecord(
      id: docId,
      date: (json['date'] as Timestamp).toDate(),
      foodType: json['foodType'],
      foodAmount: json['foodAmount'],
      weight:
          (json['weight'] ?? 0.0) == 0.0 ? null : json['weight'], // 0이면 null 처리
      note: json['note'],
    );
  }

  // 앱 -> DB
  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      if (foodType != null) 'foodType': foodType,
      if (foodAmount != null) 'foodAmount': foodAmount,
      if (weight != null) 'weight': weight,
      if (note != null) 'note': note,
    };
  }
}
