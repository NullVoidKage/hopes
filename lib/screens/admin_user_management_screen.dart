import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedSchoolYear;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUsers();
  }

  void _onTabChanged() {
    _applyFilters();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _adminService.getAllUsers();
      setState(() {
        _allUsers = users;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
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
    String? roleFilter;
    switch (_tabController.index) {
      case 0:
        roleFilter = null; // All
        break;
      case 1:
        roleFilter = 'student';
        break;
      case 2:
        roleFilter = 'teacher';
        break;
      case 3:
        roleFilter = 'administrator';
        break;
    }

    var filtered = _allUsers;

    if (roleFilter != null) {
      filtered = filtered.where((user) {
        return user.role.toString().split('.').last == roleFilter;
      }).toList();
    }

    if (_selectedSchoolYear != null) {
      filtered = filtered.where((user) => user.schoolYear == _selectedSchoolYear).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((user) {
        return user.displayName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredUsers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search users...',
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
              const SizedBox(height: 12),
              FutureBuilder<List<String>>(
                future: _adminService.getSchoolYears(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final schoolYears = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Filter by School Year',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _selectedSchoolYear,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Years')),
                      ...schoolYears.map((year) => DropdownMenuItem(
                            value: year,
                            child: Text(year),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSchoolYear = value;
                      });
                      _applyFilters();
                    },
                  );
                },
              ),
            ],
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
            Tab(text: 'All Users'),
            Tab(text: 'Students'),
            Tab(text: 'Teachers'),
            Tab(text: 'Administrators'),
          ],
        ),

        // User List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          return _buildUserCard(_filteredUsers[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
          child: user.photoURL == null
              ? Icon(
                  user.isStudent
                      ? Icons.school
                      : user.isTeacher
                          ? Icons.person
                          : Icons.admin_panel_settings,
                  color: Colors.white,
                )
              : null,
          backgroundColor: user.isStudent
              ? const Color(0xFF34C759)
              : user.isTeacher
                  ? const Color(0xFFFF9500)
                  : const Color(0xFFAF52DE),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(user.roleDisplayName),
                  backgroundColor: user.isStudent
                      ? const Color(0xFF34C759).withOpacity(0.1)
                      : user.isTeacher
                          ? const Color(0xFFFF9500).withOpacity(0.1)
                          : const Color(0xFFAF52DE).withOpacity(0.1),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: user.isStudent
                        ? const Color(0xFF34C759)
                        : user.isTeacher
                            ? const Color(0xFFFF9500)
                            : const Color(0xFFAF52DE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user.schoolYear != null)
                  Chip(
                    label: Text(user.schoolYear!),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                if (user.grade != null)
                  Chip(
                    label: Text(user.grade!),
                    backgroundColor: Colors.green.withOpacity(0.1),
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit_role') {
              _showRoleEditDialog(user);
            } else if (value == 'edit') {
              _showEditUserDialog(user);
            } else if (value == 'delete') {
              _showDeleteConfirmDialog(user);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit_role',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 20),
                  SizedBox(width: 8),
                  Text('Change Role'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit User'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete User', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleEditDialog(UserModel user) {
    UserRole? selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change User Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((role) {
              return RadioListTile<UserRole>(
                title: Text(role == UserRole.student
                    ? 'Student'
                    : role == UserRole.teacher
                        ? 'Teacher'
                        : 'Administrator'),
                value: role,
                groupValue: selectedRole,
                onChanged: (value) {
                  setDialogState(() {
                    selectedRole = value;
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedRole != user.role
                  ? () async {
                      try {
                        await _adminService.updateUserRole(user.uid, selectedRole!);
                        if (mounted) {
                          Navigator.pop(context);
                          _loadUsers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User role updated successfully'),
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
                  : null,
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    final nameController = TextEditingController(text: user.displayName);
    final gradeController = TextEditingController(text: user.grade ?? '');
    final schoolYearController = TextEditingController(text: user.schoolYear ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: gradeController,
                decoration: const InputDecoration(labelText: 'Grade'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: schoolYearController,
                decoration: const InputDecoration(labelText: 'School Year'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.updateUser(user.uid, {
                  'displayName': nameController.text,
                  'grade': gradeController.text.isEmpty ? null : gradeController.text,
                  'schoolYear': schoolYearController.text.isEmpty
                      ? null
                      : schoolYearController.text,
                });
                if (mounted) {
                  Navigator.pop(context);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User updated successfully'),
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
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.displayName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.deleteUser(user.uid);
                if (mounted) {
                  Navigator.pop(context);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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

