import 'package:flutter/material.dart';

class EnhancedBadgeCard extends StatefulWidget {
  final String title;
  final String description;
  final String category;
  final int points;
  final String iconName;
  final String colorHex;
  final bool isEarned;
  final bool isNew;
  final VoidCallback? onTap;

  const EnhancedBadgeCard({
    Key? key,
    required this.title,
    required this.description,
    required this.category,
    required this.points,
    required this.iconName,
    required this.colorHex,
    this.isEarned = false,
    this.isNew = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<EnhancedBadgeCard> createState() => _EnhancedBadgeCardState();
}

class _EnhancedBadgeCardState extends State<EnhancedBadgeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isEarned) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('0xFF${widget.colorHex.substring(1)}'));
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.isEarned 
                        ? color.withOpacity(0.3 * _glowAnimation.value)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: widget.isEarned ? 20 : 10,
                    spreadRadius: widget.isEarned ? 2 : 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Main card content
                    Container(
                      decoration: BoxDecoration(
                        gradient: widget.isEarned
                            ? LinearGradient(
                                colors: [
                                  color.withOpacity(0.1),
                                  color.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey.withOpacity(0.1),
                                  Colors.grey.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        border: Border.all(
                          color: widget.isEarned 
                              ? color.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Badge icon
                            _buildBadgeIcon(color),
                            const SizedBox(width: 16),
                            // Badge info
                            Expanded(
                              child: _buildBadgeInfo(color),
                            ),
                            // Points and status
                            _buildPointsAndStatus(color),
                          ],
                        ),
                      ),
                    ),
                    
                    // Shimmer effect for earned badges
                    if (widget.isEarned)
                      Positioned.fill(
                        child: _buildShimmerEffect(color),
                      ),
                    
                    // New badge indicator
                    if (widget.isNew)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _buildNewIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeIcon(Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: widget.isEarned ? color : Colors.grey.withOpacity(0.3),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.isEarned 
                ? color.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        _getAchievementIcon(widget.iconName),
        color: widget.isEarned ? Colors.white : Colors.grey,
        size: 40,
      ),
    );
  }

  Widget _buildBadgeInfo(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.isEarned ? color : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.description,
          style: TextStyle(
            fontSize: 14,
            color: widget.isEarned 
                ? Colors.black87 
                : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getCategoryColor(widget.category).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getCategoryColor(widget.category).withOpacity(0.5),
            ),
          ),
          child: Text(
            widget.category.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getCategoryColor(widget.category),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPointsAndStatus(Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isEarned ? Colors.amber : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.isEarned 
                    ? Colors.amber.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                color: widget.isEarned ? Colors.white : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.points}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.isEarned ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (widget.isEarned)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'EARNED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'LOCKED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShimmerEffect(Color color) {
    return CustomPaint(
      painter: ShimmerPainter(
        animationValue: _shimmerAnimation.value,
        color: color,
      ),
    );
  }

  Widget _buildNewIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Text(
        'NEW!',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'academic':
        return const Color(0xFF007AFF);
      case 'participation':
        return const Color(0xFF34C759);
      case 'streak':
        return const Color(0xFFFF9500);
      case 'milestone':
        return const Color(0xFFAF52DE);
      case 'special':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF86868B);
    }
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
    _animationController.dispose();
    super.dispose();
  }
}

class ShimmerPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  ShimmerPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          color.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: [
          0.0,
          0.5,
          1.0,
        ],
        begin: Alignment(-1.0 + animationValue, 0.0),
        end: Alignment(1.0 + animationValue, 0.0),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
