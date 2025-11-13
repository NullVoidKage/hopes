import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../services/class_service.dart';
import 'class_creation_screen.dart';
import 'class_edit_screen.dart';

class ClassManagementScreen extends StatefulWidget {
  final UserModel teacherProfile;

  const ClassManagementScreen({
    super.key,
    required this.teacherProfile,
  });

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final ClassService _classService = ClassService();
  
  List<ClassModel> _classes = [];
  bool _isLoading = true;
  String? _selectedSubject;
  String? _selectedSection;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final classes = await _classService.getClassesByTeacher(currentUser.uid);
        setState(() {
          _classes = classes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading classes: $e'),
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

  List<ClassModel> get _filteredClasses {
    var filtered = _classes;
    
    if (_selectedSubject != null) {
      filtered = filtered.where((c) => c.subject == _selectedSubject).toList();
    }
    
    if (_selectedSection != null) {
      filtered = filtered.where((c) => c.section == _selectedSection).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final teacherSubjects = widget.teacherProfile.subjects ?? [];
    final sections = ['A', 'B', 'C', 'D'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Class Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF007AFF)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassCreationScreen(
                    teacherProfile: widget.teacherProfile,
                  ),
                ),
              );
              if (result == true) {
                _loadClasses();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Subjects')),
                      ...teacherSubjects.map((subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSection,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Sections')),
                      ...sections.map((section) => DropdownMenuItem(
                        value: section,
                        child: Text('Section $section'),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSection = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Class List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClasses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.class_, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No classes found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first class to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadClasses,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredClasses.length,
                          itemBuilder: (context, index) {
                            return _buildClassCard(_filteredClasses[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(ClassModel classModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
          child: const Icon(Icons.class_, color: Color(0xFF007AFF)),
        ),
        title: Text(
          '${classModel.subject} - Section ${classModel.section}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class Code: ${classModel.classCode}'),
            Text('Students: ${classModel.enrolledStudentIds.length}/${classModel.maxStudents}'),
            if (classModel.description != null)
              Text(
                classModel.description!,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassEditScreen(
                    classModel: classModel,
                    teacherProfile: widget.teacherProfile,
                  ),
                ),
              );
              if (result == true) {
                _loadClasses();
              }
            } else if (value == 'delete') {
              _showDeleteDialog(classModel);
            } else if (value == 'copy_code') {
              // Copy class code to clipboard
              await Clipboard.setData(ClipboardData(text: classModel.classCode));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Class code "${classModel.classCode}" copied to clipboard'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'copy_code',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 20),
                  SizedBox(width: 8),
                  Text('Copy Class Code'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit Class'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Class', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(ClassModel classModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete ${classModel.subject} - Section ${classModel.section}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _classService.deleteClass(classModel.id);
                if (mounted) {
                  Navigator.pop(context);
                  _loadClasses();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Class deleted successfully'),
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
}

