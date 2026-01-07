import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/model/animal_model.dart';
import 'widget/morph_selection_dialog.dart'; // ★ 모프 선택 팝업 import

class AnimalAddScreen extends StatefulWidget {
  final Animal? animal;

  const AnimalAddScreen({super.key, this.animal});

  @override
  State<AnimalAddScreen> createState() => _AnimalAddScreenState();
}

class _AnimalAddScreenState extends State<AnimalAddScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _weightController;

  late TextEditingController _customSpeciesController;
  String _selectedSpecies = 'Leopard Gecko';
  final List<String> _speciesOptions = [
    'Leopard Gecko',
    'Fat-tailed Gecko',
    'Crested Gecko',
    'Direct Input'
  ];

  // ★ 모프 관련 변수 (텍스트 컨트롤러 대신 리스트 사용)
  List<String> _selectedMorphList = [];

  String _selectedGender = 'Male';
  String _selectedStatus = 'Holdback';
  DateTime _birthDate = DateTime.now();
  DateTime _adoptDate = DateTime.now();

  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _customSpeciesController = TextEditingController();

    if (widget.animal != null) {
      _nameController = TextEditingController(text: widget.animal!.name);
      _weightController =
          TextEditingController(text: widget.animal!.weight.toString());
      _selectedGender = widget.animal!.gender;
      _selectedStatus = widget.animal!.status;
      _birthDate = widget.animal!.birthDate;
      _adoptDate = widget.animal!.adoptionDate;

      // 종 데이터 불러오기
      if (_speciesOptions.contains(widget.animal!.species)) {
        _selectedSpecies = widget.animal!.species;
      } else {
        _selectedSpecies = 'Direct Input';
        _customSpeciesController.text = widget.animal!.species;
      }

      // ★ 기존 모프 데이터 불러오기 (콤마로 구분된 문자열 -> 리스트로 변환)
      if (widget.animal!.morph.isNotEmpty) {
        _selectedMorphList = widget.animal!.morph.split(', ').toList();
      }
    } else {
      _nameController = TextEditingController();
      _weightController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _customSpeciesController.dispose();
    super.dispose();
  }

  // ★ [기능] 모프 선택 팝업 열기
  Future<void> _showMorphDialog() async {
    final List<String>? result = await showDialog(
      context: context,
      builder: (context) =>
          MorphSelectionDialog(selectedMorphs: _selectedMorphList),
    );

    if (result != null) {
      setState(() {
        _selectedMorphList = result;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? downloadUrl = widget.animal?.photoUrl;

      if (_imageFile != null) {
        final String fileName = "${const Uuid().v4()}.jpg";
        final Reference storageRef =
            FirebaseStorage.instance.ref().child("animal_photos/$fileName");
        await storageRef.putFile(_imageFile!);
        downloadUrl = await storageRef.getDownloadURL();
      }

      String finalSpecies = _selectedSpecies;
      if (_selectedSpecies == 'Direct Input') {
        if (_customSpeciesController.text.trim().isEmpty) {
          throw Exception("종 이름을 입력해주세요.");
        }
        finalSpecies = _customSpeciesController.text.trim();
      }

      // ★ 저장 시: 리스트를 문자열로 합쳐서 저장 (예: "Mack Snow, Eclipse")
      String finalMorphString =
          _selectedMorphList.isEmpty ? "Normal" : _selectedMorphList.join(", ");

      final Map<String, dynamic> animalData = {
        'name': _nameController.text,
        'species': finalSpecies,
        'morph': finalMorphString, // ★ 여기서 합쳐서 저장됨
        'gender': _selectedGender,
        'weight': double.tryParse(_weightController.text) ?? 0.0,
        'birthDate': Timestamp.fromDate(_birthDate),
        'adoptDate': Timestamp.fromDate(_adoptDate),
        'status': _selectedStatus,
        'photoUrl': downloadUrl,
      };

      if (widget.animal != null) {
        await FirebaseFirestore.instance
            .collection('animals')
            .doc(widget.animal!.id)
            .update(animalData);
      } else {
        animalData['created_at'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('animals').add(animalData);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.animal != null ? "수정되었습니다." : "등록되었습니다.")));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", ""))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isBirth) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBirth ? _birthDate : _adoptDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => isBirth ? _birthDate = picked : _adoptDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.animal != null ? "개체 정보 수정" : "새 개체 등록";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 이미지 영역
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover)
                                : (widget.animal?.photoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(
                                            widget.animal!.photoUrl!),
                                        fit: BoxFit.cover)
                                    : null),
                          ),
                          child: (_imageFile == null &&
                                  widget.animal?.photoUrl == null)
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      Icon(Icons.add_a_photo,
                                          size: 40, color: Colors.grey),
                                      Text("사진 변경/추가")
                                    ])
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 이름
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            labelText: "이름",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.abc)),
                        validator: (value) =>
                            value!.isEmpty ? "이름을 입력해주세요" : null,
                      ),
                      const SizedBox(height: 12),

                      // 종 선택
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSpecies,
                        decoration: const InputDecoration(
                            labelText: "종(Species)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category)),
                        items: _speciesOptions
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s == 'Direct Input' ? '직접 입력' : s)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedSpecies = val!),
                      ),
                      if (_selectedSpecies == 'Direct Input') ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customSpeciesController,
                          decoration: const InputDecoration(
                              labelText: "종 이름 직접 입력",
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Color(0xFFF5F5F7)),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // ★★★ 모프 멀티 선택 UI (변경된 부분) ★★★
                      const Text("모프 / 유전 정보 (Morphs)",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showMorphDialog, // 누르면 팝업 열림
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.palette, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                // 선택된 모프가 없으면 안내 문구, 있으면 칩(태그)으로 표시
                                child: _selectedMorphList.isEmpty
                                    ? const Text("모프를 선택해주세요 (터치)",
                                        style: TextStyle(color: Colors.black54))
                                    : Wrap(
                                        spacing: 6,
                                        runSpacing: 0,
                                        children:
                                            _selectedMorphList.map((morph) {
                                          return Chip(
                                            label: Text(morph,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white)),
                                            backgroundColor: Colors.deepOrange,
                                            deleteIcon: const Icon(Icons.close,
                                                size: 14, color: Colors.white),
                                            onDeleted: () {
                                              setState(() {
                                                _selectedMorphList
                                                    .remove(morph);
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 무게
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: "무게 (g)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.scale)),
                      ),
                      const SizedBox(height: 20),

                      // 성별 & 상태
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedGender,
                              decoration: const InputDecoration(
                                  labelText: "성별",
                                  border: OutlineInputBorder()),
                              items: ['Male', 'Female', 'Unknown']
                                  .map((g) => DropdownMenuItem(
                                      value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedGender = val!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              decoration: const InputDecoration(
                                  labelText: "상태",
                                  border: OutlineInputBorder()),
                              items: ['Breeding', 'Holdback', 'For Sale', 'Pet']
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedStatus = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 날짜
                      Row(children: [
                        Expanded(
                            child: OutlinedButton.icon(
                                icon: const Icon(Icons.cake),
                                label: Text(
                                    "해칭일: ${DateFormat('yyyy-MM-dd').format(_birthDate)}"),
                                onPressed: () => _selectDate(context, true)))
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                            child: OutlinedButton.icon(
                                icon: const Icon(Icons.home),
                                label: Text(
                                    "입양일: ${DateFormat('yyyy-MM-dd').format(_adoptDate)}"),
                                onPressed: () => _selectDate(context, false)))
                      ]),

                      const SizedBox(height: 30),

                      ElevatedButton(
                        onPressed: _saveAnimal,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text(widget.animal != null ? "수정 완료" : "등록 완료"),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
