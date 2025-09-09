import 'package:flutter/material.dart';

/// Optimized metric card with const constructor for better performance
class OptimizedMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isWeb;
  final bool isTablet;

  const OptimizedMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.color,
    required this.icon,
    this.onTap,
    this.isWeb = false,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = isWeb ? 24.0 : (isTablet ? 22.0 : 20.0);
    final iconSize = isWeb ? 56.0 : (isTablet ? 52.0 : 48.0);
    final iconInnerSize = isWeb ? 28.0 : (isTablet ? 26.0 : 24.0);
    final titleFontSize = isWeb ? 16.0 : (isTablet ? 15.0 : 14.0);
    final valueFontSize = isWeb ? 28.0 : (isTablet ? 26.0 : 24.0);
    final changeFontSize = isWeb ? 14.0 : 12.0;
    final verticalSpacing = isWeb ? 20.0 : (isTablet ? 18.0 : 16.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: isWeb ? 200 : 150,
          minHeight: isWeb ? 140 : 120,
        ),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: iconInnerSize),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 10 : 8,
                    vertical: isWeb ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: changeFontSize,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: verticalSpacing),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: isWeb ? 12 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
