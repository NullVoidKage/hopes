import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../data/models/lesson.dart';
import '../../../../data/models/module.dart';
import '../../../../data/models/sync_queue.dart';
import '../../../../services/sync/content_sync_service.dart';

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
              decoration: const InputDecoration(
                labelText: 'Lesson Title',
                border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: 'Estimated Minutes',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
            const Text(
              'Lesson Content (Markdown)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Lesson content in Markdown format',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter lesson content';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveLesson,
                child: Text(_isSaving ? 'Saving...' : 'Save Lesson'),
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
      final contentRepo = ref.read(contentRepositoryProvider);
      final syncService = ref.read(contentSyncServiceProvider);
      
      final lessonId = widget.lesson?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final lesson = Lesson(
        id: lessonId,
        moduleId: widget.moduleId,
        title: _titleController.text.trim(),
        bodyMarkdown: _bodyController.text.trim(),
        estMins: int.parse(_estMinsController.text.trim()),
      );

      if (widget.lesson == null) {
        // Create new lesson
        await contentRepo.createLesson(lesson);
        await syncService.queueContentChange(
          'lessons',
          SyncOperation.create,
          lessonId,
          lesson.toJson(),
        );
      } else {
        // Update existing lesson
        await contentRepo.updateLesson(lesson);
        await syncService.queueContentChange(
          'lessons',
          SyncOperation.update,
          lessonId,
          lesson.toJson(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.lesson == null ? 'Lesson created!' : 'Lesson updated!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
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