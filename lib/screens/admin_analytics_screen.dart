import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AdminService _adminService = AdminService();
  
  Map<String, dynamic> _statistics = {};
  Map<String, dynamic> _contentStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _adminService.getSystemStatistics();
      final contentStats = await _adminService.getContentStatistics();

      setState(() {
        _statistics = stats;
        _contentStats = contentStats;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Overview
            _buildSectionTitle('System Overview'),
            const SizedBox(height: 16),
            _buildStatisticsCards(),
            const SizedBox(height: 32),

            // Content Distribution
            _buildSectionTitle('Content Distribution'),
            const SizedBox(height: 16),
            _buildContentDistribution(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1D1D1F),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'Total Users',
          '${_statistics['totalUsers'] ?? 0}',
          Icons.people,
          const Color(0xFF007AFF),
        ),
        _buildStatCard(
          'Students',
          '${_statistics['totalStudents'] ?? 0}',
          Icons.school,
          const Color(0xFF34C759),
        ),
        _buildStatCard(
          'Teachers',
          '${_statistics['totalTeachers'] ?? 0}',
          Icons.person,
          const Color(0xFFFF9500),
        ),
        _buildStatCard(
          'Assessments',
          '${_statistics['totalAssessments'] ?? 0}',
          Icons.quiz,
          const Color(0xFFAF52DE),
        ),
        _buildStatCard(
          'Lessons',
          '${_statistics['totalLessons'] ?? 0}',
          Icons.menu_book,
          const Color(0xFFFF3B30),
        ),
        _buildStatCard(
          'Administrators',
          '${_statistics['totalAdministrators'] ?? 0}',
          Icons.admin_panel_settings,
          const Color(0xFF5856D6),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF86868B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContentDistribution() {
    final assessmentsBySubject =
        _contentStats['assessmentsBySubject'] as Map<String, dynamic>? ?? {};
    final lessonsBySubject =
        _contentStats['lessonsBySubject'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        // Assessments by Subject
        _buildDistributionCard(
          'Assessments by Subject',
          Icons.quiz,
          assessmentsBySubject,
          const Color(0xFFAF52DE),
        ),
        const SizedBox(height: 16),
        // Lessons by Subject
        _buildDistributionCard(
          'Lessons by Subject',
          Icons.menu_book,
          lessonsBySubject,
          const Color(0xFFFF3B30),
        ),
      ],
    );
  }

  Widget _buildDistributionCard(
      String title, IconData icon, Map<String, dynamic> data, Color color) {
    final entries = data.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5E7)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No data available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...entries.take(5).map((entry) {
            final subject = entry.key;
            final count = entry.value as int;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$count',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: count / (entries.first.value as int),
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

