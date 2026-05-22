import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color _accent = Color(0xFFBB1919);
  static const Color _bg = Color(0xFFF9F9F9);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _termsAccepted = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_termsAccepted) {
      setState(() {
        _errorText =
            'Anda harus menyetujui Terms & Conditions terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (success) {
      context.go('/dashboard');
      return;
    }

    setState(() {
      _errorText = authProvider.errorMessage ?? 'Register gagal';
    });
  }

  Future<void> _submitGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithGoogle();

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (success) {
      context.go('/dashboard');
      return;
    }

    setState(() {
      _errorText = authProvider.errorMessage ?? 'Registrasi Google gagal';
    });
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.black45),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _accent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
      ),
    );
  }

  Widget _buildPanel() {
    return Container(
      width: 380,
      padding: const EdgeInsets.fromLTRB(36, 56, 36, 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF2C0000)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -70,
            right: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: _accent.withOpacity(0.25)),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(220),
                border: Border.all(color: _accent.withOpacity(0.12)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icon/icon.png', width: 74, height: 74),
              const SizedBox(height: 36),
              const Text(
                'Mulai lindungi\nbarang Anda',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Daftar dan pasangkan QR Code FOMI pada barang berharga Anda. Ketika ditemukan, penemu dapat langsung menghubungi Anda.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: _inputDecoration(
            hint: hint,
            icon: icon,
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showPanel = constraints.maxWidth >= 900;
          final twoColumns = constraints.maxWidth >= 560;

          return SafeArea(
            child: Row(
              children: [
                if (showPanel) _buildPanel(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 30,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!showPanel) ...[
                              Center(
                                child: Image.asset(
                                  'assets/icon/icon.png',
                                  width: 62,
                                  height: 62,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            const Text(
                              'Buat akun baru',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Isi data di bawah untuk mendaftar ke FOMI.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withOpacity(0.58),
                                height: 1.5,
                              ),
                            ),
                            if (_errorText != null) ...[
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFECACA),
                                  ),
                                ),
                                child: Text(
                                  _errorText!,
                                  style: const TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildField(
                                    label: 'NAMA LENGKAP',
                                    controller: _nameController,
                                    hint: 'Nama Anda',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Nama wajib diisi.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  if (twoColumns)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildField(
                                            label: 'EMAIL',
                                            controller: _emailController,
                                            hint: 'nama@email.com',
                                            icon: Icons.email_outlined,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            validator: (value) {
                                              final email = value?.trim() ?? '';
                                              if (email.isEmpty) {
                                                return 'Email wajib diisi.';
                                              }
                                              if (!email.contains('@')) {
                                                return 'Email belum valid.';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildField(
                                            label: 'NO. TELEPON (OPSIONAL)',
                                            controller: _phoneController,
                                            hint: '08xxxxxxxxxx',
                                            icon: Icons.phone_outlined,
                                            keyboardType: TextInputType.phone,
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    _buildField(
                                      label: 'EMAIL',
                                      controller: _emailController,
                                      hint: 'nama@email.com',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        final email = value?.trim() ?? '';
                                        if (email.isEmpty) {
                                          return 'Email wajib diisi.';
                                        }
                                        if (!email.contains('@')) {
                                          return 'Email belum valid.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _buildField(
                                      label: 'NO. TELEPON (OPSIONAL)',
                                      controller: _phoneController,
                                      hint: '08xxxxxxxxxx',
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  if (twoColumns)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildField(
                                            label: 'PASSWORD',
                                            controller: _passwordController,
                                            hint: 'Min. 8 karakter',
                                            icon: Icons.lock_outline,
                                            obscureText: !_showPassword,
                                            suffixIcon: IconButton(
                                              onPressed: () => setState(
                                                () => _showPassword =
                                                    !_showPassword,
                                              ),
                                              icon: Icon(
                                                _showPassword
                                                    ? Icons
                                                        .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: Colors.black45,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Password wajib diisi.';
                                              }
                                              if (value.length < 8) {
                                                return 'Minimal 8 karakter.';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildField(
                                            label: 'KONFIRMASI PASSWORD',
                                            controller:
                                                _confirmPasswordController,
                                            hint: 'Ulangi password',
                                            icon: Icons.lock_reset_outlined,
                                            obscureText: !_showConfirmPassword,
                                            suffixIcon: IconButton(
                                              onPressed: () => setState(
                                                () => _showConfirmPassword =
                                                    !_showConfirmPassword,
                                              ),
                                              icon: Icon(
                                                _showConfirmPassword
                                                    ? Icons
                                                        .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: Colors.black45,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Konfirmasi password wajib diisi.';
                                              }
                                              if (value !=
                                                  _passwordController.text) {
                                                return 'Password tidak sama.';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    _buildField(
                                      label: 'PASSWORD',
                                      controller: _passwordController,
                                      hint: 'Min. 8 karakter',
                                      icon: Icons.lock_outline,
                                      obscureText: !_showPassword,
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _showPassword = !_showPassword,
                                        ),
                                        icon: Icon(
                                          _showPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.black45,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password wajib diisi.';
                                        }
                                        if (value.length < 8) {
                                          return 'Minimal 8 karakter.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _buildField(
                                      label: 'KONFIRMASI PASSWORD',
                                      controller: _confirmPasswordController,
                                      hint: 'Ulangi password',
                                      icon: Icons.lock_reset_outlined,
                                      obscureText: !_showConfirmPassword,
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _showConfirmPassword =
                                              !_showConfirmPassword,
                                        ),
                                        icon: Icon(
                                          _showConfirmPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.black45,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Konfirmasi password wajib diisi.';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Password tidak sama.';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.12),
                                      ),
                                    ),
                                    child: CheckboxListTile(
                                      value: _termsAccepted,
                                      onChanged: _isSubmitting
                                          ? null
                                          : (value) {
                                              setState(() {
                                                _termsAccepted = value ?? false;
                                              });
                                            },
                                      title: RichText(
                                        text: const TextSpan(
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                            height: 1.45,
                                          ),
                                          children: [
                                            TextSpan(text: 'Saya menyetujui '),
                                            TextSpan(
                                              text: 'Terms & Conditions',
                                              style: TextStyle(
                                                color: _accent,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            TextSpan(text: ' FOMI.'),
                                          ],
                                        ),
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      activeColor: _accent,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isSubmitting ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _accent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        _isSubmitting
                                            ? 'Memproses...'
                                            : 'Buat Akun',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.black.withOpacity(0.1),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    'atau',
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.3),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.black.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _isSubmitting ? null : _submitGoogle,
                                icon: const Icon(Icons.g_mobiledata, size: 28),
                                label: const Text(
                                  'Daftar dengan Google',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.black.withOpacity(0.18),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Sudah punya akun? ',
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : () => context.pop(),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _accent,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(20, 20),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.black.withOpacity(0.45),
      ),
    );
  }
}
