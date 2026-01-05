import 'package:flutter/material.dart';
import '../../data/logic/genetic_logic.dart'; // Pairing 모델 import 불필요

class GeneticCalculatorScreen extends StatefulWidget {
  // final Pairing pairing;  <-- 이 줄이 에러의 원인이었습니다. 삭제!

  final String maleName;
  final List<String> maleMorphs;
  final String femaleName;
  final List<String> femaleMorphs;

  const GeneticCalculatorScreen({
    super.key,
    required this.maleName,
    required this.maleMorphs,
    required this.femaleName,
    required this.femaleMorphs,
  });

  @override
  State<GeneticCalculatorScreen> createState() =>
      _GeneticCalculatorScreenState();
}

class _GeneticCalculatorScreenState extends State<GeneticCalculatorScreen> {
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    // 로직 호출
    final results =
        GeneticLogic.calculateOffspring(widget.maleMorphs, widget.femaleMorphs);
    setState(() {
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("2세 유전 예측",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. 부모 정보 카드
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                    child: _buildParentCard("아빠 (Male)", widget.maleName,
                        widget.maleMorphs, Colors.blue)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.close, color: Colors.grey), // 교배 아이콘 X
                ),
                Expanded(
                    child: _buildParentCard("엄마 (Female)", widget.femaleName,
                        widget.femaleMorphs, Colors.pink)),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("예상되는 자식 모프 (확률순)",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ),
          ),

          // 2. 결과 리스트
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              itemCount: _results.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _results[index];
                final double prob = (item['prob'] as double) * 100;
                final String name = item['name'];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: prob >= 25
                            ? Colors.deepOrange.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.2),
                        width: prob >= 25 ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      // 확률 원형 차트
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: prob >= 25
                              ? Colors.deepOrange
                              : Colors.grey.shade300,
                        ),
                        child: Center(
                          child: Text(
                            "${prob.toStringAsFixed(1).replaceAll('.0', '')}%",
                            style: TextStyle(
                                color:
                                    prob >= 25 ? Colors.white : Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 모프 이름
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildParentCard(
      String label, String name, List<String> morphs, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                morphs.isEmpty ? "Normal" : morphs.join(", "),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
