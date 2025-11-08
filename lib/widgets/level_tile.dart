import 'package:apk_arena/models/level_status.dart';
import 'package:apk_arena/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LevelTile extends StatelessWidget {
  final int levelNumber;
  final LevelStatus? status;
  final VoidCallback onTap;

  const LevelTile({
    Key? key,
    required this.levelNumber,
    required this.status,
    required this.onTap,
  }) : super(key: key);
  
  Color getBorderColor() {
    if (status?.result == LevelResult.success) {
      return NunuColors.successMain;
    }
    
    if (status?.result == LevelResult.failed) {
      return NunuColors.errorMain;
    }
    
    return NunuColors.secondaryMain;
  }
  
  Color getTextColor() {
    if (status?.result == LevelResult.success) {
      return NunuColors.successLight;
    }

    if (status?.result == LevelResult.failed) {
      return NunuColors.errorLight;
    }

    return NunuColors.secondaryLight;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: getBorderColor(),
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
                    color: getTextColor(),
                  ),
                ),
              ),
              if (status?.result == LevelResult.success)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.check_circle,
                    color: NunuColors.successLight,
                    size: 20,
                  ),
                ),
              if (status?.result == LevelResult.failed)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.close,
                    color: NunuColors.errorLight,
                    size: 20,
                  ),
                ),
            ],
          )
      )
    );
  }
}