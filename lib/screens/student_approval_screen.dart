import 'package:flutter/material.dart';
import '../models/student_approval.dart';
import '../models/user_model.dart';
import '../services/student_approval_service.dart';

class StudentApprovalScreen extends StatefulWidget {
  final UserModel teacherProfile;

  const StudentApprovalScreen({
    super.key,
    required this.teacherProfile,
  });

  @override
  State<StudentApprovalScreen> createState() => _StudentApprovalScreenState();
}

class _StudentApprovalScreenState extends State<StudentApprovalScreen>
    with TickerProviderStateMixin {
  final StudentApprovalService _approvalService = StudentApprovalService();
  
  List<StudentApproval> _approvals = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filterOptions = ['All', 'Pending', 'Approved', 'Rejected', 'Grade 7 Only'];
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadApprovals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApprovals() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final approvals = await _approvalService.getApprovalsByTeacher(widget.teacherProfile.uid);
      
      if (mounted) {
        setState(() {
          _approvals = approvals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading approvals: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  List<StudentApproval> get _filteredApprovalsList {
    List<StudentApproval> filtered = _approvals;

    // Apply status filter
    if (_selectedFilter != 'All') {
      switch (_selectedFilter) {
        case 'Pending':
          filtered = filtered.where((approval) => approval.isPending).toList();
          break;
        case 'Approved':
          filtered = filtered.where((approval) => approval.isApproved).toList();
          break;
        case 'Rejected':
          filtered = filtered.where((approval) => approval.isRejected).toList();
          break;
        case 'Grade 7 Only':
          filtered = filtered.where((approval) => approval.isGrade7).toList();
          break;
      }
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((approval) =>
          approval.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          approval.studentEmail.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          approval.gradeLevel.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1D1D1F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Student Approvals',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00D4FF)),
            onPressed: _loadApprovals,
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00D4FF),
          unselectedLabelColor: const Color(0xFF86868B),
          indicatorColor: const Color(0xFF00D4FF),
          tabs: const [
            Tab(text: 'All Requests'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApprovalsList(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildApprovalsList() {
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredApprovalsList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredApprovalsList.length,
                      itemBuilder: (context, index) {
                        return _buildApprovalCard(_filteredApprovalsList[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5E7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF86868B), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search students...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Color(0xFF86868B)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFF86868B),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFFE5E5E7),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(StudentApproval approval) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _getStatusColor(approval.status).withValues(alpha: 0.1),
                child: Icon(
                  _getStatusIcon(approval.status),
                  color: _getStatusColor(approval.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approval.studentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      approval.studentEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF86868B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(approval.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  approval.statusDisplayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(approval.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.school_rounded, size: 16, color: const Color(0xFF86868B)),
              const SizedBox(width: 8),
              Text(
                approval.gradeLevel,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF86868B),
                ),
              ),
              const SizedBox(width: 24),
              Icon(Icons.access_time_rounded, size: 16, color: const Color(0xFF86868B)),
              const SizedBox(width: 8),
              Text(
                approval.formattedCreatedAt,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF86868B),
                ),
              ),
            ],
          ),
          if (approval.isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectStudent(approval),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF3B30),
                      side: const BorderSide(color: Color(0xFFFF3B30)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveStudent(approval),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34C759),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (approval.isRejected && approval.rejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded, color: Color(0xFFFF3B30), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: ${approval.rejectionReason}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF3B30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return FutureBuilder<Map<String, int>>(
      future: _approvalService.getApprovalStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading statistics: ${snapshot.error}'),
          );
        }
        
        final stats = snapshot.data ?? {};
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatCard('Total Requests', stats['total'] ?? 0, const Color(0xFF007AFF)),
              const SizedBox(height: 16),
              _buildStatCard('Pending', stats['pending'] ?? 0, const Color(0xFFFF9500)),
              const SizedBox(height: 16),
              _buildStatCard('Approved', stats['approved'] ?? 0, const Color(0xFF34C759)),
              const SizedBox(height: 16),
              _buildStatCard('Rejected', stats['rejected'] ?? 0, const Color(0xFFFF3B30)),
              const SizedBox(height: 16),
              _buildStatCard('Grade 7 Students', stats['grade7'] ?? 0, const Color(0xFFAF52DE)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.analytics_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF86868B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: Color(0xFF86868B),
          ),
          SizedBox(height: 16),
          Text(
            'No Student Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No student approval requests found',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9500);
      case 'approved':
        return const Color(0xFF34C759);
      case 'rejected':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF86868B);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  void _approveStudent(StudentApproval approval) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Student'),
        content: const Text('Are you sure you want to approve this student?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _approvalService.approveStudent(
                approval.id,
                widget.teacherProfile.uid,
                widget.teacherProfile.displayName,
              );
              _loadApprovals();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student approved successfully'),
                  backgroundColor: Color(0xFF34C759),
                ),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectStudent(StudentApproval approval) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Color(0xFFFF3B30),
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              await _approvalService.rejectStudent(
                approval.id,
                widget.teacherProfile.uid,
                widget.teacherProfile.displayName,
                reasonController.text.trim(),
              );
              _loadApprovals();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student rejected'),
                  backgroundColor: Color(0xFFFF3B30),
                ),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
