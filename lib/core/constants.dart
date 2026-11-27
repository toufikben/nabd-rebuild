/// Limits the editor actually enforces.
///
/// This file used to also carry `appName`, `appVersion`, `maxEntryLength` and
/// `supportedLanguages`. Nothing read any of them, and two were actively
/// wrong: `appVersion` said 1.0.0 while the app ships 1.0.2 (Settings reads the
/// real value from package_info), and `supportedLanguages` listed only ar and
/// en while twenty languages ship. A constant nobody reads cannot be kept
/// honest, so they are gone rather than left to mislead the next reader.
class AppConstants {
  static const maxImagesPerEntry = 10;
  static const maxAudioSeconds = 300;
}
