import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:mediswitch/utils/tailwind_utils.dart';

/// A reusable animated card component with icon, title, and subtitle
class AnimatedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final int delayMs;

  const AnimatedCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: TailwindUtils.spacing3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TailwindUtils.roundedLg),
          child: Container(
            padding: TailwindUtils.p4,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(TailwindUtils.roundedLg),
              boxShadow: TailwindUtils.shadowSm,
              border: Border.all(
                color: TailwindUtils.gray200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: TailwindUtils.p3,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(26), // 0.1 * 255 = ~26
                    borderRadius: BorderRadius.circular(TailwindUtils.roundedFull),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: TailwindUtils.spacing3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: TailwindUtils.fontSemiBold,
                        ),
                      ),
                      SizedBox(height: TailwindUtils.spacing1),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: TailwindUtils.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  TablerIcons.chevron_right,
                  color: TailwindUtils.gray400,
                ),
              ],
            ),
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(delay: Duration(milliseconds: delayMs))
    .slideX(delay: Duration(milliseconds: delayMs), begin: -10, end: 0);
  }
}