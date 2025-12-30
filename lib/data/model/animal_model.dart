import 'package:cloud_firestore/cloud_firestore.dart';

class Animal {
  String? id;
  String name;
  String species;
  String morph;
  String gender;
  double weight;
  DateTime birthDate;
  DateTime adoptDate;
  String status;
  String? photoUrl;

  Animal({
    this.id,
    required this.name,
    required this.species,
    required this.morph,
    required this.gender,
    required this.weight,
    required this.birthDate,
    required this.adoptDate,
    required this.status,
    this.photoUrl,
  });

  // ★ 이 부분이 없어서 에러가 났던 겁니다!
  // DB 데이터(JSON)를 가져와서 내 앱의 객체(Animal)로 변환하는 기능
  factory Animal.fromJson(Map<String, dynamic> json, String docId) {
    return Animal(
      id: docId,
      name: json['name'] ?? '',
      species: json['species'] ?? '',
      morph: json['morph'] ?? '',
      gender: json['gender'] ?? 'Unknown',
      weight: (json['weight'] ?? 0.0).toDouble(),
      // 날짜는 Timestamp라는 특수 형태로 저장되므로 변환 필요
      birthDate: (json['birthDate'] as Timestamp).toDate(),
      adoptDate: (json['adoptDate'] as Timestamp).toDate(),
      status: json['status'] ?? '',
      photoUrl: json['photoUrl'],
    );
  }

  // 반대로 내 객체를 DB에 저장할 때 변환하는 기능
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'morph': morph,
      'gender': gender,
      'weight': weight,
      'birthDate': Timestamp.fromDate(birthDate),
      'adoptDate': Timestamp.fromDate(adoptDate),
      'status': status,
      'photoUrl': photoUrl,
      'created_at': FieldValue.serverTimestamp(), // 최신순 정렬을 위해 추가
    };
  }
}
