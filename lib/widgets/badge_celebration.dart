import 'package:flutter/material.dart';
import 'dart:math' as math;

class BadgeCelebration extends StatefulWidget {
  final String badgeTitle;
  final String badgeDescription;
  final int points;
  final String iconName;
  final String colorHex;
  final VoidCallback? onAnimationComplete;

  const BadgeCelebration({
    Key? key,
    required this.badgeTitle,
    required this.badgeDescription,
    required this.points,
    required this.iconName,
    required this.colorHex,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<BadgeCelebration> createState() => _BadgeCelebrationState();
}

class _BadgeCelebrationState extends State<BadgeCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late AnimationController _badgeController;
  late AnimationController _textController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _setupAnimations();
    _startCelebration();
  }

  void _setupAnimations() {
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startCelebration() async {
    // Start confetti
    _confettiController.forward();
    
    // Start badge animation
    await Future.delayed(const Duration(milliseconds: 200));
    _badgeController.forward();
    
    // Start text animation
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
    
    // Complete main animation
    await Future.delayed(const Duration(milliseconds: 1000));
    _mainController.forward();
    
    // Call completion callback
    await Future.delayed(const Duration(milliseconds: 2000));
    widget.onAnimationComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Confetti background
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(_confettiController.value),
                size: Size.infinite,
              );
            },
          ),
          
          // Main celebration content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Badge with animation
                AnimatedBuilder(
                  animation: _badgeController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: _buildBadge(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Text with animation
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildText(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    final color = Color(int.parse('0xFF${widget.colorHex.substring(1)}'));
    
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        _getAchievementIcon(widget.iconName),
        color: Colors.white,
        size: 60,
      ),
    );
  }

  Widget _buildText() {
    return Column(
      children: [
        Text(
          '🎉 Congratulations! 🎉',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'You earned the',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.9),
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 5,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.badgeTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(int.parse('0xFF${widget.colorHex.substring(1)}')),
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.badgeDescription,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 5,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '+${widget.points} Points',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'trophy':
        return Icons.emoji_events;
      case 'fire':
        return Icons.local_fire_department;
      case 'book':
        return Icons.book;
      case 'school':
        return Icons.school;
      case 'lightbulb':
        return Icons.lightbulb;
      default:
        return Icons.workspace_premium;
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    _badgeController.dispose();
    _textController.dispose();
    super.dispose();
  }
}

class ConfettiPainter extends CustomPainter {
  final double animationValue;

  ConfettiPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent confetti
    
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height) - (animationValue * size.height * 2);
      final color = _getRandomColor(random);
      final confettiSize = random.nextDouble() * 8 + 4;
      
      if (y > -20) {
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(Offset(x, y), confettiSize, paint);
      }
    }
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
