import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get supabaseUrl => const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  ).isNotEmpty
      ? const String.fromEnvironment('SUPABASE_URL')
      : dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  ).isNotEmpty
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static final supabase = Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      if (!kIsWeb || !const bool.fromEnvironment('IS_PRODUCTION', defaultValue: false)) {
        await dotenv.load();
      }
    } catch (e) {
      debugPrint('Warning: .env file not found. Using environment variables.');
    }

    assert(supabaseUrl.isNotEmpty, 'SUPABASE_URL is not configured');
    assert(supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY is not configured');

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
} 