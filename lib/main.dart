import 'admin_dashboard.dart';
import 'login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Config Supabase dari Dashboard kamu
class AppConstants {
  static const String supabaseUrl = 'https://fmtndvlkihofyyoqpgqg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZtdG5kdmxraWhvZnl5b3FwZ3FnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgwNjk4NjgsImV4cCI6MjEwMzY0NTg2OH0.t_T8BrezPnixZtrbOj8shMbhq7pd36h6oemn4DCzIYk';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const RadioApp());
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radio Intan Garut',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          primary: Colors.lightBlue,
          secondary: Colors.blueAccent,
        ),
        useMaterial3: true,
      ),
      home: const PublicRequestScreen(),
    );
  }
}

class PublicRequestScreen extends StatefulWidget {
  const PublicRequestScreen({super.key});

  @override
  State<PublicRequestScreen> createState() => _PublicRequestScreenState();
}

class _PublicRequestScreenState extends State<PublicRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _laguController = TextEditingController();
  final _penyanyiController = TextEditingController();
  final _pesanController = TextEditingController();

  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  // Fungsi untuk membuka website resmi Radio Intan Garut
  Future<void> _launchRadioWebsite() async {
    final Uri url = Uri.parse('https://radiointan.garutkab.go.id/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka website resmi.')),
        );
      }
    }
  }

 Future<void> _submitRequest() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    // Memastikan insert data menggunakan client Supabase yang aktif
    await _supabase.from('requests').insert({
      'nama_pendengar': _namaController.text.trim(),
      'judul_lagu': _laguController.text.trim(),
      'penyanyi': _penyanyiController.text.trim(),
      'pesan': _pesanController.text.trim(),
      'status': 'pending',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Request lagu berhasil dikirim ke penyiar! 🎵'),
            ],
          ),
          backgroundColor: Colors.lightBlue.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _namaController.clear();
      _laguController.clear();
      _penyanyiController.clear();
      _pesanController.clear();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim request: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  void dispose() {
    _namaController.dispose();
    _laguController.dispose();
    _penyanyiController.dispose();
    _pesanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFA5D6A7).withOpacity(0.08),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.radio, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Radio Intan Garut',
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
          // Tombol Navigasi Portal Resmi di AppBar
          TextButton.icon(
            onPressed: _launchRadioWebsite,
            icon: const Icon(Icons.language_rounded, color: Colors.white, size: 20),
            label: const Text(
              'Web Resmi',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),

          // Tombol Dashboard Penyiar
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: () {
                final session = _supabase.auth.currentSession;
                if (session != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 20),
              label: const Text(
                'Dashboard',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              // --- HERO BANNER & PERTANYAAN SAMBUTAN ---
              Container(
                width: isDesktop ? 650 : screenWidth,
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.lightBlue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.lightBlue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.headset_mic_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Apakah Kamu Ingin Request Lagu di Radio Intan?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Perbaikan error white90 diganti menjadi white.withOpacity(0.9)
                    Text(
                      'Yuk, kirimkan lagu favoritmu dan titip salam hangat untuk penyiar serta pendengar setia Radio Intan Garut hari ini!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Kunjungi Website Resmi Radio Intan Garut
                    OutlinedButton.icon(
                      onPressed: _launchRadioWebsite,
                      icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                      label: const Text(
                        'Kunjungi Website Resmi Radio Intan',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --- FORM REQUEST LAGU ---
              Container(
                width: isDesktop ? 550 : screenWidth,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.lightBlue.withOpacity(0.08),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Isi Form Request Lagu',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Input Nama
                      _buildTextField(
                        controller: _namaController,
                        label: 'Nama Kamu',
                        icon: Icons.person_outline,
                        validatorText: 'Nama wajib diisi',
                      ),
                      const SizedBox(height: 18),

                      // Input Judul Lagu
                      _buildTextField(
                        controller: _laguController,
                        label: 'Judul Lagu',
                        icon: Icons.music_note_outlined,
                        validatorText: 'Judul lagu wajib diisi',
                      ),
                      const SizedBox(height: 18),

                      // Input Penyanyi
                      _buildTextField(
                        controller: _penyanyiController,
                        label: 'Penyanyi / Band',
                        icon: Icons.mic_none_outlined,
                        validatorText: 'Penyanyi wajib diisi',
                      ),
                      const SizedBox(height: 18),

                      // Input Pesan
                      _buildTextField(
                        controller: _pesanController,
                        label: 'Pesan / Titip Salam',
                        icon: Icons.chat_bubble_outline,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 28),

                      // Tombol Kirim
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Colors.lightBlue, Colors.blueAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.lightBlue.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Kirim Request Sekarang 🚀',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? validatorText,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: Colors.lightBlue),
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.lightBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      validator: validatorText != null
          ? (v) => v!.trim().isEmpty ? validatorText : null
          : null,
    );
  }
}