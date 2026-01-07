import 'package:cloud_firestore/cloud_firestore.dart';

class Animal {
  final String id;
  final String name;
  final String species;
  final String morph;
  final String gender;
  final String status;
  final DateTime birthDate;
  final DateTime adoptionDate;
  final double weight;
  final String? memo;
  final String? photoUrl;

  // 부모 정보
  final String? fatherId;
  final String? fatherName;
  final String? motherId;
  final String? motherName;

  final DateTime? createdAt;

  Animal({
    required this.id,
    required this.name,
    required this.species,
    required this.morph,
    required this.gender,
    this.status = 'Alive',
    required this.birthDate,
    required this.adoptionDate,
    required this.weight,
    this.memo,
    this.photoUrl,
    this.fatherId,
    this.fatherName,
    this.motherId,
    this.motherName,
    this.createdAt,
  });

  factory Animal.fromJson(Map<String, dynamic> json, String id) {
    return Animal(
      id: id,
      name: json['name'] ?? '',
      species: json['species'] ?? 'Leopard Gecko',
      morph: json['morph'] ?? 'Normal',
      gender: json['gender'] ?? 'Unknown',
      status: json['status'] ?? 'Alive',

      // ★ [수정됨] 날짜 데이터가 비어있으면(null) 에러 내지 말고 오늘 날짜로 대체
      birthDate: json['birthDate'] != null
          ? (json['birthDate'] as Timestamp).toDate()
          : DateTime.now(),

      adoptionDate: json['adoptionDate'] != null
          ? (json['adoptionDate'] as Timestamp).toDate()
          : DateTime.now(),

      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      memo: json['memo'],
      photoUrl: json['photoUrl'],

      fatherId: json['fatherId'],
      fatherName: json['fatherName'],
      motherId: json['motherId'],
      motherName: json['motherName'],

      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'morph': morph,
      'gender': gender,
      'status': status,
      'birthDate': Timestamp.fromDate(birthDate),
      'adoptionDate': Timestamp.fromDate(adoptionDate),
      'weight': weight,
      'memo': memo,
      'photoUrl': photoUrl,
      'fatherId': fatherId,
      'fatherName': fatherName,
      'motherId': motherId,
      'motherName': motherName,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
