import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// ★ 모프 선택 다이얼로그 경로 (경로가 다르면 수정 필요)
import '../home/widget/morph_selection_dialog.dart';

class HatchlingAddScreen extends StatefulWidget {
  final String maleName;
  final String maleId;
  final String femaleName;
  final String femaleId;
  final DateTime hatchDate;

  const HatchlingAddScreen({
    super.key,
    required this.maleName,
    required this.maleId,
    required this.femaleName,
    required this.femaleId,
    required this.hatchDate,
  });

  @override
  State<HatchlingAddScreen> createState() => _HatchlingAddScreenState();
}

class _HatchlingAddScreenState extends State<HatchlingAddScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  final TextEditingController _morphController = TextEditingController();
  final TextEditingController _weightController =
      TextEditingController(text: "2.0");
  final TextEditingController _memoController = TextEditingController();

  String _selectedGender = 'Unknown';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    String datePrefix = DateFormat('yy-MM').format(widget.hatchDate);
    _nameController = TextEditingController(text: "$datePrefix-?");
  }

  // ★ [수정됨] 모프 선택기 열기 (에러 해결 부분)
  void _showMorphSelector() async {
    // 1. 현재 입력된 텍스트를 리스트로 변환 (예: "Tangerine, Eclipse" -> ["Tangerine", "Eclipse"])
    // 텍스트 필드가 비어있으면 빈 리스트 [] 전달
    List<String> currentMorphs =
        _morphController.text.isEmpty ? [] : _morphController.text.split(', ');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => MorphSelectionDialog(
        selectedMorphs: currentMorphs, // ★ 이 부분이 빠져서 에러가 났었습니다!
      ),
    );

    if (result != null) {
      setState(() {
        _morphController.text = result;
      });
    }
  }

  Future<void> _saveHatchling() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('animals').add({
        'name': _nameController.text,
        'species': 'Leopard Gecko',
        'morph':
            _morphController.text.isEmpty ? 'Normal' : _morphController.text,
        'gender': _selectedGender,
        'birthDate': Timestamp.fromDate(widget.hatchDate),
        'adoptionDate': Timestamp.fromDate(widget.hatchDate),
        'weight': double.tryParse(_weightController.text) ?? 2.0,

        // 부모 정보 (Lineage)
        'fatherId': widget.maleId,
        'fatherName': widget.maleName,
        'motherId': widget.femaleId,
        'motherName': widget.femaleName,

        'memo': _memoController.text,
        'source': 'Self-Bred',
        'isBreeder': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("🎉 해칭 개체가 등록되었습니다!")));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("오류: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("해칭 개체 등록")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 부모 정보
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    const Text("Parents (Lineage)",
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildParentChip("F", widget.femaleName, Colors.pink),
                        const Icon(Icons.close, size: 16, color: Colors.grey),
                        _buildParentChip("M", widget.maleName, Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                        "Hatch Date: ${DateFormat('yyyy-MM-dd').format(widget.hatchDate)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. 이름 입력
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "개체 이름 (ID)",
                  hintText: "예: 26-CB-01",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "이름을 입력해주세요" : null,
              ),
              const SizedBox(height: 16),

              // 3. 모프 입력 (★ 팝업 검색 방식)
              GestureDetector(
                onTap: _showMorphSelector, // 터치 시 다이얼로그 오픈
                child: AbsorbPointer(
                  // 키보드 입력 막기 (다이얼로그로만 선택)
                  child: TextFormField(
                    controller: _morphController,
                    decoration: const InputDecoration(
                      labelText: "모프 (터치하여 검색)",
                      hintText: "Normal",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.palette),
                      suffixIcon: Icon(Icons.search),
                    ),
                    validator: (val) => null,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. 성별 및 무게
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                          labelText: "성별", border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: "Unknown", child: Text("미구분")),
                        DropdownMenuItem(value: "Male", child: Text("수컷")),
                        DropdownMenuItem(value: "Female", child: Text("암컷")),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedGender = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "무게 (g)",
                        border: OutlineInputBorder(),
                        suffixText: "g",
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. 메모
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: "특이사항 / 메모",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveHatchling,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("해칭 등록 완료"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentChip(String label, String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 6),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
