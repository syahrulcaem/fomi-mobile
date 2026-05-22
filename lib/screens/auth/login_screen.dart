import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _accent = Color(0xFFBB1919);
  static const Color _bg = Color(0xFFF9F9F9);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _showPassword = false;
  bool _rememberMe = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
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
      _errorText = authProvider.errorMessage ?? 'Login gagal';
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
      _errorText = authProvider.errorMessage ?? 'Login Google gagal';
    });
  }

  void _showForgotPasswordInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur lupa password akan segera tersedia.'),
      ),
    );
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
                'Selamat datang\nkembali',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Masuk ke akun FOMI Anda untuk memantau pesanan, langganan, dan QR Code barang Anda.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showPanel = constraints.maxWidth >= 900;

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
                              'Masuk ke akun',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Gunakan email dan password Anda untuk melanjutkan.',
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
                                  const _FieldLabel(text: 'EMAIL'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _inputDecoration(
                                      hint: 'nama@email.com',
                                      icon: Icons.email_outlined,
                                    ),
                                    validator: (value) {
                                      final email = value?.trim() ?? '';
                                      if (email.isEmpty) {
                                        return 'Email wajib diisi.';
                                      }
                                      if (!email.contains('@')) {
                                        return 'Format email belum valid.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  const _FieldLabel(text: 'PASSWORD'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_showPassword,
                                    decoration: _inputDecoration(
                                      hint: 'Min. 8 karakter',
                                      icon: Icons.lock_outline,
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
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password wajib diisi.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
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
                                      value: _rememberMe,
                                      onChanged: _isSubmitting
                                          ? null
                                          : (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                      title: const Text(
                                        'Ingat saya di perangkat ini',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      activeColor: _accent,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : _showForgotPasswordInfo,
                                      style: TextButton.styleFrom(
                                        foregroundColor: _accent,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text('Lupa password?'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
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
                                            : 'Masuk',
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
                                  'Masuk dengan Google',
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
                                    'Belum punya akun? ',
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : () => context.push('/register'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _accent,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(20, 20),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Daftar',
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
