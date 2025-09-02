import 'package:firebase_database/firebase_database.dart';
import '../models/flash_card.dart';
import '../models/lesson.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';
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
      final flashCards = _generateFlashCardsFromLesson(lesson, studentId, studentName);
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
  List<FlashCard> _generateFlashCardsFromLesson(Lesson lesson, String studentId, String studentName) {
    print('🧠 Generating flash cards for lesson: ${lesson.title}');
    print('📝 Lesson content length: ${lesson.content.length}');
    print('📄 Lesson description: ${lesson.description ?? 'None'}');
    
    final List<FlashCard> flashCards = [];
    final now = DateTime.now();
    
    // Extract key concepts from lesson title and content
    final keyConcepts = _extractKeyConcepts(lesson);
    print('🔑 Extracted key concepts: $keyConcepts');
    
    // Create flash cards for key concepts
    for (int i = 0; i < keyConcepts.length; i++) {
      final concept = keyConcepts[i];
      final question = _generateQuestion(concept, lesson.subject);
      final answer = _generateAnswer(concept, lesson);
      
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
    
    // If no key concepts found, create basic flash cards
    if (flashCards.isEmpty) {
      print('⚠️ No key concepts found, creating basic flash cards');
      flashCards.addAll([
        FlashCard(
          id: '',
          lessonId: lesson.id,
          lessonTitle: lesson.title,
          subject: lesson.subject,
          question: 'What is the main topic of this lesson?',
          answer: lesson.title,
          studentId: studentId,
          studentName: studentName,
          createdAt: now,
          updatedAt: now,
          tags: lesson.tags,
          isPublic: false,
        ),
        FlashCard(
          id: '',
          lessonId: lesson.id,
          lessonTitle: lesson.title,
          subject: lesson.subject,
          question: 'What subject does this lesson cover?',
          answer: lesson.subject,
          studentId: studentId,
          studentName: studentName,
          createdAt: now,
          updatedAt: now,
          tags: lesson.tags,
          isPublic: false,
        ),
        if (lesson.description != null && lesson.description!.isNotEmpty)
          FlashCard(
            id: '',
            lessonId: lesson.id,
            lessonTitle: lesson.title,
            subject: lesson.subject,
            question: 'What is the lesson about?',
            answer: lesson.description!,
            studentId: studentId,
            studentName: studentName,
            createdAt: now,
            updatedAt: now,
            tags: lesson.tags,
            isPublic: false,
          ),
      ]);
    }
    
    print('📚 Generated ${flashCards.length} total flash cards');
    return flashCards;
  }

  // Extract key concepts from lesson content
  List<String> _extractKeyConcepts(Lesson lesson) {
    final List<String> concepts = [];
    
    // Extract from title
    final titleWords = lesson.title.split(' ');
    for (final word in titleWords) {
      if (word.length > 3 && !_isCommonWord(word.toLowerCase())) {
        concepts.add(word);
      }
    }
    
    // Extract from content (if available)
    if (lesson.content.isNotEmpty) {
      final contentWords = lesson.content.split(' ');
      for (final word in contentWords) {
        if (word.length > 4 && !_isCommonWord(word.toLowerCase()) && concepts.length < 5) {
          concepts.add(word);
        }
      }
    }
    
    // Extract from description (if available)
    if (lesson.description != null && lesson.description!.isNotEmpty) {
      final descWords = lesson.description!.split(' ');
      for (final word in descWords) {
        if (word.length > 4 && !_isCommonWord(word.toLowerCase()) && concepts.length < 5) {
          concepts.add(word);
        }
      }
    }
    
    return concepts.take(5).toList(); // Limit to 5 concepts
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
    final questions = [
      'What is $concept?',
      'Define $concept in $subject.',
      'Explain the concept of $concept.',
      'What does $concept mean?',
      'Describe $concept.',
    ];
    return questions[concept.length % questions.length];
  }

  // Generate answer for concept
  String _generateAnswer(String concept, Lesson lesson) {
    // Try to find context in lesson content
    if (lesson.content.isNotEmpty) {
      final sentences = lesson.content.split('.');
      for (final sentence in sentences) {
        if (sentence.toLowerCase().contains(concept.toLowerCase())) {
          return sentence.trim();
        }
      }
    }
    
    // If no context found, return the concept itself
    return concept;
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
