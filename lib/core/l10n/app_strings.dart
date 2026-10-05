import 'languages.dart';

/// The string tables, one per language, generated from `l10n/<code>.json`
/// by `scripts/gen_l10n.py`. Add or change text in the JSON, never here.
///
/// English is the reference key set and the fallback for any missing key;
/// test/i18n_test.dart keeps every language complete.
class S {
  const S._();

  static Map<String, String> get ar => stringTables['ar']!;
  static Map<String, String> get en => stringTables['en']!;

  /// Every shipped language's table, keyed by language code.
  static Map<String, Map<String, String>> get byLanguage => stringTables;

  /// The table for [code], or English when the app does not ship it.
  static Map<String, String> of(String code) => stringTables[code] ?? en;
}
