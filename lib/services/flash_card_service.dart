import 'package:firebase_database/firebase_database.dart';
import '../models/flash_card.dart';
import '../models/lesson.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';
import 'file_parser_service.dart';
import 'package:flutter/foundation.dart';

class FlashCardService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Create flash cards from a lesson
  Future<List<String>> createFlashCardsFromLesson(Lesson lesson, String studentId, String studentName) async {
    try {
      print('🔍 FlashCardService: Starting flash card creation...');
      print('📚 Lesson: ${lesson.title}');
      print('👤 Student: $studentId ($studentName)');
      
      if (!_connectivityService.isConnected) {
        print('❌ No internet connection');
        throw Exception('Cannot create flash cards while offline. Please check your internet connection.');
      }

      final List<String> flashCardIds = [];
      
      // Generate flash cards from lesson content
      print('🧠 Generating flash cards from lesson content...');
      final flashCards = await _generateFlashCardsFromLesson(lesson, studentId, studentName);
      print('📝 Generated ${flashCards.length} flash cards');
      
      for (int i = 0; i < flashCards.length; i++) {
        final flashCard = flashCards[i];
        print('💾 Saving flash card ${i + 1}/${flashCards.length}: ${flashCard.question}');
        
        final flashCardRef = _database.child('flash_cards').push();
        final flashCardId = flashCardRef.key!;
        
        // Create a new flash card with the correct ID
        final flashCardWithId = flashCard.copyWith(id: flashCardId);
        
        await flashCardRef.set(flashCardWithId.toRealtimeDatabase());
        flashCardIds.add(flashCardId);
        
        // Cache the flash card locally
        await _cacheFlashCardLocally(flashCardId, flashCardWithId.toRealtimeDatabase());
        
        print('✅ Flash card ${i + 1} saved with ID: $flashCardId');
      }
      
      print('🎉 Successfully created ${flashCardIds.length} flash cards');
      return flashCardIds;
    } catch (e) {
      print('❌ FlashCardService error: $e');
      throw Exception('Failed to create flash cards: ${e.toString()}');
    }
  }

  // Generate flash cards from lesson content
  Future<List<FlashCard>> _generateFlashCardsFromLesson(Lesson lesson, String studentId, String studentName) async {
    print('🧠 Generating flash cards for lesson: ${lesson.title}');
    print('📝 Lesson content length: ${lesson.content.length}');
    print('📄 Lesson description: ${lesson.description ?? 'None'}');
    print('📁 Lesson file URL: ${lesson.fileUrl ?? 'None'}');
    
    final List<FlashCard> flashCards = [];
    final now = DateTime.now();
    
    // Get all available content sources
    String allContent = '';
    
    // Add lesson title
    allContent += lesson.title + ' ';
    
    // Add lesson description
    if (lesson.description != null && lesson.description!.isNotEmpty) {
      allContent += lesson.description! + ' ';
    }
    
    // Add lesson content
    if (lesson.content.isNotEmpty) {
      allContent += lesson.content + ' ';
    }
    
    // Extract content from file if available
    if (lesson.fileUrl != null && lesson.fileUrl!.isNotEmpty) {
      try {
        print('📄 Extracting content from file: ${lesson.fileUrl}');
        final fileContent = await FileParserService.extractTextFromFile(lesson.fileUrl!);
        if (fileContent.isNotEmpty && 
            !fileContent.contains('Error extracting text') &&
            !fileContent.contains('requires additional setup') &&
            !fileContent.contains('Firebase Storage') &&
            !fileContent.contains('PDF_FILE_DETECTED_BUT_EXTRACTION_FAILED') &&
            fileContent.length > 100) {
          allContent += fileContent + ' ';
          print('✅ Successfully extracted ${fileContent.length} characters from file');
        } else {
          print('⚠️ File extraction not available or insufficient content - using lesson content instead');
        }
      } catch (e) {
        print('❌ Error extracting file content: $e');
      }
    }
    
    print('📊 Total content length: ${allContent.length} characters');
    
    // Extract key concepts from all available content
    final keyConcepts = _extractKeyConceptsFromContent(allContent, lesson.subject);
    print('🔑 Extracted key concepts: $keyConcepts');
    
    // Create flash cards for key concepts
    for (int i = 0; i < keyConcepts.length; i++) {
      final concept = keyConcepts[i];
      final question = _generateQuestion(concept, lesson.subject);
      final answer = _generateAnswerFromContent(concept, allContent, lesson);
      
      print('📋 Creating flash card for concept: $concept');
      print('❓ Question: $question');
      print('✅ Answer: $answer');
      
      final flashCard = FlashCard(
        id: '', // Will be set by the service
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: question,
        answer: answer,
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      );
      
      flashCards.add(flashCard);
    }
    
    // If no key concepts found or content is too small, create cards from lesson structure
    if (flashCards.isEmpty || allContent.length < 200) {
      print('⚠️ No key concepts found or insufficient content, creating cards from lesson structure');
      flashCards.clear(); // Clear any irrelevant cards
      flashCards.addAll(_createCardsFromLessonStructure(lesson, studentId, studentName, now, allContent));
      
      // Add specific cards based on your lesson content
      flashCards.addAll(_createSpecificLessonCards(lesson, studentId, studentName, now));
    }
    
    print('📚 Generated ${flashCards.length} total flash cards');
    return flashCards;
  }

  // Extract key concepts from all content sources
  List<String> _extractKeyConceptsFromContent(String content, String subject) {
    final List<String> concepts = [];
    
    // Extract educational terms and concepts
    final educationalTerms = _extractEducationalTerms(content);
    concepts.addAll(educationalTerms);
    
    // Extract learning objectives
    final objectives = _extractLearningObjectives(content);
    concepts.addAll(objectives);
    
    // Extract key topics from lesson structure
    final topics = _extractLessonTopics(content);
    concepts.addAll(topics);
    
    // Extract subject-specific concepts based on Philippine curriculum
    final subjectSpecificConcepts = _extractSubjectSpecificConcepts(content, subject);
    concepts.addAll(subjectSpecificConcepts);
    
    // Remove duplicates and limit
    final uniqueConcepts = concepts.toSet().toList();
    return uniqueConcepts.take(8).toList();
  }

  // Extract educational terms and concepts
  List<String> _extractEducationalTerms(String content) {
    final List<String> terms = [];
    final lines = content.split('\n');
    
    for (final line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;
      
      // Look for definitions, key terms, and concepts across all subjects
      if (cleanLine.toLowerCase().contains('define') || 
          cleanLine.toLowerCase().contains('definition') ||
          cleanLine.toLowerCase().contains('concept') ||
          cleanLine.toLowerCase().contains('term') ||
          cleanLine.toLowerCase().contains('key') ||
          cleanLine.toLowerCase().contains('important') ||
          cleanLine.toLowerCase().contains('main') ||
          cleanLine.toLowerCase().contains('primary') ||
          cleanLine.toLowerCase().contains('essential') ||
          cleanLine.toLowerCase().contains('fundamental')) {
        
        // Extract terms from the line
        final words = cleanLine.split(' ');
        for (final word in words) {
          final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
          if (cleanWord.length > 3 && !_isCommonWord(cleanWord) && !_isEducationalCommonWord(cleanWord)) {
            terms.add(cleanWord);
          }
        }
      }
    }
    
    return terms;
  }

  // Extract learning objectives
  List<String> _extractLearningObjectives(String content) {
    final List<String> objectives = [];
    final lines = content.split('\n');
    bool inObjectivesSection = false;
    
    for (final line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;
      
      // Check if we're in objectives section (universal patterns)
      if (cleanLine.toLowerCase().contains('objectives') || 
          cleanLine.toLowerCase().contains('learning objectives') ||
          cleanLine.toLowerCase().contains('at the end of') ||
          cleanLine.toLowerCase().contains('students will be able to') ||
          cleanLine.toLowerCase().contains('learning outcomes') ||
          cleanLine.toLowerCase().contains('goals') ||
          cleanLine.toLowerCase().contains('aims') ||
          cleanLine.toLowerCase().contains('targets')) {
        inObjectivesSection = true;
        continue;
      }
      
      // Stop at next major section (universal patterns)
      if (inObjectivesSection && 
          (cleanLine.toLowerCase().contains('materials') ||
           cleanLine.toLowerCase().contains('procedure') ||
           cleanLine.toLowerCase().contains('assessment') ||
           cleanLine.toLowerCase().contains('evaluation') ||
           cleanLine.toLowerCase().contains('activities') ||
           cleanLine.toLowerCase().contains('methodology') ||
           cleanLine.toLowerCase().contains('resources') ||
           cleanLine.toLowerCase().contains('duration') ||
           cleanLine.toLowerCase().contains('time'))) {
        break;
      }
      
      // Extract key terms from objectives
      if (inObjectivesSection && cleanLine.isNotEmpty) {
        // Look for numbered objectives (1., 2., etc.)
        if (RegExp(r'^\d+\.').hasMatch(cleanLine)) {
          final objectiveText = cleanLine.replaceFirst(RegExp(r'^\d+\.\s*'), '');
          // Extract meaningful concepts from objectives
          final concepts = _extractConceptsFromObjective(objectiveText);
          objectives.addAll(concepts);
        } else {
          // Regular line in objectives section
          final concepts = _extractConceptsFromObjective(cleanLine);
          objectives.addAll(concepts);
        }
      }
    }
    
    return objectives;
  }

  // Extract meaningful concepts from objective text
  List<String> _extractConceptsFromObjective(String objectiveText) {
    final List<String> concepts = [];
    final text = objectiveText.toLowerCase();
    
    // Extract action verbs and their objects (universal for all subjects)
    final actionPatterns = [
      RegExp(r'define\s+([^.]+)', caseSensitive: false),
      RegExp(r'solve\s+([^.]+)', caseSensitive: false),
      RegExp(r'apply\s+([^.]+)', caseSensitive: false),
      RegExp(r'identify\s+([^.]+)', caseSensitive: false),
      RegExp(r'explain\s+([^.]+)', caseSensitive: false),
      RegExp(r'describe\s+([^.]+)', caseSensitive: false),
      RegExp(r'analyze\s+([^.]+)', caseSensitive: false),
      RegExp(r'evaluate\s+([^.]+)', caseSensitive: false),
      RegExp(r'create\s+([^.]+)', caseSensitive: false),
      RegExp(r'demonstrate\s+([^.]+)', caseSensitive: false),
      RegExp(r'understand\s+([^.]+)', caseSensitive: false),
      RegExp(r'learn\s+([^.]+)', caseSensitive: false),
      RegExp(r'study\s+([^.]+)', caseSensitive: false),
      RegExp(r'practice\s+([^.]+)', caseSensitive: false),
      RegExp(r'master\s+([^.]+)', caseSensitive: false),
    ];
    
    for (final pattern in actionPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final concept = match.group(1)!.trim();
        if (concept.length > 3 && !_isCommonWord(concept) && !_isEducationalCommonWord(concept)) {
          concepts.add(concept);
        }
      }
    }
    
    // Extract noun phrases and key terms
    final words = text.split(' ');
    for (int i = 0; i < words.length - 1; i++) {
      final word1 = words[i].replaceAll(RegExp(r'[^\w]'), '');
      final word2 = words[i + 1].replaceAll(RegExp(r'[^\w]'), '');
      
      if (word1.length > 3 && word2.length > 3 && 
          !_isCommonWord(word1) && !_isCommonWord(word2) &&
          !_isEducationalCommonWord(word1) && !_isEducationalCommonWord(word2)) {
        concepts.add('$word1 $word2');
      }
    }
    
    return concepts;
  }

  // Extract lesson topics and main concepts
  List<String> _extractLessonTopics(String content) {
    final List<String> topics = [];
    final lines = content.split('\n');
    
    for (final line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;
      
      // Skip error messages and irrelevant content
      if (cleanLine.toLowerCase().contains('error') ||
          cleanLine.toLowerCase().contains('clientexception') ||
          cleanLine.toLowerCase().contains('failed to fetch') ||
          cleanLine.toLowerCase().contains('firebase storage') ||
          cleanLine.toLowerCase().contains('requires additional setup')) {
        continue;
      }
      
      // Look for main topics and subjects (universal patterns)
      if (cleanLine.toLowerCase().contains('learning area') ||
          cleanLine.toLowerCase().contains('subject') ||
          cleanLine.toLowerCase().contains('topic') ||
          cleanLine.toLowerCase().contains('lesson') ||
          cleanLine.toLowerCase().contains('unit') ||
          cleanLine.toLowerCase().contains('chapter') ||
          cleanLine.toLowerCase().contains('module') ||
          cleanLine.toLowerCase().contains('theme') ||
          cleanLine.toLowerCase().contains('focus') ||
          cleanLine.toLowerCase().contains('curriculum') ||
          cleanLine.toLowerCase().contains('syllabus')) {
        
        // Extract the actual topic content after the colon
        if (cleanLine.contains(':')) {
          final parts = cleanLine.split(':');
          if (parts.length > 1) {
            final topicContent = parts[1].trim();
            // For "Learning Area: Algebra - Linear Equations in One Variable"
            // Extract "Algebra", "Linear Equations", "One Variable"
            final topicConcepts = _extractTopicConcepts(topicContent);
            topics.addAll(topicConcepts);
          }
        } else {
          // Fallback to word extraction - but be more selective
          final words = cleanLine.split(' ');
          for (final word in words) {
            final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
            if (cleanWord.length > 4 && 
                !_isCommonWord(cleanWord) && 
                !_isEducationalCommonWord(cleanWord) &&
                _isEducationalTerm(cleanWord)) {
              topics.add(cleanWord);
            }
          }
        }
      }
    }
    
    return topics;
  }

  // Extract concepts from topic content
  List<String> _extractTopicConcepts(String topicContent) {
    final List<String> concepts = [];
    
    // For "Algebra - Linear Equations in One Variable"
    // Split by common separators and extract meaningful parts
    final parts = topicContent.split(RegExp(r'[-–—]'));
    
    for (final part in parts) {
      final cleanPart = part.trim();
      if (cleanPart.isNotEmpty) {
        // Extract individual concepts from the part
        final words = cleanPart.split(' ');
        final concept = words.join(' ').trim();
        if (concept.length > 2 && !_isCommonWord(concept) && !_isEducationalCommonWord(concept)) {
          concepts.add(concept.toLowerCase());
        }
      }
    }
    
    return concepts;
  }

  // Extract subject-specific concepts based on Philippine curriculum
  List<String> _extractSubjectSpecificConcepts(String content, String subject) {
    final List<String> concepts = [];
    final subjectLower = subject.toLowerCase();
    
    // Mathematics concepts
    if (subjectLower.contains('mathematics') || subjectLower.contains('math')) {
      concepts.addAll(_extractMathConcepts(content));
    }
    
    // Science concepts
    if (subjectLower.contains('science')) {
      concepts.addAll(_extractScienceConcepts(content));
    }
    
    // English concepts
    if (subjectLower.contains('english')) {
      concepts.addAll(_extractEnglishConcepts(content));
    }
    
    // Filipino concepts
    if (subjectLower.contains('filipino')) {
      concepts.addAll(_extractFilipinoConcepts(content));
    }
    
    // Araling Panlipunan concepts
    if (subjectLower.contains('araling') || subjectLower.contains('panlipunan')) {
      concepts.addAll(_extractAralingPanlipunanConcepts(content));
    }
    
    // Values Education/GMRC concepts
    if (subjectLower.contains('values') || subjectLower.contains('gmrc')) {
      concepts.addAll(_extractValuesEducationConcepts(content));
    }
    
    // Music & Arts concepts
    if (subjectLower.contains('music') || subjectLower.contains('arts')) {
      concepts.addAll(_extractMusicArtsConcepts(content));
    }
    
    // Physical Education & Health concepts
    if (subjectLower.contains('physical') || subjectLower.contains('health')) {
      concepts.addAll(_extractPEHealthConcepts(content));
    }
    
    // EPP concepts
    if (subjectLower.contains('epp')) {
      concepts.addAll(_extractEPPConcepts(content));
    }
    
    // TLE concepts
    if (subjectLower.contains('tle') || subjectLower.contains('technology') || subjectLower.contains('livelihood')) {
      concepts.addAll(_extractTLEConcepts(content));
    }
    
    return concepts;
  }

  // Extract Mathematics concepts
  List<String> _extractMathConcepts(String content) {
    final mathKeywords = [
      'algebra', 'geometry', 'trigonometry', 'calculus', 'statistics', 'probability',
      'equation', 'variable', 'function', 'graph', 'slope', 'intercept', 'linear',
      'quadratic', 'polynomial', 'fraction', 'decimal', 'percentage', 'ratio',
      'proportion', 'angle', 'triangle', 'circle', 'square', 'rectangle', 'volume',
      'area', 'perimeter', 'diameter', 'radius', 'circumference', 'theorem',
      'formula', 'solve', 'calculate', 'compute', 'measure', 'unit', 'metric'
    ];
    return _extractConceptsByKeywords(content, mathKeywords);
  }

  // Extract Science concepts
  List<String> _extractScienceConcepts(String content) {
    final scienceKeywords = [
      'biology', 'chemistry', 'physics', 'earth', 'space', 'ecosystem', 'environment',
      'cell', 'organism', 'species', 'evolution', 'photosynthesis', 'respiration',
      'molecule', 'atom', 'element', 'compound', 'reaction', 'energy', 'force',
      'motion', 'gravity', 'magnetism', 'electricity', 'light', 'sound', 'wave',
      'temperature', 'pressure', 'density', 'mass', 'volume', 'experiment',
      'hypothesis', 'theory', 'law', 'observation', 'data', 'analysis'
    ];
    return _extractConceptsByKeywords(content, scienceKeywords);
  }

  // Extract English concepts
  List<String> _extractEnglishConcepts(String content) {
    final englishKeywords = [
      'grammar', 'syntax', 'vocabulary', 'literature', 'poetry', 'prose', 'drama',
      'novel', 'short', 'story', 'essay', 'paragraph', 'sentence', 'phrase',
      'noun', 'verb', 'adjective', 'adverb', 'pronoun', 'preposition', 'conjunction',
      'metaphor', 'simile', 'personification', 'alliteration', 'rhyme', 'rhythm',
      'theme', 'plot', 'character', 'setting', 'conflict', 'resolution', 'narrative',
      'persuasive', 'descriptive', 'expository', 'argumentative', 'reading', 'writing',
      'speaking', 'listening', 'comprehension', 'analysis', 'interpretation'
    ];
    return _extractConceptsByKeywords(content, englishKeywords);
  }

  // Extract Filipino concepts
  List<String> _extractFilipinoConcepts(String content) {
    final filipinoKeywords = [
      'wika', 'gramatika', 'panitikan', 'tula', 'kwento', 'nobela', 'dula',
      'talumpati', 'sanaysay', 'talata', 'pangungusap', 'parirala', 'salita',
      'pangngalan', 'pandiwa', 'pang-uri', 'pang-abay', 'panghalip', 'pang-ukol',
      'pangatnig', 'tayutay', 'talinghaga', 'simile', 'personipikasyon', 'aliterasyon',
      'tugma', 'sukat', 'tema', 'banghay', 'tauhan', 'tagpuan', 'tunggalian',
      'kasukdulan', 'kakalasan', 'pagsasalaysay', 'pangangatwiran', 'paglalarawan',
      'paliwanag', 'pagbasa', 'pagsulat', 'pagsasalita', 'pakikinig', 'pag-unawa',
      'pagsusuri', 'pagpapakahulugan', 'kultura', 'tradisyon', 'kaugalian'
    ];
    return _extractConceptsByKeywords(content, filipinoKeywords);
  }

  // Extract Araling Panlipunan concepts
  List<String> _extractAralingPanlipunanConcepts(String content) {
    final apKeywords = [
      'kasaysayan', 'heograpiya', 'pamahalaan', 'ekonomiya', 'kultura', 'lipunan',
      'sibilisasyon', 'imperyo', 'rebolusyon', 'demokrasya', 'republika', 'konstitusyon',
      'karapatan', 'tungkulin', 'bayanihan', 'pakikipagkapwa', 'pagkakaisa',
      'kalayaan', 'kasarinlan', 'nasyonalismo', 'patriotismo', 'bayan', 'lalawigan',
      'rehiyon', 'kapuluan', 'bundok', 'ilog', 'dagat', 'klima', 'likas', 'yaman',
      'populasyon', 'migrasyon', 'urbanisasyon', 'globalisasyon', 'teknolohiya',
      'komunikasyon', 'transportasyon', 'kalakalan', 'industriya', 'agrikultura'
    ];
    return _extractConceptsByKeywords(content, apKeywords);
  }

  // Extract Values Education/GMRC concepts
  List<String> _extractValuesEducationConcepts(String content) {
    final valuesKeywords = [
      'pagkatao', 'pagpapahalaga', 'moral', 'etika', 'prinsipyo', 'paniniwala',
      'pananampalataya', 'pagmamahal', 'paggalang', 'pagkakaisa', 'pakikipagkapwa',
      'bayanihan', 'pakikisama', 'utang', 'na', 'loob', 'hiya', 'pakikisama',
      'kapwa', 'dignidad', 'karapatan', 'tungkulin', 'responsibilidad', 'disiplina',
      'katapatan', 'katarungan', 'kapayapaan', 'kalayaan', 'demokrasya', 'pagkakapantay',
      'pagkakaisa', 'pakikipagkapwa', 'bayanihan', 'pakikisama', 'utang', 'na', 'loob'
    ];
    return _extractConceptsByKeywords(content, valuesKeywords);
  }

  // Extract Music & Arts concepts
  List<String> _extractMusicArtsConcepts(String content) {
    final musicArtsKeywords = [
      'musika', 'sining', 'tugtog', 'awit', 'sayaw', 'dula', 'pinta', 'larawan',
      'eskultura', 'arkitektura', 'ritmo', 'melodiya', 'harmonya', 'timbang',
      'tono', 'nota', 'kumpas', 'instrumento', 'boses', 'koro', 'orkestra',
      'komposisyon', 'interpretasyon', 'pagganap', 'pagtatanghal', 'eksibisyon',
      'kultura', 'tradisyon', 'kaugalian', 'sining', 'pagkakaisa', 'pagpapahalaga',
      'kreatibidad', 'imahinasyon', 'ekspresyon', 'komunikasyon', 'pakikipagkapwa'
    ];
    return _extractConceptsByKeywords(content, musicArtsKeywords);
  }

  // Extract Physical Education & Health concepts
  List<String> _extractPEHealthConcepts(String content) {
    final peHealthKeywords = [
      'pisikal', 'kalusugan', 'ehersisyo', 'palakasan', 'laro', 'sports',
      'atletika', 'gymnastics', 'swimming', 'basketball', 'volleyball', 'football',
      'badminton', 'tennis', 'track', 'field', 'fitness', 'endurance', 'strength',
      'flexibility', 'coordination', 'balance', 'agility', 'speed', 'power',
      'nutrition', 'diet', 'vitamins', 'minerals', 'protein', 'carbohydrates',
      'fats', 'water', 'hygiene', 'sanitation', 'disease', 'prevention', 'treatment',
      'first', 'aid', 'safety', 'injury', 'rehabilitation', 'wellness', 'lifestyle'
    ];
    return _extractConceptsByKeywords(content, peHealthKeywords);
  }

  // Extract EPP concepts
  List<String> _extractEPPConcepts(String content) {
    final eppKeywords = [
      'ekonomiya', 'pamumuhay', 'pamilya', 'komunidad', 'produksyon', 'konsumo',
      'kalakalan', 'serbisyo', 'hanapbuhay', 'negosyo', 'industriya', 'agrikultura',
      'pangingisda', 'pagtatanim', 'paggugubat', 'minahan', 'turismo', 'transportasyon',
      'komunikasyon', 'teknolohiya', 'makinarya', 'kagamitan', 'materyales', 'resorses',
      'kapital', 'puhunan', 'tubo', 'kita', 'gastos', 'badyet', 'pamumuhunan',
      'pag-iimpok', 'utang', 'pautang', 'kooperatiba', 'samahan', 'organisasyon'
    ];
    return _extractConceptsByKeywords(content, eppKeywords);
  }

  // Extract TLE concepts
  List<String> _extractTLEConcepts(String content) {
    final tleKeywords = [
      'teknolohiya', 'livelihood', 'kasanayan', 'kakayahan', 'hanapbuhay', 'negosyo',
      'produksyon', 'serbisyo', 'kalakalan', 'industriya', 'agrikultura', 'pangingisda',
      'pagtatanim', 'paggugubat', 'minahan', 'turismo', 'transportasyon', 'komunikasyon',
      'makinarya', 'kagamitan', 'materyales', 'resorses', 'kapital', 'puhunan',
      'tubo', 'kita', 'gastos', 'badyet', 'pamumuhunan', 'pag-iimpok', 'utang',
      'pautang', 'kooperatiba', 'samahan', 'organisasyon', 'entrepreneurship', 'management',
      'marketing', 'accounting', 'finance', 'human', 'resources', 'operations'
    ];
    return _extractConceptsByKeywords(content, tleKeywords);
  }

  // Helper method to extract concepts by keywords
  List<String> _extractConceptsByKeywords(String content, List<String> keywords) {
    final List<String> concepts = [];
    final contentLower = content.toLowerCase();
    
    for (final keyword in keywords) {
      if (contentLower.contains(keyword.toLowerCase())) {
        concepts.add(keyword);
      }
    }
    
    return concepts;
  }

  // Check if word is educational common word
  bool _isEducationalCommonWord(String word) {
    final educationalCommonWords = [
      'students', 'teacher', 'lesson', 'class', 'grade', 'subject', 'learning',
      'activity', 'problem', 'solve', 'practice', 'homework', 'assignment',
      'quiz', 'test', 'assessment', 'evaluation', 'performance', 'group',
      'individual', 'work', 'sheet', 'board', 'marker', 'chalk', 'calculator',
      'minutes', 'duration', 'quarter', 'level', 'area', 'objectives', 'materials',
      'procedure', 'introduction', 'conclusion', 'application', 'review', 'motivation',
      'will', 'able', 'end', 'able', 'understand', 'know', 'identify', 'explain',
      'describe', 'analyze', 'evaluate', 'create', 'apply', 'demonstrate', 'show',
      'present', 'discuss', 'compare', 'contrast', 'list', 'name', 'state', 'define',
      'recognize', 'distinguish', 'classify', 'categorize', 'organize', 'summarize',
      'synthesize', 'interpret', 'infer', 'predict', 'hypothesize', 'conclude',
      // Philippine curriculum subjects (to avoid treating them as concepts)
      'mathematics', 'gmrc', 'values', 'education', 'araling', 'panlipunan',
      'english', 'filipino', 'music', 'arts', 'science', 'physical', 'health',
      'epp', 'tle', 'technology', 'livelihood'
    ];
    return educationalCommonWords.contains(word.toLowerCase());
  }

  // Check if a word is likely an educational term
  bool _isEducationalTerm(String word) {
    final educationalTerms = [
      'algebra', 'linear', 'equations', 'variable', 'mathematics', 'math',
      'geometry', 'trigonometry', 'calculus', 'statistics', 'probability',
      'fraction', 'decimal', 'percentage', 'ratio', 'proportion', 'function',
      'graph', 'slope', 'intercept', 'quadratic', 'polynomial', 'exponent',
      'logarithm', 'derivative', 'integral', 'limit', 'sequence', 'series',
      'theorem', 'proof', 'axiom', 'postulate', 'corollary', 'lemma',
      'hypothesis', 'conclusion', 'premise', 'argument', 'logic', 'reasoning',
      'analysis', 'synthesis', 'evaluation', 'critique', 'interpretation',
      'comprehension', 'application', 'knowledge', 'understanding', 'skill',
      'concept', 'principle', 'theory', 'law', 'formula', 'equation',
      'solution', 'answer', 'result', 'outcome', 'conclusion', 'finding',
      'discovery', 'invention', 'innovation', 'creativity', 'imagination',
      'critical', 'thinking', 'problem', 'solving', 'decision', 'making',
      'communication', 'collaboration', 'leadership', 'teamwork', 'cooperation',
      'responsibility', 'accountability', 'integrity', 'honesty', 'respect',
      'empathy', 'compassion', 'kindness', 'generosity', 'patience', 'tolerance',
      'diversity', 'inclusion', 'equality', 'justice', 'fairness', 'equity',
      'democracy', 'citizenship', 'patriotism', 'nationalism', 'globalization',
      'sustainability', 'environment', 'conservation', 'preservation', 'protection',
      'renewable', 'energy', 'climate', 'change', 'pollution', 'waste', 'recycling',
      'biodiversity', 'ecosystem', 'habitat', 'species', 'evolution', 'adaptation',
      'photosynthesis', 'respiration', 'digestion', 'circulation', 'nervous',
      'system', 'reproductive', 'endocrine', 'immune', 'skeletal', 'muscular',
      'integumentary', 'urinary', 'respiratory', 'cardiovascular', 'lymphatic',
      'digestive', 'nervous', 'endocrine', 'reproductive', 'immune', 'skeletal',
      'muscular', 'integumentary', 'urinary', 'respiratory', 'cardiovascular',
      'lymphatic', 'digestive', 'nervous', 'endocrine', 'reproductive', 'immune'
    ];
    
    return educationalTerms.contains(word.toLowerCase());
  }



  // Check if word is common
  bool _isCommonWord(String word) {
    final commonWords = [
      'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
      'by', 'from', 'up', 'about', 'into', 'through', 'during', 'before',
      'after', 'above', 'below', 'between', 'among', 'within', 'without',
      'this', 'that', 'these', 'those', 'is', 'are', 'was', 'were', 'be',
      'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
      'would', 'could', 'should', 'may', 'might', 'can', 'shall'
    ];
    return commonWords.contains(word.toLowerCase());
  }

  // Generate question for concept
  String _generateQuestion(String concept, String subject) {
    // Generate dynamic questions based on the concept and subject
    // Avoid static templates and create context-aware questions
    
    // For mathematics concepts
    if (subject.toLowerCase().contains('mathematics') || subject.toLowerCase().contains('math')) {
      if (concept.toLowerCase().contains('equation')) {
        return 'How do you solve $concept?';
      } else if (concept.toLowerCase().contains('linear')) {
        return 'What are the properties of $concept?';
      } else if (concept.toLowerCase().contains('variable')) {
        return 'How do you work with $concept in equations?';
      } else if (concept.toLowerCase().contains('algebra')) {
        return 'What is $concept and how is it used?';
      } else {
        return 'What is $concept in mathematics?';
      }
    }
    
    // For science concepts
    if (subject.toLowerCase().contains('science')) {
      return 'What is $concept and how does it work?';
    }
    
    // For English concepts
    if (subject.toLowerCase().contains('english')) {
      return 'What is $concept in English language?';
    }
    
    // For Filipino concepts
    if (subject.toLowerCase().contains('filipino')) {
      return 'Ano ang $concept sa Filipino?';
    }
    
    // Default dynamic question
    return 'What is $concept?';
  }

  // Generate answer for concept from all content
  String _generateAnswerFromContent(String concept, String content, Lesson lesson) {
    // Try to find context in all content
    if (content.isNotEmpty) {
      // First, try to find specific explanations for the concept
      final specificAnswers = _findSpecificAnswers(concept, content);
      if (specificAnswers.isNotEmpty) {
        return specificAnswers.first;
      }
      
      // Look for sentences that contain the concept
      final sentences = content.split('.');
      for (final sentence in sentences) {
        final cleanSentence = sentence.trim();
        if (cleanSentence.toLowerCase().contains(concept.toLowerCase()) && 
            cleanSentence.length > 10) {
          
          // Limit answer length to avoid overly long responses
          if (cleanSentence.length > 200) {
            return cleanSentence.substring(0, 200) + '...';
          }
          return cleanSentence;
        }
      }
      
      // If no direct match, look for related content
      final lines = content.split('\n');
      for (final line in lines) {
        final cleanLine = line.trim();
        if (cleanLine.toLowerCase().contains(concept.toLowerCase()) && 
            cleanLine.length > 10) {
          
          if (cleanLine.length > 200) {
            return cleanLine.substring(0, 200) + '...';
          }
          return cleanLine;
        }
      }
    }
    
    // If no context found, create a meaningful answer based on the concept
    return _generateMeaningfulAnswer(concept, lesson);
  }

  // Find specific answers for concepts based on lesson content
  List<String> _findSpecificAnswers(String concept, String content) {
    final List<String> answers = [];
    final conceptLower = concept.toLowerCase();
    
    // Look for definitions in the content
    final definitionPatterns = [
      RegExp(r'$concept\s+is\s+([^.]+)', caseSensitive: false),
      RegExp(r'$concept\s+means\s+([^.]+)', caseSensitive: false),
      RegExp(r'$concept\s+refers\s+to\s+([^.]+)', caseSensitive: false),
      RegExp(r'$concept\s+are\s+([^.]+)', caseSensitive: false),
      RegExp(r'$concept\s+involves\s+([^.]+)', caseSensitive: false),
      RegExp(r'$concept\s+includes\s+([^.]+)', caseSensitive: false),
    ];
    
    for (final pattern in definitionPatterns) {
      final match = pattern.firstMatch(content.toLowerCase());
      if (match != null && match.group(1) != null) {
        final definition = match.group(1)!.trim();
        if (definition.length > 10) {
          answers.add('$concept is $definition');
        }
      }
    }
    
    // Look for sentences that contain the concept and provide context
    final sentences = content.split('.');
    for (final sentence in sentences) {
      final cleanSentence = sentence.trim();
      if (cleanSentence.toLowerCase().contains(conceptLower) && 
          cleanSentence.length > 20 && cleanSentence.length < 200) {
        answers.add(cleanSentence);
      }
    }
    
    return answers;
  }

  // Generate meaningful answer when no context is found
  String _generateMeaningfulAnswer(String concept, Lesson lesson) {
    // Universal educational response patterns that work for any subject
    final universalAnswers = [
      '$concept is an important concept in ${lesson.subject}.',
      '$concept plays a key role in understanding ${lesson.subject}.',
      '$concept is a fundamental element of ${lesson.subject}.',
      '$concept is essential for learning ${lesson.subject}.',
      '$concept is a core concept in ${lesson.subject}.',
      '$concept is a significant topic in ${lesson.subject}.',
      '$concept is a vital component of ${lesson.subject}.',
      '$concept is a crucial element in ${lesson.subject}.',
    ];
    
    // Use concept hash for consistent answer selection
    final hash = concept.hashCode.abs();
    final selectedAnswer = universalAnswers[hash % universalAnswers.length];
    
    return '$selectedAnswer Refer to your lesson materials for detailed explanation.';
  }

  // Create flash cards from lesson structure when no concepts are found
  List<FlashCard> _createCardsFromLessonStructure(Lesson lesson, String studentId, String studentName, DateTime now, String content) {
    final List<FlashCard> cards = [];
    
    // Extract key information from lesson structure (universal patterns)
    final lines = content.split('\n');
    final keyInfo = <String, String>{};
    
    for (final line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;
      
      // Extract learning area/topic (universal patterns)
      if (cleanLine.toLowerCase().contains('learning area') || 
          cleanLine.toLowerCase().contains('topic') ||
          cleanLine.toLowerCase().contains('unit') ||
          cleanLine.toLowerCase().contains('chapter') ||
          cleanLine.toLowerCase().contains('module') ||
          cleanLine.toLowerCase().contains('theme')) {
        final parts = cleanLine.split(':');
        if (parts.length > 1) {
          keyInfo['topic'] = parts[1].trim();
        }
      }
      
      // Extract grade level (universal patterns)
      if (cleanLine.toLowerCase().contains('grade') ||
          cleanLine.toLowerCase().contains('level') ||
          cleanLine.toLowerCase().contains('year')) {
        final parts = cleanLine.split(' ');
        for (int i = 0; i < parts.length - 1; i++) {
          if (parts[i].toLowerCase() == 'grade' || 
              parts[i].toLowerCase() == 'level' ||
              parts[i].toLowerCase() == 'year') {
            keyInfo['grade'] = '${parts[i]} ${parts[i + 1]}';
            break;
          }
        }
      }
      
      // Extract subject (universal patterns)
      if (cleanLine.toLowerCase().contains('subject') ||
          cleanLine.toLowerCase().contains('discipline') ||
          cleanLine.toLowerCase().contains('field')) {
        final parts = cleanLine.split(':');
        if (parts.length > 1) {
          keyInfo['subject'] = parts[1].trim();
        }
      }
      
      // Extract duration/time
      if (cleanLine.toLowerCase().contains('duration') ||
          cleanLine.toLowerCase().contains('time') ||
          cleanLine.toLowerCase().contains('minutes') ||
          cleanLine.toLowerCase().contains('hours')) {
        keyInfo['duration'] = cleanLine;
      }
      
      // Extract quarter/semester
      if (cleanLine.toLowerCase().contains('quarter') ||
          cleanLine.toLowerCase().contains('semester') ||
          cleanLine.toLowerCase().contains('term')) {
        keyInfo['period'] = cleanLine;
      }
    }
    
    // Create meaningful cards based on extracted information
    if (keyInfo.containsKey('topic')) {
      final topic = keyInfo['topic']!;
      String question;
      String answer;
      
      // Create dynamic questions based on the actual topic
      if (topic.toLowerCase().contains('linear equations')) {
        question = 'What are linear equations in one variable?';
        answer = 'Linear equations in one variable are mathematical equations where the highest power of the variable is 1, and they can be written in the form ax + b = c, where a, b, and c are constants and x is the variable.';
      } else if (topic.toLowerCase().contains('algebra')) {
        question = 'What is algebra and how is it used in mathematics?';
        answer = 'Algebra is a branch of mathematics that uses symbols and letters to represent numbers and quantities in equations and formulas. It helps us solve problems involving unknown values.';
      } else {
        question = 'What is the main focus of this lesson?';
        answer = topic;
      }
      
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: question,
        answer: answer,
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
    }
    
    if (keyInfo.containsKey('grade')) {
      final grade = keyInfo['grade']!;
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'What grade level is this mathematics lesson designed for?',
        answer: 'This lesson is designed for $grade students studying mathematics.',
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
    }
    
    if (keyInfo.containsKey('duration')) {
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'What is the duration of this lesson?',
        answer: keyInfo['duration']!,
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
    }
    
    if (keyInfo.containsKey('period')) {
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'What period does this lesson cover?',
        answer: keyInfo['period']!,
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
    }
    
    // Create a card from lesson title if it contains educational content
    if (lesson.title.isNotEmpty && lesson.title.length > 10) {
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'What is this lesson about?',
        answer: lesson.title,
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
    }
    
    // Create a card from description if available
    if (lesson.description != null && lesson.description!.isNotEmpty && lesson.description!.length > 20) {
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'What are the key points of this lesson?',
        answer: lesson.description!,
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
    }
    
    return cards;
  }

  // Create specific lesson cards based on the actual lesson content
  List<FlashCard> _createSpecificLessonCards(Lesson lesson, String studentId, String studentName, DateTime now) {
    final List<FlashCard> cards = [];
    
    // Create specific cards for Mathematics/Algebra lessons
    if (lesson.title.toLowerCase().contains('algebra') || 
        lesson.description?.toLowerCase().contains('algebra') == true ||
        lesson.subject.toLowerCase().contains('mathematics')) {
      
      // Card 1: What are linear equations?
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'What are linear equations in one variable?',
        answer: 'Linear equations in one variable are mathematical equations where the highest power of the variable is 1. They can be written in the form ax + b = c, where a, b, and c are constants and x is the variable we need to solve for.',
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
      
      // Card 2: How to solve linear equations
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'What are the steps to solve linear equations in one variable?',
        answer: 'The steps to solve linear equations are: 1) Simplify both sides of the equation, 2) Use inverse operations to isolate the variable, 3) Perform the same operation on both sides, 4) Check your solution by substituting back into the original equation.',
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
      
      // Card 3: Real-life applications
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'How are linear equations used in real-life situations?',
        answer: 'Linear equations are used in real-life situations such as calculating costs, determining distances, solving problems involving rates, finding unknown quantities in business and science, and modeling relationships between variables.',
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
      
      // Card 4: Problem-solving skills
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'What problem-solving skills are developed when working with linear equations?',
        answer: 'Working with linear equations develops critical thinking, logical reasoning, pattern recognition, systematic problem-solving approaches, and the ability to translate real-world problems into mathematical equations.',
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
    }
    
    // Create specific cards for Araling Panlipunan lessons
    if (lesson.subject.toLowerCase().contains('araling') || 
        lesson.subject.toLowerCase().contains('panlipunan') ||
        lesson.title.toLowerCase().contains('ap') ||
        lesson.description?.toLowerCase().contains('araling') == true) {
      
      // Card 1: What is Araling Panlipunan?
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'Ano ang Araling Panlipunan?',
        answer: 'Ang Araling Panlipunan ay isang asignatura na nag-aaral sa mga aspeto ng lipunan, kasaysayan, heograpiya, ekonomiya, at politika ng Pilipinas at ng mundo. Ito ay tumutulong sa mga mag-aaral na maunawaan ang kanilang kapaligiran at ang kanilang papel sa lipunan.',
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
      
      // Card 2: Asian Civilizations
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'Ano ang mga sinaunang kabihasnang Asyano?',
        answer: 'Ang mga sinaunang kabihasnang Asyano ay kinabibilangan ng Mesopotamia, Indus Valley, Tsina, at iba pa. Ang mga ito ay nagbigay ng mahahalagang kontribusyon sa sining, agham, teknolohiya, at kultura na patuloy na nakakaapekto sa kasalukuyan.',
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
      
      // Card 3: Importance of Asian Heritage
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'Bakit mahalaga ang pamana ng kabihasnang Asyano?',
        answer: 'Mahalaga ang pamana ng kabihasnang Asyano dahil ito ay nagbibigay ng pagkakakilanlan at kultura sa mga Asyano. Ito rin ay nagtuturo sa atin ng mga aral mula sa nakaraan at tumutulong sa pag-unlad ng kasalukuyang lipunan.',
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
      
      // Card 4: Learning Objectives
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'Ano ang mga layunin sa pag-aaral ng Araling Panlipunan?',
        answer: 'Ang mga layunin ay: 1) Mailarawan ang mahahalagang kontribusyon ng kabihasnang Asyano, 2) Maipaliwanag ang kahalagahan ng mga pamana sa kasalukuyan, 3) Maipakita ang pagpapahalaga sa kultura at pamana ng Asya.',
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
      
      // Card 5: Learning Activities
      cards.add(FlashCard(
        id: '',
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        subject: lesson.subject,
        question: 'Ano ang mga gawain sa pag-aaral ng Araling Panlipunan?',
        answer: 'Ang mga gawain ay kinabibilangan ng: Panimula (balik-aral at pagganyak), Paglalahad (talakayan tungkol sa mga kabihasnan), Paglalapat (gawain sa pangkat tulad ng paggawa ng poster), at Pagwawakas (buod at takdang-aralin).',
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
        updatedAt: now,
        tags: lesson.tags,
        isPublic: false,
      ));
    }
    
    return cards;
  }

  // Get flash cards by student
  Future<List<FlashCard>> getFlashCardsByStudent(String studentId) async {
    try {
      List<FlashCard> flashCards;
      
      if (_connectivityService.shouldUseCachedData) {
        flashCards = await _getCachedFlashCards(studentId);
      } else {
        final snapshot = await _database.child('flash_cards')
            .orderByChild('studentId')
            .equalTo(studentId)
            .get();
        
        flashCards = [];
        if (snapshot.exists) {
          for (final child in snapshot.children) {
            if (child.key != null) {
              final flashCard = FlashCard.fromRealtimeDatabase(
                child.key!,
                child.value as Map<dynamic, dynamic>,
              );
              flashCards.add(flashCard);
            }
          }
        }
        
        // Cache the flash cards locally
        await _cacheFlashCardsLocally(flashCards);
      }
      
      // Sort by creation date (newest first)
      flashCards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return flashCards;
    } catch (e) {
      throw Exception('Failed to get flash cards: ${e.toString()}');
    }
  }

  // Get flash cards by lesson
  Future<List<FlashCard>> getFlashCardsByLesson(String lessonId) async {
    try {
      final snapshot = await _database.child('flash_cards')
          .orderByChild('lessonId')
          .equalTo(lessonId)
          .get();
      
      final List<FlashCard> flashCards = [];
      if (snapshot.exists) {
        for (final child in snapshot.children) {
          if (child.key != null) {
            final flashCard = FlashCard.fromRealtimeDatabase(
              child.key!,
              child.value as Map<dynamic, dynamic>,
            );
            flashCards.add(flashCard);
          }
        }
      }
      
      return flashCards;
    } catch (e) {
      throw Exception('Failed to get flash cards by lesson: ${e.toString()}');
    }
  }

  // Update flash card
  Future<void> updateFlashCard(String flashCardId, FlashCard flashCard) async {
    try {
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot update flash card while offline. Please check your internet connection.');
      }

      await _database.child('flash_cards').child(flashCardId).update(
        flashCard.copyWith(updatedAt: DateTime.now()).toRealtimeDatabase(),
      );
      
      // Update local cache
      await _cacheFlashCardLocally(flashCardId, flashCard.toRealtimeDatabase());
    } catch (e) {
      throw Exception('Failed to update flash card: ${e.toString()}');
    }
  }

  // Delete flash card
  Future<void> deleteFlashCard(String flashCardId) async {
    try {
      if (!_connectivityService.isConnected) {
        throw Exception('Cannot delete flash card while offline. Please check your internet connection.');
      }

      await _database.child('flash_cards').child(flashCardId).remove();
      
      // Remove from local cache
      await _removeFlashCardFromCache(flashCardId);
    } catch (e) {
      throw Exception('Failed to delete flash card: ${e.toString()}');
    }
  }

  // Cache flash card locally
  Future<void> _cacheFlashCardLocally(String id, Map<String, dynamic> data) async {
    try {
      await OfflineService.cacheFlashCard(id, data);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cache flash card locally: $e');
      }
    }
  }

  // Cache multiple flash cards locally
  Future<void> _cacheFlashCardsLocally(List<FlashCard> flashCards) async {
    try {
      for (final flashCard in flashCards) {
        await OfflineService.cacheFlashCard(flashCard.id, flashCard.toRealtimeDatabase());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cache flash cards locally: $e');
      }
    }
  }

  // Get cached flash cards
  Future<List<FlashCard>> _getCachedFlashCards(String studentId) async {
    try {
      final cachedData = await OfflineService.getCachedFlashCards();
      final List<FlashCard> flashCards = [];
      
      for (final entry in cachedData.entries) {
        final data = entry.value as Map<dynamic, dynamic>;
        if (data['studentId'] == studentId) {
          final flashCard = FlashCard.fromRealtimeDatabase(entry.key, data);
          flashCards.add(flashCard);
        }
      }
      
      return flashCards;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get cached flash cards: $e');
      }
      return [];
    }
  }

  // Remove flash card from cache
  Future<void> _removeFlashCardFromCache(String id) async {
    try {
      await OfflineService.removeCachedFlashCard(id);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to remove flash card from cache: $e');
      }
    }
  }
}
