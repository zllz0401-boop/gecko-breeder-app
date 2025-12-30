import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/model/animal_model.dart';

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
  late TextEditingController _morphController;
  late TextEditingController _weightController;

  // ★ 종 관련 변수 추가
  late TextEditingController _customSpeciesController; // 직접 입력용
  String _selectedSpecies = 'Leopard Gecko'; // 기본값
  final List<String> _speciesOptions = [
    'Leopard Gecko',
    'Fat-tailed Gecko',
    'Crested Gecko',
    'Direct Input'
  ]; // 선택지

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
      _morphController = TextEditingController(text: widget.animal!.morph);
      _weightController =
          TextEditingController(text: widget.animal!.weight.toString());
      _selectedGender = widget.animal!.gender;
      _selectedStatus = widget.animal!.status;
      _birthDate = widget.animal!.birthDate;
      _adoptDate = widget.animal!.adoptDate;

      // ★ 종 데이터 불러오기 로직
      if (_speciesOptions.contains(widget.animal!.species)) {
        // 기본 목록에 있는 종이면 그대로 선택
        _selectedSpecies = widget.animal!.species;
      } else {
        // 목록에 없는 종이면 '직접 입력'으로 설정하고 내용 채우기
        _selectedSpecies = 'Direct Input';
        _customSpeciesController.text = widget.animal!.species;
      }
    } else {
      _nameController = TextEditingController();
      _morphController = TextEditingController();
      _weightController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _morphController.dispose();
    _weightController.dispose();
    _customSpeciesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
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

      // ★ 최종 저장될 종 이름 결정
      String finalSpecies = _selectedSpecies;
      if (_selectedSpecies == 'Direct Input') {
        if (_customSpeciesController.text.trim().isEmpty) {
          throw Exception("종 이름을 입력해주세요.");
        }
        finalSpecies = _customSpeciesController.text.trim();
      }

      final Map<String, dynamic> animalData = {
        'name': _nameController.text,
        'species': finalSpecies, // ★ 수정된 종 이름 저장
        'morph': _morphController.text,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.animal != null ? "수정되었습니다." : "등록되었습니다.")),
      );
    } catch (e) {
      if (mounted) {
        // 에러 메시지 (ex: 종 이름 미입력) 보여주기
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
      setState(() {
        if (isBirth)
          _birthDate = picked;
        else
          _adoptDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.animal != null ? "개체 정보 수정" : "새 개체 등록";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        // ★ 잊지 않고 SafeArea 적용!
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_a_photo,
                                        size: 40, color: Colors.grey),
                                    Text("사진 변경/추가"),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

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

                      // ★ 종(Species) 선택 드롭다운
                      DropdownButtonFormField<String>(
                        value: _selectedSpecies,
                        decoration: const InputDecoration(
                            labelText: "종(Species)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category)),
                        items: _speciesOptions.map((s) {
                          // 화면에 보여줄 텍스트 변환 (Direct Input -> 직접 입력)
                          String label = s;
                          if (s == 'Direct Input') label = '직접 입력';
                          return DropdownMenuItem(value: s, child: Text(label));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSpecies = val!;
                          });
                        },
                      ),

                      // ★ '직접 입력' 선택 시에만 나오는 입력창
                      if (_selectedSpecies == 'Direct Input') ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customSpeciesController,
                          decoration: const InputDecoration(
                            labelText: "종 이름 직접 입력",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.edit),
                            filled: true,
                            fillColor: Color(0xFFF5F5F7),
                          ),
                          validator: (value) {
                            if (_selectedSpecies == 'Direct Input' &&
                                (value == null || value.isEmpty)) {
                              return "종 이름을 입력해주세요.";
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _morphController,
                        decoration: const InputDecoration(
                            labelText: "모프",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.palette)),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: "무게 (g)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.scale)),
                      ),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                            labelText: "성별", border: OutlineInputBorder()),
                        items: ['Male', 'Female', 'Unknown']
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedGender = val!),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                            labelText: "상태", border: OutlineInputBorder()),
                        items: ['Breeding', 'Holdback', 'For Sale', 'Pet']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedStatus = val!),
                      ),
                      const SizedBox(height: 20),

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
