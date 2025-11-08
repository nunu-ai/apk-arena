import 'package:apk_arena/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LevelTile extends StatelessWidget {
  final int levelNumber;
  final bool isCompleted;
  final VoidCallback onTap;

  const LevelTile({
    Key? key,
    required this.levelNumber,
    required this.isCompleted,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? NunuColors.successMain : NunuColors.secondaryMain,
            width: 2,
          ),
        ), 
          child: Stack(
            children: [
              Center(
                child: Text(
                  '$levelNumber',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? NunuColors.successLight : NunuColors.secondaryLight
                  ),
                ),
              ),
              if (isCompleted)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.check_circle,
                    color: NunuColors.successLight,
                    size: 20,
                  ),
                ),
            ],
          )
      )
    );
  }
}