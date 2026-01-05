import 'package:flutter/material.dart';
import '../../../data/data_source/leopard_gecko_morphs.dart';
import '../../../data/data_source/morph_combo_definitions.dart'; // ★ 공식집 import

class MorphSelectionDialog extends StatefulWidget {
  final List<String> selectedMorphs;

  const MorphSelectionDialog({super.key, required this.selectedMorphs});

  @override
  State<MorphSelectionDialog> createState() => _MorphSelectionDialogState();
}

class _MorphSelectionDialogState extends State<MorphSelectionDialog> {
  String _searchQuery = "";
  late List<String> _currentSelected;
  late List<String> _fullMorphList;

  @override
  void initState() {
    super.initState();
    _currentSelected = List.from(widget.selectedMorphs);

    _fullMorphList = List.from(leopardGeckoMorphs);
    for (var morph in _currentSelected) {
      if (!_fullMorphList.contains(morph)) {
        _fullMorphList.insert(0, morph);
      }
    }
  }

  void _addCustomMorph(String newMorph) {
    if (newMorph.trim().isEmpty) return;
    setState(() {
      if (!_fullMorphList.contains(newMorph))
        _fullMorphList.insert(0, newMorph);
      if (!_currentSelected.contains(newMorph)) _currentSelected.add(newMorph);
      _searchQuery = "";
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
                    hintText: "예: Black Night, Raptor...",
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
              ],
            ),
          ),

          const Divider(height: 1),

          // 2. 리스트
          SizedBox(
            height: 400, // 높이를 조금 늘림 (설명 때문)
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
                      final morph = filteredMorphs[index];
                      final isSelected = _currentSelected.contains(morph);

                      // ★ 콤보인지 확인하고 재료 가져오기
                      final ingredients = getIngredients(morph);
                      final isCombo =
                          ingredients.length > 1 && ingredients[0] != morph;

                      return CheckboxListTile(
                        title: Text(morph),
                        // ★ 콤보라면 아래에 작은 글씨로 재료 표시
                        subtitle: isCombo
                            ? Text("🧬 ${ingredients.join(' + ')}",
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.deepOrange))
                            : null,
                        value: isSelected,
                        activeColor: Colors.deepOrange,
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              _currentSelected.add(morph);
                            } else {
                              _currentSelected.remove(morph);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

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
