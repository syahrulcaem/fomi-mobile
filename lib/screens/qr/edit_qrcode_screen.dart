import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/qrcode_service.dart';

class EditQrCodeScreen extends StatefulWidget {
  const EditQrCodeScreen({super.key, required this.assetId});

  final String assetId;

  @override
  State<EditQrCodeScreen> createState() => _EditQrCodeScreenState();
}

class _EditQrCodeScreenState extends State<EditQrCodeScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Data QR')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.blue.shade200, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.edit_note, size: 80, color: Colors.blue),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Barang',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Tambahan',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(thickness: 1.5),
                      const SizedBox(height: 16),
                      Text(
                        'Data Pemilik Asli',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contactNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Kontak',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contactPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Telepon',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contactEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contactAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Alamat',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contactNoteController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Kontak',
                          prefixIcon: Icon(Icons.sticky_note_2_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: _privacyMode,
                        decoration: const InputDecoration(
                          labelText: 'Mode Privasi',
                          prefixIcon: Icon(Icons.shield_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'global',
                            child: Text('Global'),
                          ),
                          DropdownMenuItem(
                            value: 'custom',
                            child: Text('Custom'),
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
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Field yang ditampilkan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
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
                            title: Text(field),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _save,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(
                              _loading ? 'Menyimpan...' : 'Simpan Perubahan'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}




