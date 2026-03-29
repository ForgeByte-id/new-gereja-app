import 'package:flutter/material.dart';

import '../core/environment.dart';
import '../core/models.dart';
import '../core/session_controller.dart';
import '../widgets/church_logo.dart';
import '../widgets/google_signin_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.session});

  final SessionController session;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const bool _showGoogleSignIn = false;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerNomorKkController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerAlamatController = TextEditingController();
  final _registerUsiaController = TextEditingController();

  int _authTab = 0;
  String _registerJenisKelamin = 'L'; // Default to Laki-laki

  String? _error;

  void _setJemaatCredentials() {
    _loginUsernameController.text = Environment.localJemaatEmail;
    _passwordController.text = Environment.localJemaatPassword;
  }

  void _setAdminCredentials() {
    _loginUsernameController.text = Environment.localAdminEmail;
    _passwordController.text = Environment.localAdminPassword;
  }

  Future<void> _handleGoogleSignIn() async {
    // TODO: Implement Google Sign In logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign In - Coming Soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _loginUsernameController.dispose();
    _passwordController.dispose();
    _registerNameController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerNomorKkController.dispose();
    _registerPhoneController.dispose();
    _registerAlamatController.dispose();
    _registerUsiaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _error = null;
    });

    try {
      await widget.session.signIn(
        username: _loginUsernameController.text.trim(),
        password: _passwordController.text,
      );
    } on ApiError catch (error) {
      setState(() {
        _error =
            '${error.message}${error.traceId != null ? ' (trace: ${error.traceId})' : ''}';
      });
    } catch (_) {
      setState(() {
        _error = 'Login gagal. Silakan coba lagi.';
      });
    }
  }

  Future<void> _submitRegister() async {
    if (!_registerFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _error = null;
    });

    try {
      final usiaText = _registerUsiaController.text.trim();
      final usia = usiaText.isNotEmpty ? int.tryParse(usiaText) : null;

      await widget.session.signUp(
        name: _registerNameController.text.trim(),
        username: _registerUsernameController.text.trim(),
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
        nomorKk: _registerNomorKkController.text.trim(),
        phoneNumber: _registerPhoneController.text.trim(),
        jenisKelamin: _registerJenisKelamin,
        usia: usia,
        alamat: _registerAlamatController.text.trim(),
      );
    } on ApiError catch (error) {
      setState(() {
        _error =
            '${error.message}${error.traceId != null ? ' (trace: ${error.traceId})' : ''}';
      });
    } catch (_) {
      setState(() {
        _error = 'Registrasi gagal. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF121212),
                    Color(0xFF1E1E1E),
                    Color(0xFF2C2C2C),
                  ]
                : const [
                    Color(0xFFE9F4F2),
                    Color(0xFFF5F7FA),
                    Color(0xFFF0F7F6),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xEE1E1E1E)
                        : const Color(0xF7FFFFFF),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.28 : 0.08,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ChurchLogo(
                          logo: null,
                          isDark: isDark,
                          height: 92,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'GPI Yehuda',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistem Informasi Jemaat & Pelayanan',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment<int>(
                            value: 0,
                            icon: Icon(Icons.login),
                            label: Text('Login'),
                          ),
                          ButtonSegment<int>(
                            value: 1,
                            icon: Icon(Icons.person_add_alt_1),
                            label: Text('Daftar Jemaat'),
                          ),
                        ],
                        selected: {_authTab},
                        onSelectionChanged: (value) {
                          setState(() {
                            _authTab = value.first;
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _authTab == 0
                            ? Form(
                                key: _loginFormKey,
                                child: Column(
                                  key: const ValueKey('login-form'),
                                  children: [
                                    TextFormField(
                                      controller: _loginUsernameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Username atau Email',
                                        prefixIcon: Icon(Icons.alternate_email),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Username atau Email wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: Icon(Icons.lock_outline),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : Form(
                                key: _registerFormKey,
                                child: Column(
                                  key: const ValueKey('register-form'),
                                  children: [
                                    TextFormField(
                                      controller: _registerNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nama Lengkap (wajib)',
                                        prefixIcon: Icon(Icons.badge_outlined),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Nama lengkap wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _registerUsernameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Username',
                                        prefixIcon: Icon(Icons.alternate_email),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Username wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _registerEmailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(Icons.mail_outline),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Email wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _registerNomorKkController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Nomor KK',
                                        prefixIcon: Icon(
                                          Icons.credit_card_outlined,
                                        ),
                                      ),
                                      validator: (value) {
                                        final trimmed = value?.trim() ?? '';
                                        if (trimmed.isEmpty) {
                                          return 'Nomor KK wajib diisi';
                                        }
                                        if (trimmed.length < 16) {
                                          return 'Nomor KK minimal 16 digit';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _registerPhoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(
                                        labelText: 'Nomor Telepon (wajib)',
                                        prefixIcon: Icon(Icons.phone_outlined),
                                      ),
                                      validator: (value) {
                                        final trimmed = value?.trim() ?? '';
                                        if (trimmed.isEmpty) {
                                          return 'Nomor telepon wajib diisi';
                                        }
                                        if (trimmed.length < 10) {
                                          return 'Nomor telepon minimal 10 digit';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    DropdownButtonFormField<String>(
                                      initialValue: _registerJenisKelamin,
                                      decoration: const InputDecoration(
                                        labelText: 'Jenis Kelamin',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'L',
                                          child: Text('Laki-laki'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'P',
                                          child: Text('Perempuan'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _registerJenisKelamin = value ?? 'L';
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _registerUsiaController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Usia (opsional)',
                                        prefixIcon: Icon(Icons.cake_outlined),
                                      ),
                                      validator: (value) {
                                        if (value != null &&
                                            value.trim().isNotEmpty) {
                                          if (int.tryParse(value.trim()) ==
                                              null) {
                                            return 'Usia harus berupa angka';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _registerAlamatController,
                                      maxLines: 2,
                                      decoration: const InputDecoration(
                                        labelText: 'Alamat (opsional)',
                                        prefixIcon: Icon(
                                          Icons.location_on_outlined,
                                        ),
                                        alignLabelWithHint: true,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _registerPasswordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: Icon(Icons.lock_outline),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password wajib diisi';
                                        }
                                        if (value.length < 8) {
                                          return 'Password minimal 8 karakter';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _authTab == 0
                            ? (widget.session.busy ? null : _submit)
                            : (widget.session.busy ? null : _submitRegister),
                        icon: _authTab == 0
                            ? (widget.session.busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login))
                            : const Icon(Icons.person_add_alt_1),
                        label: Text(
                          _authTab == 0
                              ? 'Masuk ke Dashboard'
                              : 'Daftar Jemaat',
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (Environment.isLocal)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 32,
                                child: OutlinedButton.icon(
                                  onPressed: _setAdminCredentials,
                                  icon: const Icon(
                                    Icons.admin_panel_settings,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Admin',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 32,
                                child: OutlinedButton.icon(
                                  onPressed: _setJemaatCredentials,
                                  icon: const Icon(Icons.person, size: 16),
                                  label: const Text(
                                    'Jemaat',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Divider(color: theme.colorScheme.outlineVariant),
                      if (_showGoogleSignIn) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Atau lanjutkan dengan',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: 12),
                        GoogleSignInButton(
                          onPressed: _handleGoogleSignIn,
                          isDarkMode: isDark,
                          text: 'Lanjutkan dengan Google',
                        ),
                        const SizedBox(height: 22),
                        Divider(color: theme.colorScheme.outlineVariant),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        'Alamat: Jl. Sunset Road No. 767, Denpasar, Bali',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Instagram: @gpiyehuda • YouTube: GPI Yehuda • Facebook: GPI Yehuda Bali',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: admin@gpi-yehuda.org • Telp: (0361) 123456',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
