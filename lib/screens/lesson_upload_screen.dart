import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/lesson.dart';
import '../services/lesson_service_realtime.dart';
import '../models/user_model.dart';
import 'package:firebase_database/firebase_database.dart';
import '../screens/file_preview_screen.dart'; // Added import for FilePreviewScreen

class LessonUploadScreen extends StatefulWidget {
  final UserModel teacherProfile;
  
  const LessonUploadScreen({
    super.key,
    required this.teacherProfile,
  });

  @override
  State<LessonUploadScreen> createState() => _LessonUploadScreenState();
}

class _LessonUploadScreenState extends State<LessonUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  
  String? _selectedSubject;
  bool _isPublished = false;
  List<String> _selectedTags = [];
  bool _isLoading = false;
  
  // File upload variables
  PlatformFile? _selectedFile;
  bool _isUploadingFile = false;
  String? _uploadedFileUrl;
  String? _uploadedFileName;
  
  final List<String> _availableTags = [
    'Beginner', 'Intermediate', 'Advanced',
    'Theory', 'Practice', 'Assessment',
    'Video', 'Interactive', 'Reading',
    'Problem Solving', 'Critical Thinking'
  ];

  // Supported file types
  final List<String> _supportedExtensions = ['pdf', 'docx', 'doc'];

  @override
  void initState() {
    super.initState();
    // Set default subject to Mathematics (first in the list)
    _selectedSubject = 'Mathematics';
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
        title: const Text(
          'Upload Lesson',
          style: TextStyle(
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Upload button moved to bottom of form for better UX
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
                  const SizedBox(height: 32),
                  
                  // Main Upload Button
                  _buildMainUploadButton(),
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
              Icons.upload_file_rounded,
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
                  'Create New Lesson',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your knowledge with students',
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
                    'File uploaded successfully! You can now create your lesson.',
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

  Widget _buildSubjectDropdown() {
    // Use the full list of 11 subjects instead of teacher profile subjects
    final List<String> subjects = [
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: _selectedSubject != null 
                  ? const Color(0xFF007AFF) 
                  : const Color(0xFFE5E5E7),
              width: _selectedSubject != null ? 2 : 1,
            ),
            color: const Color(0xFFF5F5F7),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSubject,
              isExpanded: true,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedSubject != null 
                      ? const Color(0xFF007AFF) 
                      : const Color(0xFF86868B),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              iconSize: 24,
              dropdownColor: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              elevation: 8,
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF1D1D1F),
                fontWeight: FontWeight.w500,
              ),
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select subject',
                  style: TextStyle(
                    color: Color(0xFF86868B),
                    fontSize: 17,
                  ),
                ),
              ),
              items: subjects.map((subject) {
                return DropdownMenuItem<String>(
                  value: subject,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(subject),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                });
              },
            ),
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
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF86868B),
              fontSize: 16,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F5F7),
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              borderSide: const BorderSide(color: Color(0xFFE5E5E7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              borderSide: const BorderSide(color: Color(0xFFE5E5E7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              borderSide: const BorderSide(
                color: Color(0xFF007AFF),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
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
            'Lesson Tags',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select tags to help students find your lesson',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                backgroundColor: const Color(0xFFF5F5F7),
                selectedColor: const Color(0xFF007AFF),
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5E7),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1D1D1F),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(
              _isPublished ? Icons.public_rounded : Icons.lock_rounded,
              color: const Color(0xFF007AFF),
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublished ? 'Published' : 'Draft',
                  style: const TextStyle(
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
              });
            },
            activeColor: const Color(0xFF007AFF),
            activeTrackColor: const Color(0xFF007AFF).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadLesson() async {
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
      print('📝 Creating lesson...');
      print('📁 File URL: $_uploadedFileUrl');
      print('📁 File Name: $_uploadedFileName');
      
      final lesson = Lesson(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        subject: _selectedSubject ?? 'Unknown Subject',
        content: _contentController.text.trim(),
        teacherId: widget.teacherProfile.uid,
        teacherName: widget.teacherProfile.displayName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublished: _isPublished,
        tags: _selectedTags,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        fileUrl: _uploadedFileUrl,
      );

      print('📋 Lesson object created with fileUrl: ${lesson.fileUrl}');

      final lessonService = LessonServiceRealtime();
      print('🚀 Calling lessonService.createLesson...');
      await lessonService.createLesson(lesson);
      print('✅ Lesson created successfully!');

      // Log the activity for teacher dashboard
      await _logTeacherActivity('Lesson Created', 'Created lesson: ${lesson.title}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson uploaded successfully!'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Lesson creation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading lesson: ${e.toString()}'),
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

  Widget _buildMainUploadButton() {
    final bool canUpload = _formKey.currentState?.validate() == true && 
                           _selectedSubject != null && 
                           (_uploadedFileUrl != null || _selectedFile == null);
    
    String buttonText = 'Upload Lesson';
    String? disabledReason;
    
    if (_selectedSubject == null) {
      disabledReason = 'Please select a subject';
    } else if (_selectedFile != null && _uploadedFileUrl == null) {
      disabledReason = 'Please upload your file first';
    } else if (_formKey.currentState?.validate() != true) {
      disabledReason = 'Please fill in all required fields';
    }
    
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          if (disabledReason != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(
                  color: const Color(0xFFFF3B30),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFFF3B30),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      disabledReason,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFF3B30),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: canUpload ? _uploadLesson : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canUpload ? const Color(0xFF007AFF) : const Color(0xFFE5E5E7),
              foregroundColor: canUpload ? Colors.white : const Color(0xFF86868B),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
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
                      Text('Creating Lesson...'),
                    ],
                  )
                : Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _logTeacherActivity(String action, String description) async {
    try {
      final database = FirebaseDatabase.instance.ref();
      final activityRef = database.child('teacher_activities').push();
      
      await activityRef.set({
        'teacherId': widget.teacherProfile.uid,
        'teacherName': widget.teacherProfile.displayName,
        'action': action,
        'description': description,
        'timestamp': ServerValue.timestamp,
        'lessonId': '', // Will be set after lesson creation
        'subject': _selectedSubject,
      });
      
      print('✅ Activity logged: $action - $description');
    } catch (e) {
      print('❌ Failed to log activity: $e');
      // Don't fail the lesson upload if activity logging fails
    }
  }
}
