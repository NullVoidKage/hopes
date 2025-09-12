import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/achievements.dart';
import '../services/achievements_service.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({Key? key}) : super(key: key);

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final AchievementsService _achievementsService = AchievementsService();
  List<Achievement> _allAchievements = [];
  List<StudentAchievement> _studentAchievements = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  int _totalPointsFromSubmissions = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      print('🏆 BadgesScreen: Starting to load data...');
      setState(() {
        _isLoading = true;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('🏆 BadgesScreen: Current user: ${currentUser.uid}');
        
        // Create sample achievements if they don't exist
        print('🏆 BadgesScreen: Creating sample achievements...');
        await _achievementsService.createSampleAchievements();
        
        // Process existing submissions for achievements (only once)
        print('🏆 BadgesScreen: Processing existing submissions for achievements...');
        await _achievementsService.processExistingSubmissionsForAchievements();
        
        // Load all available achievements
        print('🏆 BadgesScreen: Loading all available achievements...');
        final allAchievements = await _achievementsService.getAllAchievements();
        print('🏆 BadgesScreen: Found ${allAchievements.length} available achievements');
        
        // Check and award achievements first
        print('🏆 Checking achievements for current student...');
        final newAchievements = await _achievementsService.checkAndAwardAchievements(currentUser.uid);
        if (newAchievements.isNotEmpty) {
          print('🏆 🎉 Awarded ${newAchievements.length} new achievements!');
          for (final achievement in newAchievements) {
            print('🏆 - ${achievement.achievementTitle}');
          }
        }
        
        // Load student's earned achievements
        print('🏆 BadgesScreen: Loading student achievements...');
        final studentAchievements = await _achievementsService.getStudentAchievements(currentUser.uid);
        print('🏆 BadgesScreen: Found ${studentAchievements.length} earned achievements');
        
        // Calculate total points from assessment submissions
        print('🏆 BadgesScreen: Calculating total points from submissions...');
        final totalPoints = await _achievementsService.getTotalPointsFromSubmissions(currentUser.uid);
        print('🏆 BadgesScreen: Total points from submissions: $totalPoints');
        
        setState(() {
          _allAchievements = allAchievements;
          _studentAchievements = studentAchievements;
          _totalPointsFromSubmissions = totalPoints;
          _isLoading = false;
        });
        
        print('🏆 BadgesScreen: Data loading completed!');
      }
    } catch (e) {
      print('Error loading badges: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Badges & Achievements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF007AFF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF007AFF),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Achievement Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            'Earned',
                            '${_studentAchievements.length}',
                            Colors.green,
                            Icons.emoji_events,
                          ),
                          _buildStatCard(
                            'Available',
                            '${_allAchievements.length}',
                            Colors.orange,
                            Icons.star,
                          ),
                          _buildStatCard(
                            'Total Points',
                            '${_totalPointsFromSubmissions}',
                            Colors.purple,
                            Icons.diamond,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Category Filter
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Filter: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          underline: Container(),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Badges')),
                            DropdownMenuItem(value: 'academic', child: Text('Academic')),
                            DropdownMenuItem(value: 'participation', child: Text('Participation')),
                            DropdownMenuItem(value: 'streak', child: Text('Streak')),
                            DropdownMenuItem(value: 'milestone', child: Text('Milestone')),
                            DropdownMenuItem(value: 'special', child: Text('Special')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value ?? 'all';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badges List
                Expanded(
                  child: _buildBadgesList(),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesList() {
    final filteredAchievements = _selectedCategory == 'all'
        ? _allAchievements
        : _allAchievements.where((a) => a.category == _selectedCategory).toList();

    if (filteredAchievements.isEmpty) {
      return const Center(
        child: Text(
          'No badges available',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF8E8E93),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredAchievements.length,
      itemBuilder: (context, index) {
        final achievement = filteredAchievements[index];
        final isEarned = _studentAchievements.any((sa) => sa.achievementId == achievement.id);
        
        return _buildBadgeCard(achievement, isEarned);
      },
    );
  }

  Widget _buildBadgeCard(Achievement achievement, bool isEarned) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: isEarned
            ? Border.all(color: const Color(0xFF34C759), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Badge Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isEarned
                  ? Color(int.parse(achievement.colorHex.replaceFirst('#', '0xFF')))
                  : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
              border: isEarned
                  ? Border.all(color: const Color(0xFF34C759), width: 2)
                  : null,
            ),
            child: Icon(
              _getIconData(achievement.iconName),
              color: isEarned ? Colors.white : Colors.grey,
              size: 30,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Badge Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isEarned ? const Color(0xFF1D1D1F) : Colors.grey,
                        ),
                      ),
                    ),
                    if (isEarned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'EARNED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isEarned ? const Color(0xFF8E8E93) : Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: isEarned ? const Color(0xFFFFD700) : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${achievement.points} points',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isEarned ? const Color(0xFF1D1D1F) : Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(achievement.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getCategoryName(achievement.category),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getCategoryColor(achievement.category),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'star':
        return Icons.star;
      case 'fire':
        return Icons.local_fire_department;
      case 'book':
        return Icons.menu_book;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'trophy':
        return Icons.emoji_events;
      case 'diamond':
        return Icons.diamond;
      case 'medal':
        return Icons.workspace_premium;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'academic':
        return const Color(0xFF007AFF);
      case 'participation':
        return const Color(0xFF34C759);
      case 'streak':
        return const Color(0xFFFF6B35);
      case 'milestone':
        return const Color(0xFF8E44AD);
      case 'special':
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'academic':
        return 'Academic';
      case 'participation':
        return 'Participation';
      case 'streak':
        return 'Streak';
      case 'milestone':
        return 'Milestone';
      case 'special':
        return 'Special';
      default:
        return 'Other';
    }
  }
}
