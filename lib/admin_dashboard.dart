import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  // Mengambil data dari Supabase
  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('requests')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _requests = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memuat data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Mengubah status request
  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await _supabase
          .from('requests')
          .update({'status': newStatus})
          .eq('id', id);
      
      _fetchRequests(); // Refresh data setelah update
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Penyiar Radio Intan Garut'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _fetchRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada request lagu yang masuk.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final String id = req['id'];
                      final String status = req['status'] ?? 'pending';

                      Color statusColor;
                      switch (status) {
                        case 'played':
                          statusColor = Colors.green;
                          break;
                        case 'rejected':
                          statusColor = Colors.red;
                          break;
                        default:
                          statusColor = Colors.orange;
                      }

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            children: [
                              Text(
                                req['judul_lagu'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '- ${req['penyanyi']}',
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 16),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Dari: ${req['nama_pendengar']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text('Pesan: "${req['pesan'] ?? '-'}"'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  'Status: ${status.toUpperCase()}',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.green),
                                tooltip: 'Tandai Diputar',
                                onPressed: () => _updateStatus(id, 'played'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel,
                                    color: Colors.red),
                                tooltip: 'Tolak Request',
                                onPressed: () => _updateStatus(id, 'rejected'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}