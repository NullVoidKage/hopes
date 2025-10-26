import 'package:flutter/material.dart';
import '../models/student_approval.dart';
import '../models/user_model.dart';
import '../services/student_approval_service.dart';
import '../services/auth_service.dart';

class StudentPendingApprovalScreen extends StatefulWidget {
  final UserModel studentProfile;

  const StudentPendingApprovalScreen({
    super.key,
    required this.studentProfile,
  });

  @override
  State<StudentPendingApprovalScreen> createState() => _StudentPendingApprovalScreenState();
}

class _StudentPendingApprovalScreenState extends State<StudentPendingApprovalScreen> {
  final StudentApprovalService _approvalService = StudentApprovalService();
  final AuthService _authService = AuthService();
  
  StudentApproval? _approval;
  bool _isLoading = true;
  bool _isCheckingApproval = false;

  @override
  void initState() {
    super.initState();
    _loadApprovalStatus();
  }

  Future<void> _loadApprovalStatus() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final approval = await _approvalService.getApprovalByStudentId(widget.studentProfile.uid);
      
      if (mounted) {
        setState(() {
          _approval = approval;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkApprovalStatus() async {
    if (!mounted) return;

    setState(() {
      _isCheckingApproval = true;
    });

    try {
      final approval = await _approvalService.getApprovalByStudentId(widget.studentProfile.uid);
      
      if (mounted) {
        setState(() {
          _approval = approval;
          _isCheckingApproval = false;
        });

        // If approved, navigate to student dashboard
        if (approval?.isApproved == true) {
          _navigateToStudentDashboard();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingApproval = false;
        });
      }
    }
  }

  void _navigateToStudentDashboard() {
    Navigator.pushReplacementNamed(context, '/student-dashboard');
  }

  void _signOut() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildPendingApprovalContent(),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingApprovalContent() {
    if (_approval == null) {
      return _buildNoApprovalFound();
    }

    switch (_approval!.status) {
      case 'pending':
        return _buildPendingStatus();
      case 'approved':
        return _buildApprovedStatus();
      case 'rejected':
        return _buildRejectedStatus();
      default:
        return _buildUnknownStatus();
    }
  }

  Widget _buildNoApprovalFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFFFF3B30),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Approval Request Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your approval request was not found. Please contact support.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingStatus() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 64,
              color: Color(0xFFFF9500),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Approval Pending',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hello ${widget.studentProfile.displayName}!',
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your registration is being reviewed by a teacher. You will be notified once approved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Registration Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Name', widget.studentProfile.displayName),
                _buildDetailRow('Email', widget.studentProfile.email),
                _buildDetailRow('Grade Level', _approval!.gradeLevel),
                _buildDetailRow('Status', 'Pending Review'),
                _buildDetailRow('Submitted', _approval!.formattedCreatedAt),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedStatus() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: Color(0xFF34C759),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Approval Granted!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Congratulations! Your registration has been approved. You can now access the learning platform.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Approval Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Approved By', _approval!.teacherName ?? 'Teacher'),
                _buildDetailRow('Approved On', _approval!.formattedCreatedAt),
                if (_approval!.notes != null)
                  _buildDetailRow('Notes', _approval!.notes!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedStatus() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.cancel_rounded,
              size: 64,
              color: Color(0xFFFF3B30),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Registration Rejected',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Unfortunately, your registration has been rejected. Please review the reason below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Rejection Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Rejected By', _approval!.teacherName ?? 'Teacher'),
                _buildDetailRow('Rejected On', _approval!.formattedCreatedAt),
                if (_approval!.rejectionReason != null)
                  _buildDetailRow('Reason', _approval!.rejectionReason!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownStatus() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF86868B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              size: 64,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Unknown Status',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your approval status is unknown. Please contact support.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF86868B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_approval?.isPending == true) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCheckingApproval ? null : _checkApprovalStatus,
              icon: _isCheckingApproval
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(_isCheckingApproval ? 'Checking...' : 'Check Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_approval?.isApproved == true) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToStudentDashboard,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Go to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF86868B),
              side: const BorderSide(color: Color(0xFFE5E5E7)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
