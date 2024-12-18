import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart' as models;

class GameProvider extends ChangeNotifier {
  models.GameState _state = models.GameState(cards: []);
  Timer? _timer;
  Timer? _gameTimer;
  static const int baseTime = 30;
  static const int timeIncreasePerLevel = 10;
  bool _isGamePaused = false;
  DateTime? _pauseStartTime;

  models.GameState get state => _state;

  void startGame({models.GameMode gameMode = models.GameMode.normal}) {
    final level = models.GameSettings().getLevelForIndex(0);
    final cards = _generateCards(level);
    cards.shuffle();

    _state = models.GameState(
      cards: cards,
      level: 0,
      remainingTime: baseTime,
      isTimerStarted: false,
      gameMode: gameMode,
    );

    notifyListeners();
    _saveGame();
  }

  void _startTimer() {
    if (_state.gameMode == models.GameMode.zen) return;

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.remainingTime > 0 && !_state.isLevelTransition) {
        _state = _state.copy(remainingTime: _state.remainingTime - 1);
        notifyListeners();
        _saveGame();
      } else if (_state.remainingTime <= 0) {
        _saveGame();
        _gameTimer?.cancel();
        _state = _state.copy(isGameOver: true);
        notifyListeners();
      }
    });
  }

  Future<bool> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGameState = prefs.getString('memory_game_state');

    if (savedGameState != null) {
      try {
        final gameStateJson = json.decode(savedGameState);

        // Recreate cards
        final loadedCards = (gameStateJson['cards'] as List)
            .map((cardJson) => models.MemoryCard(
                  id: cardJson['id'],
                  color: Color(cardJson['color']),
                  isFlipped: cardJson['isFlipped'] ?? false,
                  isMatched: cardJson['isMatched'] ?? false,
                ))
            .toList();

        _state = models.GameState(
          cards: loadedCards,
          attempts: gameStateJson['attempts'] ?? 0,
          score: gameStateJson['score'] ?? 0,
          level: gameStateJson['level'] ?? 0,
          remainingTime: gameStateJson['remainingTime'] ?? 30,
        );

        notifyListeners();
        return true;
      } catch (e) {
        print('Error loading game: $e');
        return false;
      }
    }

    return false;
  }

  Future<void> _saveGame() async {
    if (_state.isGameOver) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'memory_game_state',
        json.encode({
          'cards': _state.cards
              .map((card) => {
                    'id': card.id,
                    'color': card.color.value,
                    'isFlipped': card.isFlipped,
                    'isMatched': card.isMatched,
                  })
              .toList(),
          'attempts': _state.attempts,
          'score': _state.score,
          'level': _state.level,
          'remainingTime': _state.remainingTime,
        }));
  }

  void flipCard(models.MemoryCard card) {
    if (_state.isLevelTransition) return;
    if (card.isMatched) return;

    if (!_state.isTimerStarted && _state.gameMode == models.GameMode.normal) {
      _state = _state.copy(isTimerStarted: true);
      _startTimer();
    }

    final updatedCards = _state.cards.map((c) {
      if (c.id == card.id) {
        return c.copy(isFlipped: !c.isFlipped);
      } else {
        return c;
      }
    }).toList();

    _state = _state.copy(cards: updatedCards);
    notifyListeners();

    final flippedCards =
        updatedCards.where((c) => c.isFlipped && !c.isMatched).toList();

    if (flippedCards.length == 2) {
      _checkMatch(flippedCards);
    }
  }

  void _checkMatch(List<models.MemoryCard> flippedCards) {
    final firstCard = flippedCards[0];
    final secondCard = flippedCards[1];

    if (firstCard.color == secondCard.color) {
      final updatedCards = _state.cards.map((c) {
        if (c.id == firstCard.id || c.id == secondCard.id) {
          return c.copy(isMatched: true);
        }
        return c;
      }).toList();

      _state = _state.copy(
        cards: updatedCards,
        score: _state.score + 10,
        powerUpPoints: _state.powerUpPoints + 5,
        attempts: _state.attempts + 1,
      );
      notifyListeners();

      prepareNextLevel();
    } else {
      _state = _state.copy(
        errors: _state.errors + 1,
        attempts: _state.attempts + 1,
      );
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 800), () {
        final updatedCards = _state.cards.map((c) {
          if (c.id == firstCard.id || c.id == secondCard.id) {
            return c.copy(isFlipped: false);
          }
          return c;
        }).toList();

        _state = _state.copy(cards: updatedCards);
        notifyListeners();
      });
    }
  }

  void nextLevel() {
    final nextLevel = _state.level + 1;
    final newLevel = models.GameSettings().getLevelForIndex(nextLevel);
    final newCards = _generateCards(newLevel);
    newCards.shuffle();

    _state = models.GameState(
      cards: newCards,
      level: nextLevel,
      score: _state.score + 10,
      remainingTime: baseTime,
      isLevelTransition: false,
      attempts: 0,
      isTimerStarted: false,
      gameMode: _state.gameMode,
    );

    notifyListeners();
    _saveGame();
  }

  List<models.MemoryCard> _generateCards(models.GameLevel level) {
    final uniqueColors =
        models.GameSettings.generateUniqueColors(level.totalCards ~/ 2);

    List<models.MemoryCard> generatedCards = [];
    for (int i = 0; i < (level.totalCards ~/ 2); i++) {
      final color = uniqueColors[i];

      generatedCards.add(models.MemoryCard(
        id: '$i-1',
        color: color,
        isFlipped: false,
        isMatched: false,
      ));
      generatedCards.add(models.MemoryCard(
        id: '$i-2',
        color: color,
        isFlipped: false,
        isMatched: false,
      ));
    }

    return generatedCards;
  }

  bool areCurrentCardsMatching() {
    final flippedCards =
        state.cards.where((card) => card.isFlipped && !card.isMatched).toList();

    if (flippedCards.length != 2) return false;
    return flippedCards[0].color == flippedCards[1].color;
  }

  void prepareNextLevel() {
    if (_state.cards.every((c) => c.isMatched)) {
      _state = _state.copy(isLevelTransition: true);
      _gameTimer?.cancel();

      Future.delayed(const Duration(seconds: 1), () {
        nextLevel();
        notifyListeners();
      });
    }
  }

  void pauseGame() {
    if (_state.gameMode == models.GameMode.normal) {
      _isGamePaused = true;
      _pauseStartTime = DateTime.now();
      _gameTimer?.cancel();
    }
  }

  void resumeGame() {
    if (_state.gameMode == models.GameMode.normal && _isGamePaused) {
      _isGamePaused = false;
      if (_pauseStartTime != null) {
        final pauseDuration = DateTime.now().difference(_pauseStartTime!);
        _pauseStartTime = null;
        _startTimer();
      }
    }
  }

  void usePowerUp(models.PowerUp powerUp) {
    if (_state.powerUpPoints < powerUp.cost) return;

    _state = _state.copy(powerUpPoints: _state.powerUpPoints - powerUp.cost);

    switch (powerUp.type) {
      case models.PowerUpType.freezeTime:
        _gameTimer?.cancel();
        Future.delayed(const Duration(seconds: 5), () {
          if (!_isGamePaused) {
            _startTimer();
          }
        });
        break;

      case models.PowerUpType.revealCard:
        final unrevealedCards = _state.cards
            .where((card) => !card.isFlipped && !card.isMatched)
            .toList();
        if (unrevealedCards.isNotEmpty) {
          final randomCard =
              unrevealedCards[Random().nextInt(unrevealedCards.length)];
          final updatedCards = _state.cards.map((c) {
            if (c.id == randomCard.id) {
              return c.copy(isFlipped: true);
            }
            return c;
          }).toList();
          _state = _state.copy(cards: updatedCards);

          Future.delayed(const Duration(seconds: 2), () {
            final revertedCards = _state.cards.map((c) {
              if (c.id == randomCard.id && !c.isMatched) {
                return c.copy(isFlipped: false);
              }
              return c;
            }).toList();
            _state = _state.copy(cards: revertedCards);
            notifyListeners();
          });
        }
        break;

      case models.PowerUpType.extraTime:
        _state = _state.copy(
          remainingTime: _state.remainingTime + 10,
        );
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _updateTimer() {
    if (_state.remainingTime > 0) {
      _state = _state.copy(remainingTime: _state.remainingTime - 1);
      notifyListeners();
    } else {
      _gameTimer?.cancel();
      _state = _state.copy(isGameOver: true);
      notifyListeners();
    }
  }
}

extension GameStateX on models.GameState {
  models.GameState copy({
    List<models.MemoryCard>? cards,
    int? attempts,
    int? errors,
    int? score,
    int? level,
    bool? isLevelTransition,
    int? remainingTime,
    bool? isGameOver,
    bool? isTimerStarted,
    models.GameMode? gameMode,
  }) {
    return models.GameState(
      cards: cards ?? this.cards,
      attempts: attempts ?? this.attempts,
      errors: errors ?? this.errors,
      score: score ?? this.score,
      level: level ?? this.level,
      isLevelTransition: isLevelTransition ?? this.isLevelTransition,
      remainingTime: remainingTime ?? this.remainingTime,
      isGameOver: isGameOver ?? this.isGameOver,
      isTimerStarted: isTimerStarted ?? this.isTimerStarted,
      gameMode: gameMode ?? this.gameMode,
    );
  }
}
