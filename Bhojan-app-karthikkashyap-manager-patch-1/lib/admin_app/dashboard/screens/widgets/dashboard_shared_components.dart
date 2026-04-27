import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isPrimary;
  final String? suffix;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.isPrimary = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? const Border(left: BorderSide(color: AppColors.primary, width: 4)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Icon(icon, color: Colors.grey.shade400, size: 16),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.bold, color: isPrimary ? AppColors.textPrimary : Colors.black87)),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(suffix!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isLocked;
  final String? route;

  const ModuleCard({
    super.key,
    required this.title,
    required this.icon,
    this.isLocked = false,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked || route == null ? null : () => context.push(route!),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: isLocked ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: isLocked ? Colors.grey.shade200 : AppColors.primary.withValues(alpha: 0.1),
                    radius: 20,
                    child: Icon(icon, color: isLocked ? Colors.grey.shade400 : AppColors.primary, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.grey.shade400 : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.lock, size: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
