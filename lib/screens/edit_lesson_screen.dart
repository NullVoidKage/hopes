import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/lesson.dart';
import '../models/user_model.dart';
import '../services/lesson_service_realtime.dart';
import '../screens/file_preview_screen.dart'; // Added import for FilePreviewScreen

class EditLessonScreen extends StatefulWidget {
  final Lesson lesson;
  final UserModel teacherProfile;

  const EditLessonScreen({
    super.key,
    required this.lesson,
    required this.teacherProfile,
  });

  @override
  State<EditLessonScreen> createState() => _EditLessonScreenState();
}

class _EditLessonScreenState extends State<EditLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  
  String? _selectedSubject;
  bool _isPublished = false;
  List<String> _selectedTags = [];
  List<String> _availableTags = [
    'Beginner', 'Intermediate', 'Advanced',
    'Theory', 'Practice', 'Quiz', 'Assignment',
    'Video', 'Audio', 'Interactive', 'Group Work'
  ];
  
  // File handling
  PlatformFile? _selectedFile;
  bool _isUploadingFile = false;
  String? _uploadedFileUrl;
  String? _uploadedFileName;
  final List<String> _supportedExtensions = ['pdf', 'docx', 'doc'];
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _titleController.text = widget.lesson.title;
    _descriptionController.text = widget.lesson.description ?? '';
    _contentController.text = widget.lesson.content;
    _selectedSubject = widget.lesson.subject;
    _isPublished = widget.lesson.isPublished;
    _selectedTags = List.from(widget.lesson.tags);
    _uploadedFileUrl = widget.lesson.fileUrl;
    _uploadedFileName = widget.lesson.fileUrl != null ? 'File attached' : null;
    
    // Listen for changes
    _titleController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _contentController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => _handleBackNavigation(),
        ),
        title: const Text(
          'Edit Lesson',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_hasChanges)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
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
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 32),
                  
                  // Lesson Form
                  _buildLessonForm(),
                  const SizedBox(height: 32),
                  
                  // File Upload Section
                  _buildFileUploadSection(),
                  const SizedBox(height: 32),
                  
                  // Tags Selection
                  _buildTagsSelection(),
                  const SizedBox(height: 32),
                  
                  // Publish Toggle
                  _buildPublishToggle(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            child: const Icon(
              Icons.edit_rounded,
              size: 32,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Lesson',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Update your lesson content and settings',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF86868B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lesson Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 24),
          
          // Subject Selection
          _buildSubjectDropdown(),
          const SizedBox(height: 20),
          
          // Title Field
          _buildTextField(
            controller: _titleController,
            label: 'Lesson Title',
            hint: 'Enter a clear, descriptive title',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a lesson title';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Description Field
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Brief overview of what students will learn',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          
          // Content Field
          _buildTextField(
            controller: _contentController,
            label: 'Lesson Content',
            hint: 'Enter your lesson content here...',
            maxLines: 8,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter lesson content';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    final subjects = widget.teacherProfile.subjects ?? [];
    
    if (subjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(
            color: const Color(0xFFE5E5E7),
            width: 1,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Color(0xFFFF9500),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'No subjects assigned. Please contact admin.',
              style: TextStyle(
                color: Color(0xFF86868B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: const Color(0xFFE5E5E7),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedSubject,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Select a subject'),
              ),
              ...subjects.map((subject) => DropdownMenuItem(
                value: subject,
                child: Text(subject),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSubject = value;
                _hasChanges = true;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a subject';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF86868B),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E7),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E7),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF007AFF),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFFF3B30),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildFileUploadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
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
              const Icon(
                Icons.attach_file_rounded,
                color: Color(0xFF007AFF),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Lesson File (Optional)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a PDF or DOCX file to supplement your lesson content',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 20),
          
          // File Upload Area
          if (_selectedFile == null && _uploadedFileUrl == null)
            _buildFileUploadArea()
          else if (_uploadedFileUrl != null)
            _buildUploadedFileInfo()
          else
            _buildSelectedFileInfo(),
          
          // Upload Status Indicator
          if (_selectedFile != null && _uploadedFileUrl == null)
            _buildUploadStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildFileUploadArea() {
    return GestureDetector(
      onTap: _isUploadingFile ? null : _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(
            color: const Color(0xFFE5E5E7),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_rounded,
              size: 48,
              color: const Color(0xFF86868B),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap to select a file',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supports PDF, DOCX, and DOC files',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF86868B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: const Text(
                'Choose File',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileInfo() {
    if (_selectedFile == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: const Color(0xFF007AFF),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getFileIcon(_selectedFile?.extension ?? ''),
                color: const Color(0xFF007AFF),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFile?.name ?? 'Unknown file',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${((_selectedFile?.size ?? 0) / 1024 / 1024).toStringAsFixed(2)} MB',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF86868B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedFile = null;
                    _hasChanges = true;
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFFF3B30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Upload Status Message
          if (_isUploadingFile)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: Border.all(
                  color: const Color(0xFFFF9500),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9500)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Uploading file to Firebase Storage...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFF9500),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: Border.all(
                  color: const Color(0xFF007AFF),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_rounded,
                    color: Color(0xFF007AFF),
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'File selected! Click "Upload File" to upload to Firebase Storage.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF007AFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUploadingFile ? null : _uploadFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isUploadingFile
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Uploading...'),
                      ],
                    )
                  : const Text(
                      'Upload File',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedFileInfo() {
    if (_uploadedFileUrl == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF34C759).withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: const Color(0xFF34C759),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF34C759),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _uploadedFileName ?? 'File uploaded successfully',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'File uploaded successfully',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF34C759),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _uploadedFileUrl = null;
                    _uploadedFileName = null;
                    _selectedFile = null;
                    _hasChanges = true;
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFFF3B30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _uploadedFileUrl != null ? () => _downloadFile(_uploadedFileUrl!) : null,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF007AFF),
                    side: const BorderSide(color: Color(0xFF007AFF)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _uploadedFileUrl != null ? () => _previewFile(_uploadedFileUrl!) : null,
                  icon: const Icon(Icons.preview_rounded),
                  label: const Text('Preview'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF007AFF),
                    side: const BorderSide(color: Color(0xFF007AFF)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadStatusIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_upload_rounded,
            color: Color(0xFF86868B),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploading file...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const Text(
                  'Please wait while your file is being processed.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF86868B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSelection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tags',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add relevant tags to help students find your lesson',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                    _hasChanges = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF007AFF)
                        : const Color(0xFFF5F5F7),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF007AFF)
                          : const Color(0xFFE5E5E7),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1D1D1F),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishToggle() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Publish Lesson',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                Text(
                  _isPublished 
                      ? 'Students can see and access this lesson'
                      : 'Lesson is private and only visible to you',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF86868B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublished,
            onChanged: (value) {
              setState(() {
                _isPublished = value;
                _hasChanges = true;
              });
            },
            activeColor: const Color(0xFF007AFF),
            activeTrackColor: const Color(0xFF007AFF).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'docx':
      case 'doc':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _supportedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Check file size (max 50MB)
        if (file.size > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 50MB'),
                backgroundColor: Color(0xFFFF3B30),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploadingFile = true;
    });

    try {
      print('🚀 Starting file upload...');
      print('📁 File name: ${_selectedFile?.name ?? 'Unknown'}');
      print('📏 File size: ${_selectedFile?.size ?? 0} bytes');
      print('🔑 Teacher ID: ${widget.teacherProfile.uid}');
      
      final storage = FirebaseStorage.instance;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile?.name ?? 'unknown_file'}';
      final ref = storage.ref().child('lesson_files/${widget.teacherProfile.uid}/$fileName');
      
      print('📤 Storage path: lesson_files/${widget.teacherProfile.uid}/$fileName');
      
      // Upload file
      print('⏳ Starting upload...');
      final uploadTask = ref.putData(_selectedFile?.bytes ?? Uint8List(0));
      final snapshot = await uploadTask;
      print('✅ Upload completed!');
      
      print('🔗 Getting download URL...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('🔗 Download URL: $downloadUrl');

      setState(() {
        _uploadedFileUrl = downloadUrl;
        _uploadedFileName = _selectedFile?.name ?? 'unknown_file';
        _isUploadingFile = false;
        _hasChanges = true;
      });

      print('💾 State updated with file URL: $_uploadedFileUrl');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'File uploaded successfully! You can now save your changes.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF34C759),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ File upload error: $e');
      setState(() {
        _isUploadingFile = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  void _downloadFile(String url) {
    // Navigate to file preview screen for download
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilePreviewScreen(
          fileUrl: url,
          fileName: _uploadedFileName ?? 'Downloaded File',
        ),
      ),
    );
  }

  void _previewFile(String url) {
    // Navigate to file preview screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilePreviewScreen(
          fileUrl: url,
          fileName: _uploadedFileName ?? 'File Preview',
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subject'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('📝 Updating lesson...');
      print('📁 File URL: $_uploadedFileUrl');
      print('📁 File Name: $_uploadedFileName');
      
      final updatedLesson = widget.lesson.copyWith(
        title: _titleController.text.trim(),
        subject: _selectedSubject!,
        content: _contentController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        isPublished: _isPublished,
        tags: _selectedTags,
        fileUrl: _uploadedFileUrl,
        updatedAt: DateTime.now(),
      );

      print('📋 Updated lesson object: ${updatedLesson.toRealtimeDatabase()}');

      final lessonService = LessonServiceRealtime();
      print('🚀 Calling lessonService.updateLesson...');
      await lessonService.updateLesson(updatedLesson.id, updatedLesson.toRealtimeDatabase());
      print('✅ Lesson updated successfully!');

      // Log the activity for teacher dashboard
      await _logTeacherActivity('Lesson Updated', 'Updated lesson: ${updatedLesson.title}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson updated successfully!'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
        Navigator.of(context).pop(updatedLesson);
      }
    } catch (e) {
      print('❌ Lesson update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating lesson: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBackNavigation() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to leave?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Leave'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _logTeacherActivity(String action, String description) async {
    final database = FirebaseDatabase.instance;
    final ref = database.ref('teacher_activities/${widget.teacherProfile.uid}');

    await ref.push().set({
      'action': action,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
