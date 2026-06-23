import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/app_shell.dart';
import 'pages/login_page.dart';
import 'services/database_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDatabase();

  await Supabase.initialize(
    url: 'https://hkyipemvlhqmyhnawkix.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhreWlwZW12bGhxbXlobmF3a2l4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE3NzMwMDQsImV4cCI6MjA5NzM0OTAwNH0.YiV8l8M2n-gnJMdTLCgKMCMlj2QVy0mIVUDBceNURM0',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniMove',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E104E)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),

      routes: {'/login': (context) => const LoginPage()},
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _scale = Tween<double>(
      begin: 0.95,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;

      final hasActiveSession =
          Supabase.instance.client.auth.currentSession != null;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) {
            return hasActiveSession ? const AppShell() : const LoginPage();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 450),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoWidth = screenWidth.clamp(280.0, 920.0) * 0.9;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF4),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _SplashAccentBackground(),
            Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scale,
                  child: Image.asset(
                    'assets/images/unimove_splash_wordmark.png',
                    key: const Key('unimove-splash-logo'),
                    width: logoWidth,
                    fit: BoxFit.contain,
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

class _SplashAccentBackground extends StatelessWidget {
  const _SplashAccentBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SplashAccentPainter());
  }
}

class _SplashAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final topPaint = Paint()..color = const Color(0xFF1E104E);
    final bottomPaint = Paint()..color = const Color(0xFFFF653F);
    final goldPaint = Paint()..color = const Color(0xFFFFC85C);

    final topPath = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.16)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.22,
        0,
        size.height * 0.13,
      )
      ..close();

    final bottomPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height * 0.9)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.84,
        0,
        size.height * 0.93,
      )
      ..close();

    canvas.drawPath(topPath, topPaint);
    canvas.drawPath(bottomPath, bottomPaint);

    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.86),
      size.shortestSide * 0.05,
      goldPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
