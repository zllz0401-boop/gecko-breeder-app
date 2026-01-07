import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/model/pairing_model.dart';
import '../../data/model/clutch_model.dart';
// ★ 아래 줄이 있어야 해칭 등록 화면으로 이동 가능합니다.
import 'hatchling_add_screen.dart';

class ClutchDetailScreen extends StatefulWidget {
  final Pairing pairing; // 부모 정보
  final Clutch clutch; // 산란 정보

  const ClutchDetailScreen({
    super.key,
    required this.pairing,
    required this.clutch,
  });

  @override
  State<ClutchDetailScreen> createState() => _ClutchDetailScreenState();
}

class _ClutchDetailScreenState extends State<ClutchDetailScreen> {
  // 경과일 계산
  int _calculateDaysPassed() {
    final now = DateTime.now();
    final layDate = widget.clutch.layDate;
    final date1 = DateTime(now.year, now.month, now.day);
    final date2 = DateTime(layDate.year, layDate.month, layDate.day);
    return date1.difference(date2).inDays;
  }

  // ★ 해칭 예정일 계산 (보수적인 안전 공식 적용)
  // 63 - ((온도 - 28) * 4)
  int _getEstimatedDays() {
    final double temp = widget.clutch.incubationTemp ?? 26.5;

    int calculatedDays = (63 - ((temp - 28) * 4)).round();

    // 안전 범위 (38~95일)
    if (calculatedDays < 38) return 38;
    if (calculatedDays > 95) return 95;

    return calculatedDays;
  }

  // 성별 예측 로직 (TSD)
  Map<String, dynamic> _predictGender() {
    final temp = widget.clutch.incubationTemp;
    if (temp == null) return {'text': "온도 정보 없음", 'color': Colors.grey};

    // 1. 저온 암컷 구간 (~28.0도)
    if (temp <= 28.0) {
      return {'text': "암컷 (Female)", 'color': Colors.pink};
    }
    // 2. 랜덤/과도기 구간 (28.1도 ~ 30.5도)
    else if (temp <= 30.5) {
      return {'text': "랜덤/반반 (Mix)", 'color': Colors.purple};
    }
    // 3. 수컷 구간 (30.6도 ~ 33.0도)
    else if (temp <= 33.0) {
      return {'text': "수컷 (Male)", 'color': Colors.blue};
    }
    // 4. 고온 암컷 구간 (33.1도~)
    else {
      return {'text': "고온 암컷 (Hot Female)", 'color': Colors.redAccent};
    }
  }

  @override
  Widget build(BuildContext context) {
    final int daysPassed = _calculateDaysPassed();
    final int totalDays = _getEstimatedDays();
    final int daysLeft = totalDays - daysPassed;

    final DateTime hatchDate =
        widget.clutch.layDate.add(Duration(days: totalDays));
    final genderPrediction = _predictGender();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text("${widget.clutch.order}차 산란 관리"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. D-Day 상태 카드
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  const Text("Incubation Status",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),

                  // D-Day 표시
                  Text(
                    daysLeft > 0 ? "D - $daysLeft" : "해칭 예정! (D+$daysPassed)",
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: daysLeft > 0 ? Colors.deepOrange : Colors.red),
                  ),

                  const SizedBox(height: 4),
                  Text(
                    "예상일: ${DateFormat('yyyy.MM.dd').format(hatchDate)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "(현재 $daysPassed일 / 약 $totalDays일 소요 예상)",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),

                  const Divider(height: 30),

                  // 성별 예측 및 온도 표시
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.thermostat,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.clutch.incubationTemp?.toString() ?? '-'}°C  →  ",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (genderPrediction['color'] as Color)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: genderPrediction['color'] as Color),
                        ),
                        child: Text(
                          genderPrediction['text'] as String,
                          style: TextStyle(
                            color: genderPrediction['color'] as Color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. 부모 정보
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Parents Info",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildParentInfo(
                          "F", widget.pairing.femaleName, Colors.pink),
                      const Icon(Icons.close, color: Colors.grey, size: 16),
                      _buildParentInfo(
                          "M", widget.pairing.maleName, Colors.blue),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text("알 상태 변경",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const SizedBox(height: 10),

            // 3. 액션 버튼
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.egg_alt,
                    label: "부화 성공\n(Hatch)",
                    color: Colors.green,
                    onTap: () {
                      // ★ 해칭 등록 화면으로 데이터 전달하며 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HatchlingAddScreen(
                            maleName: widget.pairing.maleName,
                            maleId: widget.pairing.maleId,
                            femaleName: widget.pairing.femaleName,
                            femaleId: widget.pairing.femaleId,
                            hatchDate: DateTime.now(), // 오늘 태어남
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.delete_forever,
                    label: "알 폐사\n(Disposal)",
                    color: Colors.redAccent,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("폐사 처리 기능 준비 중")));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentInfo(String sex, String name, Color color) {
    return Column(
      children: [
        Text(sex, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
