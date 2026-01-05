import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../data/model/animal_model.dart';
import '../../../data/model/pairing_model.dart';
import '../../breeding/pairing_detail_screen.dart'; // 산란 기록 상세

class BreedingHistoryFullScreen extends StatelessWidget {
  final Animal animal;

  const BreedingHistoryFullScreen({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    // 성별에 따른 검색 필드 설정
    final String searchField = animal.gender == 'Male' ? 'maleId' : 'femaleId';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("전체 브리딩 기록",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pairings')
              .where(searchField, isEqualTo: animal.id)
              .orderBy('startDate', descending: true) // 최신순
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text("기록이 없습니다."));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pairing = Pairing.fromJson(
                    docs[index].data() as Map<String, dynamic>, docs[index].id);

                // 파트너 정보
                final partnerName = animal.gender == 'Male'
                    ? pairing.femaleName
                    : pairing.maleName;
                final partnerColor =
                    animal.gender == 'Male' ? Colors.pink : Colors.blue;

                return GestureDetector(
                  onTap: () {
                    // 누르면 커플 상세(산란 기록)로 이동
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                PairingDetailScreen(pairing: pairing)));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.1), blurRadius: 4)
                      ],
                    ),
                    child: Row(
                      children: [
                        // 번호 (최신순이므로 역순 번호 or 그냥 인덱스)
                        Text("${docs.length - index}",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade400)),
                        const SizedBox(width: 16),

                        // 내용
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("With $partnerName",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: partnerColor)),
                              const SizedBox(height: 4),
                              Text(
                                  "Since ${DateFormat('yyyy.MM.dd').format(pairing.startDate)}",
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),

                        // 상태 배지 (Pairing / End)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: pairing.status == 'Pairing'
                                ? Colors.red.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(pairing.status,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: pairing.status == 'Pairing'
                                      ? Colors.red
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
