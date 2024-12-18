import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:memory_game/game_provider.dart';
import 'package:memory_game/models.dart' as models;
import 'package:memory_game/models.dart';
import 'package:memory_game/pause_menu.dart';
import 'package:provider/provider.dart';

import 'game_over_screen.dart';
import 'game_provider.dart' as game_provider;
import 'power_up_bar.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  bool _showVictoryAnimation = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, provider, child) {
            if (provider.state.isGameOver) {
              return GameOverScreen(
                score: provider.state.score,
                level: provider.state.level,
              );
            }

            if (_isPaused) {
              return PauseMenu(
                onResume: () {
                  setState(() {
                    _isPaused = false;
                    provider.resumeGame();
                  });
                },
              );
            }

            return Stack(
              children: [
                Column(
                  children: [
                    _buildGameHeader(provider.state),
                    Expanded(
                      child: _buildGameGrid(context, provider),
                    ),
                    if (provider.state.gameMode == GameMode.normal)
                      const PowerUpBar(),
                    const SizedBox(height: 16),
                  ],
                ),
                if (_showVictoryAnimation)
                  Positioned.fill(
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: pi / 2,
                      maxBlastForce: 5,
                      minBlastForce: 2,
                      emissionFrequency: 0.05,
                      numberOfParticles: 50,
                      gravity: 0.1,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGameHeader(models.GameState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                'Livello ${state.level + 1}',
                Icons.trending_up,
                Colors.blue,
              ),
              _buildStatCard(
                'Errori: ${state.errors}',
                Icons.error_outline,
                Colors.red,
              ),
              IconButton(
                icon: const Icon(Icons.pause_circle_outline),
                iconSize: 32,
                color: Colors.blue,
                onPressed: () {
                  setState(() {
                    _isPaused = true;
                    context.read<game_provider.GameProvider>().pauseGame();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Punti: ${state.score}',
            Icons.stars,
            Colors.amber,
          ),
          if (state.gameMode == GameMode.normal) ...[
            const SizedBox(height: 12),
            _buildTimerBar(state),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar(models.GameState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: state.remainingTime / game_provider.GameProvider.baseTime,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(
          state.remainingTime < 10 ? Colors.red : Colors.blue,
        ),
        minHeight: 10,
      ),
    );
  }

  Widget _buildGameGrid(
      BuildContext context, game_provider.GameProvider provider) {
    final state = provider.state;
    final level = models.GameSettings().getLevelForIndex(state.level);

    return Center(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: level.columns,
          childAspectRatio: 1.0,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        padding: const EdgeInsets.all(16),
        itemCount: state.cards.length,
        itemBuilder: (context, index) {
          final card = state.cards[index];
          return _MemoryCardWidget(
            key: ValueKey(card.id),
            card: card,
            isWrong: state.flippedCardIds.length == 2 &&
                state.flippedCardIds.contains(card.id) &&
                !provider.areCurrentCardsMatching(),
            onTap: () => provider.flipCard(card),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
}

class _MemoryCardWidget extends StatefulWidget {
  final models.MemoryCard card;
  final bool isWrong;
  final VoidCallback onTap;

  const _MemoryCardWidget({
    super.key,
    required this.card,
    required this.isWrong,
    required this.onTap,
  });

  @override
  State<StatefulWidget> createState() {
    return _MemoryCardWidgetState();
  }
}

class _MemoryCardWidgetState extends State<_MemoryCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_MemoryCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.isFlipped != widget.card.isFlipped) {
      if (widget.card.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(_controller.value * pi),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: widget.card.isMatched ? null : widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: _controller.value > 0.5 || widget.card.isMatched
                    ? widget.card.color
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: widget.isWrong
                      ? Colors.red
                      : widget.card.isMatched
                          ? Colors.green
                          : Colors.grey[400]!,
                  width: widget.isWrong || widget.card.isMatched ? 2 : 0,
                ),
              ),
              child: _controller.value > 0.5 || widget.card.isMatched
                  ? null
                  : Center(
                      child: Icon(
                        Icons.question_mark_rounded,
                        size: 40,
                        color: Colors.grey[600],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
