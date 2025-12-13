import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class GameScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onRestart;
  final VoidCallback? onPause;
  final Widget? scoreWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;

  const GameScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onRestart,
    this.onPause,
    this.scoreWidget,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          if (scoreWidget != null) ...[
            Center(child: scoreWidget!),
            const SizedBox(width: 8),
          ],
          if (onPause != null)
            IconButton(
              icon: const Icon(Icons.pause_rounded),
              onPressed: onPause,
            ),
          if (onRestart != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: onRestart,
            ),
          if (actions != null) ...actions!,
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}

class ScoreDisplay extends StatelessWidget {
  final String label;
  final int score;
  final Color? color;

  const ScoreDisplay({
    super.key,
    required this.label,
    required this.score,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color ?? AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
