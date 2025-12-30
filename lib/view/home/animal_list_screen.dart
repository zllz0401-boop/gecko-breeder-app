import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/model/animal_model.dart';
import 'animal_add_screen.dart';
import '../../view/detail/animal_detail_screen.dart';
import 'widget/qr_scanner_screen.dart';

class AnimalListScreen extends StatefulWidget {
  const AnimalListScreen({super.key});

  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends State<AnimalListScreen> {
  Future<void> _onCameraTap() async {
    final String? scannedId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (scannedId != null && mounted) {
      _findAndGoToDetail(scannedId);
    }
  }

  Future<void> _findAndGoToDetail(String id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final docSnapshot =
          await FirebaseFirestore.instance.collection('animals').doc(id).get();
      if (!mounted) return;
      Navigator.pop(context);

      if (docSnapshot.exists) {
        final animal = Animal.fromJson(docSnapshot.data()!, docSnapshot.id);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AnimalDetailScreen(animal: animal)));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("등록되지 않은 개체입니다.")));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("오류가 발생했습니다.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Gecko Breeder',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: _onCameraTap,
              icon: const Icon(Icons.qr_code_scanner, size: 28)),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('animals').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
              return const Center(
                  child: Text("등록된 개체가 없습니다.",
                      style: TextStyle(color: Colors.grey)));

            final docs = snapshot.data!.docs;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final animal = Animal.fromJson(data, docs[index].id);

                // 성별 색상 설정
                Color genderColor = Colors.grey;
                if (animal.gender == 'Male')
                  genderColor = Colors.blue;
                else if (animal.gender == 'Female') genderColor = Colors.pink;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                AnimalDetailScreen(animal: animal)));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
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
                    child: Row(
                      children: [
                        // 1. 썸네일
                        Hero(
                          tag: animal.id ?? 'thumb$index',
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              image: animal.photoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(animal.photoUrl!),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: animal.photoUrl == null
                                ? const Icon(Icons.pets, color: Colors.grey)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // 2. 정보 영역 (배치 수정됨)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 첫째 줄: [이름] ------- [무게]
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      animal.name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text("${animal.weight}g",
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87)),
                                ],
                              ),
                              const SizedBox(height: 2),

                              // 둘째 줄: [종]
                              Text(animal.species,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),

                              // 셋째 줄: [모프] ------- [성별]
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      animal.morph,
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // 성별 표시 (색상 들어간 텍스트)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: genderColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(animal.gender,
                                        style: TextStyle(
                                            color: genderColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 화살표 아이콘 (약간의 여백 추가)
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right,
                            color: Colors.grey.shade300, size: 20),
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
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AnimalAddScreen()));
        },
        label: const Text("개체 등록"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
    );
  }
}
