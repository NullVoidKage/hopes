import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'student_profile_edit_screen.dart';

class StudentSettingsScreen extends StatefulWidget {
  final UserModel userProfile;

  const StudentSettingsScreen({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  final AuthService _authService = AuthService();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1D1D1F),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Summary Card
              _buildProfileSummaryCard(),
              
              const SizedBox(height: 24),
              
              // Account Settings
              _buildSettingsSection(
                'Account Settings',
                [
                  _buildSettingsTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () => _navigateToProfileEdit(),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF86868B),
                      size: 16,
                    ),
                  ),

                ],
              ),
              
              const SizedBox(height: 24),
              
              
              
              const SizedBox(height: 32),
              
              // Sign Out Button
              _buildSignOutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF667eea).withValues(alpha: 0.1),
            backgroundImage: widget.userProfile.photoURL != null
                ? NetworkImage(widget.userProfile.photoURL!)
                : null,
            child: widget.userProfile.photoURL == null
                ? const Icon(
                    Icons.person,
                    size: 40,
                    color: Color(0xFF667eea),
                  )
                : null,
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userProfile.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  widget.userProfile.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF86868B),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  '${widget.userProfile.grade} • ${widget.userProfile.subjects?.length ?? 0} subjects',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF007AFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: () => _navigateToProfileEdit(),
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF007AFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF667eea).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF667eea),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D1D1F),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF86868B),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }



  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _signOut,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF3B30),
          side: const BorderSide(color: Color(0xFFFF3B30)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Navigation Methods
  void _navigateToProfileEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentProfileEditScreen(
          userProfile: widget.userProfile,
        ),
      ),
    );
    
    if (result != null && mounted) {
      // Refresh the screen with updated data
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile updated! Please refresh to see changes.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }



  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
