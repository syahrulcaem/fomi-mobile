import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';

// ── Shared red palette (mirrors shop_theme.dart without the import) ──────────
const _kRed = Color(0xFFD32F2F);
const _kRedLight = Color(0xFFFFEBEE);
const _kRedSoft = Color(0xFFFFCDD2);
const _kBg = Color(0xFFF5F5F5);
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextSecondary = Color(0xFF757575);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _curPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();

  bool _showPhone = true;
  bool _showEmail = true;
  bool _allowFinderContact = true;
  bool _loading = false;

  late TabController _tab;
  final _tabs = const ['Profil', 'Privasi', 'Password'];
  final _tabIcons = [
    Icons.person_rounded,
    Icons.shield_rounded,
    Icons.lock_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _curPwCtrl.dispose();
    _newPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final p = await context.read<ProfileService>().getProfile();
      if (!mounted) return;
      _nameCtrl.text = p.name;
      _emailCtrl.text = p.email;
      _phoneCtrl.text = p.phone ?? '';
      _addressCtrl.text = p.address ?? '';
      _showPhone = p.privacy?.showPhone ?? true;
      _showEmail = p.privacy?.showEmail ?? true;
      _allowFinderContact = p.privacy?.allowFinderContact ?? true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    try {
      await context.read<ProfileService>().updateProfile(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
          );
      if (!mounted) return;
      await context.read<AuthProvider>().fetchProfile();
      _snack('Profil berhasil diperbarui!', success: true);
    } catch (_) {
      if (mounted) _snack('Gagal memperbarui profil.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePassword() async {
    if (_curPwCtrl.text.isEmpty || _newPwCtrl.text.isEmpty) {
      _snack('Isi semua field password terlebih dahulu.');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<ProfileService>().updatePassword(
            currentPassword: _curPwCtrl.text,
            newPassword: _newPwCtrl.text,
          );
      if (!mounted) return;
      _curPwCtrl.clear();
      _newPwCtrl.clear();
      _snack('Password berhasil diperbarui!', success: true);
    } catch (_) {
      if (mounted) _snack('Gagal memperbarui password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePrivacy() async {
    setState(() => _loading = true);
    try {
      await context.read<ProfileService>().updatePrivacy(
            PrivacySettings(
              showPhone: _showPhone,
              showEmail: _showEmail,
              allowFinderContact: _allowFinderContact,
            ),
          );
      if (!mounted) return;
      _snack('Pengaturan privasi diperbarui!', success: true);
    } catch (_) {
      if (mounted) _snack('Gagal memperbarui privasi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style:
              GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
      backgroundColor: success ? const Color(0xFF2E7D32) : _kRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.currentUser?.name ?? '';
    final email = auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: _kBg,
      body: _loading && name.isEmpty
          ? const Center(child: CircularProgressIndicator(color: _kRed))
          : Column(
              children: [
                _buildHeader(name, email),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _buildProfileTab(),
                      _buildPrivacyTab(),
                      _buildPasswordTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(String name, String email) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB71C1C), _kRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(name),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? '...' : name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                  ),
                ),
                Text(
                  email.isEmpty ? '...' : email,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Quick links
          Row(children: [
            _headerAction(
                Icons.shopping_bag_outlined, () => context.push('/orders')),
            const SizedBox(width: 8),
            _headerAction(Icons.qr_code_2_rounded, () => context.push('/scan')),
          ]),
        ],
      ),
    );
  }

  Widget _headerAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _kRedLight,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: _kRed, size: 18),
      ),
    );
  }

  // ── Tab Bar ─────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tab,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: _kRed,
          unselectedLabelColor: _kTextSecondary,
          labelStyle:
              GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
          tabs: List.generate(
              _tabs.length,
              (i) => Tab(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_tabIcons[i], size: 14),
                        const SizedBox(width: 4),
                        Text(_tabs[i]),
                      ],
                    ),
                  )),
        ),
      ),
    );
  }

  // ── Tab 1: Profil ────────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Quick navigation tiles
          _buildQuickLinks(),
          const SizedBox(height: 4),
          // Data Diri card
          _buildCard(
            icon: Icons.person_rounded,
            title: 'Data Diri',
            child: Column(
              children: [
                _buildField(
                  label: 'Nama Lengkap',
                  controller: _nameCtrl,
                  icon: Icons.person_outline_rounded,
                  hint: 'Nama lengkap kamu',
                ),
                _buildField(
                  label: 'Email',
                  controller: _emailCtrl,
                  icon: Icons.email_outlined,
                  hint: 'email@contoh.com',
                  keyboard: TextInputType.emailAddress,
                ),
                _buildField(
                  label: 'Nomor HP / WhatsApp',
                  controller: _phoneCtrl,
                  icon: Icons.phone_outlined,
                  hint: '08xxxxxxxxxx',
                  keyboard: TextInputType.phone,
                ),
                _buildField(
                  label: 'Alamat',
                  controller: _addressCtrl,
                  icon: Icons.location_on_outlined,
                  hint: 'Alamat lengkap kamu...',
                  maxLines: 3,
                ),
                const SizedBox(height: 6),
                _primaryButton(
                  label: 'Simpan Profil',
                  icon: Icons.check_rounded,
                  onTap: _loading ? null : _saveProfile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Logout button
          GestureDetector(
            onTap: () async {
              final router = GoRouter.of(context);
              await context.read<AuthProvider>().logout();
              router.go('/login');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kRedSoft, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.exit_to_app_rounded, color: _kRed, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Keluar Akun',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildQuickLinks() {
    final links = [
      _QuickLink(
          Icons.shopping_bag_rounded,
          'Pesanan',
          'Riwayat order',
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
          () => context.push('/orders')),
      _QuickLink(
          Icons.cloud_download_rounded,
          'Digital',
          'File download',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          () => context.push('/digital-products')),
      _QuickLink(Icons.credit_card_rounded, 'Langganan', 'Perpanjang QR',
          _kRedLight, _kRed, () => context.push('/shop/subscription')),
      _QuickLink(
          Icons.qr_code_2_rounded,
          'QR Saya',
          'Kelola aset',
          const Color(0xFFFFF8E1),
          const Color(0xFFF57F17),
          () => context.go('/qrcodes')),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      padding: const EdgeInsets.only(bottom: 14),
      children: links
          .map((l) => GestureDetector(
                onTap: l.onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: l.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(l.icon, color: l.fg, size: 17),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l.label,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextPrimary)),
                            Text(l.sub,
                                style: GoogleFonts.poppins(
                                    fontSize: 9, color: _kTextSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ── Tab 2: Privasi ───────────────────────────────────────────────────────────
  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFF2E7D32),
            title: 'Pengaturan Privasi',
            subtitle:
                'Pilih informasi yang boleh ditampilkan saat QR Code Anda discan.',
            child: Column(
              children: [
                _privacyToggle(
                  Icons.person_rounded,
                  'Nama Lengkap',
                  'Tampilkan nama Anda',
                  _showPhone,
                  (v) => setState(() => _showPhone = v),
                ),
                _privacyToggle(
                  Icons.phone_rounded,
                  'Nomor HP / WA',
                  'Tampilkan nomor telepon',
                  _showEmail,
                  (v) => setState(() => _showEmail = v),
                ),
                _privacyToggle(
                  Icons.email_rounded,
                  'Email',
                  'Tampilkan email Anda',
                  _allowFinderContact,
                  (v) => setState(() => _allowFinderContact = v),
                ),
                const SizedBox(height: 8),
                _primaryButton(
                  label: 'Simpan Privasi',
                  icon: Icons.shield_outlined,
                  onTap: _loading ? null : _savePrivacy,
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _privacyToggle(IconData icon, String title, String sub, bool value,
      ValueChanged<bool> onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => onChange(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: value ? _kRedLight : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: value ? _kRedSoft : Colors.grey.shade200, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: value ? _kRed : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 17, color: value ? Colors.white : _kTextSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary)),
                    Text(sub,
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: _kTextSecondary)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChange,
                activeColor: _kRed,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 3: Password ──────────────────────────────────────────────────────────
  Widget _buildPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            icon: Icons.lock_rounded,
            iconColor: const Color(0xFFF57F17),
            title: 'Ubah Password',
            child: Column(
              children: [
                _buildField(
                  label: 'Password Saat Ini',
                  controller: _curPwCtrl,
                  icon: Icons.key_rounded,
                  hint: '••••••••',
                  obscure: true,
                ),
                _buildField(
                  label: 'Password Baru',
                  controller: _newPwCtrl,
                  icon: Icons.vpn_key_outlined,
                  hint: 'Min. 8 karakter',
                  obscure: true,
                ),
                const SizedBox(height: 6),
                _primaryButton(
                  label: 'Perbarui Password',
                  icon: Icons.lock_reset_rounded,
                  onTap: _loading ? null : _savePassword,
                  color: const Color(0xFFF57F17),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Shared UI helpers ────────────────────────────────────────────────────────
  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
    Color? iconColor,
    String? subtitle,
  }) {
    final fg = iconColor ?? _kRed;
    final bg = Color.alphaBlend(fg.withOpacity(0.1), Colors.white);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: fg, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _kTextPrimary)),
                      if (subtitle != null)
                        Text(subtitle,
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: _kTextSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _kTextSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            obscureText: obscure,
            maxLines: maxLines,
            style: GoogleFonts.poppins(fontSize: 13, color: _kTextPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                  fontSize: 13, color: _kTextSecondary.withOpacity(0.5)),
              prefixIcon: Icon(icon, size: 18, color: _kTextSecondary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: _kBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kRed, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    Color? color,
  }) {
    final c = color ?? _kRed;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: onTap != null
              ? LinearGradient(
                  colors: [
                    Color.alphaBlend(Colors.black12, c),
                    c,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: onTap == null ? Colors.grey.shade200 : null,
          borderRadius: BorderRadius.circular(30),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                      color: c.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (onTap == null)
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
            else
              Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: onTap == null ? _kTextSecondary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink {
  const _QuickLink(
      this.icon, this.label, this.sub, this.bg, this.fg, this.onTap);
  final IconData icon;
  final String label;
  final String sub;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
}
