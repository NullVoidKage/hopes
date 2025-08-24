import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lesson.dart';
import '../services/lesson_service_realtime.dart';
import '../services/connectivity_service.dart';
import '../services/offline_service.dart';
import '../widgets/safe_network_image.dart';
import '../screens/lesson_detail_screen.dart'; // Added import for LessonDetailScreen

class StudentLessonViewerScreen extends StatefulWidget {
  const StudentLessonViewerScreen({super.key});

  @override
  State<StudentLessonViewerScreen> createState() => _StudentLessonViewerScreenState();
}

class _StudentLessonViewerScreenState extends State<StudentLessonViewerScreen>
    with TickerProviderStateMixin {
  final LessonServiceRealtime _lessonService = LessonServiceRealtime();
  final ConnectivityService _connectivityService = ConnectivityService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Lesson> _lessons = [];
  List<Lesson> _filteredLessons = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSubject = 'All';
  String _selectedGrade = 'All';
  
  late TabController _tabController;
  
  final List<String> _subjects = [
    'All',
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
  
  final List<String> _grades = [
    'Grade 7',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedGrade = 'Grade 7'; // Set default to Grade 7
    _loadLessons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Lesson> lessons;
      
      if (_connectivityService.shouldUseCachedData) {
        // Use offline cached data
        print('🔍 StudentLessonViewer: Using offline cached data');
        lessons = await _getCachedLessons();
      } else {
        // Fetch from Firebase and cache
        print('🔍 StudentLessonViewer: Fetching from Firebase');
        lessons = await _lessonService.getAllPublishedLessons();
        print('🔍 StudentLessonViewer: Fetched ${lessons.length} lessons from Firebase');
        await _cacheLessonsLocally(lessons);
      }
      
      if (mounted) {
        setState(() {
          _lessons = lessons;
          _filteredLessons = lessons;
          _isLoading = false;
        });
        print('🔍 StudentLessonViewer: Loaded ${lessons.length} lessons total');
      }
    } catch (e) {
      print('🔍 StudentLessonViewer: Error loading lessons: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading lessons: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  Future<List<Lesson>> _getCachedLessons() async {
    try {
      print('🔍 StudentLessonViewer: Getting cached lessons');
      final cachedData = await OfflineService.getCachedLessons();
      print('🔍 StudentLessonViewer: Found ${cachedData.length} cached lessons');
      
      final lessons = <Lesson>[];
      for (final lessonData in cachedData) {
        if (lessonData['isPublished'] == true) {
          try {
            final lesson = Lesson.fromRealtimeDatabase(
              lessonData['id'] ?? '', 
              lessonData
            );
            lessons.add(lesson);
          } catch (e) {
            print('🔍 StudentLessonViewer: Error parsing cached lesson: $e');
          }
        }
      }
      
      print('🔍 StudentLessonViewer: Parsed ${lessons.length} published lessons from cache');
      return lessons;
    } catch (e) {
      print('🔍 StudentLessonViewer: Error getting cached lessons: $e');
      return [];
    }
  }

  Future<void> _cacheLessonsLocally(List<Lesson> lessons) async {
    try {
      final lessonData = lessons.map((lesson) => lesson.toRealtimeDatabase()).toList();
      await OfflineService.cacheLessons(lessonData);
    } catch (e) {
      // Silently fail if caching is not available
    }
  }

  void _filterLessons() {
    setState(() {
      _filteredLessons = _lessons.where((lesson) {
        final matchesSearch = lesson.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            (lesson.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                            lesson.subject.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesSubject = _selectedSubject == 'All' || lesson.subject == _selectedSubject;
        final matchesGrade = true; // Always true since we only have Grade 7
        
        return matchesSearch && matchesSubject && matchesGrade;
      }).toList();
    });
  }

  void _previewLesson(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(lesson: lesson),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Search
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lesson Library',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_filteredLessons.length} lessons available',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF86868B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_lessons.isNotEmpty)
                      Text(
                        '${_lessons.where((l) => l.isPublished).length} published • ${_lessons.where((l) => !l.isPublished).length} draft',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF86868B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              // Offline indicator
              if (_connectivityService.shouldUseCachedData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF9500),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 16,
                        color: const Color(0xFFFF9500),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Offline (${_lessons.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF9500),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF34C759),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_done_rounded,
                        size: 16,
                        color: const Color(0xFF34C759),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Online (${_lessons.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF34C759),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5E5E7),
                width: 1,
              ),
            ),
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _filterLessons();
              },
              decoration: const InputDecoration(
                hintText: 'Search lessons...',
                hintStyle: TextStyle(
                  color: Color(0xFF86868B),
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF007AFF),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1D1D1F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Filters
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  value: _selectedSubject,
                  items: _subjects,
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value!;
                    });
                    _filterLessons();
                  },
                  label: 'Subject',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  value: _selectedGrade,
                  items: _grades,
                  onChanged: (value) {
                    // No change needed since only Grade 7 is available
                  },
                  label: 'Grade',
                  enabled: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF86868B),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1D1D1F),
          fontWeight: FontWeight.w500,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        dropdownColor: Colors.white,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF007AFF),
        ),
      ),
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E5E7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _previewLesson(lesson),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson Title
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Subject and Grade Tags
                Row(
                  children: [
                    _buildTag(lesson.subject, const Color(0xFF007AFF)),
                    const SizedBox(width: 12),
                    _buildTag('Grade 7', const Color(0xFF34C759)),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Content/Description
                if (lesson.description != null && lesson.description!.isNotEmpty)
                  Text(
                    lesson.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF86868B),
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (lesson.content.isNotEmpty)
                  Text(
                    lesson.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF86868B),
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 16),
                
                // Teacher Information
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 16,
                        color: const Color(0xFF007AFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created by',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF86868B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            lesson.teacherName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1D1D1F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getFileTypeColor(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFFF3B30);
      case 'docx':
      case 'doc':
        return const Color(0xFF007AFF);
      case 'pptx':
      case 'ppt':
        return const Color(0xFFFF9500);
      default:
        return const Color(0xFF86868B);
    }
  }

  IconData _getFileTypeIcon(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'docx':
      case 'doc':
        return Icons.description_rounded;
      case 'pptx':
      case 'ppt':
        return Icons.slideshow_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E7).withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.library_books_outlined,
              size: 40,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No lessons found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Try adjusting your search or filters to find more lessons.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

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
          'Lesson Library',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF007AFF),
            ),
            onPressed: _loadLessons,
            tooltip: 'Refresh lessons',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF007AFF),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading lessons...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF86868B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredLessons.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _filteredLessons.length,
                          itemBuilder: (context, index) {
                            return _buildLessonCard(_filteredLessons[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
