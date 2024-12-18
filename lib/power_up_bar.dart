import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'game_provider.dart';
import 'models.dart';

class PowerUpBar extends StatelessWidget {
  const PowerUpBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        if (provider.state.gameMode == GameMode.zen) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Punti Power-Up: ${provider.state.powerUpPoints}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: PowerUp.getAvailablePowerUps().map((powerUp) {
                  final canAfford =
                      provider.state.powerUpPoints >= powerUp.cost;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap:
                          canAfford ? () => provider.usePowerUp(powerUp) : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Tooltip(
                          message: '${powerUp.name}\n${powerUp.description}',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                powerUp.icon,
                                color:
                                    canAfford ? Colors.blue : Colors.grey[400],
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${powerUp.cost}',
                                style: TextStyle(
                                  color: canAfford
                                      ? Colors.blue
                                      : Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
