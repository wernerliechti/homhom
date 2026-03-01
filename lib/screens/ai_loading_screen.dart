import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AILoadingScreen extends StatefulWidget {
  const AILoadingScreen({super.key});

  @override
  State<AILoadingScreen> createState() => _AILoadingScreenState();
}

class _AILoadingScreenState extends State<AILoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  Timer? _messageTimer;
  int _currentMessageIndex = 0;

  final List<String> _funnyMessages = [
    "🔬 Counting all the peas...",
    "📏 Measuring food height...",
    "🧬 Calculating protein molecules...",
    "🌽 Identifying mystery vegetables...",
    "⚖️ Weighing invisible calories...",
    "🍎 Teaching AI what an apple is...",
    "🔍 Searching for hidden nutrients...",
    "🧮 Doing complex food math...",
    "🎨 Analyzing food colors scientifically...",
    "🤖 Consulting our robot nutritionist...",
    "📊 Generating nutrition facts...",
    "🥗 Calculating salad complexity...",
    "🍕 Estimating cheese density...",
    "🥕 Measuring carrot crunchiness...",
    "🍔 Deconstructing burger layers..."
  ];

  @override
  void initState() {
    super.initState();

    // Set up animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();

    // Start message rotation
    _startMessageRotation();
  }

  void _startMessageRotation() {
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _funnyMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Animated AI brain/analysis icon
              _buildAnimatedIcon(),
              
              const SizedBox(height: 48),
              
              // Title
              const Text(
                'AI Analysis in Progress',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              const Text(
                'Our AI nutritionist is examining your meal',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Rotating funny messages
              _buildFunnyMessage(),
              
              const SizedBox(height: 48),
              
              // Progress bar
              _buildProgressBar(),
              
              const Spacer(),
              
              // Estimated time
              const Text(
                'Usually takes 10-30 seconds',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer rotating ring
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * pi,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withAlpha(100),
                    width: 2,
                  ),
                ),
                child: CustomPaint(
                  painter: _DottedCirclePainter(),
                ),
              ),
            );
          },
        ),
        
        // Middle pulsing circle
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withAlpha(30),
                ),
              ),
            );
          },
        ),
        
        // Center brain icon
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary,
          ),
          child: const Icon(
            Icons.psychology,
            color: Colors.white,
            size: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildFunnyMessage() {
    return SizedBox(
      height: 60,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey(_currentMessageIndex),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _funnyMessages[_currentMessageIndex],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: AppTheme.primary.withAlpha(30),
          ),
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                value: null, // Indeterminate progress
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...List.generate(4, (index) {
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final delay = index * 0.2;
                  final animValue = (_pulseController.value + delay) % 1.0;
                  final opacity = (sin(animValue * pi) * 0.5 + 0.5).clamp(0.3, 1.0);
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withValues(alpha: opacity),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _DottedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withAlpha(150)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dotCount = 12;
    const dotRadius = 3.0;

    for (int i = 0; i < dotCount; i++) {
      final angle = (i * 2 * pi) / dotCount;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}