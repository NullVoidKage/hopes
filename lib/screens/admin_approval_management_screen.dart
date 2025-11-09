import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_service.dart';
import '../models/student_approval.dart';
import '../services/auth_service.dart';

class AdminApprovalManagementScreen extends StatefulWidget {
  const AdminApprovalManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminApprovalManagementScreen> createState() => _AdminApprovalManagementScreenState();
}

class _AdminApprovalManagementScreenState extends State<AdminApprovalManagementScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  List<StudentApproval> _allApprovals = [];
  List<StudentApproval> _filteredApprovals = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadApprovals();
  }

  void _onTabChanged() {
    _applyFilters();
  }

  Future<void> _loadApprovals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final approvals = await _adminService.getAllApprovals();
      setState(() {
        _allApprovals = approvals;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading approvals: $e'),
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

  void _applyFilters() {
    String? statusFilter;
    switch (_tabController.index) {
      case 0:
        statusFilter = null; // All
        break;
      case 1:
        statusFilter = 'pending';
        break;
      case 2:
        statusFilter = 'approved';
        break;
    }

    var filtered = _allApprovals;

    if (statusFilter != null) {
      filtered = filtered.where((approval) => approval.status == statusFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((approval) {
        return approval.studentName.toLowerCase().contains(query) ||
            approval.studentEmail.toLowerCase().contains(query) ||
            approval.gradeLevel.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredApprovals = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search approvals...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
        ),

        // Tab Bar
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFAF52DE),
          unselectedLabelColor: const Color(0xFF86868B),
          indicatorColor: const Color(0xFFAF52DE),
          tabs: const [
            Tab(text: 'All Approvals'),
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
          ],
        ),

        // Approval List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredApprovals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pending_actions, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No approvals found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadApprovals,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredApprovals.length,
                        itemBuilder: (context, index) {
                          return _buildApprovalCard(_filteredApprovals[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildApprovalCard(StudentApproval approval) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (approval.status) {
      case 'pending':
        statusColor = const Color(0xFFFF9500);
        statusIcon = Icons.pending;
        statusText = 'Pending';
        break;
      case 'approved':
        statusColor = const Color(0xFF34C759);
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = const Color(0xFFFF3B30);
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          approval.studentName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(approval.studentEmail),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(statusText),
                  backgroundColor: statusColor.withOpacity(0.1),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Chip(
                  label: Text('Grade ${approval.gradeLevel}'),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  labelStyle: const TextStyle(fontSize: 12),
                ),
                if (approval.teacherName != null)
                  Chip(
                    label: Text('Reviewed by: ${approval.teacherName}'),
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            if (approval.rejectionReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Reason: ${approval.rejectionReason}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
        trailing: approval.status == 'pending'
            ? PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'approve') {
                    await _approveStudent(approval);
                  } else if (value == 'reject') {
                    _showRejectDialog(approval);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'approve',
                    child: Row(
                      children: [
                        Icon(Icons.check, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Approve'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reject',
                    child: Row(
                      children: [
                        Icon(Icons.close, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Reject'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Future<void> _approveStudent(StudentApproval approval) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userProfile = await _authService.getUserProfile(currentUser.uid);
      if (userProfile == null) return;

      await _adminService.approveStudent(
        approval.id,
        currentUser.uid,
        userProfile.displayName,
        notes: 'Approved by administrator',
      );

      if (mounted) {
        _loadApprovals();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(StudentApproval approval) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject ${approval.studentName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Enter reason for rejection...',
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
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) return;

                final userProfile = await _authService.getUserProfile(currentUser.uid);
                if (userProfile == null) return;

                await _adminService.rejectStudent(
                  approval.id,
                  currentUser.uid,
                  userProfile.displayName,
                  reasonController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  _loadApprovals();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student rejected'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }
}

