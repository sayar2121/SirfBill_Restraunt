import 'package:flutter/material.dart';
import '../../../../themes/app_colors.dart';

class CustomerAvatar extends StatelessWidget {
  final String initials;
  final double radius;
  final double fontSize;

  const CustomerAvatar({
    super.key,
    required this.initials,
    this.radius = 16,
    this.fontSize = 12,
  });

  static Color getAvatarColor(String initials) {
    if (initials == 'RD') return AppColors.secondaryLight;
    if (initials == 'PS') return AppColors.infoLight;
    if (initials == 'AM') return AppColors.warningLight;
    if (initials == 'KM') return AppColors.errorLight;
    return AppColors.primaryLight;
  }

  static Color getAvatarTextColor(String initials) {
    if (initials == 'RD') return AppColors.secondary;
    if (initials == 'PS') return AppColors.info;
    if (initials == 'AM') return AppColors.warning;
    if (initials == 'KM') return AppColors.error;
    return AppColors.primaryDark;
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: getAvatarColor(initials),
      child: Text(
        initials,
        style: TextStyle(
          color: getAvatarTextColor(initials),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class CustomerStatusChip extends StatelessWidget {
  final String status;

  const CustomerStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    if (status == 'Active') {
      bgColor = AppColors.primaryLight;
      textColor = AppColors.primaryDark;
    } else if (status == 'Inactive') {
      bgColor = AppColors.errorLight;
      textColor = AppColors.error;
    } else {
      bgColor = AppColors.secondaryLight;
      textColor = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: textColor),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
