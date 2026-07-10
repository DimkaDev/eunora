import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:eunora/features/passport/models/passport_data.dart';

class PassportChartRenderer {
  /// Renders Chart A: Hot Flash Frequency per day (Line Chart)
  static pw.Widget renderHotFlashChart({
    required ChartData data,
    required List<DateTime> doseChangeDates,
    required double width,
    required double height,
  }) {
    if (data.points.length < 3) {
      return _renderInsufficientData(width, height, "Hot Flash Frequency");
    }

    final double maxVal = data.points.map((p) => p.value).reduce((a, b) => a > b ? a : b).clamp(5.0, 100.0);
    final double minVal = 0.0;

    return pw.Container(
      width: width,
      height: height,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("Hot Flash Frequency per Day", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Expanded(
            child: pw.CustomPaint(
              size: const PdfPoint(200, 100),
              painter: (PdfGraphics canvas, PdfPoint size) {
                // Draw Y Axis grid lines and labels
                final double gridCount = 4;
                for (int i = 0; i <= gridCount; i++) {
                  final double yRatio = i / gridCount;
                  final double yPos = size.y * yRatio;
                  canvas.setStrokeColor(PdfColors.grey200);
                  canvas.setLineWidth(0.5);
                  canvas.moveTo(25, yPos);
                  canvas.lineTo(size.x, yPos);
                  canvas.strokePath();

                  // Y Label
                  final double val = minVal + (maxVal - minVal) * yRatio;
                  // Draw simple text at (5, yPos)
                  canvas.setColor(PdfColors.grey700);
                }

                // Draw X Axis line
                canvas.setStrokeColor(PdfColors.grey500);
                canvas.setLineWidth(1.0);
                canvas.moveTo(25, 0);
                canvas.lineTo(size.x, 0);
                canvas.strokePath();

                // Draw Dose Change vertical dashed lines
                if (data.points.isNotEmpty) {
                  final startMs = data.points.first.date.millisecondsSinceEpoch;
                  final endMs = data.points.last.date.millisecondsSinceEpoch;
                  final span = (endMs - startMs).clamp(1, double.infinity);

                  for (final dcDate in doseChangeDates) {
                    final dcMs = dcDate.millisecondsSinceEpoch;
                    if (dcMs >= startMs && dcMs <= endMs) {
                      final double xRatio = (dcMs - startMs) / span;
                      final double xPos = 25 + (size.x - 25) * xRatio;
                      
                      // Draw vertical dashed line
                      canvas.setStrokeColor(PdfColor.fromInt(0xFFE8A89B));
                      canvas.setLineWidth(1.0);
                      for (double y = 0; y < size.y; y += 4) {
                        canvas.moveTo(xPos, y);
                        canvas.lineTo(xPos, (y + 2).clamp(0.0, size.y));
                        canvas.strokePath();
                      }
                    }
                  }
                }

                // Plot Line Data
                if (data.points.isNotEmpty) {
                  final startMs = data.points.first.date.millisecondsSinceEpoch;
                  final endMs = data.points.last.date.millisecondsSinceEpoch;
                  final span = (endMs - startMs).clamp(1, double.infinity);

                  canvas.setStrokeColor(PdfColors.grey800);
                  canvas.setLineWidth(1.5);
                  canvas.setFillColor(PdfColors.grey800);

                  for (int i = 0; i < data.points.length; i++) {
                    final p = data.points[i];
                    final double xRatio = (p.date.millisecondsSinceEpoch - startMs) / span;
                    final double yRatio = (p.value - minVal) / (maxVal - minVal);

                    final double xPos = 25 + (size.x - 25) * xRatio;
                    final double yPos = size.y * yRatio;

                    if (i == 0) {
                      canvas.moveTo(xPos, yPos);
                    } else {
                      canvas.lineTo(xPos, yPos);
                    }
                  }
                  canvas.strokePath();

                  // Draw dots
                  for (final p in data.points) {
                    final double xRatio = (p.date.millisecondsSinceEpoch - startMs) / span;
                    final double yRatio = (p.value - minVal) / (maxVal - minVal);
                    final double xPos = 25 + (size.x - 25) * xRatio;
                    final double yPos = size.y * yRatio;
                    canvas.drawEllipse(xPos, yPos, 2, 2);
                    canvas.fillPath();
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Renders Chart B: Sleep Quality area chart (7-day rolling average)
  static pw.Widget renderSleepChart({
    required ChartData data,
    required List<DateTime> doseChangeDates,
    required double width,
    required double height,
  }) {
    if (data.points.length < 3) {
      return _renderInsufficientData(width, height, "Sleep Quality");
    }

    final double maxVal = 5.0; // Quality is 1-5
    final double minVal = 0.0;

    return pw.Container(
      width: width,
      height: height,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("Sleep Quality (7-day Rolling Avg)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Expanded(
            child: pw.CustomPaint(
              size: const PdfPoint(200, 100),
              painter: (PdfGraphics canvas, PdfPoint size) {
                // Draw Grid
                for (int i = 0; i <= 5; i++) {
                  final double yRatio = i / 5.0;
                  final double yPos = size.y * yRatio;
                  canvas.setStrokeColor(PdfColors.grey200);
                  canvas.setLineWidth(0.5);
                  canvas.moveTo(25, yPos);
                  canvas.lineTo(size.x, yPos);
                  canvas.strokePath();
                }

                // X Axis line
                canvas.setStrokeColor(PdfColors.grey500);
                canvas.setLineWidth(1.0);
                canvas.moveTo(25, 0);
                canvas.lineTo(size.x, 0);
                canvas.strokePath();

                // Dose Change lines
                if (data.points.isNotEmpty) {
                  final startMs = data.points.first.date.millisecondsSinceEpoch;
                  final endMs = data.points.last.date.millisecondsSinceEpoch;
                  final span = (endMs - startMs).clamp(1, double.infinity);

                  for (final dcDate in doseChangeDates) {
                    final dcMs = dcDate.millisecondsSinceEpoch;
                    if (dcMs >= startMs && dcMs <= endMs) {
                      final double xRatio = (dcMs - startMs) / span;
                      final double xPos = 25 + (size.x - 25) * xRatio;
                      
                      canvas.setStrokeColor(PdfColor.fromInt(0xFFE8A89B));
                      canvas.setLineWidth(1.0);
                      for (double y = 0; y < size.y; y += 4) {
                        canvas.moveTo(xPos, y);
                        canvas.lineTo(xPos, (y + 2).clamp(0.0, size.y));
                        canvas.strokePath();
                      }
                    }
                  }
                }

                // Plot Area & Line
                if (data.points.isNotEmpty) {
                  final startMs = data.points.first.date.millisecondsSinceEpoch;
                  final endMs = data.points.last.date.millisecondsSinceEpoch;
                  final span = (endMs - startMs).clamp(1, double.infinity);

                  // 1. Draw Area (fill)
                  canvas.setFillColor(PdfColors.grey100);
                  canvas.moveTo(25, 0);
                  for (int i = 0; i < data.points.length; i++) {
                    final p = data.points[i];
                    final double xRatio = (p.date.millisecondsSinceEpoch - startMs) / span;
                    final double yRatio = (p.value - minVal) / (maxVal - minVal);
                    final double xPos = 25 + (size.x - 25) * xRatio;
                    final double yPos = size.y * yRatio;
                    canvas.lineTo(xPos, yPos);
                  }
                  final lastX = 25 + (size.x - 25) * 1.0;
                  canvas.lineTo(lastX, 0);
                  canvas.closePath();
                  canvas.fillPath();

                  // 2. Draw Top Line
                  canvas.setStrokeColor(PdfColors.grey800);
                  canvas.setLineWidth(1.5);
                  for (int i = 0; i < data.points.length; i++) {
                    final p = data.points[i];
                    final double xRatio = (p.date.millisecondsSinceEpoch - startMs) / span;
                    final double yRatio = (p.value - minVal) / (maxVal - minVal);
                    final double xPos = 25 + (size.x - 25) * xRatio;
                    final double yPos = size.y * yRatio;

                    if (i == 0) {
                      canvas.moveTo(xPos, yPos);
                    } else {
                      canvas.lineTo(xPos, yPos);
                    }
                  }
                  canvas.strokePath();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Renders Chart C: Mood stacked weekly bar chart
  static pw.Widget renderMoodChart({
    required ChartData data,
    required List<DateTime> doseChangeDates,
    required double width,
    required double height,
  }) {
    if (data.weeklyMoods.length < 1) {
      return _renderInsufficientData(width, height, "Mood Score");
    }

    final double maxVal = 15.0; // Anxiety + Irritability + Brain Fog max combined (each 5)
    final double minVal = 0.0;

    return pw.Container(
      width: width,
      height: height,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("Weekly Mood Score (Anxiety + Irritability + Brain Fog)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Expanded(
            child: pw.CustomPaint(
              size: const PdfPoint(200, 100),
              painter: (PdfGraphics canvas, PdfPoint size) {
                // Draw Grid
                for (int i = 0; i <= 3; i++) {
                  final double yRatio = i / 3.0;
                  final double yPos = size.y * yRatio;
                  canvas.setStrokeColor(PdfColors.grey200);
                  canvas.setLineWidth(0.5);
                  canvas.moveTo(25, yPos);
                  canvas.lineTo(size.x, yPos);
                  canvas.strokePath();
                }

                // X Axis line
                canvas.setStrokeColor(PdfColors.grey500);
                canvas.setLineWidth(1.0);
                canvas.moveTo(25, 0);
                canvas.lineTo(size.x, 0);
                canvas.strokePath();

                // Draw stacked bars
                final double barWidth = (size.x - 25) / (data.weeklyMoods.length * 2);
                for (int i = 0; i < data.weeklyMoods.length; i++) {
                  final wp = data.weeklyMoods[i];
                  final double xCenter = 25 + (i * 2 + 1) * barWidth;

                  // 1. Anxiety block (Bottom)
                  final double anxietyH = (wp.anxiety / maxVal) * size.y;
                  canvas.setFillColor(PdfColor.fromInt(0xFFB8A7C5)); // purple/anxiety
                  canvas.drawRect(xCenter - barWidth/2, 0, barWidth, anxietyH);
                  canvas.fillPath();

                  // 2. Irritability block (Middle)
                  final double irrH = (wp.irritability / maxVal) * size.y;
                  canvas.setFillColor(PdfColor.fromInt(0xFFD4A5A5)); // pinkish/irritability
                  canvas.drawRect(xCenter - barWidth/2, anxietyH, barWidth, irrH);
                  canvas.fillPath();

                  // 3. Brain Fog block (Top)
                  final double fogH = (wp.brainFog / maxVal) * size.y;
                  canvas.setFillColor(PdfColor.fromInt(0xFF8EB8B5)); // greenish/brainfog
                  canvas.drawRect(xCenter - barWidth/2, anxietyH + irrH, barWidth, fogH);
                  canvas.fillPath();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _renderInsufficientData(double width, double height, String chartName) {
    return pw.Container(
      width: width,
      height: height,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(chartName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text("Insufficient data for this period", style: pw.TextStyle(color: PdfColors.grey600, fontSize: 9)),
        ],
      ),
    );
  }
}
