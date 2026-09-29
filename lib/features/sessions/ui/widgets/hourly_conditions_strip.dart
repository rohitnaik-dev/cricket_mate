import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../weather/data/models/daily_astro.dart';
import '../../../weather/data/models/hourly_weather.dart';

/// Interactive conditions strip visualizing hourly forecast for the session window
/// +/- 2 hours drawn with a custom painter (rain probability bars, temperature line,
/// match window highlight band, and sunset marker).
class HourlyConditionsStrip extends StatelessWidget {
  const HourlyConditionsStrip({
    super.key,
    required this.sessionStart,
    required this.sessionEnd,
    required this.hourlyForecast,
    this.dailyAstro = const [],
    this.height = 200.0,
  });

  final DateTime sessionStart;
  final DateTime sessionEnd;
  final List<HourlyWeather> hourlyForecast;
  final List<DailyAstro> dailyAstro;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Window +/- 2 hours
    final rangeStart = sessionStart.subtract(const Duration(hours: 2));
    final rangeEnd = sessionEnd.add(const Duration(hours: 2));

    // Filter relevant hourly forecast items
    final items = hourlyForecast.where((h) {
      return (h.time.isAfter(rangeStart) ||
              h.time.isAtSameMomentAs(rangeStart)) &&
          (h.time.isBefore(rangeEnd) || h.time.isAtSameMomentAs(rangeEnd));
    }).toList()..sort((a, b) => a.time.compareTo(b.time));

    // Find sunset time within this day if available
    DateTime? sunsetTime;
    for (final astro in dailyAstro) {
      if (astro.sunset != null) {
        final s = astro.sunset!;
        if ((s.isAfter(rangeStart) || s.isAtSameMomentAs(rangeStart)) &&
            (s.isBefore(rangeEnd) || s.isAtSameMomentAs(rangeEnd))) {
          sunsetTime = s;
          break;
        }
      }
    }

    if (items.isEmpty) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'Hourly condition strip unavailable for this window.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final temps = items
        .map(
          (e) => (e.apparentTemperature ?? e.temperature2m ?? 20.0).toDouble(),
        )
        .toList();
    final minTemp = temps.reduce(math.min);
    final maxTemp = temps.reduce(math.max);
    final rainProbs = items
        .map((e) => e.precipitationProbability ?? 0)
        .toList();
    final maxRainProb = rainProbs.reduce(math.max);

    final semanticsLabel =
        'Hourly forecast strip from ${DateFormatter.formatShortHour(rangeStart)} to ${DateFormatter.formatShortHour(rangeEnd)}. '
        'Temperatures between ${minTemp.round()}°C and ${maxTemp.round()}°C. '
        'Peak rain probability is $maxRainProb%. '
        '${sunsetTime != null ? "Sunset is at ${DateFormatter.formatTime(sunsetTime)}." : ""}';

