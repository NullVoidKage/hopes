import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/lesson.dart';
import '../../../../data/models/module.dart';
import '../../../../data/models/sync_queue.dart';

class LessonEditor extends ConsumerStatefulWidget {
  final Lesson? lesson; // null for new lesson
  final String moduleId;

  const LessonEditor({
    super.key,
    this.lesson,
    required this.moduleId,
  });

  @override
  ConsumerState<LessonEditor> createState() => _LessonEditorState();
}

class _LessonEditorState extends ConsumerState<LessonEditor> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _estMinsController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.lesson != null) {
      _titleController.text = widget.lesson!.title;
      _bodyController.text = widget.lesson!.bodyMarkdown;
      _estMinsController.text = widget.lesson!.estMins.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _estMinsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson == null ? 'Create Lesson' : 'Edit Lesson'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Lesson Title',
                labelStyle: TextStyle(
                  color: AppTheme.neutralGray,
                  fontWeight: FontWeight.w500,
                ),
                hintText: 'Enter the lesson title',
                hintStyle: TextStyle(
                  color: AppTheme.neutralGray.withOpacity(0.7),
                ),
              ),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _estMinsController,
              decoration: InputDecoration(
                labelText: 'Estimated Minutes',
                labelStyle: TextStyle(
                  color: AppTheme.neutralGray,
                  fontWeight: FontWeight.w500,
                ),
                hintText: 'e.g., 15',
                hintStyle: TextStyle(
                  color: AppTheme.neutralGray.withOpacity(0.7),
                ),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter estimated time';
                }
                final minutes = int.tryParse(value);
                if (minutes == null || minutes <= 0) {
                  return 'Please enter a valid number of minutes';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lesson Content (Markdown)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bodyController,
                    decoration: InputDecoration(
                      labelText: 'Write your lesson content here...',
                      labelStyle: TextStyle(
                        color: AppTheme.neutralGray,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: '# Lesson Title\n\nYour markdown content here...',
                      hintStyle: TextStyle(
                        color: AppTheme.neutralGray.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 15,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'monospace',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter lesson content';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveLesson,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isSaving ? 'Saving...' : 'Save Lesson',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Update to use Firestore when implementing teacher features
      // final contentRepo = ref.read(contentRepositoryProvider);
      // final syncService = ref.read(contentSyncServiceProvider);
      
      // Temporarily disable lesson saving until teacher features are migrated
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher features coming soon!')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
} 