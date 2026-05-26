import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

// --- 1. Consistency Grid (Heatmap) ---
class ConsistencyGrid extends StatelessWidget {
  final Map<DateTime, int> data;

  const ConsistencyGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Sort dates in ascending order
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Consistencia de Actividad",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Últimas 4 Semanas",
                  style: TextStyle(color: CyberTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: sortedEntries.map((entry) {
                  final workouts = entry.value;
                  final date = entry.key;

                  Color color = CyberTheme.surface.withOpacity(0.5);
                  if (workouts > 0) {
                    color = Color.lerp(CyberTheme.neonRose, CyberTheme.cyberTeal, min(workouts / 2, 1.0))!;
                  }

                  return Tooltip(
                    message: "${date.day}/${date.month}: $workouts entrenamiento(s)",
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: workouts > 0 ? color.withOpacity(0.5) : CyberTheme.borderTranslucent,
                          width: 1,
                        ),
                        boxShadow: workouts > 0 ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          )
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          "${date.day}",
                          style: TextStyle(
                            fontSize: 10,
                            color: workouts > 0 ? Colors.white : CyberTheme.textSecondary.withOpacity(0.8),
                            fontWeight: workouts > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. Custom Line Chart (1RM Progress) ---
class VolumeLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> progressData;

  const VolumeLineChart({super.key, required this.progressData});

  @override
  Widget build(BuildContext context) {
    if (progressData.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "Realiza entrenamientos para ver el progreso 1RM",
            style: TextStyle(color: CyberTheme.textSecondary),
          ),
        ),
      );
    }

    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
      child: CustomPaint(
        painter: LineChartPainter(data: progressData),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final double paddingX = 35.0;
    final double paddingY = 20.0;
    final double drawWidth = size.width - paddingX - 10;
    final double drawHeight = size.height - paddingY * 2;

    // Get Min/Max 1RM values
    final double maxVal = data.map((d) => d['1rm'] as double).reduce(max);
    final double minVal = data.map((d) => d['1rm'] as double).reduce(min);
    final double range = maxVal - minVal;
    final double gridMax = range == 0 ? maxVal + 10 : maxVal + (range * 0.1);
    final double gridMin = range == 0 ? max(0.0, maxVal - 10) : max(0.0, minVal - (range * 0.1));
    final double gridRange = gridMax - gridMin;

    // Grid lines & Y Axis labels
    final paintGrid = Paint()
      ..color = CyberTheme.borderTranslucent
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    // Draw Y axis lines
    final int gridLinesCount = 3;
    for (int i = 0; i <= gridLinesCount; i++) {
      final double ratio = i / gridLinesCount;
      final double y = paddingY + drawHeight * (1 - ratio);
      
      canvas.drawLine(Offset(paddingX, y), Offset(size.width - 10, y), paintGrid);
      
      // Draw label
      final double labelVal = gridMin + gridRange * ratio;
      textPainter.text = TextSpan(
        text: labelVal.toStringAsFixed(0),
        style: TextStyle(color: CyberTheme.textSecondary, fontSize: 10),
      );
      textPainter.layout(maxWidth: paddingX - 5);
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Map data points
    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final double ratioX = data.length == 1 ? 0.5 : i / (data.length - 1);
      final double x = paddingX + drawWidth * ratioX;
      
      final double val = data[i]['1rm'] as double;
      final double ratioY = gridRange == 0 ? 0.5 : (val - gridMin) / gridRange;
      final double y = paddingY + drawHeight * (1 - ratioY);
      
      points.add(Offset(x, y));
    }

    // Draw area path (gradient under line)
    if (points.isNotEmpty) {
      final areaPath = Path()
        ..moveTo(points.first.dx, paddingY + drawHeight);
      
      for (var p in points) {
        areaPath.lineTo(p.dx, p.dy);
      }
      
      areaPath.lineTo(points.last.dx, paddingY + drawHeight);
      areaPath.close();

      final areaPaint = Paint()
        ..shader = LinearGradient(
          colors: [CyberTheme.cyberTeal.withOpacity(0.4), CyberTheme.cyberTeal.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(paddingX, paddingY, drawWidth, drawHeight));
      
      canvas.drawPath(areaPath, areaPaint);
    }

    // Draw line
    final paintLine = Paint()
      ..color = CyberTheme.cyberTeal
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paintLine);
    }

    // Draw points (glowing dots)
    final paintDot = Paint()..color = CyberTheme.textPrimary;
    final paintDotOuter = Paint()
      ..color = CyberTheme.cyberTeal
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      // Draw glow
      canvas.drawCircle(p, 6.0, paintDotOuter);
      // Draw core
      canvas.drawCircle(p, 3.5, paintDot);

      // Draw X labels (dates)
      if (i == 0 || i == points.length - 1 || (data.length > 2 && i == (data.length / 2).floor())) {
        textPainter.text = TextSpan(
          text: data[i]['date'] as String,
          style: TextStyle(color: CyberTheme.textSecondary, fontSize: 9),
        );
        textPainter.layout();
        canvas.drawText(
          textPainter,
          Offset(p.dx - textPainter.width / 2, paddingY + drawHeight + 5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- 3. Custom Radar Chart (Muscle Volume Distribution) ---
class MuscleRadarChart extends StatelessWidget {
  final Map<String, double> data;

  const MuscleRadarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Check if there is volume logged
    final double totalVolume = data.values.fold(0, (sum, val) => sum + val);
    if (totalVolume == 0) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            "Registra entrenamientos para generar el análisis de volumen",
            style: TextStyle(color: CyberTheme.textSecondary),
          ),
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CustomPaint(
        painter: RadarChartPainter(data: data),
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final Map<String, double> data;

  RadarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) * 0.35;
    final keys = data.keys.toList();
    final int sides = keys.length;
    
    if (sides == 0) return;

    final double maxVal = data.values.reduce(max);
    final double scaleMax = maxVal == 0 ? 100 : maxVal;

    // Draw concentric reference polygons (grid lines)
    final paintGrid = Paint()
      ..color = CyberTheme.borderTranslucent
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final int gridLevels = 3;
    for (int level = 1; level <= gridLevels; level++) {
      final double levelRadius = radius * (level / gridLevels);
      final gridPath = Path();
      
      for (int i = 0; i < sides; i++) {
        final double angle = i * 2 * pi / sides - pi / 2;
        final double x = center.dx + levelRadius * cos(angle);
        final double y = center.dy + levelRadius * sin(angle);
        
        if (i == 0) {
          gridPath.moveTo(x, y);
        } else {
          gridPath.lineTo(x, y);
        }
      }
      gridPath.close();
      canvas.drawPath(gridPath, paintGrid);
    }

    // Draw spokes (lines from center to corners)
    for (int i = 0; i < sides; i++) {
      final double angle = i * 2 * pi / sides - pi / 2;
      final double x = center.dx + radius * cos(angle);
      final double y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), paintGrid);
    }

    // Map and Draw Data Shape
    final dataPath = Path();
    final List<Offset> points = [];

    for (int i = 0; i < sides; i++) {
      final double angle = i * 2 * pi / sides - pi / 2;
      final double val = data[keys[i]] ?? 0.0;
      final double valueRadius = radius * (val / scaleMax);
      final double x = center.dx + valueRadius * cos(angle);
      final double y = center.dy + valueRadius * sin(angle);

      points.add(Offset(x, y));
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    // Fill data shape with glowing rose gradient
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [CyberTheme.neonRose.withOpacity(0.5), CyberTheme.neonRose.withOpacity(0.15)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Draw data outline border
    final outlinePaint = Paint()
      ..color = CyberTheme.neonRose
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(dataPath, outlinePaint);

    // Draw corner markers and labels
    final markerPaint = Paint()..color = CyberTheme.textPrimary;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < sides; i++) {
      final double angle = i * 2 * pi / sides - pi / 2;
      final double labelDistance = radius + 20;
      final double labelX = center.dx + labelDistance * cos(angle);
      final double labelY = center.dy + labelDistance * sin(angle);

      // Draw dot on data point
      if (points.isNotEmpty && (data[keys[i]] ?? 0.0) > 0) {
        canvas.drawCircle(points[i], 3.0, markerPaint);
      }

      // Draw label text
      textPainter.text = TextSpan(
        text: keys[i],
        style: const TextStyle(
          color: CyberTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      
      // Offset text slightly to prevent overlaps
      final double alignmentOffsetX = textPainter.width * (cos(angle) - 1.0) / 2.0;
      final double alignmentOffsetY = textPainter.height * (sin(angle) - 1.0) / 2.0;
      
      canvas.drawText(
        textPainter,
        Offset(labelX + alignmentOffsetX, labelY + alignmentOffsetY),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Extension to allow text painting easily on custom painter canvas
extension CanvasText on Canvas {
  void drawText(TextPainter tp, Offset offset) {
    tp.paint(this, offset);
  }
}
