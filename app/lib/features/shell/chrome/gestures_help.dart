import 'package:flutter/material.dart';

/// Item in the gestures help registry.
class GestureHelpEntry {
  final IconData icon;
  final String name;
  final String howToDoIt;
  final String? visibleFallback;

  const GestureHelpEntry({
    required this.icon,
    required this.name,
    required this.howToDoIt,
    this.visibleFallback,
  });
}

/// Registry of gestures and their accessible fallbacks.
const List<GestureHelpEntry> kGestures = [
  GestureHelpEntry(
    icon: Icons.swipe,
    name: 'Swipe sideways on Patients',
    howToDoIt:
        'Swipe horizontally across the Patients list to switch between Patients and Hospital.',
    visibleFallback: 'Patients/Hospital segmented button or Quick button',
  ),
  GestureHelpEntry(
    icon: Icons.unfold_more,
    name: 'Scroll to hide or show bars',
    howToDoIt:
        'Scroll down to hide top and bottom bars; scroll up or scroll to the top to show them.',
    visibleFallback: 'Bottom handle, or Settings > Bars: Always show',
  ),
  GestureHelpEntry(
    icon: Icons.horizontal_rule,
    name: 'Bottom handle',
    howToDoIt:
        'When bars are hidden, tap or drag upward on the small bottom handle to reveal them. Swipe horizontally on the handle to switch between Patients and Hospital (works on both pages).',
    visibleFallback:
        'Patients/Hospital segmented button or Settings > Bars: Always show',
  ),
  GestureHelpEntry(
    icon: Icons.bolt,
    name: 'Quick button',
    howToDoIt:
        'Tap the bolt button to open the fan-out menu. Press and hold, then drag to reposition it along either screen edge.',
    visibleFallback: 'Settings > Navigation',
  ),
  GestureHelpEntry(
    icon: Icons.arrow_back,
    name: 'System back edge guard',
    howToDoIt:
        'The outer 24 dp of left and right screen edges are reserved for the Android back gesture and will never be captured by app gestures.',
    visibleFallback: null,
  ),
];

/// Screen displaying the registry of gestures and visible fallbacks.
class GesturesHelpScreen extends StatelessWidget {
  const GesturesHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestures help'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: kGestures.length,
          separatorBuilder: (context, index) => const Divider(height: 24),
          itemBuilder: (context, index) {
            final gesture = kGestures[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      gesture.icon,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gesture.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gesture.howToDoIt,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (gesture.visibleFallback != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fallback: ',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  gesture.visibleFallback!,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
