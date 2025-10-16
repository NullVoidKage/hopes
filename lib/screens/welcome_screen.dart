import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_wrapper.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.autoNavigate = true});

  final bool autoNavigate;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    print('WelcomeScreen initState called');
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Create scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // Start animation
    _animationController.forward();

    // Navigate to main app after animation completes (only if autoNavigate is true)
    if (widget.autoNavigate) {
      _navigateToMainApp();
    }
  }

  Future<void> _navigateToMainApp() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (mounted) {
      // Mark welcome screen as shown
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('welcome_shown', true);
      
      // Navigate back to AppInitializer which will now show AuthWrapper
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildLottieAnimation() {
    print('Building Lottie animation...');
    
    // Try the original Welcome.json first (it's more likely to work)
    return Lottie.asset(
      'assets/lottie/Welcome.json',
      width: 300,
      height: 300,
      fit: BoxFit.contain,
      repeat: true,
      animate: true,
      onLoaded: (composition) {
        print('Welcome.json Lottie animation loaded successfully - Duration: ${composition.duration}');
      },
      errorBuilder: (context, error, stackTrace) {
        print('Welcome.json Lottie error: $error');
        print('Stack trace: $stackTrace');
        // Try the simple animation as fallback
        return Lottie.asset(
          'assets/lottie/welcome.json',
          width: 300,
          height: 300,
          fit: BoxFit.contain,
          repeat: true,
          animate: true,
          onLoaded: (composition) {
            print('Welcome.json Lottie animation loaded successfully - Duration: ${composition.duration}');
          },
          errorBuilder: (context, fallbackError, stackTrace) {
            print('Both Lottie animations failed: $fallbackError');
            print('Fallback stack trace: $stackTrace');
            return _buildFallbackAnimation();
          },
        );
      },
    );
  }

  Widget _buildFallbackAnimation() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(150),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.school,
            size: 120,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Hopes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    print('WelcomeScreen build method called');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // App's light gray background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00D4FF), // App's electric blue
              Color(0xFF007AFF), // App's Apple blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie Animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: _buildLottieAnimation(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // App Title
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          const Text(
                            'Hopes',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Grade 7 E-Learning Platform',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Empowering Education Through Technology',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 60),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}