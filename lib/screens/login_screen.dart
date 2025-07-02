import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _showLogin = false;
  bool _showPassword = false;
  bool _showApiKey = false;
  bool _isLoading = false;

  final _phoneMaskFormatter = MaskTextInputFormatter(mask: '0000000000', filter: {"0": RegExp(r'[0-9]')});

  late AnimationController _floatingAnimationController;
  late AnimationController _particleAnimationController;

  @override
  void initState() {
    super.initState();
    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _loadCredentials();
  }

  @override
  void dispose() {
    _floatingAnimationController.dispose();
    _particleAnimationController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loginController.text = prefs.getString('login') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _apiKeyController.text = prefs.getString('apiKey') ?? '';
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('login', _loginController.text);
    await prefs.setString('password', _passwordController.text);
    await prefs.setString('apiKey', _apiKeyController.text);
  }

  void _onLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final token = await ApiService.getToken(
          login: _loginController.text,
          password: _passwordController.text,
          apiKey: _apiKeyController.text,
        );
        await _saveCredentials();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(
              login: _loginController.text,
              password: _passwordController.text,
              apiKey: _apiKeyController.text,
              token: token,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка авторизації: $e'),
            backgroundColor: const Color(0xFFff6b6b),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlesPainter(_particleAnimationController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildFloatingLogo() {
    return AnimatedBuilder(
      animation: _floatingAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 15 * sin(_floatingAnimationController.value * 2 * pi)),
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.analytics_outlined,
            size: 60,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    bool hasVisibilityToggle = false,
    VoidCallback? onVisibilityToggle,
    bool showText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.nunito(
          fontSize: 16,
          color: const Color(0xFF333333),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.nunito(color: const Color(0xFF667eea)),
          hintStyle: GoogleFonts.nunito(color: Colors.grey[400]),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          suffixIcon: hasVisibilityToggle
              ? IconButton(
                  icon: Icon(
                    showText ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF667eea),
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFff6b6b), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: _buildFloatingLogo(),
                      ),
                      const SizedBox(height: 32),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: Text(
                          'SmartKasa',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInUp(
                        duration: const Duration(milliseconds: 700),
                        child: Text(
                          'Система аналітики продажів',
                          style: GoogleFonts.nunito(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Вхід до системи',
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      // Телефон
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Телефон',
                                            style: GoogleFonts.nunito(
                                              color: const Color(0xFF667eea),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          _buildStyledTextField(
                                            controller: _loginController,
                                            label: '',
                                            hint: '067XXXXXXX',
                                            icon: Icons.phone,
                                            keyboardType: TextInputType.phone,
                                            inputFormatters: (Platform.isAndroid || Platform.isIOS)
                                                ? [_phoneMaskFormatter]
                                                : [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                                            validator: (v) {
                                              if (v == null || v.isEmpty) return 'Введіть номер телефону';
                                              if (v.length != 10) return 'Формат: 067XXXXXXX';
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      // Пароль
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Пароль',
                                            style: GoogleFonts.nunito(
                                              color: const Color(0xFF667eea),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          _buildStyledTextField(
                                            controller: _passwordController,
                                            label: '',
                                            hint: 'Введіть пароль',
                                            icon: Icons.lock,
                                            obscureText: !_showPassword,
                                            hasVisibilityToggle: true,
                                            showText: _showPassword,
                                            onVisibilityToggle: () => setState(() => _showPassword = !_showPassword),
                                            validator: (v) => v == null || v.isEmpty ? 'Введіть пароль' : null,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      // API-ключ
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'API-ключ',
                                            style: GoogleFonts.nunito(
                                              color: const Color(0xFF667eea),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          _buildStyledTextField(
                                            controller: _apiKeyController,
                                            label: '',
                                            hint: 'Введіть API-ключ',
                                            icon: Icons.vpn_key,
                                            obscureText: !_showApiKey,
                                            hasVisibilityToggle: true,
                                            showText: _showApiKey,
                                            onVisibilityToggle: () => setState(() => _showApiKey = !_showApiKey),
                                            validator: (v) => v == null || v.isEmpty ? 'Введіть API-ключ' : null,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 32),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(0xFF667eea),
                                            elevation: 8,
                                            shadowColor: Colors.black.withOpacity(0.3),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          onPressed: _isLoading ? null : _onLogin,
                                          child: _isLoading
                                              ? SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      const Color(0xFF667eea),
                                                    ),
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.login, size: 24),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      'Увійти',
                                                      style: GoogleFonts.nunito(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
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
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticlesPainter extends CustomPainter {
  final double animationValue;

  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final x = (size.width / 30 * i + sin(animationValue * 2 * pi + i) * 20) % size.width;
      final y = (size.height / 20 * (i % 20) + cos(animationValue * 2 * pi + i) * 30) % size.height;
      final radius = 2 + sin(animationValue * 4 * pi + i) * 1;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
} 