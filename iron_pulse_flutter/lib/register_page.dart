import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'widgets/custom_widgets.dart';
import 'services/supabase_auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  int _passwordScore = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;

    setState(() {
      _passwordScore = score;
    });
  }

  Color _getStrengthColor() {
    switch (_passwordScore) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orangeAccent;
      case 3:
        return Colors.yellowAccent;
      case 4:
        return const Color(0xFF10B981);
      default:
        return Colors.redAccent;
    }
  }

  String _getStrengthLabel() {
    switch (_passwordScore) {
      case 1:
        return "Weak";
      case 2:
        return "Fair";
      case 3:
        return "Good";
      case 4:
        return "Strong 💪";
      default:
        return "";
    }
  }

  void _showToast(String message, {bool isError = false, bool isInfo = false}) {
    final color = isError
        ? Colors.redAccent
        : isInfo
            ? AppTheme.primary
            : const Color(0xFF10B981);

    final icon = isError
        ? Icons.error_outline
        : isInfo
            ? Icons.info_outline
            : Icons.check_circle_outline;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      await SupabaseAuthService().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: name,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final firstName = name.split(' ').first;
      _showToast("Welcome aboard, $firstName! Please check your email or sign in. 🔥");

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      
      // Remover la página de registro de la pila
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showToast(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showToast("Registration failed. Please check your credentials.", isError: true);
    }
  }

  Future<void> _handleSocialRegister(String provider) async {
    _showToast("Connecting with $provider…", isInfo: true);
    try {
      final providerEnum = provider.toLowerCase() == 'google'
          ? OAuthProvider.google
          : OAuthProvider.apple;

      await SupabaseAuthService().signInWithOAuth(providerEnum);
    } catch (e) {
      _showToast("OAuth sign-up failed: $e", isError: true);
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.2,
            width: size.width * 0.8,
            height: size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            right: -size.width * 0.1,
            width: size.width * 0.6,
            height: size.height * 0.3,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.05),
              ),
            ),
          ),

          // Scrollable layout
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image + Overlay Header
                Stack(
                  children: [
                    Container(
                      height: size.height * 0.3,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuBiZQz0Kxc9Bqx0Rz8CE2KTKcANCmqYS_Q0LR82WYCYE1ZZOzMMXLt1D6q61ATjrRBYjSZo_UWaImh1x-gPhnNOC08ivC4k4PsWzCxd1J7sL-m6v64PZS7xFPH0m6_zJ88V81ScnM7zjpCBlU4UOvjkBFBVXDohLLuh25QsUxRT55ROeHVogmxDCw3Afq_W1neA7m_F_fdTbmvBztOKQbLvRr81WjlX1cmJlcMRCuyjroswLsPlqnUF90xVrf21n4m_Qz2wJ5ART6im',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Gradients covering the image
                    Container(
                      height: size.height * 0.3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.background.withOpacity(0.3),
                            AppTheme.background.withOpacity(0.6),
                            AppTheme.background,
                          ],
                        ),
                      ),
                    ),
                    // Branding Logo
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 24,
                      child: Row(
                        children: [
                          Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "IRON PULSE",
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Form Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                            children: const [
                              TextSpan(text: "Join the pulse,\n"),
                              TextSpan(
                                text: "Athlete.",
                                style: TextStyle(color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Create your free account today.",
                          style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textMuted,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Full Name
                        CustomTextField(
                          controller: _nameController,
                          labelText: "Full Name",
                          hintText: "John Carter",
                          keyboardType: TextInputType.name,
                          rightIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter your full name.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Email
                        CustomTextField(
                          controller: _emailController,
                          labelText: "Email Address",
                          hintText: "athlete@ironpulse.com",
                          keyboardType: TextInputType.emailAddress,
                          rightIcon: Icons.mail_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter your email address.";
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                              return "Please enter a valid email address.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              controller: _passwordController,
                              labelText: "Password",
                              hintText: "Min. 8 characters",
                              isPassword: true,
                              onChanged: _checkPasswordStrength,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter a password.";
                                }
                                if (value.length < 8) {
                                  return "Password must be at least 8 characters.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            // Password strength bar
                            Container(
                              height: 4,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    width: _passwordScore == 0
                                        ? 0
                                        : (size.width - 48) * (_passwordScore / 4.0),
                                    decoration: BoxDecoration(
                                      color: _getStrengthColor(),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_passwordScore > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                _getStrengthLabel(),
                                style: GoogleFonts.spaceGrotesk(
                                  color: _getStrengthColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password
                        CustomTextField(
                          controller: _confirmPasswordController,
                          labelText: "Confirm Password",
                          hintText: "••••••••",
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please confirm your password.";
                            }
                            if (value != _passwordController.text) {
                              return "Passwords do not match.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Create Account button
                        PrimaryButton(
                          text: "Create Account",
                          isLoading: _isLoading,
                          onPressed: _handleRegister,
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppTheme.surface,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                "Or continue with",
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppTheme.surface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Social Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SocialButton(
                                text: "Google",
                                iconUrl:
                                    "https://lh3.googleusercontent.com/aida-public/AB6AXuDDteqkUrPqzgg5ImUnbpemCrBQaMQ89HQVElnupGHH896U9VsXjcs8kHAJPqLrSuquLsKyaECtGv3hE28xlalzapmq0W3QjyNFQGze_GT49P-wNavC5sewMYSTUfvfWeJWL-QxNjLoo0c-GqCBBwBn2fx1I1Jk-Ya-aOSm3CAsPjJ4V9NxYk4iXoxVk4z9kaBgU5SajYFYDMUVQP24FX7aBviDkWNpmvA1cUwF5MsBtMqAVmiYr1MMj2F2rBzaIakukpPeRB1HpsJh",
                                onPressed: () => _handleSocialRegister("Google"),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SocialButton(
                                text: "Apple",
                                iconUrl:
                                    "https://lh3.googleusercontent.com/aida-public/AB6AXuCgg-rIhaqvyu4KLIokG8rsU4kWIvJxHnmmRWwSfLiKoF32f4_tDv_bDd5NKCTa47uSYjQIV2dpbUX8tZPQXvG25jS2RxbA3O_ZY_ZLKp-KGVP6cGWzA21eX-12GH3p8w9jhHKFs-5C94EKi7ckb_hzfu1RBBUSwMcuH7bzVDH-tMTGDxvj1Mg4jYWIdb1UPi0V5KmOl96t_vt7jV_XIkQJVulyBqiEsp1VVtiZFJO_RwhE1wZxwCkqfFTqGtkqMDD7bcr9vWMwEKj3",
                                invertIcon: true,
                                onPressed: () => _handleSocialRegister("Apple"),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 36),

                        // Footer
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacementNamed(context, '/');
                              }
                            },
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppTheme.textMuted,
                                  fontSize: 14,
                                ),
                                children: const [
                                  TextSpan(text: "Already have an account?"),
                                  TextSpan(
                                    text: " Sign In",
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