    return Semantics(
      label: semanticsLabel,
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Legend
              Row(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Hourly Forecast',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Window ± 2h',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Legend indicators
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _LegendIndicator(
                    color: Colors.blue.shade600,
                    label: 'Rain %',
                    isBar: true,
                  ),
                  _LegendIndicator(
                    color: theme.colorScheme.primary,
                    label: 'Temp (°C)',
                    isBar: false,
                  ),
                  _LegendIndicator(
                    color: Colors.green.withValues(alpha: 0.3),
                    label: 'Match Window',
                    isBand: true,
                  ),
                  if (sunsetTime != null)
                    _LegendIndicator(
                      color: Colors.amber.shade800,
                      label: 'Sunset',
                      isDashed: true,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Canvas chart
              SizedBox(
                height: height,
                width: double.infinity,
                child: CustomPaint(
                  size: Size(double.infinity, height),
                  painter: HourlyStripPainter(
                    items: items,
                    rangeStart: rangeStart,
                    rangeEnd: rangeEnd,
                    sessionStart: sessionStart,
                    sessionEnd: sessionEnd,
                    sunsetTime: sunsetTime,
                    theme: theme,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendIndicator extends StatelessWidget {
  const _LegendIndicator({
    required this.color,
    required this.label,
    this.isBar = false,
    this.isBand = false,
    this.isDashed = false,
  });

  final Color color;
  final String label;
  final bool isBar;
  final bool isBand;
  final bool isDashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBand)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.green.shade700, width: 1),
            ),
          )
        else if (isBar)
          Container(
            width: 8,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else if (isDashed)
          SizedBox(
            width: 12,
            height: 12,
            child: Center(child: Container(width: 2, height: 12, color: color)),
          )
        else
          Container(
            width: 12,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// CustomPainter rendering the active match window, rain bars, temperature line, and sunset line.
class HourlyStripPainter extends CustomPainter {
  HourlyStripPainter({
    required this.items,
    required this.rangeStart,
    required this.rangeEnd,
    required this.sessionStart,
    required this.sessionEnd,
    required this.sunsetTime,
    required this.theme,
  });

  final List<HourlyWeather> items;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final DateTime sessionStart;
  final DateTime sessionEnd;
  final DateTime? sunsetTime;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final width = size.width;
    final height = size.height;

    const bottomPadding = 24.0;
    const topPadding = 28.0;
    final chartHeight = height - bottomPadding - topPadding;

    final n = items.length;
    final step = n > 1 ? width / (n - 1) : width;

    // 1. Draw Active Match Window Highlight Band
    _drawMatchWindowBand(canvas, size, step, topPadding, chartHeight);

    // 2. Draw Sunset Marker Line if within window
    _drawSunsetMarker(canvas, size, step, topPadding, chartHeight);

    // 3. Draw Rain Probability Bars (bottom 50% of chart area)
    _drawRainBars(canvas, size, step, topPadding, chartHeight);

    // 4. Draw Temperature Line & Dots
    _drawTemperatureLine(canvas, size, step, topPadding, chartHeight);

    // 5. Draw Time Axis Labels
    _drawTimeLabels(canvas, size, step);
  }

  void _drawMatchWindowBand(
    Canvas canvas,
    Size size,
    double step,
    double topPadding,
    double chartHeight,
  ) {
    int startIdx = items.indexWhere(
      (h) =>
          h.time.isAtSameMomentAs(sessionStart) || h.time.isAfter(sessionStart),
    );
    int endIdx = items.lastIndexWhere(
      (h) => h.time.isAtSameMomentAs(sessionEnd) || h.time.isBefore(sessionEnd),
    );

    if (startIdx == -1) startIdx = 0;
    if (endIdx == -1) endIdx = items.length - 1;

    final startX = (startIdx * step).clamp(0.0, size.width);
    final endX = (endIdx * step).clamp(0.0, size.width);

    final bandRect = Rect.fromLTRB(
      startX,
      topPadding - 4,
      math.max(startX + 16, endX),
      topPadding + chartHeight + 4,
    );

    final bandPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.green.shade700.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(bandRect, const Radius.circular(8));
    canvas.drawRRect(rrect, bandPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Match Window Badge at top
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'MATCH WINDOW',
        style: TextStyle(
          color: Color(0xFF2E7D32),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeX = (startX + 6).clamp(4.0, size.width - textPainter.width - 6);
    textPainter.paint(canvas, Offset(badgeX, topPadding - 18));
  }

  void _drawSunsetMarker(
    Canvas canvas,
    Size size,
    double step,
    double topPadding,
    double chartHeight,
  ) {
    if (sunsetTime == null) return;

    final totalDuration = rangeEnd.difference(rangeStart).inMinutes;
    if (totalDuration <= 0) return;

    final offsetMinutes = sunsetTime!.difference(rangeStart).inMinutes;
    final ratio = (offsetMinutes / totalDuration).clamp(0.0, 1.0);
    final sunsetX = ratio * size.width;

    final linePaint = Paint()
      ..color = Colors.amber.shade800
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw dashed vertical line
    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = topPadding;
    final endY = topPadding + chartHeight;

    while (startY < endY) {
      canvas.drawLine(
        Offset(sunsetX, startY),
        Offset(sunsetX, math.min(startY + dashHeight, endY)),
        linePaint,
      );
      startY += dashHeight + dashSpace;
    }

    // Sunset text label
    final sunsetText = TextPainter(
      text: TextSpan(
        text: 'Sunset ${DateFormatter.formatTime(sunsetTime!)}',
        style: TextStyle(
          color: Colors.amber.shade900,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelX = (sunsetX - sunsetText.width / 2).clamp(
      4.0,
      size.width - sunsetText.width - 4,
    );
    sunsetText.paint(canvas, Offset(labelX, endY - 14));
  }

  void _drawRainBars(
    Canvas canvas,
    Size size,
    double step,
    double topPadding,
    double chartHeight,
  ) {
    final barMaxHeight = chartHeight * 0.45;
    final barBaseY = topPadding + chartHeight;
    final barWidth = (step * 0.38).clamp(8.0, 24.0);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final rainProb = item.precipitationProbability ?? 0;
      if (rainProb <= 0) continue;

      final barH = (rainProb / 100.0) * barMaxHeight;
      final x = (i * step) - (barWidth / 2);
      final y = barBaseY - barH;

      final barRect = Rect.fromLTWH(x, y, barWidth, barH);
      final rrect = RRect.fromRectAndCorners(
        barRect,
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade700.withValues(alpha: 0.6),
          ],
        ).createShader(barRect);

      canvas.drawRRect(rrect, barPaint);

      // Rain percentage label above bar
      if (rainProb >= 15) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$rainProb%',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(i * step - (tp.width / 2), y - 11));
      }
    }
  }

  void _drawTemperatureLine(
    Canvas canvas,
    Size size,
    double step,
    double topPadding,
    double chartHeight,
  ) {
    final temps = items
        .map(
          (e) => (e.apparentTemperature ?? e.temperature2m ?? 20.0).toDouble(),
        )
        .toList();
    final minT = temps.reduce(math.min);
    final maxT = temps.reduce(math.max);
    final range = (maxT - minT).clamp(2.0, 40.0);

    final tempLineTop = topPadding + 6;
    final tempLineHeight = chartHeight * 0.42;

    double tempToY(double temp) {
      final ratio = (temp - minT) / range;
      // Higher temp = higher on canvas (smaller Y)
      return (tempLineTop + tempLineHeight) - (ratio * tempLineHeight);
    }

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < items.length; i++) {
      final x = i * step;
      final y = tempToY(temps[i]);
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Stroke line
    final linePaint = Paint()
      ..color = theme.colorScheme.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Draw dots and temperature labels
    final dotPaint = Paint()..color = theme.colorScheme.primary;
    final innerDotPaint = Paint()..color = Colors.white;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 4.0, dotPaint);
      canvas.drawCircle(pt, 2.0, innerDotPaint);

      final tempVal = temps[i].round();
      final tp = TextPainter(
        text: TextSpan(
          text: '$tempVal°',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(pt.dx - (tp.width / 2), pt.dy - 16));
    }
  }

  void _drawTimeLabels(Canvas canvas, Size size, double step) {
    final y = size.height - 18;

    for (int i = 0; i < items.length; i++) {
      final hourStr = DateFormatter.formatShortHour(items[i].time);
      final tp = TextPainter(
        text: TextSpan(
          text: hourStr,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final x = (i * step) - (tp.width / 2);
      final clampedX = x.clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(clampedX, y));
    }
  }

  @override
  bool shouldRepaint(covariant HourlyStripPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.sessionStart != sessionStart ||
        oldDelegate.sessionEnd != sessionEnd ||
        oldDelegate.sunsetTime != sunsetTime;
  }
}
