import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/supabase/supabase_service.dart';

class RideCareDatabaseTestPage extends StatefulWidget {
  const RideCareDatabaseTestPage({super.key});

  @override
  State<RideCareDatabaseTestPage> createState() => _RideCareDatabaseTestPageState();
}

class _RideCareDatabaseTestPageState extends State<RideCareDatabaseTestPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;
  String? _testVehicleId;
  List<Map<String, dynamic>> _vehiclesList = [];
  final List<String> _logs = [];

  void _log(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toIso8601String().substring(11, 19)}] $message');
    });
  }

  Future<void> _createTestVehicle() async {
    setState(() => _isLoading = true);
    final newId = const Uuid().v4();
    _log('CREATE: Menambahkan kendaraan Honda Beat 2024...');

    try {
      final payload = {
        'id': newId,
        'brand': 'Honda',
        'model': 'Beat',
        'year': 2024,
        'vehicle_type': 'motorcycle',
        'current_odometer': 0,
      };

      try {
        final res = await _supabaseService.insertData('vehicles', payload);
        _testVehicleId = newId;
        _log('CREATE Berhasil! Data tersimpan: $res');
        await _readVehicles();
      } catch (e) {
        if (e.toString().contains('current_odometer')) {
          _log('Pemberitahuan: Mencoba fallback ke current_kilometer...');
          final fallbackPayload = {
            'id': newId,
            'brand': 'Honda',
            'model': 'Beat',
            'year': 2024,
            'vehicle_type': 'motorcycle',
            'current_kilometer': 0.0,
          };
          final res = await _supabaseService.insertData('vehicles', fallbackPayload);
          _testVehicleId = newId;
          _log('CREATE Berhasil (current_kilometer)! Data tersimpan: $res');
          await _readVehicles();
        } else {
          rethrow;
        }
      }
    } catch (e) {
      _log('CREATE Gagal: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _readVehicles() async {
    setState(() => _isLoading = true);
    _log('READ: Mengambil data vehicles...');

    try {
      final res = await _supabaseService.getData('vehicles', limit: 20);
      setState(() {
        _vehiclesList = res;
      });
      _log('READ Berhasil! Ditemukan ${res.length} kendaraan.');
    } catch (e) {
      _log('READ Gagal: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTestVehicle() async {
    if (_testVehicleId == null && _vehiclesList.isNotEmpty) {
      _testVehicleId = _vehiclesList.first['id']?.toString();
    }

    if (_testVehicleId == null) {
      _log('UPDATE Gagal: Tidak ada kendaraan untuk di-update. Silakan CREATE dulu.');
      return;
    }

    setState(() => _isLoading = true);
    _log('UPDATE: Memperbarui kendaraan ID: $_testVehicleId...');

    try {
      final updatePayload = {
        'model': 'Beat Street (Updated)',
        'current_odometer': 1250,
      };

      try {
        final res = await _supabaseService.updateData(
          'vehicles',
          updatePayload,
          matchColumn: 'id',
          matchValue: _testVehicleId!,
        );
        _log('UPDATE Berhasil! Hasil: $res');
        await _readVehicles();
      } catch (e) {
        if (e.toString().contains('current_odometer')) {
          final fallbackPayload = {
            'model': 'Beat Street (Updated)',
            'current_kilometer': 1250.0,
          };
          final res = await _supabaseService.updateData(
            'vehicles',
            fallbackPayload,
            matchColumn: 'id',
            matchValue: _testVehicleId!,
          );
          _log('UPDATE Berhasil (current_kilometer)! Hasil: $res');
          await _readVehicles();
        } else {
          rethrow;
        }
      }
    } catch (e) {
      _log('UPDATE Gagal: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTestVehicle() async {
    if (_testVehicleId == null && _vehiclesList.isNotEmpty) {
      _testVehicleId = _vehiclesList.first['id']?.toString();
    }

    if (_testVehicleId == null) {
      _log('DELETE Gagal: Tidak ada kendaraan untuk dihapus.');
      return;
    }

    setState(() => _isLoading = true);
    _log('DELETE: Menghapus data testing ID: $_testVehicleId...');

    try {
      final res = await _supabaseService.deleteData(
        'vehicles',
        matchColumn: 'id',
        matchValue: _testVehicleId!,
      );
      _log('DELETE Berhasil! Hasil: $res');
      _testVehicleId = null;
      await _readVehicles();
    } catch (e) {
      _log('DELETE Gagal: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runFullCrudTest() async {
    _log('--- Memulai Full Testing CRUD ---');
    await _createTestVehicle();
    await Future.delayed(const Duration(milliseconds: 500));
    await _readVehicles();
    await Future.delayed(const Duration(milliseconds: 500));
    await _updateTestVehicle();
    await Future.delayed(const Duration(milliseconds: 500));
    await _deleteTestVehicle();
    _log('--- Full Testing CRUD Selesai ---');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RideCare Database Test Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            tooltip: 'Jalankan Full CRUD Test',
            onPressed: _isLoading ? null : _runFullCrudTest,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createTestVehicle,
                  icon: const Icon(Icons.add, color: Colors.green),
                  label: const Text('1. CREATE (Beat 2024)'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _readVehicles,
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  label: const Text('2. READ (Vehicles)'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateTestVehicle,
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  label: const Text('3. UPDATE'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _deleteTestVehicle,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('4. DELETE'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Text(
                    'Vehicles Data (${_vehiclesList.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _vehiclesList.isEmpty
                      ? const Center(child: Text('Belum ada data vehicles'))
                      : ListView.builder(
                          itemCount: _vehiclesList.length,
                          itemBuilder: (context, index) {
                            final item = _vehiclesList[index];
                            return ListTile(
                              leading: const Icon(Icons.two_wheeler),
                              title: Text('${item['brand']} ${item['model']} (${item['year']})'),
                              subtitle: Text('ID: ${item['id']}\nKM: ${item['current_kilometer'] ?? item['current_odometer'] ?? 0}'),
                              isThreeLine: true,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black87,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test Execution Logs:',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: log.contains('Gagal') || log.contains('Error')
                                ? Colors.redAccent
                                : log.contains('Berhasil')
                                    ? Colors.greenAccent
                                    : Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
