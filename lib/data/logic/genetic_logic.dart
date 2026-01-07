// lib/data/logic/genetic_logic.dart
import '../data_source/morph_combo_definitions.dart';
import '../data_source/leopard_gecko_morphs.dart';

class GeneticLogic {
  static const List<String> incDomGenes = ['Mack Snow', 'Giant', 'Lemon Frost'];
  static const List<String> domGenes = [
    'White & Yellow (W&Y)',
    'Enigma',
    'TUG Snow',
    'Gem Snow',
    'Ghost',
    'Pastel'
  ];

  static const Map<String, String> superForms = {
    'Super Snow': 'Mack Snow',
    'Super Giant': 'Giant',
  };

  static String _getCoreName(String morph) {
    return morph.replaceAll("Het ", "").trim();
  }

  static bool _isPolygenic(String morph) {
    String core = _getCoreName(morph);
    if (incDomGenes.contains(core)) return false;
    if (domGenes.contains(core)) return false;

    const List<String> knownPolygenics = [
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

    for (var poly in knownPolygenics) {
      if (core.contains(poly)) return true;
    }
    return false;
  }

  static Map<String, dynamic> calculateOffspring(
      List<String> maleMorphs, List<String> femaleMorphs) {
    List<String> maleGenes = _expandGenes(maleMorphs);
    List<String> femaleGenes = _expandGenes(femaleMorphs);

    Set<String> mendelianTypes = {};
    Set<String> polygenicTraits = {};

    for (var g in [...maleGenes, ...femaleGenes]) {
      String core = _getCoreName(g);
      String finalGene = superForms[core] ?? core;

      if (_isPolygenic(finalGene)) {
        polygenicTraits.add(finalGene);
      } else {
        mendelianTypes.add(finalGene);
      }
    }

    List<List<Map<String, dynamic>>> geneResults = [];
    for (var gene in mendelianTypes) {
      if (!_isPolygenic(gene)) {
        geneResults.add(_calculateSingleGene(gene, maleGenes, femaleGenes));
      }
    }

    List<Map<String, dynamic>> genotypeResults =
        _combineProbabilities(geneResults);
    List<Map<String, dynamic>> phenotypeResults =
        _groupByPhenotype(genotypeResults);

    return {
      'outcomes': phenotypeResults,
      'polygenics': polygenicTraits.toList(),
    };
  }

  static List<Map<String, dynamic>> _groupByPhenotype(
      List<Map<String, dynamic>> genotypes) {
    Map<String, Map<String, dynamic>> groups = {};

    for (var g in genotypes) {
      List<String> traits = (g['names'] as List<String>);
      List<String> visualTraits =
          traits.where((t) => !t.startsWith("Het ")).toList();
      visualTraits.sort();

      String phenotypeName =
          visualTraits.isEmpty ? "Normal" : visualTraits.join(" + ");

      if (visualTraits.contains('Super Snow') &&
          visualTraits.contains('Eclipse')) {
        phenotypeName = phenotypeName
            .replaceAll('Eclipse + Super Snow', 'Total Eclipse')
            .replaceAll('Super Snow + Eclipse', 'Total Eclipse');
      }

      if (!groups.containsKey(phenotypeName)) {
        groups[phenotypeName] = {
          'prob': 0.0,
          'genotypes': <Map<String, dynamic>>[]
        };
      }
      groups[phenotypeName]!['prob'] += g['prob'];
      (groups[phenotypeName]!['genotypes'] as List).add(g);
    }

    List<Map<String, dynamic>> finalPhenotypes = [];

    groups.forEach((pName, data) {
      double totalProb = data['prob'];
      List<Map<String, dynamic>> contributors = data['genotypes'];

      Set<String> potentialHets = {};
      for (var c in contributors) {
        List<String> traits = c['names'];
        for (var t in traits) {
          if (t.startsWith("Het ")) potentialHets.add(t);
        }
      }

      List<String> hetStrings = [];

      for (var het in potentialHets) {
        double carryingProb = 0.0;
        for (var c in contributors) {
          if ((c['names'] as List<String>).contains(het)) {
            carryingProb += c['prob'];
          }
        }

        double percent = (carryingProb / totalProb) * 100;
        String coreName = het.replaceAll("Het ", "");

        if (percent >= 99.9) {
          hetStrings.add("100% Het $coreName");
        } else {
          String percentText;
          if (percent > 66 && percent < 67) {
            percentText = "66";
          } else {
            percentText = percent.toStringAsFixed(0);
          }
          hetStrings.add("$percentText% Poss. Het $coreName");
        }
      }

      hetStrings.sort();

      finalPhenotypes
          .add({'visual': pName, 'hets': hetStrings, 'prob': totalProb});
    });

    finalPhenotypes
        .sort((a, b) => (b['prob'] as double).compareTo(a['prob'] as double));
    return finalPhenotypes;
  }

  static List<String> _expandGenes(List<String> morphs) {
    List<String> expanded = [];
    for (var m in morphs) expanded.addAll(getIngredients(m));
    return expanded;
  }

  static List<Map<String, dynamic>> _calculateSingleGene(
      String gene, List<String> maleGenes, List<String> femaleGenes) {
    int maleAlleles = _countAlleles(gene, maleGenes);
    int femaleAlleles = _countAlleles(gene, femaleGenes);
    List<int> mGametes = _getGametes(maleAlleles);
    List<int> fGametes = _getGametes(femaleAlleles);
    Map<int, double> outcomes = {0: 0, 1: 0, 2: 0};

    for (var m in mGametes) {
      for (var f in fGametes) {
        int child = m + f;
        outcomes[child] = outcomes[child]! + 0.25;
      }
    }

    List<Map<String, dynamic>> results = [];
    bool isIncDom = incDomGenes.contains(gene);
    bool isDom = domGenes.contains(gene);

    outcomes.forEach((score, prob) {
      if (prob > 0) {
        if (score == 2) {
          if (isIncDom) {
            String superName = superForms.keys.firstWhere(
                (k) => superForms[k] == gene,
                orElse: () => "Super $gene");
            results.add({'gene': superName, 'prob': prob});
          } else {
            results.add({'gene': gene, 'prob': prob});
          }
        } else if (score == 1) {
          if (isIncDom || isDom) {
            results.add({'gene': gene, 'prob': prob});
          } else {
            results.add({'gene': "Het $gene", 'prob': prob});
          }
        }
      }
    });
    return results;
  }

  static int _countAlleles(String gene, List<String> currentGenes) {
    String superName = superForms.keys
        .firstWhere((k) => superForms[k] == gene, orElse: () => "");
    if (superName.isNotEmpty && currentGenes.contains(superName)) return 2;
    if (currentGenes.contains(gene)) {
      if (!incDomGenes.contains(gene) && !domGenes.contains(gene)) return 2;
      return 1;
    }
    if (currentGenes.contains("Het $gene")) return 1;
    return 0;
  }

  static List<int> _getGametes(int alleleCount) {
    if (alleleCount == 2) return [1, 1];
    if (alleleCount == 1) return [0, 1];
    return [0, 0];
  }

  static List<Map<String, dynamic>> _combineProbabilities(
      List<List<Map<String, dynamic>>> geneResults) {
    List<Map<String, dynamic>> currentCombos = [
      {'names': <String>[], 'prob': 1.0}
    ];
    for (var geneList in geneResults) {
      List<Map<String, dynamic>> newCombos = [];
      for (var existing in currentCombos) {
        double geneProbSum =
            geneList.fold(0.0, (sum, item) => sum + (item['prob'] as double));
        double normalProb = 1.0 - geneProbSum;
        if (normalProb > 0) {
          newCombos.add({
            'names': List<String>.from(existing['names']),
            'prob': existing['prob'] * normalProb,
          });
        }
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
}
