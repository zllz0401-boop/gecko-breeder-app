import 'package:flutter/material.dart';
// ★★★ [해결 핵심] 아래 줄이 빠져서 에러가 난 겁니다. 이 줄이 꼭 있어야 합니다. ★★★
import '../../data/logic/genetic_logic.dart';

class GeneticCalculatorScreen extends StatefulWidget {
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
  List<Map<String, dynamic>> _outcomes = [];
  List<String> _polygenics = [];

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    // 위에서 import를 했기 때문에 이제 GeneticLogic을 찾을 수 있습니다.
    final result =
        GeneticLogic.calculateOffspring(widget.maleMorphs, widget.femaleMorphs);
    setState(() {
      _outcomes = result['outcomes'] as List<Map<String, dynamic>>;
      _polygenics = result['polygenics'] as List<String>;
    });
  }

  // 모프 색상 반환
  Color _getMorphColor(String morphName) {
    if (GeneticLogic.incDomGenes.contains(morphName) ||
        GeneticLogic.domGenes.contains(morphName)) {
      return Colors.blue.shade700;
    }
    if (morphName.contains("Super ")) {
      return Colors.blue.shade900;
    }
    const List<String> polyKeywords = [
      'Tangerine',
      'Inferno',
      'Mandarin',
      'Blood',
      'Black Night',
      'Black Pearl',
      'Clown',
      'G-Project',
      'Charcoal',
      'Bold',
      'Stripe',
      'Jungle',
      'Aberrant',
      'High Yellow',
      'Normal',
      'Hyper Melanistic',
      'Red Diamond',
      'Electric',
      'Hypo'
    ];
    for (var keyword in polyKeywords) {
      if (morphName.contains(keyword)) return Colors.teal.shade700;
    }
    if (morphName.contains(" ") && !morphName.contains("+")) {
      return Colors.purple.shade600;
    }
    return Colors.pinkAccent.shade700;
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 부모 정보
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                      child: _buildParentCard("아빠", widget.maleName,
                          widget.maleMorphs, Colors.blue)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.close, color: Colors.grey),
                  ),
                  Expanded(
                      child: _buildParentCard("엄마", widget.femaleName,
                          widget.femaleMorphs, Colors.pink)),
                ],
              ),
            ),

            // 형질(Polygenic)
            if (_polygenics.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("🧬 라인 / 형질 (Polygenic)",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _polygenics
                      .map((trait) => Chip(
                            label: Text(trait,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.white)),
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.all(0),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("📊 예상 모프 (Visual Color-coded)",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ),
            const SizedBox(height: 10),

            // 결과 리스트
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              itemCount: _outcomes.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _outcomes[index];
                final double prob = (item['prob'] as double) * 100;
                final String visualName = item['visual'];
                final List<String> hets = item['hets'] as List<String>;
                final List<String> visualParts = visualName.split(" + ");

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: prob >= 25
                              ? Colors.deepOrange
                              : Colors.grey.shade300,
                        ),
                        child: Center(
                          child: Text(
                            "${prob.toStringAsFixed(0)}%",
                            style: TextStyle(
                                color:
                                    prob >= 25 ? Colors.white : Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: visualParts.expand((part) {
                                  return [
                                    TextSpan(
                                      text: part,
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: _getMorphColor(part)),
                                    ),
                                    const TextSpan(
                                      text: " + ",
                                      style: TextStyle(
                                          fontSize: 17, color: Colors.grey),
                                    ),
                                  ];
                                }).toList()
                                  ..removeLast(),
                              ),
                            ),
                            if (hets.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: hets.map((het) {
                                  final bool isConfirmed = het.contains("100%");
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isConfirmed
                                          ? Colors.purple.shade50
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: isConfirmed
                                              ? Colors.purple.shade200
                                              : Colors.orange.shade200,
                                          width: 1),
                                    ),
                                    child: Text(
                                      het,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isConfirmed
                                              ? Colors.purple.shade800
                                              : Colors.deepOrange.shade800),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
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
