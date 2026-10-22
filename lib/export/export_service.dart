import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum PdfExportChartKind {
  pie,
  line,
  verticalBars,
}

class PdfExportPoint {
  final String label;
  final double value;
  final String? note;

  const PdfExportPoint({
    required this.label,
    required this.value,
    this.note,
  });
}

class PdfExportEntry {
  final String title;
  final String? subtitle;
  final List<String> lines;

  const PdfExportEntry({
    required this.title,
    this.subtitle,
    this.lines = const <String>[],
  });
}

class PdfExportSection {
  final String title;
  final String? intro;
  final String? chartTitle;
  final PdfExportChartKind? chartKind;
  final List<PdfExportPoint> chartPoints;
  final List<String> bullets;
  final List<PdfExportEntry> entries;
  final String? emptyMessage;

  const PdfExportSection({
    required this.title,
    this.intro,
    this.chartTitle,
    this.chartKind,
    this.chartPoints = const <PdfExportPoint>[],
    this.bullets = const <String>[],
    this.entries = const <PdfExportEntry>[],
    this.emptyMessage,
  });
}

class PdfExportDocumentData {
  final String appName;
  final Uint8List? appIconBytes;
  final String? appIconSvg;
  final String title;
  final String subtitle;
  final String generatedAtLabel;
  final String rangeLabel;
  final List<PdfExportSection> sections;

  const PdfExportDocumentData({
    required this.appName,
    this.appIconBytes,
    this.appIconSvg,
    required this.title,
    required this.subtitle,
    required this.generatedAtLabel,
    required this.rangeLabel,
    required this.sections,
  });
}

class PdfExportService {
  static const String _fontRegularAsset = 'assets/fonts/NotoSans-Regular.ttf';
  static const String _fontBoldAsset = 'assets/fonts/NotoSans-Bold.ttf';

  static Future<pw.Font> _loadPdfFont(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return pw.Font.ttf(data);
  }

