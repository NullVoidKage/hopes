import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/learning_path.dart';
import '../models/user_model.dart';
import '../services/learning_path_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/offline_indicator.dart';

class LearningPathCreationScreen extends StatefulWidget {
  final UserModel teacherProfile;
  final LearningPath? learningPath; // For editing existing paths

  const LearningPathCreationScreen({
    super.key,
    required this.teacherProfile,
    this.learningPath,
  });

  @override
  State<LearningPathCreationScreen> createState() => _LearningPathCreationScreenState();
}

class _LearningPathCreationScreenState extends State<LearningPathCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedSubject;
  bool _isPublished = false;
  List<String> _selectedTags = [];
  List<LearningPathStep> _steps = [];
  bool _isLoading = false;
  
  final List<String> _availableTags = [
    'Beginner', 'Intermediate', 'Advanced',
    'Theory', 'Practice', 'Assessment',
    'Video', 'Interactive', 'Reading',
    'Problem Solving', 'Critical Thinking',
    'Fundamentals', 'Review', 'Challenge'
  ];

  final List<String> _subjects = [
    'Mathematics',
    'GMRC',
    'Values Education',
    'Araling Panlipunan',
    'English',
    'Filipino',
    'Music & Arts',
    'Science',
    'Physical Education & Health',
    'EPP',
    'TLE'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.learningPath != null) {
      // Editing existing learning path
      _titleController.text = widget.learningPath!.title;
      _descriptionController.text = widget.learningPath!.description;
      _selectedSubject = widget.learningPath!.subjects.isNotEmpty ? widget.learningPath!.subjects.first : null;
      _selectedTags = List.from(widget.learningPath!.tags);
      _isPublished = widget.learningPath!.isPublished;
      _steps = List.from(widget.learningPath!.steps);
    } else {
      // Creating new learning path
      if (widget.teacherProfile.subjects != null && widget.teacherProfile.subjects!.isNotEmpty) {
        _selectedSubject = widget.teacherProfile.subjects!.first;
      }
      _addStep(); // Add initial step
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addStep() {
    final newStep = LearningPathStep(
      id: const Uuid().v4(),
      title: '',
      description: '',
      type: 'lesson',
      order: _steps.length + 1,
      estimatedDuration: 30,
    );
    
    setState(() {
      _steps.add(newStep);
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
      // Reorder remaining steps
      for (int i = 0; i < _steps.length; i++) {
        _steps[i] = _steps[i].copyWith(order: i + 1);
      }
    });
  }

  void _updateStep(int index, LearningPathStep step) {
    setState(() {
      _steps[index] = step;
    });
  }

  void _moveStepUp(int index) {
    if (index > 0) {
      setState(() {
        final step = _steps.removeAt(index);
        _steps.insert(index - 1, step);
        // Reorder
        for (int i = 0; i < _steps.length; i++) {
          _steps[i] = _steps[i].copyWith(order: i + 1);
        }
      });
    }
  }

  void _moveStepDown(int index) {
    if (index < _steps.length - 1) {
      setState(() {
        final step = _steps.removeAt(index);
        _steps.insert(index + 1, step);
        // Reorder
        for (int i = 0; i < _steps.length; i++) {
          _steps[i] = _steps[i].copyWith(order: i + 1);
        }
      });
    }
  }

  Future<void> _saveLearningPath() async {
    if (!_formKey.currentState!.validate()) return;
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one step to the learning path')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final learningPath = LearningPath(
        id: widget.learningPath?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        teacherId: widget.teacherProfile.uid,
        teacherName: widget.teacherProfile.displayName ?? widget.teacherProfile.email,
        subjects: _selectedSubject != null ? [_selectedSubject!] : [],
        tags: _selectedTags,
        steps: _steps,
        isPublished: _isPublished,
        createdAt: widget.learningPath?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final service = LearningPathService();
      
      if (widget.learningPath != null) {
        // Update existing
        await service.updateLearningPath(learningPath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Learning path updated successfully')),
        );
      } else {
        // Create new
        await service.createLearningPath(learningPath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Learning path created successfully')),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          widget.learningPath != null ? 'Edit Learning Path' : 'Create Learning Path',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1D1F),
        elevation: 0,
        shadowColor: const Color(0xFF000000).withValues(alpha: 0.04),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!ConnectivityService().isConnected)
            const OfflineIndicator(),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      _buildSectionHeader('Basic Information'),
                      const SizedBox(height: 16),
                      
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter learning path title',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe the learning path',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Subject and Tags
                      _buildSectionHeader('Subject & Tags'),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSubject,
                              decoration: const InputDecoration(
                                labelText: 'Subject',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: _subjects.map((subject) => DropdownMenuItem(
                                value: subject,
                                child: Text(subject),
                              )).toList(),
                              onChanged: (value) {
                                setState(() => _selectedSubject = value);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Subject is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Tags
                      _buildTagsSection(),
                      const SizedBox(height: 24),
                      
                      // Steps
                      _buildSectionHeader('Learning Steps'),
                      const SizedBox(height: 16),
                      
                      if (_steps.isEmpty)
                        _buildEmptyStepsState()
                      else
                        ..._steps.asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          return _buildStepCard(index, step);
                        }).toList(),
                      
                      // Add Step Button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _addStep,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Step'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Publish Toggle
                      _buildSectionHeader('Publishing'),
                      const SizedBox(height: 16),
                      
                      SwitchListTile(
                        title: const Text('Publish Learning Path'),
                        subtitle: const Text('Make this learning path available for assignment'),
                        value: _isPublished,
                        onChanged: (value) {
                          setState(() => _isPublished = value);
                        },
                        activeColor: const Color(0xFF007AFF),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Save Button
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E5E7)),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveLearningPath,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            widget.learningPath != null ? 'Update Learning Path' : 'Create Learning Path',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1D1D1F),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        
        // Selected tags
        if (_selectedTags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) => Chip(
              label: Text(tag),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _selectedTags.remove(tag));
              },
              backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
              labelStyle: const TextStyle(color: Color(0xFF007AFF)),
            )).toList(),
          ),
        
        const SizedBox(height: 8),
        
        // Available tags
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags
              .where((tag) => !_selectedTags.contains(tag))
              .map((tag) => ActionChip(
                label: Text(tag),
                onPressed: () {
                  setState(() => _selectedTags.add(tag));
                },
                backgroundColor: Colors.grey[200],
                labelStyle: const TextStyle(color: Color(0xFF1D1D1F)),
              ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyStepsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E7)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.layers_outlined,
            size: 48,
            color: Color(0xFF86868B),
          ),
          SizedBox(height: 16),
          Text(
            'No steps added yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add learning steps to create a complete learning path',
            style: TextStyle(
              color: Color(0xFF86868B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(int index, LearningPathStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E7)),
      ),
      child: Column(
        children: [
          // Step Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF007AFF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${step.order}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Step ${step.order}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                ),
                // Move up button
                if (index > 0)
                  IconButton(
                    onPressed: () => _moveStepUp(index),
                    icon: const Icon(Icons.keyboard_arrow_up),
                    tooltip: 'Move up',
                  ),
                // Move down button
                if (index < _steps.length - 1)
                  IconButton(
                    onPressed: () => _moveStepDown(index),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    tooltip: 'Move down',
                  ),
                // Remove button
                IconButton(
                  onPressed: () => _removeStep(index),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove step',
                  color: Colors.red,
                ),
              ],
            ),
          ),
          
          // Step Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Title
                TextFormField(
                  initialValue: step.title,
                  decoration: const InputDecoration(
                    labelText: 'Step Title',
                    hintText: 'Enter step title',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _updateStep(index, step.copyWith(title: value));
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Step title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description
                TextFormField(
                  initialValue: step.description,
                  decoration: const InputDecoration(
                    labelText: 'Step Description',
                    hintText: 'Describe what this step covers',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    _updateStep(index, step.copyWith(description: value));
                  },
                ),
                const SizedBox(height: 16),
                
                // Type and Duration
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: step.type,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'lesson', child: Text('Lesson')),
                          DropdownMenuItem(value: 'assessment', child: Text('Assessment')),
                          DropdownMenuItem(value: 'activity', child: Text('Activity')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _updateStep(index, step.copyWith(type: value));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: step.estimatedDuration.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final duration = int.tryParse(value) ?? 30;
                          _updateStep(index, step.copyWith(estimatedDuration: duration));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
