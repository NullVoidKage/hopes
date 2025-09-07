import 'package:flutter/material.dart';
import '../models/flash_card.dart';
import '../services/flash_card_service.dart';

class FlashCardStudyScreen extends StatefulWidget {
  final List<FlashCard> flashCards;
  final String lessonTitle;

  const FlashCardStudyScreen({
    super.key,
    required this.flashCards,
    required this.lessonTitle,
  });

  @override
  State<FlashCardStudyScreen> createState() => _FlashCardStudyScreenState();
}

class _FlashCardStudyScreenState extends State<FlashCardStudyScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentCardIndex = 0;
  bool _showAnswer = false;
  bool _isFlipping = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  final FlashCardService _flashCardService = FlashCardService();
  List<FlashCard> _flashCards = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _flashCards = List.from(widget.flashCards);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _nextCard() {
    if (_currentCardIndex < widget.flashCards.length - 1) {
      setState(() {
        _currentCardIndex++;
        _showAnswer = false;
      });
      _flipController.reset();
    }
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      setState(() {
        _currentCardIndex--;
        _showAnswer = false;
      });
      _flipController.reset();
    }
  }

  void _toggleAnswer() {
    setState(() {
      _isFlipping = true;
    });
    
    if (_showAnswer) {
      _flipController.reverse().then((_) {
        setState(() {
          _showAnswer = false;
          _isFlipping = false;
        });
      });
    } else {
      _flipController.forward().then((_) {
        setState(() {
          _showAnswer = true;
          _isFlipping = false;
        });
      });
    }
  }

  void _markAsKnown() {
    // TODO: Implement marking cards as known/unknown for spaced repetition
    _nextCard();
  }

  void _markAsUnknown() {
    // TODO: Implement marking cards as known/unknown for spaced repetition
    _nextCard();
  }

  void _deleteCurrentCard() {
    if (_flashCards.isEmpty) return;
    
    final currentCard = _flashCards[_currentCardIndex];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Color(0xFFFF3B30),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Flash Card',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this flash card?',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF86868B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentCard.question,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1D1D1F),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFFF3B30),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF86868B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _confirmDeleteCard(currentCard);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteCard(FlashCard card) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            ),
          );
        },
      );

      // Delete the flash card
      await _flashCardService.deleteFlashCard(card.id);
      
      // Remove from local list
      setState(() {
        _flashCards.removeWhere((c) => c.id == card.id);
        
        // Adjust current index if needed
        if (_currentCardIndex >= _flashCards.length) {
          _currentCardIndex = _flashCards.length - 1;
        }
        if (_currentCardIndex < 0) {
          _currentCardIndex = 0;
        }
        
        _showAnswer = false;
      });
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flash card deleted successfully'),
            backgroundColor: Color(0xFF34C759),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // If no cards left, go back
      if (_flashCards.isEmpty && mounted) {
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting flash card: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B30),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _deleteSpecificCard(FlashCard card, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Color(0xFFFF3B30),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Flash Card',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this flash card?',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF86868B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.question,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1D1D1F),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFFF3B30),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF86868B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _confirmDeleteCard(card);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_flashCards.isEmpty) {
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
            'Flash Cards',
            style: const TextStyle(
              color: Color(0xFF1D1D1F),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'No flash cards available for this lesson.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
            ),
          ),
        ),
      );
    }

    final currentCard = _flashCards[_currentCardIndex];

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
        title: Column(
          children: [
            Text(
              'Flash Cards',
              style: const TextStyle(
                color: Color(0xFF1D1D1F),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            Text(
              widget.lessonTitle,
              style: const TextStyle(
                color: Color(0xFF86868B),
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_rounded,
              color: Color(0xFFFF3B30),
            ),
            onPressed: _deleteCurrentCard,
            tooltip: 'Delete current card',
          ),
          IconButton(
            icon: const Icon(
              Icons.list_rounded,
              color: Color(0xFF007AFF),
            ),
            onPressed: () {
              _showCardList();
            },
            tooltip: 'View all cards',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            const SizedBox(height: 24),
            
            // Flash card
            Expanded(
              child: _buildFlashCard(currentCard),
            ),
            
            const SizedBox(height: 24),
            
            // Navigation controls
            _buildNavigationControls(),
            
            const SizedBox(height: 24),
            
            // Action buttons
            _buildActionButtons(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_currentCardIndex + 1} of ${_flashCards.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF86868B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${((_currentCardIndex + 1) / _flashCards.length * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentCardIndex + 1) / _flashCards.length,
            backgroundColor: const Color(0xFFE5E5E7),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashCard(FlashCard card) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final flipValue = _flipAnimation.value;
          final isFlipped = flipValue > 0.5;
          
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(flipValue * 3.14159),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateY(isFlipped ? 3.14159 : 0), // Counter-rotate the content to keep text readable
              child: Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isFlipping ? null : _toggleAnswer,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Card type indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isFlipped ? 'Answer' : 'Question',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF007AFF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Card content
                            Expanded(
                              child: Center(
                                child: Text(
                                  isFlipped ? card.answer : card.question,
                                  style: TextStyle(
                                    fontSize: isFlipped ? 18 : 20,
                                    color: const Color(0xFF1D1D1F),
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            
                            // Tap hint
                            if (!_isFlipping)
                              Text(
                                'Tap to flip',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF86868B).withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: _currentCardIndex > 0 ? _previousCard : null,
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: _currentCardIndex > 0 
                ? const Color(0xFF007AFF) 
                : const Color(0xFFE5E5E7),
          ),
          tooltip: 'Previous card',
        ),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_currentCardIndex + 1} / ${_flashCards.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        
        IconButton(
          onPressed: _currentCardIndex < widget.flashCards.length - 1 ? _nextCard : null,
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            color: _currentCardIndex < widget.flashCards.length - 1 
                ? const Color(0xFF007AFF) 
                : const Color(0xFFE5E5E7),
          ),
          tooltip: 'Next card',
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: _markAsUnknown,
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text(
                'Don\'t Know',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: _markAsKnown,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Know It',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCardList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'All Flash Cards',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _flashCards.length,
                itemBuilder: (context, index) {
                  final card = _flashCards[index];
                  final isCurrentCard = index == _currentCardIndex;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isCurrentCard 
                          ? const Color(0xFF007AFF).withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentCard 
                            ? const Color(0xFF007AFF)
                            : const Color(0xFFE5E5E7),
                        width: isCurrentCard ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        card.question,
                        style: TextStyle(
                          fontWeight: isCurrentCard ? FontWeight.w600 : FontWeight.w500,
                          color: isCurrentCard 
                              ? const Color(0xFF007AFF)
                              : const Color(0xFF1D1D1F),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Card ${index + 1}',
                        style: TextStyle(
                          color: isCurrentCard 
                              ? const Color(0xFF007AFF)
                              : const Color(0xFF86868B),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: Color(0xFFFF3B30),
                              size: 20,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteSpecificCard(card, index);
                            },
                            tooltip: 'Delete this card',
                          ),
                          if (isCurrentCard)
                            const Icon(
                              Icons.radio_button_checked,
                              color: Color(0xFF007AFF),
                            ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _currentCardIndex = index;
                          _showAnswer = false;
                        });
                        _flipController.reset();
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
