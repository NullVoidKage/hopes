import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/achievements.dart';
import '../services/achievements_service.dart';
import '../services/student_service.dart';
import '../services/offline_service.dart';
import '../widgets/enhanced_badge_card.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final AchievementsService _achievementsService = AchievementsService();
  final StudentService _studentService = StudentService();
  
  List<LeaderboardEntry> _leaderboard = [];
  List<Achievement> _achievements = [];
  LeaderboardEntry? _currentUserPosition;
  bool _isLoading = false;
  String _selectedFilter = 'all';
  String _selectedCategory = 'all';
  bool _hasTriedCreatingSampleData = false;

  @override
  void initState() {
    super.initState();
    print('🎯 LeaderboardScreen: initState called');
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Load achievements first
        final achievements = await _achievementsService.getAllAchievements();
        
        // Get current user position if they're a student
        LeaderboardEntry? userPosition;
        try {
          userPosition = await _achievementsService.getStudentLeaderboardPosition(currentUser.uid);
        } catch (e) {
          // User might not be a student or not on leaderboard
        }

        // Load leaderboard from Firebase
        final leaderboard = await _achievementsService.getLeaderboard(limit: 100);
        
        // If still empty, try to calculate from existing submissions (only once)
        if (leaderboard.isEmpty && !_hasTriedCreatingSampleData) {
          _hasTriedCreatingSampleData = true;
          try {
            await _achievementsService.updateLeaderboardForExistingSubmissions();
            final updatedLeaderboard = await _achievementsService.getLeaderboard(limit: 100);
            setState(() {
              _leaderboard = updatedLeaderboard;
              _achievements = achievements;
              _currentUserPosition = userPosition;
            });
            return;
          } catch (e) {
            print('Error calculating leaderboard from existing submissions: $e');
          }
        }
        print('🎯 LeaderboardScreen: Loaded ${leaderboard.length} leaderboard entries');
        
        setState(() {
          _leaderboard = leaderboard;
          _achievements = achievements;
          _currentUserPosition = userPosition;
        });
      }
    } catch (e) {
      print('🎯 LeaderboardScreen: Error loading data: $e');
      setState(() {
        _leaderboard = [];
        _achievements = [];
        _currentUserPosition = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load leaderboard data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
      ),
      body: _buildLeaderboardTab(),
    );
  }

  Widget _buildLeaderboardTab() {
    final filteredLeaderboard = _getFilteredLeaderboard();
    print('🎯 LeaderboardScreen: Building leaderboard tab');
    print('🎯 LeaderboardScreen: Total leaderboard entries: ${_leaderboard.length}');
    print('🎯 LeaderboardScreen: Filtered leaderboard entries: ${filteredLeaderboard.length}');
    print('🎯 LeaderboardScreen: Is loading: $_isLoading');

    return Column(
      children: [
        _buildLeaderboardFilters(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredLeaderboard.isEmpty
                  ? const Center(
                      child: Text(
                        'No leaderboard data available',
                        style: TextStyle(color: Color(0xFF86868B)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredLeaderboard.length,
                      itemBuilder: (context, index) {
                        final entry = filteredLeaderboard[index];
                        final isCurrentUser = _currentUserPosition?.studentId == entry.studentId;
                        return _buildLeaderboardCard(entry, index + 1, isCurrentUser);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E7))),
      ),
      child: Row(
        children: [
          const Text(
            'Filter:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Students')),
                DropdownMenuItem(value: 'top10', child: Text('Top 10')),
                DropdownMenuItem(value: 'top25', child: Text('Top 25')),
                DropdownMenuItem(value: 'recent', child: Text('Recently Active')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value ?? 'all';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, int rank, bool isCurrentUser) {
    final rankColor = _getRankColor(rank);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFF007AFF).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? const Color(0xFF007AFF) : const Color(0xFFE5E5E7),
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: rankColor,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              rank.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              entry.studentName,
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                color: isCurrentUser ? const Color(0xFF007AFF) : const Color(0xFF1D1D1F),
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'YOU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber[600]),
                const SizedBox(width: 4),
                Text(
                  '${entry.totalPoints} points',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.emoji_events, size: 16, color: Colors.amber[600]),
                const SizedBox(width: 4),
                Text(
                  '${entry.achievementsCount} achievements',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Last active: ${_formatDate(entry.lastActivity)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF86868B),
              ),
            ),
          ],
        ),
        trailing: _buildStatsChips(entry),
      ),
    );
  }

  Widget _buildStatsChips(LeaderboardEntry entry) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (entry.stats['lessonsCompleted'] != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${entry.stats['lessonsCompleted']} lessons',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF34C759),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (entry.stats['assessmentsCompleted'] != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFAF52DE).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${entry.stats['assessmentsCompleted']} tests',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFAF52DE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAchievementsTab() {
    final filteredAchievements = _getFilteredAchievements();

    return Column(
      children: [
        _buildAchievementFilters(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredAchievements.isEmpty
                  ? const Center(
                      child: Text(
                        'No achievements available',
                        style: TextStyle(color: Color(0xFF86868B)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredAchievements.length,
                      itemBuilder: (context, index) {
                        return _buildAchievementCard(filteredAchievements[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAchievementFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E7))),
      ),
      child: Row(
        children: [
          const Text(
            'Category:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Categories')),
                DropdownMenuItem(value: 'academic', child: Text('Academic')),
                DropdownMenuItem(value: 'participation', child: Text('Participation')),
                DropdownMenuItem(value: 'streak', child: Text('Streaks')),
                DropdownMenuItem(value: 'milestone', child: Text('Milestones')),
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
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    // Check if current user has earned this achievement
    final currentUser = FirebaseAuth.instance.currentUser;
    final isEarned = currentUser != null && 
        _currentUserPosition != null && 
        _currentUserPosition!.achievementsCount > 0;
    
    return EnhancedBadgeCard(
      title: achievement.title,
      description: achievement.description,
      category: achievement.category,
      points: achievement.points,
      iconName: achievement.iconName,
      colorHex: achievement.colorHex,
      isEarned: isEarned,
      isNew: false, // You can implement logic to detect new badges
      onTap: () => _showBadgeDetails(achievement),
    );
  }

  Widget _buildMyProgressTab() {
    if (_currentUserPosition == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Color(0xFF86868B),
            ),
            SizedBox(height: 16),
            Text(
              'You are not on the leaderboard yet',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF86868B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete lessons and assessments to earn points!',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF86868B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMyStatsCard(),
          const SizedBox(height: 24),
          _buildMyAchievementsSection(),
        ],
      ),
    );
  }

  Widget _buildMyStatsCard() {
    final entry = _currentUserPosition!;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF34C759)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your Ranking',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Rank', '#${entry.rank}', Icons.emoji_events),
              _buildStatItem('Points', '${entry.totalPoints}', Icons.star),
              _buildStatItem('Achievements', '${entry.achievementsCount}', Icons.workspace_premium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMyAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Achievements',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 16),
        // This would show the user's recent achievements
        // For now, showing a placeholder
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E7)),
          ),
          child: const Center(
            child: Text(
              'Achievement history will appear here',
              style: TextStyle(color: Color(0xFF86868B)),
            ),
          ),
        ),
      ],
    );
  }

  List<LeaderboardEntry> _getFilteredLeaderboard() {
    try {
      // Safety check to prevent infinite loops
      if (_leaderboard.isEmpty) {
        return [];
      }
      
      switch (_selectedFilter) {
        case 'top10':
          return _leaderboard.take(10).toList();
        case 'top25':
          return _leaderboard.take(25).toList();
        case 'recent':
          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          return _leaderboard
              .where((entry) => entry.lastActivity.isAfter(weekAgo))
              .toList();
        default:
          return List.from(_leaderboard); // Create a copy to prevent issues
      }
    } catch (e) {
      print('🎯 LeaderboardScreen: Error filtering leaderboard: $e');
      return [];
    }
  }

  List<Achievement> _getFilteredAchievements() {
    if (_selectedCategory == 'all') {
      return _achievements;
    }
    return _achievements.where((a) => a.category == _selectedCategory).toList();
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.orange[700]!;
    return const Color(0xFF007AFF);
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showBadgeDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Color(int.parse('0xFF${achievement.colorHex.substring(1)}')).withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${achievement.colorHex.substring(1)}')),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(int.parse('0xFF${achievement.colorHex.substring(1)}')).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _getAchievementIcon(achievement.iconName),
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              
              // Badge title
              Text(
                achievement.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(int.parse('0xFF${achievement.colorHex.substring(1)}')),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Badge description
              Text(
                achievement.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Points and category
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${achievement.points} Points',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(achievement.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getCategoryColor(achievement.category),
                      ),
                    ),
                    child: Text(
                      achievement.category.toUpperCase(),
                      style: TextStyle(
                        color: _getCategoryColor(achievement.category),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Close button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(int.parse('0xFF${achievement.colorHex.substring(1)}')),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeCelebration(Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text('🎉 ${achievement.title}'),
        content: Text(achievement.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

}
