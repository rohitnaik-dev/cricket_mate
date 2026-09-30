import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../sessions/domain/ball_type.dart';
import '../../weather/state/place_controller.dart';
import '../state/settings_controller.dart';

/// Screen allowing users to configure match preferences (ball type, default duration,
/// quorum requirement), application preferences (theme mode, language/locale),
/// and view Open-Meteo weather data attribution.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsControllerProvider);
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);
    final selectedPlace = ref.watch(selectedPlaceProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle), centerTitle: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape =
              constraints.maxWidth >= 600 ||
              (MediaQuery.orientationOf(context) == Orientation.landscape &&
                  constraints.maxWidth >= 500);

          if (isLandscape) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    children: [
                      _MatchPreferencesCard(
                        settingsState: settingsState,
                        settingsNotifier: settingsNotifier,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    children: [
                      _AppPreferencesCard(
                        settingsState: settingsState,
                        settingsNotifier: settingsNotifier,
                      ),
                      const SizedBox(height: 12),
                      _AboutCard(selectedPlaceName: selectedPlace?.name),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            children: [
              _MatchPreferencesCard(
                settingsState: settingsState,
                settingsNotifier: settingsNotifier,
              ),
              const SizedBox(height: 16),
              _AppPreferencesCard(
                settingsState: settingsState,
                settingsNotifier: settingsNotifier,
              ),
              const SizedBox(height: 16),
              _AboutCard(selectedPlaceName: selectedPlace?.name),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

/// Card grouping match preferences: ball type, match duration, and squad quorum.
class _MatchPreferencesCard extends StatelessWidget {
  const _MatchPreferencesCard({
    required this.settingsState,
    required this.settingsNotifier,
  });

  final SettingsState settingsState;
  final SettingsController settingsNotifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(
                  Icons.sports_cricket,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.matchSettingsSection,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // 1. Ball Type Preference
            Text(
              l10n.defaultBallType,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getBallTypeDescription(settingsState.ballType, l10n),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Semantics(
              label:
                  '${l10n.defaultBallType}: ${settingsState.ballType.displayName}',
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<BallType>(
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  segments: [
                    ButtonSegment<BallType>(
                      value: BallType.tennis,
                      label: Text(
                        l10n.ballTypeTennis,
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: const Icon(
                        Icons.sports_baseball_outlined,
                        size: 18,
                      ),
                    ),
                    ButtonSegment<BallType>(
                      value: BallType.leather,
                      label: Text(
                        l10n.ballTypeLeather,
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                    ),
                    ButtonSegment<BallType>(
                      value: BallType.box,
                      label: Text(
                        l10n.ballTypeBox,
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: const Icon(Icons.crop_square_outlined, size: 18),
                    ),
                  ],
                  selected: {settingsState.ballType},
                  onSelectionChanged: (newSelection) {
                    if (newSelection.isNotEmpty) {
                      settingsNotifier.setBallType(newSelection.first);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Default Match Duration Preference
            Text(
              l10n.defaultDuration,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.durationHours(
                settingsState.sessionDuration.inHours > 0
                    ? settingsState.sessionDuration.inHours
                    : 1,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Semantics(
              label:
                  '${l10n.defaultDuration}: ${settingsState.sessionDuration.inMinutes} minutes',
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  segments: [
                    ButtonSegment<int>(
                      value: 60,
                      label: Text(l10n.durationHoursShort('1')),
                      tooltip: l10n.durationHours(1),
                    ),
                    ButtonSegment<int>(
                      value: 90,
                      label: Text(l10n.durationHoursShort('1.5')),
                      tooltip: '1.5 hours',
                    ),
                    ButtonSegment<int>(
                      value: 120,
                      label: Text(l10n.durationHoursShort('2')),
                      tooltip: l10n.durationHours(2),
                    ),
                    ButtonSegment<int>(
                      value: 180,
                      label: Text(l10n.durationHoursShort('3')),
                      tooltip: l10n.durationHours(3),
                    ),
                  ],
                  selected: {settingsState.sessionDuration.inMinutes},
                  onSelectionChanged: (newSelection) {
                    if (newSelection.isNotEmpty) {
                      settingsNotifier.setSessionDuration(
                        Duration(minutes: newSelection.first),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Minimum Squad Quorum Requirement
            Text(
              l10n.squadQuorum,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.quorumDescription(settingsState.quorum),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Decrease quorum',
                    child: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: theme.colorScheme.primary,
                      iconSize: 26,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      tooltip: 'Decrease quorum',
                      onPressed: settingsState.quorum > 4
                          ? () => settingsNotifier.setQuorum(
                              settingsState.quorum - 1,
                            )
                          : null,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${settingsState.quorum}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Increase quorum',
                    child: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: theme.colorScheme.primary,
                      iconSize: 26,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      tooltip: 'Increase quorum',
                      onPressed: settingsState.quorum < 11
                          ? () => settingsNotifier.setQuorum(
                              settingsState.quorum + 1,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBallTypeDescription(BallType ballType, AppLocalizations l10n) {
    return switch (ballType) {
      BallType.tennis => l10n.ballTypeTennisDesc,
      BallType.leather => l10n.ballTypeLeatherDesc,
      BallType.box => l10n.ballTypeBoxDesc,
    };
  }
}

/// Card grouping application preferences: theme mode and language / locale.
class _AppPreferencesCard extends StatelessWidget {
  const _AppPreferencesCard({
    required this.settingsState,
    required this.settingsNotifier,
  });

  final SettingsState settingsState;
  final SettingsController settingsNotifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.appPreferencesSection,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // 1. Theme Mode
            Text(
              l10n.appTheme,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Semantics(
              label: '${l10n.appTheme}: ${settingsState.themeMode.name}',
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  segments: [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text(
                        l10n.themeSystem,
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: const Icon(Icons.brightness_auto, size: 18),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text(
                        l10n.themeLight,
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: const Icon(Icons.light_mode_outlined, size: 18),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text(
                        l10n.themeDark,
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: const Icon(Icons.dark_mode_outlined, size: 18),
                    ),
                  ],
                  selected: {settingsState.themeMode},
                  onSelectionChanged: (newSelection) {
                    if (newSelection.isNotEmpty) {
                      settingsNotifier.setThemeMode(newSelection.first);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Language / भाषा
            Text(
              l10n.appLanguage,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Semantics(
              label:
                  '${l10n.appLanguage}: ${settingsState.locale?.languageCode ?? 'en'}',
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  segments: [
                    ButtonSegment<String>(
                      value: 'en',
                      label: Text(
                        l10n.languageEnglish,
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: const Icon(Icons.translate, size: 18),
                    ),
                    ButtonSegment<String>(
                      value: 'hi',
                      label: Text(
                        l10n.languageHindi,
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: const Icon(Icons.language, size: 18),
                    ),
                  ],
                  selected: {settingsState.locale?.languageCode ?? 'en'},
                  onSelectionChanged: (newSelection) {
                    if (newSelection.isNotEmpty) {
                      final code = newSelection.first;
                      settingsNotifier.setLocale(Locale(code));
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying Open-Meteo CC BY 4.0 data attribution and app metadata.
class _AboutCard extends StatelessWidget {
  const _AboutCard({this.selectedPlaceName});

  final String? selectedPlaceName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.aboutSection,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Open-Meteo Data Attribution
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.cloud_outlined,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              title: Text(
                l10n.dataAttribution,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                l10n.dataAttributionSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Selected Cricket Ground / Pitch
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.place_outlined,
                  color: theme.colorScheme.secondary,
                  size: 22,
                ),
              ),
              title: Text(
                l10n.homePitch,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                l10n.homePitchSubtitle(selectedPlaceName ?? 'Not configured'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // App Version Badge
            Center(
              child: Text(
                l10n.versionInfo,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
