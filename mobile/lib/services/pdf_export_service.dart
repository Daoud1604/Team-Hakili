import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/motor.dart';
import '../models/telemetry.dart';
import '../repositories/telemetry_repository.dart';
import '../core/constants/app_constants.dart';

class PdfExportResult {
  final Uint8List bytes;
  final String filePath;
  final String fileName;
  final int motorCount;
  final int totalEntries;

  const PdfExportResult({
    required this.bytes,
    required this.filePath,
    required this.fileName,
    required this.motorCount,
    required this.totalEntries,
  });
}

class PdfExportService {
  final TelemetryRepository _telemetryRepository = TelemetryRepository();
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  Future<PdfExportResult?> generateMotorReport({
    required List<Motor> motors,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (motors.isEmpty) return null;

    final document = pw.Document();
    int totalEntries = 0;
    const int maxTelemetryPerMotor = 1000; // Limite stricte par moteur

    // Traiter chaque moteur avec des pauses pour ne pas bloquer l'UI
    for (int i = 0; i < motors.length; i++) {
      final motor = motors[i];
      final motorId = motor.id;
      if (motorId == null) continue;

      // Permettre à l'UI de se rafraîchir entre chaque moteur
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final allTelemetry = await _telemetryRepository.getTelemetryBetween(
        motorId,
        startDate,
        endDate,
      );

      // Limiter drastiquement les données dès le départ
      final telemetry = allTelemetry.length > maxTelemetryPerMotor
          ? [
              ...allTelemetry.take(maxTelemetryPerMotor ~/ 2),
              ...allTelemetry
                  .skip(allTelemetry.length - maxTelemetryPerMotor ~/ 2),
            ]
          : allTelemetry;

      totalEntries += telemetry.length;

      if (telemetry.isEmpty) {
        // Page vide pour ce moteur
        document.addPage(
          pw.MultiPage(
            margin: const pw.EdgeInsets.all(32),
            build: (context) {
              return [
                _buildHeader(motor, startDate, endDate),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Aucune donnée disponible pour cette période.',
                  style: pw.TextStyle(color: PdfColors.grey700),
                ),
              ];
            },
          ),
        );
        continue;
      }

      // Limiter le nombre de points pour les graphiques
      final sampledTelemetry =
          _sampleTelemetry(telemetry, AppConstants.maxPdfChartPoints);

      // Construire la page
      document.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return [
              _buildHeader(motor, startDate, endDate),
              pw.SizedBox(height: 16),
              _buildStatsSection(telemetry),
              pw.SizedBox(height: 16),
              _buildChartsSection(sampledTelemetry),
              pw.SizedBox(height: 16),
              _buildTelemetryTable(telemetry),
            ];
          },
        ),
      );
    }

    if (totalEntries == 0) {
      return null;
    }

    // Pause avant la génération finale pour permettre à l'UI de se rafraîchir
    await Future.delayed(const Duration(milliseconds: 100));

    // Générer le PDF (asynchrone mais optimisé avec les limites de données)
    final bytes = await document.save();

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'motorguard_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    return PdfExportResult(
      bytes: bytes,
      filePath: file.path,
      fileName: fileName,
      motorCount: motors.length,
      totalEntries: totalEntries,
    );
  }

  pw.Widget _buildHeader(
    Motor motor,
    DateTime startDate,
    DateTime endDate,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Rapport MotorGuard',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          '${motor.name} (Code: ${motor.code})',
          style: const pw.TextStyle(fontSize: 16),
        ),
        pw.Text('Localisation : ${motor.location ?? 'Non spécifiée'}'),
        if (motor.description != null) pw.Text(motor.description!),
        pw.SizedBox(height: 12),
        pw.Text(
          'Période analysée : ${_dateTimeFormat.format(startDate)}'
          ' → ${_dateTimeFormat.format(endDate)}',
          style: pw.TextStyle(color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildStatsSection(List<Telemetry> telemetry) {
    final metrics = {
      'Température (°C)': telemetry.map((t) => t.temperature).toList(),
      'Vibration (mm/s)': telemetry.map((t) => t.vibration).toList(),
      'Courant (A)': telemetry.map((t) => t.current).toList(),
      'Vitesse (RPM)': telemetry.map((t) => t.speedRpm).toList(),
    };

    final rows = metrics.entries.map((entry) {
      final stats = _MetricStats.fromValues(entry.value);
      return [
        pw.Text(entry.key),
        pw.Text(stats.min.toStringAsFixed(2)),
        pw.Text(stats.max.toStringAsFixed(2)),
        pw.Text(stats.avg.toStringAsFixed(2)),
      ];
    }).toList();

    final runningTime = telemetry.where((t) => t.isRunning).length;
    final runningPercentage =
        telemetry.isEmpty ? 0 : (runningTime / telemetry.length) * 100;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Statistiques principales',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ['Métrique', 'Min', 'Max', 'Moyenne'],
          data: rows,
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColors.blueGrey800),
          cellAlignment: pw.Alignment.centerLeft,
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellHeight: 22,
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
          },
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Temps de fonctionnement : '
          '${runningTime} lectures (${runningPercentage.toStringAsFixed(1)}%)',
        ),
      ],
    );
  }

  pw.Widget _buildChartsSection(List<Telemetry> telemetry) {
    if (telemetry.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Graphiques',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildLineChart(
              title: 'Température (°C)',
              telemetry: telemetry,
              selector: (t) => t.temperature,
              color: PdfColors.deepOrange,
            ),
            _buildLineChart(
              title: 'Vibration (mm/s)',
              telemetry: telemetry,
              selector: (t) => t.vibration,
              color: PdfColors.green600,
            ),
            _buildLineChart(
              title: 'Courant (A)',
              telemetry: telemetry,
              selector: (t) => t.current,
              color: PdfColors.blueGrey,
            ),
            _buildLineChart(
              title: 'Vitesse (RPM)',
              telemetry: telemetry,
              selector: (t) => t.speedRpm,
              color: PdfColors.indigo,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildLineChart({
    required String title,
    required List<Telemetry> telemetry,
    required double Function(Telemetry telemetry) selector,
    required PdfColor color,
  }) {
    final values = telemetry.map(selector).toList();
    if (values.isEmpty) {
      return pw.Container(
        width: 250,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text('$title\nPas de données disponibles.'),
      );
    }

    final labels = telemetry
        .map((entry) => DateFormat('dd/MM HH:mm').format(entry.createdAt))
        .toList();
    final yAxisValues = _buildYAxisValues(values);

    return pw.Container(
      width: 250,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          pw.SizedBox(
            height: 160,
            child: pw.Chart(
              grid: pw.CartesianGrid(
                xAxis: pw.FixedAxis.fromStrings(
                  labels,
                  marginStart: 10,
                  marginEnd: 10,
                  textStyle: const pw.TextStyle(fontSize: 6),
                  angle: 0.5,
                ),
                yAxis: pw.FixedAxis(
                  yAxisValues,
                  marginStart: 30,
                  textStyle: const pw.TextStyle(fontSize: 6),
                  divisions: true,
                  divisionsColor: PdfColors.grey400,
                  divisionsWidth: 0.2,
                ),
              ),
              datasets: [
                pw.LineDataSet(
                  drawPoints: false,
                  color: color,
                  lineWidth: 2,
                  data: [
                    for (var i = 0; i < values.length; i++)
                      pw.PointChartValue(i.toDouble(), values[i]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTelemetryTable(List<Telemetry> telemetry) {
    // Limiter le nombre de lignes pour éviter le crash
    final maxRows = AppConstants.maxPdfTableRows;
    final limitedTelemetry = telemetry.length > maxRows
        ? [
            ...telemetry.take(maxRows ~/ 2),
            ...telemetry.skip(telemetry.length - maxRows ~/ 2),
          ]
        : telemetry;

    final dataRows = limitedTelemetry.map((entry) {
      return [
        _dateTimeFormat.format(entry.createdAt),
        entry.temperature.toStringAsFixed(1),
        entry.vibration.toStringAsFixed(2),
        entry.current.toStringAsFixed(2),
        entry.speedRpm.toStringAsFixed(0),
        entry.isRunning ? 'Oui' : 'Non',
      ];
    }).toList();

    // Ajouter une note si des données ont été tronquées
    if (telemetry.length > maxRows) {
      dataRows.insert(
        maxRows ~/ 2,
        [
          '... (${telemetry.length - maxRows} entrées omises) ...',
          '',
          '',
          '',
          '',
          '',
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Historique des mesures',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const [
            'Date/Heure',
            'Temp (°C)',
            'Vibr (mm/s)',
            'Courant (A)',
            'RPM',
            'En marche',
          ],
          data: dataRows,
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColors.blueGrey700),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellHeight: 20,
          columnWidths: {
            0: const pw.FlexColumnWidth(2.2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(0.8),
          },
        ),
      ],
    );
  }

  List<Telemetry> _sampleTelemetry(List<Telemetry> source, int maxPoints) {
    if (source.length <= maxPoints) return source;
    final step = (source.length / maxPoints).ceil();
    final sampled = <Telemetry>[];
    for (var i = 0; i < source.length; i += step) {
      sampled.add(source[i]);
    }
    if (sampled.last != source.last) {
      sampled.add(source.last);
    }
    return sampled;
  }

  List<double> _buildYAxisValues(List<double> values) {
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = (maxValue - minValue).abs();
    if (range == 0) {
      return List<double>.generate(5, (index) => minValue + index.toDouble());
    }
    final step = range / 4;
    return List<double>.generate(5, (index) => minValue + (step * index));
  }
}

class _MetricStats {
  final double min;
  final double max;
  final double avg;

  const _MetricStats({
    required this.min,
    required this.max,
    required this.avg,
  });

  factory _MetricStats.fromValues(List<double> values) {
    if (values.isEmpty) {
      return const _MetricStats(min: 0, max: 0, avg: 0);
    }
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final avgValue = values.reduce((a, b) => a + b) / values.length;
    return _MetricStats(min: minValue, max: maxValue, avg: avgValue);
  }
}
