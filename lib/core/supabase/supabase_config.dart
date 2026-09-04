import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String fallbackUrl = 'https://cmueermihksabkdqkup.supabase.co';
  static const String fallbackAnonKey = 'sb_publishable_NxXWu7hSOj5tCQoH9rmOhw_n3Rn88wz';

  static String get url =>
      (dotenv.isInitialized ? dotenv.env['SUPABASE_URL'] : null) ?? fallbackUrl;
  static String get anonKey =>
      (dotenv.isInitialized ? dotenv.env['SUPABASE_ANON_KEY'] : null) ?? fallbackAnonKey;

  static bool get isInitialized {
    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Warning: .env failed to load, falling back to default configuration: $e');
    }

    // ignore: deprecated_member_use
    await Supabase.initialize(
      url: url,
      // ignore: deprecated_member_use
      anonKey: anonKey,
      debug: kDebugMode,
    );
  }
}
