import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/qrcode_service.dart';

class EditQrCodeScreen extends StatefulWidget {
  const EditQrCodeScreen({super.key, required this.assetId});

  final String assetId;

  @override
  State<EditQrCodeScreen> createState() => _EditQrCodeScreenState();
}

class _EditQrCodeScreenState extends State<EditQrCodeScreen> {
  static const Color _accent = Color(0xFFB00000);

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactAddressController = TextEditingController();
  final _contactNoteController = TextEditingController();
  final Set<String> _visibleFields = <String>{};
  bool _loading = false;
  String? _privacyMode;

  static const List<String> _visibleFieldOptions = [
    'name',
    'phone',
    'email',
    'address',
  ];

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _contactAddressController.dispose();
    _contactNoteController.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    setState(() => _loading = true);
    try {
      final service = context.read<QrCodeService>();
      final detail = await service.getQrCodeDetail(widget.assetId);
      if (!mounted || detail == null) {
        return;
      }
      _nameController.text = detail.name;
      _descController.text = detail.description ?? '';
      _contactNameController.text =
          detail.contactInfo?['name']?.toString() ?? '';
      _contactPhoneController.text =
          detail.contactInfo?['phone']?.toString() ?? '';
      _contactEmailController.text =
          detail.contactInfo?['email']?.toString() ?? '';
      _contactAddressController.text =
          detail.contactInfo?['address']?.toString() ?? '';
      _contactNoteController.text =
          detail.contactInfo?['note']?.toString() ?? '';

      final privacyMode = detail.privacyMode;
      if (privacyMode == 'global' || privacyMode == 'custom') {
        _privacyMode = privacyMode;
      }
      _visibleFields
        ..clear()
        ..addAll(detail.visibleFields.where(_visibleFieldOptions.contains));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama wajib diisi.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final service = context.read<QrCodeService>();
      await service.updateQrCode(
        assetId: widget.assetId,
        name: name,
        description: _descController.text.trim(),
        contactName: _contactNameController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactAddress: _contactAddressController.text.trim(),
        contactNote: _contactNoteController.text.trim(),
        privacyMode: _privacyMode,
        visibleFields:
            _privacyMode == 'custom' ? _visibleFields.toList() : null,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan data QR.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.montserrat(color: Colors.black54),
      prefixIcon: Icon(icon, color: _accent),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Edit Data QR',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
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
                      children: [
                        const Icon(Icons.edit_note_rounded, size: 80, color: _accent),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _nameController,
                          style: GoogleFonts.montserrat(),
                          decoration: _buildInputDecoration('Nama Barang', Icons.inventory_2_outlined),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descController,
                          style: GoogleFonts.montserrat(),
                          decoration: _buildInputDecoration('Deskripsi Tambahan', Icons.description_outlined),
                        ),
                        const SizedBox(height: 24),
                        Divider(color: Colors.grey.shade100, thickness: 1.5),
                        const SizedBox(height: 16),
                        Text(
                          'Data Pemilik Asli',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _contactNameController,
                          style: GoogleFonts.montserrat(),
                          decoration: _buildInputDecoration('Nama Kontak', Icons.person_outline),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _contactPhoneController,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.montserrat(),
                          decoration: _buildInputDecoration('Nomor Telepon', Icons.phone_outlined),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _contactEmailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.montserrat(),
                          decoration: _buildInputDecoration('Alamat Email', Icons.email_outlined),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _contactAddressController,
                          style: GoogleFonts.montserrat(),
                          decoration: _buildInputDecoration('Alamat', Icons.location_on_outlined),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _contactNoteController,
                          minLines: 2,
                          maxLines: 4,
                          style: GoogleFonts.montserrat(),
                          decoration: _buildInputDecoration('Catatan Kontak', Icons.sticky_note_2_outlined),
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          value: _privacyMode,
                          style: GoogleFonts.montserrat(color: Colors.black87),
                          decoration: _buildInputDecoration('Mode Privasi', Icons.shield_outlined),
                          items: [
                            DropdownMenuItem(
                              value: 'global',
                              child: Text('Global', style: GoogleFonts.montserrat()),
                            ),
                            DropdownMenuItem(
                              value: 'custom',
                              child: Text('Custom', style: GoogleFonts.montserrat()),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _privacyMode = value;
                              if (value != 'custom') {
                                _visibleFields.clear();
                              }
                            });
                          },
                        ),
                        if (_privacyMode == 'custom') ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Field yang ditampilkan',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._visibleFieldOptions.map(
                            (field) => CheckboxListTile(
                              value: _visibleFields.contains(field),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _visibleFields.add(field);
                                  } else {
                                    _visibleFields.remove(field);
                                  }
                                });
                              },
                              title: Text(field, style: GoogleFonts.montserrat()),
                              dense: true,
                              activeColor: _accent,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _save,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 20, color: Colors.white),
                      label: Text(
                        _loading ? 'Menyimpan...' : 'Simpan Perubahan',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}





