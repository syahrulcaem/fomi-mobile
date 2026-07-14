import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/qrcode_model.dart';
import '../../services/qrcode_service.dart';
import '../../widgets/skeleton_loader.dart';

class QrCodeDetailScreen extends StatefulWidget {
  const QrCodeDetailScreen({super.key, required this.assetId});

  final String assetId;

  @override
  State<QrCodeDetailScreen> createState() => _QrCodeDetailScreenState();
}

class _QrCodeDetailScreenState extends State<QrCodeDetailScreen> {
  static const Color _accent = Color(0xFFB00000);
  
  bool _loading = false;
  QrCodeModel? _qrcode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = context.read<QrCodeService>();
      final item = await service.getQrCodeDetail(widget.assetId);
      if (!mounted) {
        return;
      }
      setState(() => _qrcode = item);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat detail QR.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleLost() async {
    setState(() => _loading = true);
    try {
      final service = context.read<QrCodeService>();
      await service.toggleLostStatus(widget.assetId);
      await _load();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal toggle status.')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qr = _qrcode;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Detail QR Code',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading && qr == null
          ? _buildSkeleton()
          : qr == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner_outlined, size: 60, color: _accent),
                      const SizedBox(height: 16),
                      Text(
                        'Data QR tidak ditemukan',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMainCard(qr),
                      const SizedBox(height: 16),
                      _buildContactCard(qr),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/qrcodes/${widget.assetId}/edit'),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: Text(
                                'Edit QR',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _accent,
                                side: const BorderSide(color: _accent, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _toggleLost,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Icon(qr.isLost ? Icons.check_circle_outline : Icons.warning_amber_rounded, size: 18),
                              label: Text(
                                qr.isLost ? 'Barang Ketemu' : 'Barang Hilang',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: qr.isLost ? Colors.green.shade600 : _accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SkeletonLoader(
          width: double.infinity,
          height: 380,
          borderRadius: 18,
        ),
        const SizedBox(height: 16),
        const SkeletonLoader(
          width: double.infinity,
          height: 200,
          borderRadius: 18,
        ),
      ],
    );
  }

  Widget _buildMainCard(QrCodeModel qr) {
    final bool hasImage = qr.imageUrl != null && qr.imageUrl!.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE3E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: hasImage
                ? Image.network(
                    qr.imageUrl!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      width: double.infinity,
                      color: const Color(0xFFFFF5F5),
                      child: const Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey),
                    ),
                  )
                : Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF5F5),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, size: 80, color: _accent),
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            qr.name,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            qr.description ?? 'Belum ada deskripsi nih!',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: qr.isLost ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Status: ${qr.status ?? '-'}',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: qr.isLost ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(QrCodeModel qr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF5F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.contact_mail_outlined, color: _accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Kontak Pemilik',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade100, thickness: 1.5, height: 1),
          const SizedBox(height: 16),
          _buildContactRow(Icons.person_outline_rounded, 'Nama', qr.contactInfo?['name']),
          const SizedBox(height: 16),
          _buildContactRow(Icons.phone_outlined, 'Telepon', qr.contactInfo?['phone']),
          const SizedBox(height: 16),
          _buildContactRow(Icons.email_outlined, 'Email', qr.contactInfo?['email']),
          if (qr.scanLogsCount != null) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100, thickness: 1.5, height: 1),
            const SizedBox(height: 16),
            _buildContactRow(Icons.history_rounded, 'Jumlah Scan', '${qr.scanLogsCount} kali discan'),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String title, String? subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black45, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle ?? '-',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}




