import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:mediswitch/utils/animation_utils.dart';
import 'package:mediswitch/utils/tailwind_utils.dart';
import 'package:mediswitch/widgets/animated_card.dart';

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Components'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: TailwindUtils.p4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with animation
            Text(
              'Modern UI Components',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: TailwindUtils.fontBold,
                color: theme.colorScheme.primary,
              ),
            )
            .animate()
            .fadeIn(duration: AnimationUtils.durationNormal)
            .slideX(begin: -20, end: 0),
            
            SizedBox(height: TailwindUtils.spacing4),
            
            // Subtitle with animation
            Text(
              'Beautiful, responsive, and animated UI components for your app',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: TailwindUtils.gray600,
              ),
            )
            .animate()
            .fadeIn(delay: 200.ms, duration: AnimationUtils.durationNormal)
            .slideX(begin: -10, end: 0),
            
            SizedBox(height: TailwindUtils.spacing8),
            
            // Section title
            Text(
              'Cards',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: TailwindUtils.fontSemiBold,
              ),
            )
            .animate()
            .fadeIn(delay: 300.ms),
            
            SizedBox(height: TailwindUtils.spacing4),
            
            // Animated cards
            AnimatedCard(
              title: 'Medication Management',
              subtitle: 'Track and manage your medications',
              icon: TablerIcons.pill,
              iconColor: TailwindUtils.primary,
              onTap: () {},
            ),
            
            AnimatedCard(
              title: 'Dose Calculator',
              subtitle: 'Calculate accurate medication doses',
              icon: TablerIcons.calculator,
              iconColor: TailwindUtils.secondary,
              onTap: () {},
            ),
            
            AnimatedCard(
              title: 'Drug Interactions',
              subtitle: 'Check for potential drug interactions',
              icon: TablerIcons.alert_triangle,
              iconColor: TailwindUtils.warning,
              onTap: () {},
            ),
            
            SizedBox(height: TailwindUtils.spacing8),
            
            // Section title
            Text(
              'Buttons',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: TailwindUtils.fontSemiBold,
              ),
            )
            .animate()
            .fadeIn(delay: 400.ms),
            
            SizedBox(height: TailwindUtils.spacing4),
            
            // Buttons with animations
            Wrap(
              spacing: TailwindUtils.spacing3,
              runSpacing: TailwindUtils.spacing3,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TailwindUtils.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: TailwindUtils.spacing4, vertical: TailwindUtils.spacing3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TailwindUtils.roundedLg),
                    ),
                  ),
                  child: const Text('Primary'),
                )
                .animate()
                .fadeIn(delay: 500.ms)
                .scale(delay: 500.ms, begin: Offset(0.9, 0.9)),
                
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TailwindUtils.primary,
                    side: BorderSide(color: TailwindUtils.primary),
                    padding: EdgeInsets.symmetric(horizontal: TailwindUtils.spacing4, vertical: TailwindUtils.spacing3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TailwindUtils.roundedLg),
                    ),
                  ),
                  child: const Text('Secondary'),
                )
                .animate()
                .fadeIn(delay: 600.ms)
                .scale(delay: 600.ms, begin: Offset(0.9, 0.9)),
                
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: TailwindUtils.primary,
                    padding: EdgeInsets.symmetric(horizontal: TailwindUtils.spacing4, vertical: TailwindUtils.spacing3),
                  ),
                  child: const Text('Text Button'),
                )
                .animate()
                .fadeIn(delay: 700.ms)
                .scale(delay: 700.ms, begin: Offset(0.9, 0.9)),
              ],
            ),
            
            SizedBox(height: TailwindUtils.spacing8),
            
            // Section title
            Text(
              'Icons',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: TailwindUtils.fontSemiBold,
              ),
            )
            .animate()
            .fadeIn(delay: 800.ms),
            
            SizedBox(height: TailwindUtils.spacing4),
            
            // Icons with animations
            Wrap(
              spacing: TailwindUtils.spacing6,
              runSpacing: TailwindUtils.spacing6,
              children: [
                _buildIconWithLabel(TablerIcons.heart, 'Favorites', TailwindUtils.danger, 900),
                _buildIconWithLabel(TablerIcons.settings, 'Settings', TailwindUtils.gray600, 1000),
                _buildIconWithLabel(TablerIcons.user, 'Profile', TailwindUtils.primary, 1100),
                _buildIconWithLabel(TablerIcons.bell, 'Notifications', TailwindUtils.warning, 1200),
                _buildIconWithLabel(TablerIcons.home, 'Home', TailwindUtils.secondary, 1300),
                _buildIconWithLabel(TablerIcons.search, 'Search', TailwindUtils.info, 1400),
              ],
            ),
            
            SizedBox(height: TailwindUtils.spacing12),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIconWithLabel(IconData icon, String label, Color color, int delayMs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: TailwindUtils.p3,
          decoration: BoxDecoration(
            color: color.withAlpha(26), // 0.1 * 255 = ~26
            borderRadius: BorderRadius.circular(TailwindUtils.roundedFull),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(height: TailwindUtils.spacing2),
        Text(
          label,
          style: TextStyle(
            fontSize: TailwindUtils.textSm,
            fontWeight: TailwindUtils.fontMedium,
            color: TailwindUtils.gray700,
          ),
        ),
      ],
    )
    .animate()
    .fadeIn(delay: delayMs.ms)
    .scale(delay: delayMs.ms, begin: Offset(0.8, 0.8));
  }
}