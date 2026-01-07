import 'package:flutter/material.dart';
import '../../../data/data_source/leopard_gecko_morphs.dart';
import '../../../data/data_source/morph_combo_definitions.dart';

class MorphSelectionDialog extends StatefulWidget {
  final List<String> selectedMorphs;

  const MorphSelectionDialog({super.key, required this.selectedMorphs});

  @override
  State<MorphSelectionDialog> createState() => _MorphSelectionDialogState();
}

class _MorphSelectionDialogState extends State<MorphSelectionDialog> {
  String _searchQuery = "";
  late List<String> _currentSelected; // "Eclipse", "Het Eclipse" 등이 섞여서 저장됨
  late List<String> _fullMorphList; // "Eclipse", "Mack Snow" 등 원본 이름만 저장됨

  @override
  void initState() {
    super.initState();
    _currentSelected = List.from(widget.selectedMorphs);

    _fullMorphList = List.from(leopardGeckoMorphs);

    // 이미 선택된 커스텀 모프(리스트에 없는 것)가 있다면 원본 리스트에 추가
    for (var selected in _currentSelected) {
      // "Het Eclipse" -> "Eclipse"로 원본 이름 추출
      String coreName = selected.replaceAll("Het ", "").trim();

      if (!_fullMorphList.contains(coreName)) {
        _fullMorphList.insert(0, coreName);
      }
    }
  }

  void _addCustomMorph(String newMorph) {
    if (newMorph.trim().isEmpty) return;
    setState(() {
      if (!_fullMorphList.contains(newMorph)) {
        _fullMorphList.insert(0, newMorph);
      }
      if (!_currentSelected.contains(newMorph)) _currentSelected.add(newMorph);
      _searchQuery = "";
    });
  }

  // Het 상태 토글 함수
  void _toggleHet(String baseMorph) {
    setState(() {
      if (_currentSelected.contains(baseMorph)) {
        // Visual -> Het 변환
        _currentSelected.remove(baseMorph);
        _currentSelected.add("Het $baseMorph");
      } else if (_currentSelected.contains("Het $baseMorph")) {
        // Het -> Visual 변환
        _currentSelected.remove("Het $baseMorph");
        _currentSelected.add(baseMorph);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredMorphs = _fullMorphList
        .where(
            (morph) => morph.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 헤더
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("모프 검색 및 추가",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: "예: Eclipse, Tremper...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ""))
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 4),
                const Text("💡 체크 후 우측 [Het] 버튼을 누르면 보인자로 설정됩니다.",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),

          const Divider(height: 1),

          // 2. 리스트
          SizedBox(
            height: 400,
            child: filteredMorphs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("'$_searchQuery' 없음",
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => _addCustomMorph(_searchQuery),
                          icon: const Icon(Icons.add),
                          label: const Text("새 모프로 직접 추가"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredMorphs.length,
                    itemBuilder: (context, index) {
                      final baseMorph = filteredMorphs[index];

                      // 현재 상태 확인 (Visual or Het)
                      final bool isVisual =
                          _currentSelected.contains(baseMorph);
                      final bool isHet =
                          _currentSelected.contains("Het $baseMorph");
                      final bool isSelected = isVisual || isHet;

                      // 콤보 재료 확인
                      final ingredients = getIngredients(baseMorph);
                      final isCombo =
                          ingredients.length > 1 && ingredients[0] != baseMorph;

                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  // 선택 해제 (Visual, Het 모두 삭제)
                                  _currentSelected.remove(baseMorph);
                                  _currentSelected.remove("Het $baseMorph");
                                } else {
                                  // 선택 (기본 Visual)
                                  _currentSelected.add(baseMorph);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  // 체크박스
                                  Icon(
                                    isSelected
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    color: isSelected
                                        ? Colors.deepOrange
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),

                                  // 모프 이름 & 설명
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          baseMorph,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? Colors.black87
                                                : Colors.black54,
                                          ),
                                        ),
                                        if (isCombo)
                                          Text("🧬 ${ingredients.join(' + ')}",
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.deepOrange)),
                                      ],
                                    ),
                                  ),

                                  // ★ Het 토글 버튼 (선택되었을 때만 보임)
                                  if (isSelected)
                                    GestureDetector(
                                      onTap: () => _toggleHet(baseMorph),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isHet
                                              ? Colors.purple
                                              : Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: isHet
                                                  ? Colors.purple
                                                  : Colors.grey.shade400),
                                        ),
                                        child: Text(
                                          "Het",
                                          style: TextStyle(
                                            color: isHet
                                                ? Colors.white
                                                : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  ),
          ),

          // 3. 하단 버튼
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text("${_currentSelected.length}개 선택됨",
                      style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("취소",
                            style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, _currentSelected),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white),
                      child: const Text("완료"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
