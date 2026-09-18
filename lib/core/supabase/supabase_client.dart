import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Custom Supabase Exception Classes for Production Error Handling
class SupabaseAppException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const SupabaseAppException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() => 'SupabaseAppException: $message';
}

class SupabaseNetworkException extends SupabaseAppException {
  const SupabaseNetworkException(super.message, [super.originalError, super.stackTrace]);
}

class SupabaseTimeoutException extends SupabaseAppException {
  const SupabaseTimeoutException(super.message, [super.originalError, super.stackTrace]);
}

class SupabaseAuthException extends SupabaseAppException {
  const SupabaseAuthException(super.message, [super.originalError, super.stackTrace]);
}

class SupabaseDatabaseException extends SupabaseAppException {
  final String? code;
  final String? details;
  final String? hint;

  const SupabaseDatabaseException(
    String message, {
    this.code,
    this.details,
    this.hint,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(message, originalError, stackTrace);
}

class SupabaseDataParseException extends SupabaseAppException {
  const SupabaseDataParseException(super.message, [super.originalError, super.stackTrace]);
}

/// Supabase Client Layer - Production-Ready Singleton
/// Provides unified access to Supabase client, connection checks, and error handling.
class AppSupabaseClient {
  AppSupabaseClient._();

  static final AppSupabaseClient instance = AppSupabaseClient._();

  SupabaseClient? _client;

  /// Returns the singleton SupabaseClient instance
  SupabaseClient get client {
    if (_client != null) return _client!;
    if (SupabaseConfig.isInitialized) {
      _client = SupabaseConfig.client;
      return _client!;
    }
    throw const SupabaseAppException(
      'Supabase is not initialized. Please ensure SupabaseConfig.init() is called before accessing.',
    );
  }

  /// Sets an explicit client (useful for dependency injection or testing)
  void setClient(SupabaseClient client) {
    _client = client;
  }

  /// Production-grade connection check with timeout and detailed error interception
  Future<bool> checkConnection({
    String table = 'vehicles',
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      if (!SupabaseConfig.isInitialized && _client == null) {
        return false;
      }
      final query = client.from(table).select().limit(1);
      await query.timeout(timeout);
      return true;
    } on TimeoutException catch (e) {
      debugPrint('AppSupabaseClient: Connection check timed out after ${timeout.inSeconds}s: $e');
      return false;
    } on SocketException catch (e) {
      debugPrint('AppSupabaseClient: Network unreachable: $e');
      return false;
    } catch (e) {
      debugPrint('AppSupabaseClient: Connection check failed: $e');
      return false;
    }
  }

  /// Standardized error wrapper to map Postgrest/Supabase exceptions into strongly-typed AppExceptions
  SupabaseAppException handleException(dynamic error, [StackTrace? stackTrace]) {
    if (error is TimeoutException) {
      return SupabaseTimeoutException(
        'Koneksi ke server timeout. Silakan periksa jaringan internet Anda.',
        error,
        stackTrace,
      );
    }

    if (error is SocketException) {
      return SupabaseNetworkException(
        'Tidak ada sambungan internet. Menampilkan data lokal (Offline).',
        error,
        stackTrace,
      );
    }

    if (error is PostgrestException) {
      if (error.code == '42501' || error.message.toLowerCase().contains('policy') || error.message.toLowerCase().contains('jwt')) {
        return SupabaseAuthException(
          'Akses ditolak atau sesi telah berakhir: ${error.message}',
          error,
          stackTrace,
        );
      }
      return SupabaseDatabaseException(
        'Database error: ${error.message}',
        code: error.code,
        details: error.details?.toString(),
        hint: error.hint?.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException || error is TypeError) {
      return SupabaseDataParseException(
        'Format data tidak valid: $error',
        error,
        stackTrace,
      );
    }

    return SupabaseAppException(
      error?.toString() ?? 'Terjadi kesalahan tidak terduga',
      error,
      stackTrace,
    );
  }
}
