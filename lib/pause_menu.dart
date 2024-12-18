import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_provider.dart';

class PauseMenu extends StatelessWidget {
  final VoidCallback onResume;

  const PauseMenu({
    super.key,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gioco in Pausa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildButton(
                context,
                'Riprendi',
                Icons.play_arrow,
                onResume,
              ),
              const SizedBox(height: 15),
              _buildButton(
                context,
                'Ricomincia',
                Icons.refresh,
                () {
                  context.read<GameProvider>().startGame(
                        gameMode: context.read<GameProvider>().state.gameMode,
                      );
                },
              ),
              const SizedBox(height: 15),
              _buildButton(
                context,
                'Abbandona',
                Icons.exit_to_app,
                () => Navigator.of(context).pop(),
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Text(text),
          ],
        ),
      ),
    );
  }
}
