// lib/data/data_source/morph_combo_definitions.dart

// [모프 계산기용] 콤보 레시피 정의 (Combo Formulas)
// Key: 콤보 이름
// Value: 구성 유전자 리스트 (Base Genes)
final Map<String, List<String>> morphComboRecipes = {
  // [1] Eclipse Combos
  'RAPTOR': ['Tremper Albino', 'Eclipse'],
  'RADAR': ['Bell Albino', 'Eclipse'],
  'Typhoon': ['Rainwater Albino', 'Eclipse'],
  'APTOR': ['Tremper Albino'],
  'Total Eclipse': ['Super Snow', 'Eclipse'],
  'Galaxy': ['Super Snow', 'Eclipse'],
  'Universe': ['Super Snow', 'White & Yellow (W&Y)', 'Eclipse'],
  'Super Typhoon': ['Super Snow', 'Rainwater Albino', 'Eclipse'],
  'Mist': ['Mack Snow', 'Rainwater Albino', 'Eclipse'],
  'Black Hole': ['Mack Snow', 'Enigma', 'Eclipse'],
  'Nova': ['Enigma', 'Tremper Albino', 'Eclipse'],
  'Super Nova': ['Super Snow', 'Enigma', 'Tremper Albino', 'Eclipse'],
  'Dreamsickle': ['Mack Snow', 'Enigma', 'Tremper Albino', 'Eclipse'],
  'Stealth': ['Mack Snow', 'Enigma', 'Bell Albino', 'Eclipse'],
  'Vortex': ['Mack Snow', 'Enigma', 'Rainwater Albino', 'Eclipse'],
  'Bee': ['Enigma', 'Eclipse'],
  'Cyclone': ['Rainwater Albino', 'Murphy Patternless', 'Eclipse'],
  'Crystal': ['Mack Snow', 'Enigma', 'Tremper Albino', 'Eclipse'],
  'Abyssinian': ['Mack Snow', 'Eclipse'],

  // [2] Blizzard / Patternless Combos
  'Diablo Blanco': ['Blizzard', 'Tremper Albino', 'Eclipse'],
  'Blazing Blizzard': ['Blizzard', 'Tremper Albino'],
  'Bell Blazing Blizzard': ['Blizzard', 'Bell Albino'],
  'Rainwater Blazing Blizzard': ['Blizzard', 'Rainwater Albino'],
  'White Knight': ['Blizzard', 'Bell Albino', 'Eclipse'],
  'Banana Blizzard': ['Blizzard', 'Murphy Patternless'],
  'Ember': ['Murphy Patternless', 'Tremper Albino', 'Eclipse'],
  'Snowflake': ['Mack Snow', 'Murphy Patternless'],
  'Super Platinum': ['Super Snow', 'Murphy Patternless'],
  'Phantom': ['TUG Snow', 'SHTCT'],

  // [3] Snow / Tangerine / Hybino Combos
  'Sunglow': ['SHTCT', 'Tremper Albino'],
  'Hybino': ['Hypo', 'Tremper Albino'],
  'Bell Hybino': ['Hypo', 'Bell Albino'],
  'Rainwater Hybino': ['Hypo', 'Rainwater Albino'],
  'Creamsicle': ['Mack Snow', 'SHTCT'],
  'Snowglow': ['Mack Snow', 'SHTCT', 'Tremper Albino'],
  'Aurora': ['White & Yellow (W&Y)', 'Bell Albino'],
  'Firewater': ['Rainwater Albino', 'Tangerine'],
  'Black Ice': ['Mack Snow', 'Black Night'],

  // [4] Super Forms
  'Super Snow': ['Mack Snow', 'Mack Snow'],
  'Super Giant': ['Giant', 'Giant'],
};

// [유틸리티 함수] 콤보 이름을 넣으면 구성 유전자를 반환
List<String> getIngredients(String morphName) {
  if (morphComboRecipes.containsKey(morphName)) {
    return morphComboRecipes[morphName]!;
  }
  return [morphName];
}
