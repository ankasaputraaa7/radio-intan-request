import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'news_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  // State Request Lagu
  bool _isLoadingRequests = true;
  List<Map<String, dynamic>> _allRequests = [];
  String _selectedFilter = 'all';

  // State Naskah Siaran
  bool _isLoadingNews = true;
  List<NewsItem> _newsList = [];
  final List<Map<String, String>> _customScripts = [
    {
      'sesi': 'Sesi Pagi - Menyapa Garut',
      'judul': 'Opening Script & Salam Pembuka',
      'isi':
          'Selamat pagi wargi Garut! Selamat bergabung di Radio Intan Garut. Tetap semangat menjalani aktivitas hari ini bersama musik-musik favorit kamu.'
    },
    {
      'sesi': 'Sesi Siang - Hits Santai',
      'judul': 'Informasi Lalu Lintas & Rest Area',
      'isi':
          'Untuk pendengar yang sedang berada di perjalanan jalur Tarogong - Leles, arus lalu lintas siang ini terpantau lancar. Hati-hati di jalan!'
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRequests();
    _loadNews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoadingRequests = true);
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
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _loadNews() async {
    setState(() => _isLoadingNews = true);
    final items = await NewsService.fetchPemkabNews();
    if (mounted) {
      setState(() {
        _newsList = items;
        _isLoadingNews = false;
      });
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

  void _showAddScriptDialog() {
    final sesiController = TextEditingController();
    final judulController = TextEditingController();
    final isiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Colors.lightBlue),
              SizedBox(width: 8),
              Text('Tambah Naskah Sesi'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sesiController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Sesi Siaran (misal: Sesi Sore)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: judulController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Naskah',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: isiController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Isi Teks Bacaan / Script',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (sesiController.text.isNotEmpty &&
                    judulController.text.isNotEmpty &&
                    isiController.text.isNotEmpty) {
                  setState(() {
                    _customScripts.add({
                      'sesi': sesiController.text,
                      'judul': judulController.text,
                      'isi': isiController.text,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan Naskah'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_selectedFilter == 'all') return _allRequests;
    return _allRequests
        .where((req) => req['status'] == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        _allRequests.where((r) => r['status'] == 'pending').length;
    final playedCount =
        _allRequests.where((r) => r['status'] == 'played').length;
    final rejectedCount =
        _allRequests.where((r) => r['status'] == 'rejected').length;

    return Scaffold(
      backgroundColor: const Color(0xFFA5D6A7).withOpacity(0.08),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Dashboard Penyiar - Radio Intan Garut',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
            onPressed: () {
              _fetchRequests();
              _loadNews();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Keluar Admin',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.queue_music_rounded),
              text: 'Antrean Request',
            ),
            Tab(
              icon: Icon(Icons.article_rounded),
              text: 'Naskah Siaran',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ==================== TAB 1: ANTREAN REQUEST ====================
          _isLoadingRequests
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.lightBlue))
              : RefreshIndicator(
                  onRefresh: _fetchRequests,
                  color: Colors.lightBlue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isDesktop = constraints.maxWidth > 700;
                            if (isDesktop) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Menunggu (Pending)',
                                      count: pendingCount,
                                      color: Colors.orangeAccent,
                                      icon: Icons.hourglass_top_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Sudah Diputar',
                                      count: playedCount,
                                      color: Colors.lightBlue,
                                      icon: Icons.play_circle_fill_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Ditolak',
                                      count: rejectedCount,
                                      color: Colors.redAccent,
                                      icon: Icons.cancel_rounded,
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: _buildStatCard(
                                      title: 'Menunggu (Pending)',
                                      count: pendingCount,
                                      color: Colors.orangeAccent,
                                      icon: Icons.hourglass_top_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: _buildStatCard(
                                      title: 'Sudah Diputar',
                                      count: playedCount,
                                      color: Colors.lightBlue,
                                      icon: Icons.play_circle_fill_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: _buildStatCard(
                                      title: 'Ditolak',
                                      count: rejectedCount,
                                      color: Colors.redAccent,
                                      icon: Icons.cancel_rounded,
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 32),

                        // Filter Status
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

                        // List Request Cards
                        _filteredRequests.isEmpty
                            ? Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Tidak ada data request pada kategori ini.',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredRequests.length,
                                itemBuilder: (context, index) {
                                  final req = _filteredRequests[index];
                                  final String id = req['id'];
                                  final String status =
                                      req['status'] ?? 'pending';

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
                                    shadowColor:
                                        Colors.lightBlue.withOpacity(0.08),
                                    margin: const EdgeInsets.only(bottom: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor:
                                                Colors.lightBlue.shade50,
                                            child: Text(
                                              (req['nama_pendengar'] ??
                                                  'A')[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.lightBlue,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      req['judul_lagu'] ?? '',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade200,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '💬 "${req['pesan'] ?? '-'}"',
                                                    style: TextStyle(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                        color: statusColor),
                                                  ),
                                                  child: Text(
                                                    statusText,
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
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
                                                    : () => _updateStatus(
                                                        id, 'played'),
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
                                                    : () => _updateStatus(
                                                        id, 'rejected'),
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

          // ==================== TAB 2: NASKAH SIARAN ====================
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.record_voice_over_rounded,
                        color: Colors.lightBlue, size: 28),
                    const SizedBox(width: 10),
                    const Text(
                      'Naskah Siaran Radio & Portal Berita Garut',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: NewsService.openGarutNewsPortal,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Buka garutkab.go.id/berita'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.lightBlue,
                        side: const BorderSide(color: Colors.lightBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _showAddScriptDialog,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tambah Sesi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 🎙️ SECTION 1: TEKS OPENING & CLOSING STANDAR
                const Text(
                  '🎧 Teks Opening & Closing Siaran (Panduan Penyiar)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.lightBlue.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'TEKS OPENING SIARAN',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '🗣️ "Halo, selamat pagi/siang/sore Wargi Garut! Selamat bergabung kembali di Radio Intan Garut, tempatnya informasi terkini dan lagu-lagu hits favorit kamu.\n\n'
                          'Bersama saya (Nama Penyiar) yang bakal menemani aktivitas kamu beberapa jam ke depan. Jangan lupa buat Wargi yang mau kirim lagu favorit dan titip salam hangat, langsung aja isi Form Request Lagu di web kita ya! Tetap stay tuned di Radio Intan Garut!"',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey[850],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.redAccent.shade100),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'TEKS CLOSING SIARAN',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '🗣️ "Gak terasa nih Wargi Garut, (Nama Penyiar) udah menemani kamu di sesi siaran hari ini. Terima kasih banyak buat Wargi yang udah request lagu dan meramaikan siaran kita.\n\n'
                          'Tetap jaga kesehatan, selamat melanjutkan aktivitas, dan sampai jumpa di program siaran Radio Intan Garut berikutnya. (Nama Penyiar) pamit undur diri, terima kasih dan sampai di sesi selanjutnya!"',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey[850],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 📌 SECTION 2: SCRIPT MANUAL PER SESI
                const Text(
                  '📌 Script Tambahan Per Sesi (Custom)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue,
                  ),
                ),
                const SizedBox(height: 10),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _customScripts.length,
                  itemBuilder: (context, index) {
                    final item = _customScripts[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item['sesi'] ?? '',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['judul'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['isi'] ?? '',
                              style: TextStyle(
                                  color: Colors.grey[800], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // 📰 SECTION 3: 5 BERITA TERBARU PEMKAB GARUT
                const Text(
                  '📰 Berita Resmi Pemkab Garut (5 Terkini Real-Time)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue,
                  ),
                ),
                const SizedBox(height: 10),

                _isLoadingNews
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.lightBlue))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _newsList.length,
                        itemBuilder: (context, index) {
                          final news = _newsList[index];
                          return Card(
                            elevation: 3,
                            shadowColor: Colors.lightBlue.withOpacity(0.08),
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ExpansionTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.lightBlue,
                                child: Icon(Icons.newspaper_rounded,
                                    color: Colors.white, size: 20),
                              ),
                              title: Text(
                                news.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                'Dipublikasikan: ${news.pubDate}',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Poin Penting Berita
                                      const Text(
                                        '📌 Poin-Poin Penting Berita:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.lightBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: news.keyPoints
                                            .map(
                                              (point) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 4.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('• ',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    Expanded(
                                                      child: Text(
                                                        point,
                                                        style: const TextStyle(
                                                            fontSize: 13),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                      const SizedBox(height: 16),

                                      // Draft Naskah Siaran Panjang
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          news.broadcastScript,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.6,
                                            color: Colors.grey[850],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
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