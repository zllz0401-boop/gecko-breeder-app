import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/model/animal_model.dart';
import '../home/widget/qr_scanner_screen.dart';

class PairingAddScreen extends StatefulWidget {
  const PairingAddScreen({super.key});

  @override
  State<PairingAddScreen> createState() => _PairingAddScreenState();
}

class _PairingAddScreenState extends State<PairingAddScreen> {
  DateTime _startDate = DateTime.now();

  // ★ 프로젝트명 입력 컨트롤러
  final TextEditingController _projectController = TextEditingController();

  String? _selectedMaleId;
  String? _selectedMaleName;
  String? _selectedMaleSpecies;

  String? _selectedFemaleId;
  String? _selectedFemaleName;
  String? _selectedFemaleSpecies;

  bool _isLoading = false;

  @override
  void dispose() {
    _projectController.dispose();
    super.dispose();
  }

  Stream<List<Animal>> _getAnimalsByGender(
      String gender, String? targetSpecies) {
    return FirebaseFirestore.instance
        .collection('animals')
        .where('gender', isEqualTo: gender)
        .snapshots()
        .map((snapshot) {
      final animals = snapshot.docs
          .map((doc) => Animal.fromJson(doc.data(), doc.id))
          .toList();
      if (targetSpecies != null) {
        return animals.where((a) => a.species == targetSpecies).toList();
      }
      return animals;
    });
  }

  Future<void> _scanAndSelect(bool isMale) async {
    final String? scannedId = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => const QrScannerScreen()));
    if (scannedId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('animals')
        .doc(scannedId)
        .get();
    if (!doc.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("등록되지 않은 개체입니다.")));
      return;
    }

    final animal = Animal.fromJson(doc.data()!, doc.id);
    final targetGender = isMale ? 'Male' : 'Female';

    if (animal.gender != targetGender) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("성별이 맞지 않습니다. (${animal.gender})")));
      return;
    }

    if (isMale) {
      if (_selectedFemaleSpecies != null &&
          _selectedFemaleSpecies != animal.species) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("종이 다릅니다!")));
        return;
      }
    } else {
      if (_selectedMaleSpecies != null &&
          _selectedMaleSpecies != animal.species) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("종이 다릅니다!")));
        return;
      }
    }

    setState(() {
      if (isMale) {
        _selectedMaleId = animal.id;
        _selectedMaleName = animal.name;
        _selectedMaleSpecies = animal.species;
      } else {
        _selectedFemaleId = animal.id;
        _selectedFemaleName = animal.name;
        _selectedFemaleSpecies = animal.species;
      }
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("'${animal.name}' 선택 완료!")));
  }

  Future<void> _savePairing() async {
    if (_selectedMaleId == null || _selectedFemaleId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("수컷과 암컷을 모두 선택해주세요.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('pairings').add({
        'projectName': _projectController.text.isEmpty
            ? 'Untitled Project'
            : _projectController.text, // ★ 저장
        'maleId': _selectedMaleId,
        'maleName': _selectedMaleName ?? 'Unknown',
        'femaleId': _selectedFemaleId,
        'femaleName': _selectedFemaleName ?? 'Unknown',
        'species': _selectedMaleSpecies ?? 'Unknown',
        'startDate': Timestamp.fromDate(_startDate),
        'status': 'Pairing',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("에러: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("새로운 커플 등록")),
      body: SafeArea(
        child: SingleChildScrollView(
          // 스크롤 가능하게 변경
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ★ 0. 프로젝트명 입력 (맨 위)
              const Text("프로젝트명 (Project Name)",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              TextField(
                controller: _projectController,
                decoration: const InputDecoration(
                  hintText: "예: 블랙나이트 프로젝트",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 24),

              // 1. 수컷 선택
              const Text("아빠 (Male)",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue)),
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<List<Animal>>(
                      stream:
                          _getAnimalsByGender('Male', _selectedFemaleSpecies),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const LinearProgressIndicator();
                        final males = snapshot.data!;

                        if (males.isEmpty && _selectedFemaleSpecies != null) {
                          return Text("등록된 ${_selectedFemaleSpecies} 수컷이 없습니다.",
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12));
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedMaleId,
                          isExpanded: true,
                          hint: const Text("수컷 선택"),
                          items: males.map((animal) {
                            return DropdownMenuItem(
                              value: animal.id,
                              child: Text("${animal.name} (${animal.species})",
                                  overflow: TextOverflow.ellipsis),
                              onTap: () {
                                setState(() {
                                  _selectedMaleName = animal.name;
                                  _selectedMaleSpecies = animal.species;
                                  if (_selectedFemaleSpecies != null &&
                                      _selectedFemaleSpecies !=
                                          animal.species) {
                                    _selectedFemaleId = null;
                                    _selectedFemaleName = null;
                                    _selectedFemaleSpecies = null;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "종이 변경되어 암컷 선택이 해제되었습니다.")));
                                  }
                                });
                              },
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedMaleId = val),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                      onPressed: () => _scanAndSelect(true),
                      icon: const Icon(Icons.qr_code_scanner,
                          size: 30, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 20),

              // 2. 암컷 선택
              const Text("엄마 (Female)",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.pink)),
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<List<Animal>>(
                      stream:
                          _getAnimalsByGender('Female', _selectedMaleSpecies),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const LinearProgressIndicator();
                        final females = snapshot.data!;

                        if (females.isEmpty && _selectedMaleSpecies != null) {
                          return Text("등록된 ${_selectedMaleSpecies} 암컷이 없습니다.",
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12));
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedFemaleId,
                          isExpanded: true,
                          hint: const Text("암컷 선택"),
                          items: females.map((animal) {
                            return DropdownMenuItem(
                              value: animal.id,
                              child: Text("${animal.name} (${animal.species})",
                                  overflow: TextOverflow.ellipsis),
                              onTap: () {
                                setState(() {
                                  _selectedFemaleName = animal.name;
                                  _selectedFemaleSpecies = animal.species;
                                  if (_selectedMaleSpecies != null &&
                                      _selectedMaleSpecies != animal.species) {
                                    _selectedMaleId = null;
                                    _selectedMaleName = null;
                                    _selectedMaleSpecies = null;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "종이 변경되어 수컷 선택이 해제되었습니다.")));
                                  }
                                });
                              },
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedFemaleId = val),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                      onPressed: () => _scanAndSelect(false),
                      icon: const Icon(Icons.qr_code_scanner,
                          size: 30, color: Colors.pink)),
                ],
              ),
              const SizedBox(height: 20),

              // 3. 합사일
              const Text("합사일 (Pairing Date)",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now());
                  if (picked != null) setState(() => _startDate = picked);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('yyyy년 MM월 dd일').format(_startDate)),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              ),

              const SizedBox(height: 40),

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
                    : const Text("커플 맺기 ❤️"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
