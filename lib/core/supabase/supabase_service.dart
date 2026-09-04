import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class SupabaseService {
  SupabaseClient? _client;

  SupabaseService([SupabaseClient? client]) : _client = client;

  SupabaseClient get client {
    if (_client != null) return _client!;
    if (SupabaseConfig.isInitialized) {
      _client = SupabaseConfig.client;
      return _client!;
    }
    throw StateError('Supabase is not initialized. Please call SupabaseConfig.init() first.');
  }

  /// Checks connection to Supabase by querying the specified table.
  /// Defaults to 'maintenance_catalog'.
  Future<bool> checkConnection({String table = 'maintenance_catalog'}) async {
    try {
      if (!SupabaseConfig.isInitialized && _client == null) return false;
      final response = await client.from(table).select().limit(1);
      return response.isNotEmpty || response.isEmpty;
    } catch (e) {
      debugPrint('Supabase connection check failed: $e');
      return false;
    }
  }

  /// Reads data from the specified table with optional filtering and ordering.
  Future<List<Map<String, dynamic>>> getData(
    String table, {
    String columns = '*',
    Map<String, dynamic>? match,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      var query = client.from(table).select(columns);

      if (match != null && match.isNotEmpty) {
        query = query.match(Map<String, Object>.from(match));
      }

      PostgrestTransformBuilder<List<Map<String, dynamic>>> transform = query;

      if (orderBy != null) {
        transform = transform.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        transform = transform.limit(limit);
      }

      final response = await transform;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting data from $table: $e');
      rethrow;
    }
  }

  /// Inserts a single record or multiple records into the specified table.
  Future<List<Map<String, dynamic>>> insertData(
    String table,
    dynamic data,
  ) async {
    try {
      final response = await client.from(table).insert(data).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error inserting data into $table: $e');
      rethrow;
    }
  }

  /// Updates records in the specified table where [matchColumn] == [matchValue].
  Future<List<Map<String, dynamic>>> updateData(
    String table,
    Map<String, dynamic> data, {
    required String matchColumn,
    required dynamic matchValue,
  }) async {
    try {
      final response = await client
          .from(table)
          .update(data)
          .eq(matchColumn, matchValue)
          .select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error updating data in $table ($matchColumn: $matchValue): $e');
      rethrow;
    }
  }

  /// Deletes records in the specified table where [matchColumn] == [matchValue].
  Future<List<Map<String, dynamic>>> deleteData(
    String table, {
    required String matchColumn,
    required dynamic matchValue,
  }) async {
    try {
      final response = await client
          .from(table)
          .delete()
          .eq(matchColumn, matchValue)
          .select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error deleting data from $table ($matchColumn: $matchValue): $e');
      rethrow;
    }
  }
}
