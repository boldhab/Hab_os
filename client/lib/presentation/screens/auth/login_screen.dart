// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/utils/google_auth_launcher.dart';

class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;
    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Red arc (top)
    canvas.drawArc(rect, -0.65, -1.95, false, paintRed);
    // Yellow arc (left)
    canvas.drawArc(rect, -2.6, -0.9, false, paintYellow);
    // Green arc (bottom)
    canvas.drawArc(rect, -3.5, -1.2, false, paintGreen);
    // Blue arc (right)
    canvas.drawArc(rect, -4.7, -1.0, false, paintBlue);

    // Blue horizontal arm
    final armPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final armRect = Rect.fromLTWH(
      center.dx,
      center.dy - strokeWidth / 2,
      radius - strokeWidth / 4,
      strokeWidth,
    );
    canvas.drawRect(armRect, armPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  void _signInWithGoogle() {
    GoogleAuthLauncher.launch(context);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      if (next.status == AuthStatus.authenticated) {
        context.go('/');
      }
    });

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryRed = colorScheme.primary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Background ambient gradient glow
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            height: 340,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    primaryRed.withOpacity(isDark ? 0.16 : 0.08),
                    primaryRed.withOpacity(isDark ? 0.04 : 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Branding Icon & Identity
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryRed,
                              Color.lerp(primaryRed, Colors.black, 0.15) ??
                                  primaryRed,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: primaryRed.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryRed.withOpacity(0.18),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'PERSONAL OPERATING SYSTEM',
                          style: textTheme.labelSmall?.copyWith(
                            color: primaryRed,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'HABos',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 32,
                          letterSpacing: -0.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to your Personal Operating System',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Card Container
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.surfaceContainerHigh
                              : colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark
                                ? colorScheme.outlineVariant.withOpacity(0.2)
                                : colorScheme.outlineVariant.withOpacity(0.4),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDark ? 0.30 : 0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color:
                                  primaryRed.withOpacity(isDark ? 0.08 : 0.03),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Input Label
                            Text(
                              'EMAIL ADDRESS',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'name@example.com',
                                hintStyle: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  size: 20,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.7),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? colorScheme.surfaceContainerLow
                                    : const Color(0xFFF7F6F4),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? colorScheme.outlineVariant
                                            .withOpacity(0.2)
                                        : colorScheme.outlineVariant
                                            .withOpacity(0.4),
                                    width: 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: primaryRed,
                                    width: 1.8,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: colorScheme.error,
                                    width: 1.0,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: colorScheme.error,
                                    width: 1.8,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password Input Label
                            Text(
                              'PASSWORD',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                hintStyle: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  size: 20,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.7),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.7),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? colorScheme.surfaceContainerLow
                                    : const Color(0xFFF7F6F4),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? colorScheme.outlineVariant
                                            .withOpacity(0.2)
                                        : colorScheme.outlineVariant
                                            .withOpacity(0.4),
                                    width: 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: primaryRed,
                                    width: 1.8,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: colorScheme.error,
                                    width: 1.0,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: colorScheme.error,
                                    width: 1.8,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // Submit Button
                            Container(
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    primaryRed,
                                    Color.lerp(
                                            primaryRed, Colors.black, 0.15) ??
                                        primaryRed,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryRed.withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: isDark
                                        ? colorScheme.outlineVariant
                                            .withOpacity(0.2)
                                        : colorScheme.outlineVariant
                                            .withOpacity(0.4),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    'OR',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.6),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: isDark
                                        ? colorScheme.outlineVariant
                                            .withOpacity(0.2)
                                        : colorScheme.outlineVariant
                                            .withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Google Sign In Button
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? colorScheme.surfaceContainerLow
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? colorScheme.outlineVariant
                                          .withOpacity(0.25)
                                      : colorScheme.outlineVariant
                                          .withOpacity(0.5),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(isDark ? 0.20 : 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: OutlinedButton(
                                onPressed: isLoading ? null : _signInWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const GoogleLogoIcon(size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Sign in with Google',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Secondary Register Option
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Register',
                              style: textTheme.bodyMedium?.copyWith(
                                color: primaryRed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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
  }
}
