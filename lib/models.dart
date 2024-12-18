import 'dart:math';

import 'package:flutter/material.dart';

enum GameMode { normal, zen }

class MemoryCard {
  final String id;
  final Color color;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.color,
    this.isFlipped = false,
    this.isMatched = false,
  });

  MemoryCard copy({
    bool? isFlipped,
    bool? isMatched,
  }) =>
      MemoryCard(
        id: id,
        color: color,
        isFlipped: isFlipped ?? this.isFlipped,
        isMatched: isMatched ?? this.isMatched,
      );
}

class GameLevel {
  final int rows;
  final int columns;

  const GameLevel({
    required this.rows,
    required this.columns,
  });

  int get totalCards => rows * columns;
}

class GameSettings {
  List<GameLevel> getLevels(int maxLevel) {
    List<GameLevel> levels = [];
    for (int i = 0; i <= maxLevel; i++) {
      levels.add(GameLevel(rows: i + 2, columns: i + 2));
    }
    return levels;
  }

  GameLevel getLevelForIndex(int index) {
    return GameLevel(rows: index + 2, columns: index + 2);
  }

  static List<Color> generateUniqueColors(int count) {
    final random = Random();
    final colors = <Color>[];

    while (colors.length < count) {
      final color = Color.fromRGBO(
          random.nextInt(256), random.nextInt(256), random.nextInt(256), 1.0);

      if (!colors.any((c) => _areSimilarColors(c, color))) {
        colors.add(color);
      }
    }

    return colors;
  }

  static bool _areSimilarColors(Color color1, Color color2) {
    const threshold = 50;
    return (color1.red - color2.red).abs() < threshold &&
        (color1.green - color2.green).abs() < threshold &&
        (color1.blue - color2.blue).abs() < threshold;
  }
}

class GameState {
  final List<MemoryCard> cards;
  final int attempts;
  final int errors;
  final int score;
  final int powerUpPoints;
  final int level;
  final bool isLevelTransition;
  final int remainingTime;
  final bool isGameOver;
  final bool isTimerStarted;
  final GameMode gameMode;

  List<String> get flippedCardIds => cards
      .where((card) => card.isFlipped && !card.isMatched)
      .map((card) => card.id)
      .toList();

  const GameState({
    required this.cards,
    this.attempts = 0,
    this.errors = 0,
    this.score = 0,
    this.powerUpPoints = 0,
    this.level = 0,
    this.isLevelTransition = false,
    this.remainingTime = 30,
    this.isGameOver = false,
    this.isTimerStarted = false,
    this.gameMode = GameMode.normal,
  });

  GameState copy({
    List<MemoryCard>? cards,
    int? attempts,
    int? errors,
    int? score,
    int? powerUpPoints,
    int? level,
    bool? isLevelTransition,
    int? remainingTime,
    bool? isGameOver,
    bool? isTimerStarted,
    GameMode? gameMode,
  }) {
    return GameState(
      cards: cards ?? this.cards,
      attempts: attempts ?? this.attempts,
      errors: errors ?? this.errors,
      score: score ?? this.score,
      powerUpPoints: powerUpPoints ?? this.powerUpPoints,
      level: level ?? this.level,
      isLevelTransition: isLevelTransition ?? this.isLevelTransition,
      remainingTime: remainingTime ?? this.remainingTime,
      isGameOver: isGameOver ?? this.isGameOver,
      isTimerStarted: isTimerStarted ?? this.isTimerStarted,
      gameMode: gameMode ?? this.gameMode,
    );
  }
}

enum PowerUpType {
  freezeTime,
  revealCard,
  extraTime,
}

class PowerUp {
  final PowerUpType type;
  final String name;
  final String description;
  final IconData icon;
  final int cost;
  final bool isAvailable;

  const PowerUp({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.cost,
    this.isAvailable = true,
  });

  static List<PowerUp> getAvailablePowerUps() {
    return [
      PowerUp(
        type: PowerUpType.freezeTime,
        name: 'Ferma Tempo',
        description: 'Ferma il timer per 5 secondi',
        icon: Icons.timer_off,
        cost: 50,
      ),
      PowerUp(
        type: PowerUpType.revealCard,
        name: 'Rivela Carta',
        description: 'Mostra una carta casuale per 2 secondi',
        icon: Icons.visibility,
        cost: 75,
      ),
      PowerUp(
        type: PowerUpType.extraTime,
        name: 'Tempo Extra',
        description: 'Aggiunge 10 secondi al timer',
        icon: Icons.add_alarm,
        cost: 100,
      ),
    ];
  }
}
