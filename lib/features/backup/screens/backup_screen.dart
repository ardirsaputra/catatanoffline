import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../backup_service.dart';
import '../../berkas/providers/berkas_provider.dart';
import '../../berkas/providers/category_provider.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cadangan & Migrasi',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.primaryContainer),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔐', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enkripsi End-to-End',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Data dikompres dan dienkripsi dengan kunci yang diturunkan dari PIN Anda menggunakan PBKDF2-SHA256 (60.000 iterasi). File .bkse hanya bisa dibuka dengan PIN yang benar.',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: colorScheme.onPrimaryContainer.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Export Section ────────────────────────────────────────────────
          _SectionTitle(icon: '📤', title: 'Export Data'),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.file_download_outlined,
            title: 'Buat File Backup',
            subtitle: 'Simpan ke Downloads atau bagikan file .bkse terenkripsi',
            color: const Color(0xFF4CAF50),
            onTap: () => _showExportSheet(context),
          ),
          const SizedBox(height: 24),

          // ── Import Section ────────────────────────────────────────────────
          _SectionTitle(icon: '📥', title: 'Import Data'),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.file_upload_outlined,
            title: 'Pulihkan dari Backup',
            subtitle: 'Buka file .bkse dan masukkan PIN untuk memulihkan data',
            color: const Color(0xFF2196F3),
            onTap: () => _showImportSheet(context),
          ),
          const SizedBox(height: 32),

          // How-to
          _HowToSection(colorScheme: colorScheme),
        ],
      ),
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ExportSheet(),
    );
  }

  void _showImportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ImportSheet(),
    );
  }
}

// ── Export Sheet ──────────────────────────────────────────────────────────────