  static Future<Uint8List> buildReport(PdfExportDocumentData data) async {
    final baseFont = await _loadPdfFont(_fontRegularAsset);
    final boldFont = await _loadPdfFont(_fontBoldAsset);
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
          theme: pw.ThemeData.withFont(
            base: baseFont,
            bold: boldFont,
          ),
        ),
        build: (context) {
          return <pw.Widget>[
            _header(
              data.appName,
              data.title,
              data.subtitle,
              data.appIconBytes,
              data.appIconSvg,
              baseFont,
              boldFont,
            ),
            pw.SizedBox(height: 12),
            _metaBox(
              data.generatedAtLabel,
              data.rangeLabel,
              baseFont,
            ),
            pw.SizedBox(height: 18),
            ...data.sections.expand((s) => _buildSection(s, baseFont, boldFont)),
          ];
        },
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(
              font: baseFont,
              fontSize: 10,
              color: PdfColors.blueGrey400,
            ),
          ),
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(
    String appName,
    String title,
    String subtitle,
    Uint8List? appIconBytes,
    String? appIconSvg,
    pw.Font baseFont,
    pw.Font boldFont,
  ) {
    final svg = appIconSvg?.trim();
    final hasSvg = svg != null && svg.isNotEmpty;
    pw.MemoryImage? raster;
    if (!hasSvg) {
      final bytes = appIconBytes;
      if (bytes != null) {
        raster = pw.MemoryImage(bytes);
      }
    }
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.indigo100),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (hasSvg)
            pw.Container(
              width: 44,
              height: 44,
              margin: const pw.EdgeInsets.only(right: 12),
              child: pw.ClipRRect(
                horizontalRadius: 10,
                verticalRadius: 10,
                child: pw.SvgImage(svg: svg, fit: pw.BoxFit.cover),
              ),
            )
          else if (raster != null)
            pw.Container(
              width: 44,
              height: 44,
              margin: const pw.EdgeInsets.only(right: 12),
              child: pw.ClipRRect(
                horizontalRadius: 10,
                verticalRadius: 10,
                child: pw.Image(raster, fit: pw.BoxFit.cover),
              ),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  appName,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 11,
                    color: PdfColors.indigo700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 20,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  subtitle,
                  style: pw.TextStyle(
                    font: baseFont,
                    fontSize: 10.5,
                    color: PdfColors.blueGrey700,
                    lineSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _metaBox(String generatedAtLabel, String rangeLabel, pw.Font baseFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blueGrey100),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            generatedAtLabel,
            style: pw.TextStyle(font: baseFont, fontSize: 11, color: PdfColors.blueGrey800),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            rangeLabel,
            style: pw.TextStyle(font: baseFont, fontSize: 11, color: PdfColors.blueGrey800),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildSection(PdfExportSection section, pw.Font baseFont, pw.Font boldFont) {
    final content = <pw.Widget>[
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pw.BoxDecoration(
          color: PdfColors.indigo50,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          section.title,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 15,
            color: PdfColors.indigo700,
          ),
        ),
      ),
      pw.SizedBox(height: 10),
    ];

    if (section.intro != null && section.intro!.trim().isNotEmpty) {
      content.add(
        pw.Text(
          section.intro!,
          style: pw.TextStyle(font: baseFont, fontSize: 11, lineSpacing: 2),
        ),
      );
      content.add(pw.SizedBox(height: 10));
    }

    if (section.chartKind != null && section.chartPoints.isNotEmpty) {
      if (section.chartTitle != null && section.chartTitle!.trim().isNotEmpty) {
        content.add(
          pw.Text(
            section.chartTitle!,
            style: pw.TextStyle(font: boldFont, fontSize: 12),
          ),
        );
        content.add(pw.SizedBox(height: 8));
      }
      content.add(
        switch (section.chartKind!) {
          PdfExportChartKind.pie => _pieChartWithLegend(section.chartPoints, baseFont),
          PdfExportChartKind.line => _lineChart(section.chartPoints, baseFont),
          PdfExportChartKind.verticalBars => _verticalBarChart(section.chartPoints, baseFont),
        },
      );
      content.add(pw.SizedBox(height: 12));
    }

    if (section.bullets.isNotEmpty) {
      content.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: section.bullets
              .map(
                (line) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: pw.TextStyle(font: baseFont, fontSize: 11)),
                      pw.Expanded(
                        child: pw.Text(
                          line,
                          style: pw.TextStyle(font: baseFont, fontSize: 11, lineSpacing: 2),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      );
      content.add(pw.SizedBox(height: 8));
    }

    if (section.entries.isNotEmpty) {
      content.add(
        pw.Column(
          children: section.entries.map((e) => _entryCard(e, baseFont, boldFont)).toList(),
        ),
      );
    } else if (section.emptyMessage != null && section.emptyMessage!.trim().isNotEmpty) {
      content.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blueGrey100),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            section.emptyMessage!,
            style: pw.TextStyle(font: baseFont, fontSize: 11, color: PdfColors.blueGrey700),
          ),
        ),
      );
    }

    content.add(pw.SizedBox(height: 16));
    return content;
  }

  static pw.Widget _entryCard(PdfExportEntry entry, pw.Font baseFont, pw.Font boldFont) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey100),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            entry.title,
            style: pw.TextStyle(font: boldFont, fontSize: 11.5),
          ),
          if (entry.subtitle != null && entry.subtitle!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              entry.subtitle!,
              style: pw.TextStyle(font: baseFont, fontSize: 10.5, color: PdfColors.indigo700),
            ),
          ],
          if (entry.lines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            ...entry.lines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  line,
                  style: pw.TextStyle(font: baseFont, fontSize: 10.5, lineSpacing: 1.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _pieChartWithLegend(List<PdfExportPoint> points, pw.Font baseFont) {
    final visible = _limitPoints(points, maxPoints: 8);
    final svg = _pieChartSvg(visible);
    return pw.Container(
      constraints: const pw.BoxConstraints(maxHeight: 220),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 180,
            height: 180,
            alignment: pw.Alignment.center,
            child: pw.SvgImage(svg: svg),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: List.generate(visible.length, (index) {
                final point = visible[index];
                final color = _chartPalette[index % _chartPalette.length];
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 10,
                        height: 10,
                        margin: const pw.EdgeInsets.only(top: 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex(color),
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(
                          point.note == null || point.note!.trim().isEmpty
                              ? point.label
                              : '${point.label} (${point.note})',
                          style: pw.TextStyle(font: baseFont, fontSize: 9.5, lineSpacing: 1.6),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _lineChart(List<PdfExportPoint> points, pw.Font baseFont) {
    final visible = _limitPoints(points, maxPoints: 16);
    const double chartTotalH = 160;
    const double padTop = 10;
    const double padBottom = 8;
    final double plotH = chartTotalH - padTop - padBottom;
    final yMax = _chartAxisMax(visible);

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.SizedBox(
            height: chartTotalH,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _yAxisScaleColumn(
                  yMax: yMax,
                  plotHeight: plotH,
                  padTop: padTop,
                  padBottom: padBottom,
                  baseFont: baseFont,
                  width: 40,
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.SvgImage(svg: _lineChartSvg(visible, yMax: yMax)),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: visible
                .map(
                  (point) => pw.Expanded(
                    child: pw.Text(
                      point.label,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: baseFont,
                        fontSize: 8,
                        color: PdfColors.blueGrey700,
                      ),
                      maxLines: 2,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _verticalBarChart(List<PdfExportPoint> points, pw.Font baseFont) {
    final visible = _limitPoints(points, maxPoints: 18);
    final yMax = _chartAxisMax(visible);
    const double plotH = 88;
    const double padTop = 6;
    const double padBottom = 6;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.SizedBox(
            height: plotH + padTop + padBottom,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _yAxisScaleColumn(
                  yMax: yMax,
                  plotHeight: plotH,
                  padTop: padTop,
                  padBottom: padBottom,
                  baseFont: baseFont,
                  width: 40,
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Stack(
                    alignment: pw.Alignment.bottomCenter,
                    children: [
                      pw.Positioned(
                        top: padTop,
                        bottom: padBottom,
                        left: 0,
                        right: 0,
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: PdfColors.blueGrey300, width: 1.2),
                          ),
                          child: pw.Column(
                            children: List.generate(5, (row) {
                              final isLast = row == 4;
                              return pw.Expanded(
                                child: pw.Container(
                                  decoration: pw.BoxDecoration(
                                    border: isLast
                                        ? null
                                        : pw.Border(
                                            bottom: pw.BorderSide(
                                              color: PdfColors.blueGrey200,
                                              width: 0.75,
                                            ),
                                          ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      pw.Positioned(
                        top: padTop,
                        bottom: padBottom,
                        left: 0,
                        right: 0,
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: visible
                              .map(
                                (point) => pw.Expanded(
                                  child: pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                                    child: pw.Container(
                                      height: (point.value / yMax) * (plotH - 8) + 6,
                                      decoration: pw.BoxDecoration(
                                        color: PdfColors.indigo300,
                                        borderRadius: const pw.BorderRadius.vertical(
                                          top: pw.Radius.circular(5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: visible
                .map(
                  (point) => pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                      child: pw.Text(
                        point.label,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: baseFont,
                          fontSize: 7.5,
                          color: PdfColors.blueGrey700,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  static String _formatAxisTick(double v) {
    if (v.isNaN || v.isInfinite) return '0';
    final r = v.roundToDouble();
    if ((v - r).abs() < 1e-6) return r.toInt().toString();
    return v.toStringAsFixed(1);
  }

  /// Верхняя граница шкалы Y: чуть выше максимума данных, «ровное» число.
  static double _chartAxisMax(List<PdfExportPoint> points) {
    final m = points.fold<double>(0, (a, e) => e.value > a ? e.value : a);
    if (m <= 0) return 1;
    if (m <= 1) return 1;
    if (m <= 5) return 5;
    if (m <= 10) return 10;
    final log10 = math.log(m) / math.ln10;
    final pow10 = math.pow(10, log10.floor()).toDouble();
    final n = m / pow10;
    final f = n <= 1
        ? 1.0
        : n <= 2
            ? 2.0
            : n <= 5
                ? 5.0
                : 10.0;
    var cap = f * pow10;
    while (cap < m) {
      cap *= 1.25;
    }
    return cap;
  }

  /// Левая колонка с числовой шкалой (подсветка рамкой и фоном).
  static pw.Widget _yAxisScaleColumn({
    required double yMax,
    required double plotHeight,
    required double padTop,
    required double padBottom,
    required pw.Font baseFont,
    required double width,
  }) {
    const tickSteps = 4;
    return pw.SizedBox(
      width: width,
      child: pw.Column(
        children: [
          pw.SizedBox(height: padTop),
          pw.Container(
            height: plotHeight,
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.blueGrey400, width: 1.2),
            ),
            padding: const pw.EdgeInsets.only(right: 5, left: 4),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: List.generate(tickSteps + 1, (i) {
                final tick = yMax * (tickSteps - i) / tickSteps;
                return pw.Text(
                  _formatAxisTick(tick),
                  style: pw.TextStyle(
                    font: baseFont,
                    fontSize: 7.5,
                    color: PdfColors.blueGrey900,
                  ),
                );
              }),
            ),
          ),
          pw.SizedBox(height: padBottom),
        ],
      ),
    );
  }

  static List<PdfExportPoint> _limitPoints(List<PdfExportPoint> points, {required int maxPoints}) {
    if (points.length <= maxPoints) return points;
    final out = <PdfExportPoint>[];
    final step = (points.length - 1) / (maxPoints - 1);
    for (var i = 0; i < maxPoints; i++) {
      out.add(points[(i * step).round()]);
    }
    return out;
  }

  static const List<String> _chartPalette = <String>[
    '#5C6BC0',
    '#26A69A',
    '#FFB300',
    '#EF5350',
    '#8E24AA',
    '#29B6F6',
    '#9CCC65',
    '#FF7043',
  ];

  static String _pieChartSvg(List<PdfExportPoint> points) {
    const size = 180.0;
    const cx = 90.0;
    const cy = 90.0;
    const r = 72.0;
    final total = points.fold<double>(0, (sum, e) => sum + e.value);
    if (total <= 0) {
      return '''
<svg xmlns="http://www.w3.org/2000/svg" width="$size" height="$size" viewBox="0 0 $size $size">
  <circle cx="$cx" cy="$cy" r="$r" fill="#E8EAF6" />
</svg>
''';
    }
    if (points.length == 1) {
      final fill = _chartPalette.first;
      return '''
<svg xmlns="http://www.w3.org/2000/svg" width="$size" height="$size" viewBox="0 0 $size $size">
  <circle cx="$cx" cy="$cy" r="$r" fill="$fill" />
</svg>
''';
    }

    final buffer = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$size" height="$size" viewBox="0 0 $size $size">',
    );
    var startAngle = -math.pi / 2;
    for (var i = 0; i < points.length; i++) {
      final sweep = (points[i].value / total) * math.pi * 2;
      final endAngle = startAngle + sweep;
      final start = _polar(cx, cy, r, startAngle);
      final end = _polar(cx, cy, r, endAngle);
      final largeArc = sweep > math.pi ? 1 : 0;
      final color = _chartPalette[i % _chartPalette.length];
      buffer.write(
        '<path d="M $cx $cy L ${start.$1} ${start.$2} A $r $r 0 $largeArc 1 ${end.$1} ${end.$2} Z" fill="$color" />',
      );
      startAngle = endAngle;
    }
    buffer.write('<circle cx="$cx" cy="$cy" r="30" fill="#FFFFFF" />');
    buffer.write('</svg>');
    return buffer.toString();
  }

  static String _lineChartSvg(List<PdfExportPoint> points, {required double yMax}) {
    const width = 360.0;
    const height = 160.0;
    const left = 10.0;
    const right = 10.0;
    const top = 10.0;
    const bottom = 8.0;
    final plotWidth = width - left - right;
    final plotHeight = height - top - bottom;
    final safeMaxY = yMax <= 0 ? 1.0 : yMax;
    final denom = points.length <= 1 ? 1.0 : (points.length - 1).toDouble();
    final coords = <(double, double)>[];
    for (var i = 0; i < points.length; i++) {
      final x = left + (plotWidth * i / denom);
      final y = top + plotHeight - ((points[i].value / safeMaxY) * plotHeight);
      coords.add((x, y));
    }
    final path = coords.isEmpty
        ? ''
        : coords
            .mapIndexed((index, p) => '${index == 0 ? 'M' : 'L'} ${p.$1.toStringAsFixed(1)} ${p.$2.toStringAsFixed(1)}')
            .join(' ');

    final buffer = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">',
    );
    buffer.write('<rect x="0" y="0" width="$width" height="$height" fill="#FFFFFF" rx="6" stroke="#94A3B8" stroke-width="1.2" />');
    for (var i = 0; i <= 4; i++) {
      final y = top + (plotHeight * i / 4);
      buffer.write(
        '<line x1="$left" y1="$y" x2="${width - right}" y2="$y" stroke="#CBD5E1" stroke-width="1" />',
      );
    }
    buffer.write('<line x1="$left" y1="$top" x2="$left" y2="${height - bottom}" stroke="#64748B" stroke-width="1.4" />');
    buffer.write('<line x1="$left" y1="${height - bottom}" x2="${width - right}" y2="${height - bottom}" stroke="#64748B" stroke-width="1.4" />');
    if (path.isNotEmpty) {
      buffer.write('<path d="$path" fill="none" stroke="#5C6BC0" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />');
      for (var i = 0; i < coords.length; i++) {
        buffer.write('<circle cx="${coords[i].$1.toStringAsFixed(1)}" cy="${coords[i].$2.toStringAsFixed(1)}" r="3.5" fill="#5C6BC0" />');
      }
    }
    buffer.write('</svg>');
    return buffer.toString();
  }

  static (double, double) _polar(double cx, double cy, double r, double angle) {
    final x = cx + r * math.cos(angle);
    final y = cy + r * math.sin(angle);
    return (x, y);
  }
}

extension on Iterable<dynamic> {
  Iterable<T> mapIndexed<T>(T Function(int index, dynamic item) transform) sync* {
    var index = 0;
    for (final item in this) {
      yield transform(index, item);
      index++;
    }
  }
}
