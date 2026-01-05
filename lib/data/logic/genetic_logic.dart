import '../data_source/morph_combo_definitions.dart';

class GeneticLogic {
  // [1] 유전자 타입 정의 (유전 방식)
  static const List<String> incDomGenes = [
    'Mack Snow',
    'Giant',
    'Lemon Frost'
  ]; // 공우성 (슈퍼폼 있음)
  static const List<String> domGenes = [
    'White & Yellow (W&Y)',
    'Enigma',
    'TUG Snow',
    'Gem Snow',
    'Ghost',
    'Pastel'
  ]; // 우성
  // 나머지는 기본적으로 열성(Recessive)으로 처리

  // [2] 슈퍼폼 매핑 (Super Form 이름 -> 원본 유전자)
  static const Map<String, String> superForms = {
    'Super Snow': 'Mack Snow',
    'Super Giant': 'Giant',
  };

  // [핵심] 부모 모프를 받아서 자식 확률 계산
  static List<Map<String, dynamic>> calculateOffspring(
      List<String> maleMorphs, List<String> femaleMorphs) {
    // 1. 콤보 분해 (예: Galaxy -> Super Snow, Eclipse)
    List<String> maleGenes = _expandGenes(maleMorphs);
    List<String> femaleGenes = _expandGenes(femaleMorphs);

    // 2. 분석할 모든 유전자 종류 수집
    Set<String> allGeneTypes = {};
    for (var g in [...maleGenes, ...femaleGenes]) {
      // 슈퍼폼이면 원본 유전자로 변환해서 등록 (예: Super Snow -> Mack Snow)
      allGeneTypes.add(superForms[g] ?? g);
    }

    // 3. 각 유전자별 확률 계산 (독립 시행)
    List<List<Map<String, dynamic>>> geneResults = [];

    for (var gene in allGeneTypes) {
      geneResults.add(_calculateSingleGene(gene, maleGenes, femaleGenes));
    }

    // 4. 모든 경우의 수 조합 (Cartesian Product)
    List<Map<String, dynamic>> finalResults =
        _combineProbabilities(geneResults);

    // 5. 결과 정리 (콤보 이름으로 다시 합치기 + 정렬)
    return _finalizeResults(finalResults);
  }

  // ---------------------------------------------------------------------------
  // [내부 로직]
  // ---------------------------------------------------------------------------

  // 콤보를 단일 유전자로 분해
  static List<String> _expandGenes(List<String> morphs) {
    List<String> expanded = [];
    for (var m in morphs) {
      expanded.addAll(getIngredients(m));
    }
    return expanded;
  }

  // 유전자 하나에 대한 멘델 유전 계산 (Punnett Square)
  static List<Map<String, dynamic>> _calculateSingleGene(
      String gene, List<String> maleGenes, List<String> femaleGenes) {
    int maleAlleles = _countAlleles(gene, maleGenes);
    int femaleAlleles = _countAlleles(gene, femaleGenes);

    // 멘델의 법칙 (2x2 퍼넷 사각형)
    // 0: Wild, 1: Het/Visual(Dom), 2: Hom(Rec)/Super(IncDom)
    // Allele: 0 or 1. Parent has 2 slots.

    List<int> mGametes = _getGametes(maleAlleles);
    List<int> fGametes = _getGametes(femaleAlleles);

    Map<int, double> outcomes = {
      0: 0,
      1: 0,
      2: 0
    }; // 0:None, 1:Single, 2:Double

    for (var m in mGametes) {
      for (var f in fGametes) {
        int child = m + f;
        outcomes[child] = outcomes[child]! + 0.25; // 4칸 중 1칸 = 25%
      }
    }

    // 결과 변환 (유전 방식에 따라 이름 붙이기)
    List<Map<String, dynamic>> results = [];
    bool isIncDom = incDomGenes.contains(gene);
    bool isDom = domGenes.contains(gene);

    outcomes.forEach((score, prob) {
      if (prob > 0) {
        if (score == 2) {
          // 2카피 (Homozygous / Super Form)
          if (isIncDom) {
            String superName = superForms.keys.firstWhere(
                (k) => superForms[k] == gene,
                orElse: () => "Super $gene");
            results.add({'gene': superName, 'prob': prob});
          } else {
            // 열성이면 Visual, 우성이면 그냥 Visual(Super)
            results.add({'gene': gene, 'prob': prob});
          }
        } else if (score == 1) {
          // 1카피 (Heterozygous / Single Form)
          if (isIncDom || isDom) {
            results.add({'gene': gene, 'prob': prob}); // 우성/공우성은 1카피도 Visual
          } else {
            results.add({'gene': "Het $gene", 'prob': prob}); // 열성은 Het
          }
        }
        // score 0은 표기 안 함 (Normal)
      }
    });

    return results;
  }

