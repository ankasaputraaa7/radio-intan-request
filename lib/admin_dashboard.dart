import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allRequests = [];
  String _selectedFilter = 'all'; // 'all', 'pending', 'played', 'rejected'

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
        _allRequests = List<Map<String, dynamic>>.from(response);
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

      _fetchRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e')),
        );
      }
    }
  }

  // Fungsi Logout Admin
  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // Filter List Data
  List<Map<String, dynamic>> get _filteredRequests {
    if (_selectedFilter == 'all') return _allRequests;
    return _allRequests.where((req) => req['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Menghitung statistik data
    final pendingCount = _allRequests.where((r) => r['status'] == 'pending').length;
    final playedCount = _allRequests.where((r) => r['status'] == 'played').length;
    final rejectedCount = _allRequests.where((r) => r['status'] == 'rejected').length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dashboard Penyiar - Radio Intan Garut'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _fetchRequests,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar Admin',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRequests,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. RINGKASAN STATISTIK ---
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 700;
                        return Flex(
                          direction: isDesktop ? Axis.horizontal : Axis.vertical,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatCard(
                              title: 'Menunggu (Pending)',
                              count: pendingCount,
                              color: Colors.orange,
                              icon: Icons.hourglass_top,
                            ),
                            SizedBox(height: isDesktop ? 0 : 12, width: isDesktop ? 12 : 0),
                            _buildStatCard(
                              title: 'Sudah Diputar',
                              count: playedCount,
                              color: Colors.green,
                              icon: Icons.play_circle_fill,
                            ),
                            SizedBox(height: isDesktop ? 0 : 12, width: isDesktop ? 12 : 0),
                            _buildStatCard(
                              title: 'Ditolak',
                              count: rejectedCount,
                              color: Colors.red,
                              icon: Icons.cancel,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // --- 2. BARIS FILTER STATUS ---
                    Row(
                      children: [
                        const Text(
                          'Antrean Request',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildFilterChip('Semua', 'all'),
                            _buildFilterChip('Pending', 'pending'),
                            _buildFilterChip('Diputar', 'played'),
                            _buildFilterChip('Ditolak', 'rejected'),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // --- 3. LIST REQUEST CARDS ---
                    _filteredRequests.isEmpty
                        ? Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: const Text(
                              'Tidak ada data request pada kategori ini.',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredRequests.length,
                            itemBuilder: (context, index) {
                              final req = _filteredRequests[index];
                              final String id = req['id'];
                              final String status = req['status'] ?? 'pending';

                              Color statusColor;
                              String statusText;
                              switch (status) {
                                case 'played':
                                  statusColor = Colors.green;
                                  statusText = 'DIPUTAR';
                                  break;
                                case 'rejected':
                                  statusColor = Colors.red;
                                  statusText = 'DITOLAK';
                                  break;
                                default:
                                  statusColor = Colors.orange;
                                  statusText = 'PENDING';
                              }

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Avatar Pendengar
                                      CircleAvatar(
                                        backgroundColor: Colors.deepOrange.shade100,
                                        child: Text(
                                          (req['nama_pendengar'] ?? 'A')[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.deepOrange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Detail Lagu & Pesan
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
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
                                            const SizedBox(height: 6),
                                            Text(
                                              'Dari: ${req['nama_pendengar']}',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '💬 "${req['pesan'] ?? '-'}"',
                                                style: TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors.grey[800]),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            // Badge Status
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: statusColor),
                                              ),
                                              child: Text(
                                                statusText,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Tombol Aksi Penyiar
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check_circle, color: Colors.green),
                                            tooltip: 'Tandai Diputar',
                                            onPressed: status == 'played'
                                                ? null
                                                : () => _updateStatus(id, 'played'),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.cancel, color: Colors.red),
                                            tooltip: 'Tolak Request',
                                            onPressed: status == 'rejected'
                                                ? null
                                                : () => _updateStatus(id, 'rejected'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget Kartu Statistik
  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 24,
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Widget Chip Filter
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.deepOrange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() => _selectedFilter = value);
        }
      },
    );
  }
}