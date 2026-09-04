import 'package:flutter/material.dart';
import '../../../../core/supabase/supabase_service.dart';

class SupabaseConnectionTestPage extends StatefulWidget {
  const SupabaseConnectionTestPage({super.key});

  @override
  State<SupabaseConnectionTestPage> createState() => _SupabaseConnectionTestPageState();
}

class _SupabaseConnectionTestPageState extends State<SupabaseConnectionTestPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  bool _isConnected = false;
  String? _errorMessage;
  int _catalogCount = 0;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _supabaseService.getData('maintenance_catalog', limit: 5);
      setState(() {
        _isConnected = true;
        _isLoading = false;
        _catalogCount = data.length;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'RideCare Backend Status',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Testing connection to maintenance_catalog...'),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isConnected ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _isConnected ? '🟢 Connected' : '🔴 Failed',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isConnected ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isConnected)
                  Text(
                    'Query "maintenance_catalog" successful! Found $_catalogCount records.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.green),
                  )
                else if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Error details:\n$_errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _checkConnection,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Test Connection Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
