import 'admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

// Config Supabase dari Dashboard kamu
class AppConstants {
  static const String supabaseUrl = 'https://fmtndvlkihofyyoqpgqg.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_ItiGGrPCKHu0C2ZNLp9dLw_IEUcKeAM'; // Ganti dengan key lengkap kamu jika ada update
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase SDK
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
      title: 'Radio Intan Garut - Request Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
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

  // Instance Supabase Client
  final _supabase = Supabase.instance.client;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Menyimpan data ke tabel 'requests' di Supabase
      await _supabase.from('requests').insert({
        'nama_pendengar': _namaController.text,
        'judul_lagu': _laguController.text,
        'penyanyi': _penyanyiController.text,
        'pesan': _pesanController.text,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request lagu berhasil dikirim ke penyiar! 🎵'),
            backgroundColor: Colors.green,
          ),
        );
        // Reset Form
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
            backgroundColor: Colors.red,
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Radio Intan Garut 98.5 FM'),
        elevation: 2,
        actions: [
          TextButton.icon(
           onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const LoginScreen(),
    ),
  );
},
            icon: const Icon(Icons.dashboard, color: Colors.white),
            label: const Text(
              'Dashboard Penyiar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: isDesktop ? 550 : screenWidth,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Form Request Lagu & Titip Salam',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kirimkan lagu favoritmu beserta titip salam untuk siaran hari ini.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _namaController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kamu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _laguController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Lagu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.music_note),
                    ),
                    validator: (v) => v!.isEmpty ? 'Judul lagu wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _penyanyiController,
                    decoration: const InputDecoration(
                      labelText: 'Penyanyi / Band',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.mic),
                    ),
                    validator: (v) => v!.isEmpty ? 'Penyanyi wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pesanController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Pesan / Titip Salam',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Kirim Request Lagu',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}