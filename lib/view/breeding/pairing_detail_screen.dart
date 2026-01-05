import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/model/pairing_model.dart';
import '../../data/model/clutch_model.dart';
import '../../data/model/animal_model.dart'; // ★ 부모 정보 조회를 위해 추가
import 'genetic_calculator_screen.dart'; // ★ 계산기 화면 import

class PairingDetailScreen extends StatefulWidget {
  final Pairing pairing;

  const PairingDetailScreen({super.key, required this.pairing});

  @override
  State<PairingDetailScreen> createState() => _PairingDetailScreenState();
}

class _PairingDetailScreenState extends State<PairingDetailScreen> {
  // [기능 1] 산란 기록 추가 팝업 (중복 방지 적용됨)
  void _showAddClutchDialog(int nextOrder) {
    DateTime layDate = DateTime.now();
    final TextEditingController countController =
        TextEditingController(text: "2");
    final TextEditingController memoController = TextEditingController();

    bool isSaving = false; // 로딩 상태

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("$nextOrder차 산란 기록"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title:
                      Text("산란일: ${DateFormat('yyyy-MM-dd').format(layDate)}"),
                  trailing: const Icon(Icons.calendar_today),
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: layDate,
                      firstDate: widget.pairing.startDate,
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDialogState(() => layDate = picked);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "알 개수 (개)",
                      border: OutlineInputBorder(),
                      isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: memoController,
                  decoration: const InputDecoration(
                      labelText: "메모 (예: 1유정 1무정)",
                      border: OutlineInputBorder(),
                      isDense: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text("취소")),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true); // 버튼 비활성화

                        try {
                          // DB 중복 체크
                          final checkQuery = await FirebaseFirestore.instance
                              .collection('pairings')
                              .doc(widget.pairing.id)
                              .collection('clutches')
                              .where('order', isEqualTo: nextOrder)
                              .get();

                          if (checkQuery.docs.isNotEmpty) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "이미 $nextOrder차 산란 기록이 존재합니다.")));
                            }
                            return;
                          }

                          // 저장 실행
                          await FirebaseFirestore.instance
                              .collection('pairings')
                              .doc(widget.pairing.id)
                              .collection('clutches')
                              .add({
                            'pairingId': widget.pairing.id,
                            'order': nextOrder,
                            'layDate': Timestamp.fromDate(layDate),
                            'eggCount': int.tryParse(countController.text) ?? 0,
                            'memo': memoController.text,
                            'created_at': FieldValue.serverTimestamp(),
                          });

                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("저장 중 오류가 발생했습니다.")));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("저장"),
              ),
            ],
          );
        },
      ),
    );
  }

  // [기능 2] 커플 삭제
  void _deletePairing() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("커플 기록을 삭제하시겠습니까?"),
        content: const Text("포함된 모든 산란 기록도 함께 삭제됩니다."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("취소")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('pairings')
          .doc(widget.pairing.id)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }

  // ★ [기능 3] 부모 정보 로딩 및 계산기 이동 (새로 추가됨)
  Future<void> _openGeneticCalculator() async {
    // 1. 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. 부모(수컷, 암컷) 정보 DB에서 가져오기
      final maleDoc = await FirebaseFirestore.instance
          .collection('animals')
          .doc(widget.pairing.maleId)
          .get();
      final femaleDoc = await FirebaseFirestore.instance
          .collection('animals')
          .doc(widget.pairing.femaleId)
          .get();

      if (!maleDoc.exists || !femaleDoc.exists)
        throw Exception("부모 개체 정보를 찾을 수 없습니다.");

      final male = Animal.fromJson(maleDoc.data()!, maleDoc.id);
      final female = Animal.fromJson(femaleDoc.data()!, femaleDoc.id);

      // 모프 문자열 -> 리스트 변환 (예: "Mack Snow, Eclipse" -> ["Mack Snow", "Eclipse"])
      List<String> maleMorphs = male.morph.isEmpty || male.morph == 'Normal'
          ? []
          : male.morph.split(', ');
      List<String> femaleMorphs =
          female.morph.isEmpty || female.morph == 'Normal'
              ? []
              : female.morph.split(', ');

      if (mounted) {
        Navigator.pop(context); // 로딩 닫기
        // 3. 계산기 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GeneticCalculatorScreen(
              maleName: male.name,
              maleMorphs: maleMorphs,
              femaleName: female.name,
              femaleMorphs: femaleMorphs,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 닫기
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("오류: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("Pairing Detail",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: _deletePairing,
              icon: const Icon(Icons.delete_outline, color: Colors.grey)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 커플 정보 카드 (헤더)
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _buildInfoCard(
                              "아빠", widget.pairing.maleName, Colors.blue)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.favorite,
                            color: Colors.redAccent, size: 32),
                      ),
                      Expanded(
                          child: _buildInfoCard(
                              "엄마", widget.pairing.femaleName, Colors.pink)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "합사일: ${DateFormat('yyyy년 MM월 dd일').format(widget.pairing.startDate)} ~",
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  // ★ [추가] 2세 예측 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openGeneticCalculator,
                      icon: const Icon(Icons.science,
                          color: Colors.white), // 과학 아이콘
                      label: const Text("2세 모프 예측하기 (Genetic Calculator)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 산란 기록 리스트 (Clutch List)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pairings')
                    .doc(widget.pairing.id)
                    .collection('clutches')
                    .orderBy('order', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Center(
                      child: Text("아직 산란 기록이 없습니다.\n알을 낳으면 아래 버튼을 눌러주세요!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade400)),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final clutch = Clutch.fromJson(
                          docs[index].data() as Map<String, dynamic>,
                          docs[index].id);
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 5)
                          ],
                        ),
                        child: Row(
                          children: [
                            // 차수 배지
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Text("${clutch.order}차",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange)),
                            ),
                            const SizedBox(width: 16),
                            // 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "${DateFormat('yyyy.MM.dd').format(clutch.layDate)} 산란",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(
                                      "🥚 ${clutch.eggCount}개  |  ${clutch.memo ?? ''}",
                                      style: TextStyle(
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 3. 산란 추가 버튼
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pairings')
            .doc(widget.pairing.id)
            .collection('clutches')
            .snapshots(),
        builder: (context, snapshot) {
          int nextOrder = 1;
          if (snapshot.hasData) nextOrder = snapshot.data!.docs.length + 1;

          return FloatingActionButton.extended(
            onPressed: () => _showAddClutchDialog(nextOrder),
            label: Text("🥚 $nextOrder차 산란 등록"),
            backgroundColor: Colors.deepOrange,
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String name, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(name,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }
}
