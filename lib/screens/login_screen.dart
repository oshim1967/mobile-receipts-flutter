import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _showLogin = false;
  bool _showPassword = false;
  bool _showApiKey = false;

  final _phoneMaskFormatter = MaskTextInputFormatter(mask: '0000000000', filter: {"0": RegExp(r'[0-9]')});

  @override
  void initState() {
    super.initState();
    _loadCredentials();
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

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
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
          SnackBar(content: Text('Ошибка авторизации: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9D423), Color(0xFFFC913A), Color(0xFF9D50BB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: SvgPicture.asset(
                    'assets/tea_cup.svg',
                    height: 140,
                  ),
                ),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Вход в SmartKasa',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF9D50BB),
                                ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _loginController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: (Platform.isAndroid || Platform.isIOS)
                              ? [_phoneMaskFormatter]
                              : [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                            decoration: InputDecoration(
                              labelText: 'Телефон',
                              hintText: '067XXXXXXX',
                              prefixIcon: const Icon(Icons.phone, color: Color(0xFFFC913A)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Введите номер телефона';
                              if (v.length != 10) return 'Формат: 067XXXXXXX';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              prefixIcon: const Icon(Icons.lock, color: Color(0xFFFC913A)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              suffixIcon: IconButton(
                                icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _showPassword = !_showPassword),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Введите пароль' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _apiKeyController,
                            obscureText: !_showApiKey,
                            decoration: InputDecoration(
                              labelText: 'API-ключ',
                              prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFFFC913A)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              suffixIcon: IconButton(
                                icon: Icon(_showApiKey ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _showApiKey = !_showApiKey),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Введите API-ключ' : null,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9D50BB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: Icon(Icons.login, size: 24),
                              label: const Text('Войти', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              onPressed: _onLogin,
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
        ),
      ),
    );
  }
} 