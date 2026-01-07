import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../data/model/animal_model.dart';
import '../../../data/model/pairing_model.dart';
import '../../breeding/pairing_detail_screen.dart';
import '../../breeding/pairing_add_screen.dart';

class BreedingHistoryFullScreen extends StatelessWidget {
  final Animal animal;

  const BreedingHistoryFullScreen({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text("${animal.name}의 브리딩 기록"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pairings')
            .orderBy('startDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // 내 기록만 필터링
          final myPairings = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['maleId'] == animal.id || data['femaleId'] == animal.id;
          }).toList();

          if (myPairings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text("아직 브리딩 기록이 없습니다.",
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: myPairings.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = myPairings[index];
              final pairing =
                  Pairing.fromJson(doc.data() as Map<String, dynamic>, doc.id);

              final bool isMale = animal.gender == 'Male';
              final String partnerName =
                  isMale ? pairing.femaleName : pairing.maleName;

              // ★ [수정됨] endDate 에러 해결: 시작일만 표시
              return GestureDetector(
                onTap: () {
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
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.1), blurRadius: 5)
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMale
                              ? Colors.pink.shade50
                              : Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.favorite,
                            color: isMale ? Colors.pink : Colors.blue,
                            size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("With $partnerName",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            // endDate 대신 '합사 시작' 문구로 변경
                            Text(
                              "${DateFormat('yyyy.MM.dd').format(pairing.startDate)} 합사 시작",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PairingAddScreen(initialAnimal: animal)));
        },
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.add_link),
        label: const Text("새 페어링"),
      ),
    );
  }
}