  // 유전자 보유 수 확인 (0, 1, 2)
  static int _countAlleles(String gene, List<String> currentGenes) {
    // 슈퍼폼(2카피)인지 확인
    String superName = superForms.keys
        .firstWhere((k) => superForms[k] == gene, orElse: () => "");
    if (superName.isNotEmpty && currentGenes.contains(superName)) return 2;

    // 일반(1카피)인지 확인
    if (currentGenes.contains(gene)) {
      // 열성 유전자의 경우, Visual이면 2카피로 간주 (Visual 입력 기준 앱이므로)
      if (!incDomGenes.contains(gene) && !domGenes.contains(gene)) return 2;
      return 1; // 공우성/우성은 Visual이 1카피일 수도 있음 (여기선 1로 가정. 슈퍼폼은 위에서 걸러짐)
    }
    return 0;
  }

  // 생식세포 생성 (0 또는 1 유전자 전달)
  static List<int> _getGametes(int alleleCount) {
    if (alleleCount == 2) return [1, 1]; // 무조건 전달
    if (alleleCount == 1) return [0, 1]; // 50% 전달
    return [0, 0]; // 전달 안 함
  }

  // 확률 조합 (Cartesian Product)
  static List<Map<String, dynamic>> _combineProbabilities(
      List<List<Map<String, dynamic>>> geneResults) {
    List<Map<String, dynamic>> currentCombos = [
      {'names': <String>[], 'prob': 100.0}
    ];

    for (var geneList in geneResults) {
      List<Map<String, dynamic>> newCombos = [];
      for (var existing in currentCombos) {
        // 유전자가 발현되지 않는 경우(Normal) 처리 (100% - 나머지 확률 합)
        double geneProbSum =
            geneList.fold(0.0, (sum, item) => sum + (item['prob'] as double));
        double normalProb = 1.0 - geneProbSum;

        // Normal인 경우 (유전자 없음)
        if (normalProb > 0) {
          newCombos.add({
            'names': List<String>.from(existing['names']),
            'prob': existing['prob'] * normalProb,
          });
        }

        // 유전자가 있는 경우
        for (var geneOutcome in geneList) {
          List<String> nextNames = List<String>.from(existing['names']);
          nextNames.add(geneOutcome['gene']);
          newCombos.add({
            'names': nextNames,
            'prob': existing['prob'] * (geneOutcome['prob'] as double),
          });
        }
      }
      currentCombos = newCombos;
    }
    return currentCombos;
  }

  // 최종 결과 정리 (콤보 이름 매핑)
  static List<Map<String, dynamic>> _finalizeResults(
      List<Map<String, dynamic>> rawResults) {
    List<Map<String, dynamic>> finalOutput = [];

    // 레시피 역방향 맵 만들기 (재료 -> 콤보명)
    // 예: {'Super Snow', 'Eclipse'} -> 'Total Eclipse'
    // 구현 단순화를 위해 주요 콤보만 체크하거나, 이름 리스트를 그냥 보여줌.
    // 여기서는 단순히 이름을 정렬해서 보여줍니다.

    for (var result in rawResults) {
      if (result['prob'] == 0) continue;

      List<String> traits = (result['names'] as List<String>);
      if (traits.isEmpty) {
        finalOutput.add({'name': 'Normal (Wild Type)', 'prob': result['prob']});
      } else {
        // 콤보 이름 찾기 로직은 복잡하므로, 일단 나열식으로 표시하고
        // morph_combo_definitions.dart를 역으로 검색해서 이름을 붙여줄 수도 있음.
        // 현재는 리스트 조인으로 표시.
        traits.sort();
        String displayName = traits.join(" + ");

        // 간단한 콤보 이름 치환 (예시)
        if (traits.contains('Super Snow') && traits.contains('Eclipse')) {
          displayName = displayName
              .replaceAll('Eclipse + Super Snow', 'Total Eclipse')
              .replaceAll('Super Snow + Eclipse', 'Total Eclipse');
        }

        finalOutput.add({'name': displayName, 'prob': result['prob']});
      }
    }

    // 확률 높은 순 정렬
    finalOutput
        .sort((a, b) => (b['prob'] as double).compareTo(a['prob'] as double));
    return finalOutput;
  }
}
