import 'package:flutter/material.dart';
import '../models/lesson.dart';
import 'file_preview_screen.dart';

class LessonDetailScreen extends StatelessWidget {
  final Lesson lesson;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
  });

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
        title: Text(
          lesson.title,
          style: const TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lesson Header Card
              _buildLessonHeader(),
              
              const SizedBox(height: 24),
              
              // Lesson Content Card
              _buildLessonContent(),
              
              const SizedBox(height: 24),
              
              // Teacher Information Card
              _buildTeacherInfo(),
              
              const SizedBox(height: 24),
              
              // Lesson Metadata Card
              _buildLessonMetadata(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            lesson.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tags Row
          Row(
            children: [
              _buildTag(lesson.subject, const Color(0xFF007AFF)),
              const SizedBox(width: 12),
              _buildTag('Grade 7', const Color(0xFF34C759)),
              if (lesson.isPublished) ...[
                const SizedBox(width: 12),
                _buildTag('Published', const Color(0xFF34C759)),
              ] else ...[
                const SizedBox(width: 12),
                _buildTag('Draft', const Color(0xFFFF9500)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  size: 20,
                  color: Color(0xFF007AFF),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lesson Content',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // File Information (if available)
          if (lesson.fileUrl != null && lesson.fileUrl!.isNotEmpty) ...[
            _buildFileSection(),
            const SizedBox(height: 20),
          ],
          
          // Description or Content
          if (lesson.description != null && lesson.description!.isNotEmpty) ...[
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF86868B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lesson.description!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1D1D1F),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          const Text(
            'Content',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF86868B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lesson.content,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1D1D1F),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSection() {
    final fileName = _getFileNameFromUrl(lesson.fileUrl!);
    final fileExtension = _getFileExtension(fileName);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getFileTypeColor(fileExtension).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getFileTypeIcon(fileExtension),
                  size: 24,
                  color: _getFileTypeColor(fileExtension),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lesson File',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF86868B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fileExtension.toUpperCase()} File',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF86868B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // File Actions
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) => ElevatedButton.icon(
                    onPressed: () => _openFile(context, lesson.fileUrl!),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder: (context) => OutlinedButton.icon(
                    onPressed: () => _downloadFile(context, lesson.fileUrl!, fileName),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF007AFF),
                      side: const BorderSide(color: Color(0xFF007AFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: Color(0xFF34C759),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Created by',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Teacher Details
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 30,
                  color: Color(0xFF34C759),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.teacherName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Teacher',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF86868B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonMetadata() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  size: 20,
                  color: Color(0xFFFF9500),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lesson Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Metadata Items
          _buildMetadataItem(
            'Subject',
            lesson.subject,
            Icons.subject_rounded,
            const Color(0xFF007AFF),
          ),
          const SizedBox(height: 16),
          _buildMetadataItem(
            'Grade',
            'Grade 7',
            Icons.grade_rounded,
            const Color(0xFF34C759),
          ),
          const SizedBox(height: 16),
          _buildMetadataItem(
            'Created',
            _formatDate(lesson.createdAt),
            Icons.calendar_today_rounded,
            const Color(0xFFFF9500),
          ),
          const SizedBox(height: 16),
          _buildMetadataItem(
            'Last Updated',
            _formatDate(lesson.updatedAt),
            Icons.update_rounded,
            const Color(0xFFAF52DE),
          ),
          if (lesson.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMetadataItem(
              'Tags',
              lesson.tags.join(', '),
              Icons.tag_rounded,
              const Color(0xFF86868B),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF86868B),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1D1D1F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getFileNameFromUrl(String url) {
    try {
      // Extract the filename from the Firebase Storage URL
      // URL format: https://firebasestorage.googleapis.com/v0/b/bucket/o/lesson_files%2FuserId%2Ffilename
      final uri = Uri.parse(url);
      final pathSegments = uri.path.split('/');
      
      // Find the filename after the last encoded segment
      for (int i = pathSegments.length - 1; i >= 0; i--) {
        final segment = pathSegments[i];
        if (segment.contains('%2F')) {
          // This is an encoded path segment, extract the filename after it
          final decodedSegment = Uri.decodeComponent(segment);
          final parts = decodedSegment.split('/');
          if (parts.length > 1) {
            final fullFilename = parts.last;
            return _cleanFilename(fullFilename);
          }
        } else if (segment.isNotEmpty && !segment.contains('.')) {
          // This might be a filename without extension
          continue;
        } else if (segment.isNotEmpty && segment.contains('.')) {
          // This looks like a filename with extension
          return _cleanFilename(segment);
        }
      }
      
      // Fallback: try to get the last non-empty segment
      final lastSegment = pathSegments.lastWhere((segment) => segment.isNotEmpty);
      return _cleanFilename(lastSegment);
    } catch (e) {
      // If parsing fails, return a generic name
      return 'lesson_file';
    }
  }

  String _cleanFilename(String filename) {
    // Remove timestamp prefix (13-digit numbers followed by underscore)
    // Pattern: 1755937722086_actual_filename.pdf
    final cleanName = filename.replaceAll(RegExp(r'^\d{13}_'), '');
    
    // If the filename is empty after cleaning, return the original
    if (cleanName.isEmpty) {
      return filename;
    }
    
    return cleanName;
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  IconData _getFileTypeIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileTypeColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFD32F2F); // Red for PDF
      case 'doc':
      case 'docx':
        return const Color(0xFF34C759); // Green for Word
      case 'xls':
      case 'xlsx':
        return const Color(0xFF1976D2); // Blue for Excel
      case 'ppt':
      case 'pptx':
        return const Color(0xFFF57C00); // Orange for PowerPoint
      default:
        return const Color(0xFF86868B); // Grey for other files
    }
  }

  void _openFile(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilePreviewScreen(
          fileUrl: url,
          fileName: _getFileNameFromUrl(url),
        ),
      ),
    );
  }

  void _downloadFile(BuildContext context, String url, String fileName) {
    // Show a message that the file is being prepared
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparing $fileName for download...'),
        backgroundColor: const Color(0xFF007AFF),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // In a real implementation, you would handle the actual download
    // For now, we'll just show the message
  }
}
