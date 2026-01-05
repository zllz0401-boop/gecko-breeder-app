import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/model/pairing_model.dart';
import 'pairing_add_screen.dart';
import 'pairing_detail_screen.dart';

class BreedingScreen extends StatelessWidget {
  const BreedingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("Breeding Room",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pairings')
              .orderBy('created_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.favorite_border, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("진행 중인 페어링이 없습니다.",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pairing = Pairing.fromJson(
                    docs[index].data() as Map<String, dynamic>, docs[index].id);

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
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ★ 1. 프로젝트명 (가장 크게)
                        Row(
                          children: [
                            const Icon(Icons.folder_open,
                                size: 18, color: Colors.deepOrange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pairing.projectName ?? "Untitled Project",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 상태 배지
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text("Pairing",
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // 2. 아빠 <-> 엄마
                        Row(
                          children: [
                            Expanded(
                                child: _buildNameTag(
                                    pairing.maleName, Colors.blue)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child:
                                  Icon(Icons.favorite, color: Colors.redAccent),
                            ),
                            Expanded(
                                child: _buildNameTag(
                                    pairing.femaleName, Colors.pink)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 3. 날짜 (맨 아래 작게)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Since ${DateFormat('yyyy.MM.dd').format(pairing.startDate)}",
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const PairingAddScreen())),
        label: const Text("새 커플"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildNameTag(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(name,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
