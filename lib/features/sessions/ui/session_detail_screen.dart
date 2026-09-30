import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/date_formatter.dart';
import '../../players/data/models/player.dart';
import '../../players/state/players_controller.dart';
import '../../weather/state/place_controller.dart';
import '../../weather/state/weather_controller.dart';
import '../domain/reason_chip.dart';
import '../domain/session_candidate.dart';
import 'widgets/hourly_conditions_strip.dart';
import 'widgets/players_attendance_section.dart';
import 'widgets/score_breakdown_bars.dart';
import 'widgets/score_ring.dart';

/// Full-featured Session Details Screen reached via a Hero transition.
///
/// Features animated score ring, "Why this time?" breakdown bars, confirmed
/// vs missing players, custom-painted hourly forecast strip (+/- 2h),
/// WhatsApp-friendly invite sharing, two-pane landscape layout, and Open-Meteo attribution.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({
    super.key,
    required this.candidate,
    this.placeName,
  });

  final SessionCandidate candidate;
  final String? placeName;

  /// Unique Hero tag shared between cards and this detail screen.
  static String heroTag(SessionCandidate candidate) {
    return 'session_hero_${candidate.window.start.millisecondsSinceEpoch}_${candidate.window.end.millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squad = ref.watch(squadPlayersProvider);
    final weatherState = ref.watch(weatherControllerProvider);
    final selectedPlace = ref.watch(selectedPlaceProvider);
    final effectivePlaceName =
        placeName ?? selectedPlace?.name ?? 'Selected Ground';

    final forecast = weatherState.dataOrNull;
    final hourly = forecast?.hourly ?? const [];
    final astro = forecast?.dailyAstro ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Invite',
            onPressed: () => _shareInvite(
              context,
              candidate: candidate,
              placeName: effectivePlaceName,
              allPlayers: squad,
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape =
              constraints.maxWidth >= 600 ||
              MediaQuery.orientationOf(context) == Orientation.landscape &&
                  constraints.maxWidth >= 500;

          if (isLandscape) {
            return _buildTwoPaneLayout(
              context,
              candidate: candidate,
              placeName: effectivePlaceName,
              squad: squad,
              hourly: hourly,
              astro: astro,
            );
          }

          return _buildSingleColumnLayout(
            context,
            candidate: candidate,
            placeName: effectivePlaceName,
            squad: squad,
            hourly: hourly,
            astro: astro,
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: () => _shareInvite(
              context,
              candidate: candidate,
              placeName: effectivePlaceName,
              allPlayers: squad,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Share Invite with Squad',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleColumnLayout(
    BuildContext context, {
    required SessionCandidate candidate,
    required String placeName,
    required List<Player> squad,
    required List<dynamic> hourly,
    required List<dynamic> astro,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildHeroHeaderCard(context, candidate, placeName),
        const SizedBox(height: 16),
        ScoreBreakdownBars(candidate: candidate),
        const SizedBox(height: 16),
        HourlyConditionsStrip(
          sessionStart: candidate.window.start,
          sessionEnd: candidate.window.end,
          hourlyForecast: hourly.cast(),
          dailyAstro: astro.cast(),
        ),
        const SizedBox(height: 16),
        PlayersAttendanceSection(candidate: candidate, allSquadPlayers: squad),
        const SizedBox(height: 24),
        _buildAttributionFooter(context),
      ],
    );
  }

  Widget _buildTwoPaneLayout(
    BuildContext context, {
    required SessionCandidate candidate,
    required String placeName,
    required List<Player> squad,
    required List<dynamic> hourly,
    required List<dynamic> astro,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Pane: Hero Header Card, Score Breakdown, and Key Factors
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroHeaderCard(context, candidate, placeName),
                const SizedBox(height: 16),
                ScoreBreakdownBars(candidate: candidate),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // Right Pane: Hourly Strip, Squad Attendance, and Attribution
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HourlyConditionsStrip(
                  sessionStart: candidate.window.start,
                  sessionEnd: candidate.window.end,
                  hourlyForecast: hourly.cast(),
                  dailyAstro: astro.cast(),
                ),
                const SizedBox(height: 16),
                PlayersAttendanceSection(
                  candidate: candidate,
                  allSquadPlayers: squad,
                ),
                const SizedBox(height: 24),
                _buildAttributionFooter(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeaderCard(
    BuildContext context,
    SessionCandidate candidate,
    String placeName,
  ) {
    final theme = Theme.of(context);
    final dateStr = DateFormatter.formatDayHeader(candidate.window.start);
    final timeStr = DateFormatter.formatSessionRange(
      candidate.window.start,
      candidate.window.end,
    );

    return Hero(
      tag: heroTag(candidate),
      child: Material(
        type: MaterialType.transparency,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  theme.colorScheme.surface,
                ],
              ),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Location & Ball Type Badge
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        placeName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            candidate.ballType.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Main Info Row: Date, Window, and Animated Score Ring
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              timeStr,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.groups,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${candidate.window.playerCount} confirmed available',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 88,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ScoreRing(
                            score: candidate.score,
                            rating: candidate.rating,
                            size: 72.0,
                            strokeWidth: 6.5,
                            showLabel: true,
                            animate: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttributionFooter(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wb_cloudy_outlined,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Weather data by Open-Meteo.com',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds WhatsApp-friendly text invitation and opens system share sheet.
  Future<void> _shareInvite(
    BuildContext context, {
    required SessionCandidate candidate,
    required String placeName,
    required List<Player> allPlayers,
  }) async {
    final inviteText = buildInviteText(
      candidate: candidate,
      placeName: placeName,
      allPlayers: allPlayers,
    );

    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await SharePlus.instance.share(
        ShareParams(
          text: inviteText,
          subject: 'Cricket Match Session Invitation',
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      // Fallback: Copy to clipboard if native share sheet is unavailable
      await Clipboard.setData(ClipboardData(text: inviteText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation copied to clipboard!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Formats WhatsApp and messaging friendly invitation markdown.
  static String buildInviteText({
    required SessionCandidate candidate,
    required String placeName,
    required List<Player> allPlayers,
  }) {
    final dateStr = DateFormatter.formatDayHeader(candidate.window.start);
    final timeStr = DateFormatter.formatSessionRange(
      candidate.window.start,
      candidate.window.end,
    );
    final confirmed = candidate.window.players;

    final reasonsList = candidate.reasonChips
        .where((ReasonChip c) => c.isPositive)
        .take(3)
        .map((ReasonChip c) => '• ${c.message}')
        .join('\n');

    final lineup = confirmed.isNotEmpty
        ? confirmed.map((Player p) => '✅ ${p.name}').join('\n')
        : '• Pending confirmations';

    return '''🏏 *Cricket Match Invitation!*

📍 *Venue:* $placeName
📅 *Date:* $dateStr
⏰ *Time:* $timeStr
⭐ *Viability Score:* ${candidate.score.round()}/100 (${candidate.label})
🎯 *Ball Type:* ${candidate.ballType.displayName}

${reasonsList.isNotEmpty ? "🌤️ *Why this time:*\n$reasonsList\n\n" : ""}👥 *Confirmed Lineup (${confirmed.length}):*
$lineup

Let's play cricket! 🏏''';
  }
}
