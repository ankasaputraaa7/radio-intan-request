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
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

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
          SnackBar(
            content: Text('Error memuat data: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
          SnackBar(
            content: Text('Gagal memperbarui status: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_selectedFilter == 'all') return _allRequests;
    return _allRequests.where((req) => req['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _allRequests.where((r) => r['status'] == 'pending').length;
    final playedCount = _allRequests.where((r) => r['status'] == 'played').length;
    final rejectedCount = _allRequests.where((r) => r['status'] == 'rejected').length;

    return Scaffold(
      backgroundColor: const Color(0xFFA5D6A7).withOpacity(0.08),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Dashboard Penyiar - Radio Intan Garut',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.lightBlue, Colors.blueAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Data',
            onPressed: _fetchRequests,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Keluar Admin',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.lightBlue))
          : RefreshIndicator(
              onRefresh: _fetchRequests,
              color: Colors.lightBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. RINGKASAN STATISTIK DESAIN MODERN ---
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
                              color: Colors.orangeAccent,
                              icon: Icons.hourglass_top_rounded,
                            ),
                            SizedBox(height: isDesktop ? 0 : 12, width: isDesktop ? 12 : 0),
                            _buildStatCard(
                              title: 'Sudah Diputar',
                              count: playedCount,
                              color: Colors.lightBlue,
                              icon: Icons.play_circle_fill_rounded,
                            ),
                            SizedBox(height: isDesktop ? 0 : 12, width: isDesktop ? 12 : 0),
                            _buildStatCard(
                              title: 'Ditolak',
                              count: rejectedCount,
                              color: Colors.redAccent,
                              icon: Icons.cancel_rounded,
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
                          'Antrean Request Lagu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
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
                                  statusColor = Colors.lightBlue;
                                  statusText = 'DIPUTAR';
                                  break;
                                case 'rejected':
                                  statusColor = Colors.redAccent;
                                  statusText = 'DITOLAK';
                                  break;
                                default:
                                  statusColor = Colors.orangeAccent;
                                  statusText = 'PENDING';
                              }

                              return Card(
                                elevation: 3,
                                shadowColor: Colors.lightBlue.withOpacity(0.08),
                                margin: const EdgeInsets.only(bottom: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Avatar Pendengar
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: Colors.lightBlue.shade50,
                                        child: Text(
                                          (req['nama_pendengar'] ?? 'A')[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.lightBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
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
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '- ${req['penyanyi']}',
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Dari: ${req['nama_pendengar']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.grey.shade200,
                                                ),
                                              ),
                                              child: Text(
                                                '💬 "${req['pesan'] ?? '-'}"',
                                                style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            // Badge Status
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.12),
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
                                            icon: const Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.lightBlue,
                                              size: 28,
                                            ),
                                            tooltip: 'Tandai Diputar',
                                            onPressed: status == 'played'
                                                ? null
                                                : () => _updateStatus(id, 'played'),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.cancel_rounded,
                                              color: Colors.redAccent,
                                              size: 28,
                                            ),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.lightBlue,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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