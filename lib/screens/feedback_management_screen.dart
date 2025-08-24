import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feedback.dart';
import '../services/feedback_service.dart';
import 'feedback_creation_screen.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackManagementScreen> createState() => _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FeedbackService _feedbackService = FeedbackService();
  
  List<StudentFeedback> _feedback = [];
  List<StudentRecommendation> _recommendations = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final feedback = await _feedbackService.getTeacherFeedback(currentUser.uid);
        final recommendations = await _feedbackService.getTeacherRecommendations(currentUser.uid);
        final stats = await _feedbackService.getFeedbackStatistics(currentUser.uid);

        setState(() {
          _feedback = feedback;
          _recommendations = recommendations;
          _statistics = stats;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
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
        title: const Text('Feedback & Recommendations'),
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Feedback'),
            Tab(text: 'Recommendations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildFeedbackTab(),
          _buildRecommendationsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToFeedbackCreation(),
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Feedback'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticsCards(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
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
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Feedback',
          _statistics['totalFeedback']?.toString() ?? '0',
          Icons.feedback,
          const Color(0xFF007AFF),
        ),
        _buildStatCard(
          'Unread Feedback',
          _statistics['unreadFeedback']?.toString() ?? '0',
          Icons.mark_email_unread,
          const Color(0xFFFF9500),
        ),
        _buildStatCard(
          'Total Recommendations',
          _statistics['totalRecommendations']?.toString() ?? '0',
          Icons.lightbulb,
          const Color(0xFF34C759),
        ),
        _buildStatCard(
          'Completion Rate',
          '${_statistics['completionRate']?.toString() ?? '0'}%',
          Icons.trending_up,
          const Color(0xFFAF52DE),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
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
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentFeedback = _feedback.take(5).toList();
    final recentRecommendations = _recommendations.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 16),
        if (recentFeedback.isNotEmpty) ...[
          const Text(
            'Recent Feedback',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 8),
          ...recentFeedback.map((f) => _buildFeedbackTile(f)),
          const SizedBox(height: 16),
        ],
        if (recentRecommendations.isNotEmpty) ...[
          const Text(
            'Recent Recommendations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF34C759),
            ),
          ),
          const SizedBox(height: 8),
          ...recentRecommendations.map((r) => _buildRecommendationTile(r)),
        ],
      ],
    );
  }

  Widget _buildFeedbackTab() {
    final filteredFeedback = _getFilteredFeedback();

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: filteredFeedback.isEmpty
              ? const Center(
                  child: Text(
                    'No feedback found',
                    style: TextStyle(color: Color(0xFF86868B)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredFeedback.length,
                  itemBuilder: (context, index) {
                    return _buildFeedbackCard(filteredFeedback[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsTab() {
    final filteredRecommendations = _getFilteredRecommendations();

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: filteredRecommendations.isEmpty
              ? const Center(
                  child: Text(
                    'No recommendations found',
                    style: TextStyle(color: Color(0xFF86868B)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRecommendations.length,
                  itemBuilder: (context, index) {
                    return _buildRecommendationCard(filteredRecommendations[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
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
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'unread', child: Text('Unread')),
                DropdownMenuItem(value: 'recent', child: Text('Recent (7 days)')),
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

  List<StudentFeedback> _getFilteredFeedback() {
    switch (_selectedFilter) {
      case 'unread':
        return _feedback.where((f) => !f.isRead).toList();
      case 'recent':
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        return _feedback.where((f) => f.createdAt.isAfter(weekAgo)).toList();
      default:
        return _feedback;
    }
  }

  List<StudentRecommendation> _getFilteredRecommendations() {
    switch (_selectedFilter) {
      case 'unread':
        return _recommendations.where((r) => !r.isRead).toList();
      case 'recent':
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        return _recommendations.where((r) => r.createdAt.isAfter(weekAgo)).toList();
      default:
        return _recommendations;
    }
  }

  Widget _buildFeedbackCard(StudentFeedback feedback) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: feedback.isRead ? const Color(0xFFE5E5E7) : const Color(0xFF007AFF),
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
        leading: CircleAvatar(
          backgroundColor: feedback.isRead ? const Color(0xFF86868B) : const Color(0xFF007AFF),
          child: Icon(
            Icons.feedback,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          feedback.studentName,
          style: TextStyle(
            fontWeight: feedback.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              feedback.feedbackType.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              feedback.feedback,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber[600]),
                const SizedBox(width: 4),
                Text(
                  feedback.rating.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                Text(
                  _formatDate(feedback.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF86868B),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: !feedback.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF007AFF),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _viewFeedbackDetails(feedback),
      ),
    );
  }

  Widget _buildRecommendationCard(StudentRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recommendation.isRead ? const Color(0xFFE5E5E7) : const Color(0xFF34C759),
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
        leading: CircleAvatar(
          backgroundColor: recommendation.isRead ? const Color(0xFF86868B) : const Color(0xFF34C759),
          child: Icon(
            Icons.lightbulb,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          recommendation.title,
          style: TextStyle(
            fontWeight: recommendation.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              recommendation.studentName,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              recommendation.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(recommendation.priority),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Priority ${recommendation.priority}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(recommendation.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF86868B),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: !recommendation.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _viewRecommendationDetails(recommendation),
      ),
    );
  }

  Widget _buildFeedbackTile(StudentFeedback feedback) {
    return ListTile(
      leading: Icon(
        Icons.feedback,
        color: feedback.isRead ? const Color(0xFF86868B) : const Color(0xFF007AFF),
      ),
      title: Text(
        'Feedback for ${feedback.studentName}',
        style: TextStyle(
          fontWeight: feedback.isRead ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _formatDate(feedback.createdAt),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: !feedback.isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF007AFF),
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  Widget _buildRecommendationTile(StudentRecommendation recommendation) {
    return ListTile(
      leading: Icon(
        Icons.lightbulb,
        color: recommendation.isRead ? const Color(0xFF86868B) : const Color(0xFF34C759),
      ),
      title: Text(
        recommendation.title,
        style: TextStyle(
          fontWeight: recommendation.isRead ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'For ${recommendation.studentName} • ${_formatDate(recommendation.createdAt)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: !recommendation.isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF34C759),
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
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

  void _navigateToFeedbackCreation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FeedbackCreationScreen(),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _viewFeedbackDetails(StudentFeedback feedback) {
    // Mark as read
    if (!feedback.isRead) {
      _feedbackService.markFeedbackAsRead(feedback.id);
      setState(() {
        feedback = feedback.copyWith(isRead: true);
      });
    }

    // Show details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Feedback for ${feedback.studentName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${feedback.feedbackType.replaceAll('_', ' ').toUpperCase()}'),
              const SizedBox(height: 8),
              Text('Rating: ${feedback.rating}/5'),
              const SizedBox(height: 16),
              const Text('Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(feedback.feedback),
              const SizedBox(height: 16),
              const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(feedback.recommendations),
              const SizedBox(height: 8),
              Text('Created: ${_formatDate(feedback.createdAt)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewRecommendationDetails(StudentRecommendation recommendation) {
    // Mark as read
    if (!recommendation.isRead) {
      _feedbackService.markRecommendationAsRead(recommendation.id);
      setState(() {
        recommendation = recommendation.copyWith(isRead: true);
      });
    }

    // Show details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recommendation.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('For: ${recommendation.studentName}'),
              const SizedBox(height: 8),
              Text('Type: ${recommendation.recommendationType.replaceAll('_', ' ').toUpperCase()}'),
              const SizedBox(height: 8),
              Text('Priority: ${recommendation.priority}'),
              const SizedBox(height: 16),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(recommendation.description),
              const SizedBox(height: 16),
              const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(recommendation.reason),
              const SizedBox(height: 16),
              const Text('Action Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(recommendation.actionItems),
              const SizedBox(height: 8),
              Text('Created: ${_formatDate(recommendation.createdAt)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
