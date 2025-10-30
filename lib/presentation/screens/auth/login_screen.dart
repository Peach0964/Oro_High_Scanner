import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/services/supabase_service.dart';
import '../../widgets/common/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController(); // Student ID or Email
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final identifier = _idController.text.trim();
      final password = _passwordController.text;

      // If Supabase is configured use it, else fallback to demo login.
      if (SupabaseService.isConfigured) {
        await SupabaseService.signInWithStudentIdOrEmail(
          identifier: identifier,
          password: password,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/scanner');
      } else {
        // Demo fallback
        if (identifier == '2025123456' && password == 'password123') {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/scanner');
        } else if (identifier == 'admin@orohigh.edu' &&
            password == 'admin123') {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/scanner');
        } else {
          throw Exception('Invalid credentials');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF173B79),
              const Color(0xFF1F4592),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _buildCard(isWide),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(bool isWide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top emblem (school logo from assets)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'asset/orosite.jpg', // uses asset declared in pubspec.yaml
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.school,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title + subtitle
            Text(
              AppStrings.appTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.appTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 22),

            // Student ID / Email
            _buildField(
              controller: _idController,
              hint: 'Student ID or Email',
              prefix: const Icon(Icons.person, color: Color(0xFF6B7280)),
              validator: (v) =>
                  Validators.validateRequired(v, 'Student ID or Email'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Password
            _buildField(
              controller: _passwordController,
              hint: 'Password',
              prefix: const Icon(Icons.lock, color: Color(0xFF6B7280)),
              obscure: _obscurePassword,
              validator: Validators.validatePassword,
              onSubmit: (_) => _login(),
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF6B7280),
                ),
                onPressed: () => setState(() {
                  _obscurePassword = !_obscurePassword;
                }),
              ),
            ),
            const SizedBox(height: 18),

            // Login button
            CustomButton(
              text: 'Login',
              icon: Icons.login_rounded,
              onPressed: _login,
              isLoading: _isLoading,
              height: 52,
              borderRadius: 12,
            ),

            const SizedBox(height: 14),

            // Default credentials hint
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFF6B7280)),
                  SizedBox(width: 8),
                ],
              ),
            ),

            // Text after icon to keep const block simple
            const Padding(
              padding: EdgeInsets.only(top: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Default: 2025123456 / password123',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required Widget prefix,
    String? Function(String?)? validator,
    Widget? suffix,
    bool obscure = false,
    TextInputAction? textInputAction,
    void Function(String)? onSubmit,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmit,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefix,
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