class _ExportSheet extends StatefulWidget {
  const _ExportSheet();

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _doExport() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length < 4) {
      setState(() => _error = 'PIN minimal 4 digit');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'PIN tidak cocok');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bytes = await BackupService.exportBytes(pin);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'berkasKu_backup_$ts.bkse';

      // Coba simpan langsung ke lokasi pilihan user (Downloads via SAF).
      String? savedPath;
      try {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan Backup',
          fileName: fileName,
          type: FileType.any,
          bytes: bytes,
        );
      } catch (_) {
        savedPath = null;
      }

      if (!mounted) return;

      // Tangkap messenger sebelum pop agar tetap valid setelah sheet ditutup.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);

      if (savedPath != null) {
        // File berhasil disimpan ke lokasi pilihan user (biasanya Downloads).
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              '✅ File backup disimpan ke Downloads',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Bagikan',
              textColor: Colors.white,
              onPressed: () async {
                final dir = await getTemporaryDirectory();
                final tmp = File('${dir.path}/$fileName');
                await tmp.writeAsBytes(bytes);
                await Share.shareXFiles(
                  [XFile(tmp.path, mimeType: 'application/octet-stream')],
                  subject: 'BerkasKu Backup',
                  text: 'File backup terenkripsi BerkasKu — buka dengan PIN yang Anda tentukan.',
                );
              },
            ),
          ),
        );
      } else {
        // User membatalkan dialog SAF — fallback ke share sheet.
        final dir = await getTemporaryDirectory();
        final tmp = File('${dir.path}/$fileName');
        await tmp.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(tmp.path, mimeType: 'application/octet-stream')],
          subject: 'BerkasKu Backup',
          text: 'File backup terenkripsi BerkasKu — buka dengan PIN yang Anda tentukan.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal membuat backup: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('📤 Buat File Backup', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text(
                'Tentukan PIN untuk mengenkripsi file backup. Simpan PIN ini — Anda akan membutuhkannya saat memulihkan data.',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // PIN field
              TextField(
                controller: _pinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 12,
                decoration: InputDecoration(
                  labelText: 'PIN Enkripsi',
                  hintText: 'Minimal 4 digit',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),

              // Confirm PIN field
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                keyboardType: TextInputType.number,
                maxLength: 12,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  counterText: '',
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: colorScheme.error)),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _doExport,
                  icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.download_rounded),
                  label: Text(
                    _loading ? 'Mengenkripsi...' : 'Simpan ke Downloads',
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Import Sheet ──────────────────────────────────────────────────────────────

class _ImportSheet extends ConsumerStatefulWidget {
  const _ImportSheet();

  @override
  ConsumerState<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends ConsumerState<_ImportSheet> {
  final _pinController = TextEditingController();
  bool _obscurePin = true;
  bool _loading = false;
  String? _error;
  String? _selectedFilePath;
  String? _selectedFileName;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bkse'],
        withData: false,
        withReadStream: false,
      );
    } catch (_) {
      // Ekstensi kustom tidak didukung perangkat ini (misal MIUI),
      // fallback ke semua file agar pengguna bisa navigasi manual.
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          withData: false,
          withReadStream: false,
        );
      } catch (_) {
        if (mounted) setState(() => _error = 'Tidak dapat membuka file picker');
        return;
      }
    }

    final picked = result?.files.firstOrNull;
    if (picked != null) {
      if (picked.path == null) {
        if (mounted) setState(() => _error = 'Tidak dapat mengakses path file');
        return;
      }
      // Validasi ekstensi secara manual jika filter tidak diterapkan
      if (!picked.name.toLowerCase().endsWith('.bkse')) {
        if (mounted) setState(() => _error = 'File harus berekstensi .bkse');
        return;
      }
      setState(() {
        _selectedFilePath = picked.path;
        _selectedFileName = picked.name;
        _error = null;
      });
    }
  }

  Future<void> _doImport() async {
    final pin = _pinController.text.trim();
    if (_selectedFilePath == null) {
      setState(() => _error = 'Pilih file backup terlebih dahulu');
      return;
    }
    if (pin.length < 4) {
      setState(() => _error = 'PIN minimal 4 digit');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bytes = await File(_selectedFilePath!).readAsBytes();
      final result = await BackupService.importBytes(Uint8List.fromList(bytes), pin);

      if (!mounted) return;

      if (result.isSuccess) {
        // Refresh in-memory state agar data yang baru diimpor langsung tampil.
        ref.read(berkasProvider.notifier).refresh();
        ref.read(categoryProvider.notifier).refresh();
      }

      final messenger = ScaffoldMessenger.of(context);
      final errorColor = Theme.of(context).colorScheme.error;
      Navigator.pop(context);

      if (result.isSuccess) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '✅ Berhasil memulihkan ${result.berkasCount} berkas dan ${result.categoryCount} kategori',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Gagal', style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal membaca file: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('📥 Pulihkan dari Backup', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text(
                'Pilih file .bkse dan masukkan PIN yang digunakan saat membuat backup. Data yang ada akan digabung (tidak ditimpa).',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // File picker
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedFilePath != null ? const Color(0xFF4CAF50) : colorScheme.outlineVariant,
                      width: _selectedFilePath != null ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedFilePath != null ? const Color(0xFF4CAF50).withOpacity(0.06) : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedFilePath != null ? Icons.check_circle_outline : Icons.folder_open_outlined,
                        color: _selectedFilePath != null ? const Color(0xFF4CAF50) : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFileName ?? 'Ketuk untuk pilih file .bkse',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: _selectedFilePath != null ? const Color(0xFF2E7D32) : colorScheme.onSurfaceVariant,
                            fontWeight: _selectedFilePath != null ? FontWeight.w600 : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // PIN field
              TextField(
                controller: _pinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 12,
                decoration: InputDecoration(
                  labelText: 'PIN Enkripsi',
                  hintText: 'Masukkan PIN yang digunakan saat backup',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                  counterText: '',
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: colorScheme.error)),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _doImport,
                  icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.restore_rounded),
                  label: Text(
                    _loading ? 'Mendekripsi...' : 'Pulihkan Data',
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Internal reusable widgets ─────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: colorScheme.onSurface)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowToSection extends StatelessWidget {
  final ColorScheme colorScheme;
  const _HowToSection({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'Tekan "Buat File Backup" dan tentukan PIN minimal 4 digit.'),
      ('2', 'File .bkse dibuat lalu Anda bisa langsung kirim via WhatsApp, email, dsb.'),
      ('3', 'Di perangkat tujuan, buka aplikasi → Pengaturan → Cadangan & Migrasi → Pulihkan.'),
      ('4', 'Pilih file .bkse dan masukkan PIN yang sama untuk mendekripsi.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cara Transfer ke Perangkat Lain', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: colorScheme.onSurface)),
        const SizedBox(height: 12),
        for (final step in steps) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(step.$1, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(step.$2, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
