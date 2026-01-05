import 'package:cloud_firestore/cloud_firestore.dart';

class Pairing {
  final String id;
  final String maleId;
  final String maleName;
  final String femaleId;
  final String femaleName;
  final String species; // 종 정보 (필수)
  final DateTime startDate;
  final String status;
  final String? projectName; // ★ 프로젝트명 추가

  Pairing({
    required this.id,
    required this.maleId,
    required this.maleName,
    required this.femaleId,
    required this.femaleName,
    required this.species,
    required this.startDate,
    this.status = 'Pairing',
    this.projectName,
  });

  factory Pairing.fromJson(Map<String, dynamic> json, String docId) {
    return Pairing(
      id: docId,
      maleId: json['maleId'] ?? '',
      maleName: json['maleName'] ?? 'Unknown',
      femaleId: json['femaleId'] ?? '',
      femaleName: json['femaleName'] ?? 'Unknown',
      species: json['species'] ?? '',
      startDate: (json['startDate'] as Timestamp).toDate(),
      status: json['status'] ?? 'Pairing',
      projectName: json['projectName'], // ★ 불러오기
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maleId': maleId,
      'maleName': maleName,
      'femaleId': femaleId,
      'femaleName': femaleName,
      'species': species,
      'startDate': Timestamp.fromDate(startDate),
      'status': status,
      'projectName': projectName, // ★ 저장하기
    };
  }
}
