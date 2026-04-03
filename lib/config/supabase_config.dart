/// Supabase project settings.
///
/// Defina no build/run (não commitar chaves):
/// `flutter run --dart-define=SUPABASE_ANON_KEY=sua_chave_anon`
abstract final class SupabaseConfig {
  static const String url = 'https://ivtrzkqkcqluddujxiwe.supabase.co';

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String creativesBucket = 'creatives';
  static const String generateVariantsFunction = 'generate-variants';
}
