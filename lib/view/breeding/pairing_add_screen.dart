import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/model/animal_model.dart';
import '../home/widget/qr_scanner_screen.dart'; // QR 스캐너 import

class PairingAddScreen extends StatefulWidget {
  final Animal? initialAnimal; // 상세페이지에서 넘어왔을 때 사용

  const PairingAddScreen({super.key, this.initialAnimal});

  @override
  State<PairingAddScreen> createState() => _PairingAddScreenState();
}

class _PairingAddScreenState extends State<PairingAddScreen> {
  Animal? _selectedMale;
  Animal? _selectedFemale;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  // 파트너 선택을 위한 리스트
  List<Animal> _availablePartners = [];

  @override
  void initState() {
    super.initState();
    // 1. 초기 개체 세팅 (상세페이지에서 넘어온 경우)
    if (widget.initialAnimal != null) {
      if (widget.initialAnimal!.gender == 'Male') {
        _selectedMale = widget.initialAnimal;
      } else if (widget.initialAnimal!.gender == 'Female') {
        _selectedFemale = widget.initialAnimal;
      }
      // 2. 파트너 목록 불러오기
      _loadPartners();
    }
  }

  // ★ 파트너 목록 로드 (종은 같고, 성별은 반대인 개체들)
  Future<void> _loadPartners() async {
    if (widget.initialAnimal == null) return;

    final targetGender =
        widget.initialAnimal!.gender == 'Male' ? 'Female' : 'Male';
    final targetSpecies = widget.initialAnimal!.species;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('species', isEqualTo: targetSpecies)
          .where('gender', isEqualTo: targetGender)
          // .where('status', isEqualTo: 'Breeding') // 필요하면 상태값 필터도 추가 가능
          .get();

      setState(() {
        _availablePartners = snapshot.docs
            .map((doc) => Animal.fromJson(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      print("파트너 로드 오류: $e");
    }
  }

  // ★ QR 코드로 파트너 찾기
  Future<void> _scanPartnerQR() async {
    final String? scannedId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (scannedId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('animals')
            .doc(scannedId)
            .get();
        if (doc.exists) {
          final scannedAnimal = Animal.fromJson(doc.data()!, doc.id);

          // 유효성 검사
          if (widget.initialAnimal != null) {
            if (scannedAnimal.species != widget.initialAnimal!.species) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("종(Species)이 다릅니다!")));
              }
              return;
            }
            if (scannedAnimal.gender == widget.initialAnimal!.gender) {
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text("성별이 같습니다!")));
              }
              return;
            }
          }

          setState(() {
            if (scannedAnimal.gender == 'Male') {
              _selectedMale = scannedAnimal;
            } else {
              _selectedFemale = scannedAnimal;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${scannedAnimal.name} 선택됨")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("개체 정보를 불러오지 못했습니다.")));
      }
    }
  }

  Future<void> _savePairing() async {
    if (_selectedMale == null || _selectedFemale == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("암수 개체를 모두 선택해주세요.")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('pairings').add({
        'maleId': _selectedMale!.id,
        'maleName': _selectedMale!.name,
        'femaleId': _selectedFemale!.id,
        'femaleName': _selectedFemale!.name,
        'startDate': Timestamp.fromDate(_startDate),
        'isActive': true,
        'created_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("페어링이 등록되었습니다!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("오류: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 내가 남자면 -> 남자는 고정, 여자는 선택
    // 내가 여자면 -> 여자는 고정, 남자는 선택
    final bool isMaleFixed = widget.initialAnimal?.gender == 'Male';
    final bool isFemaleFixed = widget.initialAnimal?.gender == 'Female';

    return Scaffold(
      appBar: AppBar(title: const Text("새 페어링 등록")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 커플 카드 UI
              Row(
                children: [
                  Expanded(
                      child: _buildSelectionCard("아빠 (Male)", _selectedMale,
                          Colors.blue, isMaleFixed)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child:
                        Icon(Icons.favorite, color: Colors.redAccent, size: 32),
                  ),
                  Expanded(
                      child: _buildSelectionCard("엄마 (Female)", _selectedFemale,
                          Colors.pink, isFemaleFixed)),
                ],
              ),

              const SizedBox(height: 30),

              // 2. 날짜 선택
              ListTile(
                title: const Text("합사 시작일"),
                subtitle: Text(DateFormat('yyyy년 MM월 dd일').format(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300)),
                onTap: () async {
                  final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now());
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),

              const Spacer(),

              // 3. 저장 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _savePairing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("페어링 시작하기"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 선택 카드 위젯
  Widget _buildSelectionCard(
      String label, Animal? animal, Color color, bool isFixed) {
    final bool isTarget = !isFixed; // 내가 선택해야 할 대상인가?

    return GestureDetector(
      onTap: isTarget
          ? () {
              // 선택 모달 띄우기 (파트너 리스트)
              _showPartnerSelectionSheet(label.contains("Male"));
            }
          : null,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (animal != null) ...[
              // 선택된 개체 정보
              CircleAvatar(
                radius: 30,
                backgroundImage: animal.photoUrl != null
                    ? NetworkImage(animal.photoUrl!)
                    : null,
                backgroundColor: color.withOpacity(0.2),
                child: animal.photoUrl == null
                    ? Icon(Icons.pets, color: color)
                    : null,
              ),
              const SizedBox(height: 10),
              Text(animal.name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: color),
                  overflow: TextOverflow.ellipsis),
              Text(animal.morph,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ] else ...[
              // 선택 안됨
              Icon(Icons.add_circle_outline,
                  size: 40, color: color.withOpacity(0.5)),
              const SizedBox(height: 8),
              Text("터치하여 선택",
                  style:
                      TextStyle(color: color.withOpacity(0.6), fontSize: 12)),
            ],

            // 변경/QR 버튼 (고정되지 않은 경우에만)
            if (isTarget) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Select",
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 14),
                  ],
                ),
              )
            ] else ...[
              const SizedBox(height: 8),
              const Text("(고정됨)",
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }

  // ★ 파트너 선택 바텀 시트 (리스트 + QR 버튼)
  void _showPartnerSelectionSheet(bool selectingMale) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(selectingMale ? "아빠 선택" : "엄마 선택",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),

                  // ★ QR 스캔 버튼
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // 시트 닫고
                      _scanPartnerQR(); // 스캔 화면으로
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("QR로 찾기"),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.deepOrange),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _availablePartners.isEmpty
                  ? Center(
                      child: Text(
                          "매칭 가능한 ${selectingMale ? '수컷' : '암컷'}이 없습니다.",
                          style: const TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _availablePartners.length,
                      itemBuilder: (context, index) {
                        final partner = _availablePartners[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: partner.photoUrl != null
                                ? NetworkImage(partner.photoUrl!)
                                : null,
                            child: partner.photoUrl == null
                                ? const Icon(Icons.pets, size: 16)
                                : null,
                          ),
                          title: Text(partner.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(partner.morph),
                          onTap: () {
                            setState(() {
                              if (selectingMale) {
                                _selectedMale = partner;
                              } else {
                                _selectedFemale = partner;
                              }
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
