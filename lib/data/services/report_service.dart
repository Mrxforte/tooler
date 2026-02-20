// ignore_for_file: unused_import, unused_element

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/tool.dart';
import '../models/construction_object.dart';
// import '../models/salary.dart'; // Commented out - model doesn't exist
import '../../core/utils/error_handler.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/tools_provider.dart';
import '../../viewmodels/objects_provider.dart';

enum ReportType { pdf, text, screenshot }

/// Service for generating and sharing reports
/// FULL IMPLEMENTATION: Extract the complete ReportService class from main.dart (lines ~1147-2006)
/// This includes PDF generation with Cyrillic support, tool reports, object reports,
/// inventory reports, worker reports, and sharing functionality.
class ReportService {
  static Future<pw.Font> _loadFont() async {
    final fontData = await rootBundle.load('assets/fonts/robo.ttf');
    return pw.Font.ttf(fontData);
  }

  static String _iconToString(IconData icon) {
    if (icon == Icons.build) return '🔧';
    if (icon == Icons.location_city) return '🏢';
    if (icon == Icons.inventory) return '📦';
    if (icon == Icons.list) return '📋';
    if (icon == Icons.favorite) return '⭐';
    if (icon == Icons.history) return '📜';
    if (icon == Icons.garage) return '🏠';
    return '•';
  }

  /// Filter out consecutive duplicate location history entries
  /// Only shows unique locations in sequence (no "moved to existing location")
  static List<LocationHistory> _filterDuplicateLocations(List<LocationHistory> history) {
    if (history.isEmpty) return history;
    
    final filtered = <LocationHistory>[history.first];
    for (int i = 1; i < history.length; i++) {
      if (history[i].locationId != history[i - 1].locationId) {
        filtered.add(history[i]);
      }
    }
    return filtered;
  }

  static Future<Uint8List> _generateToolReportPdf(Tool tool) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final primaryColor = PdfColors.blue700;
    final font = await _loadFont();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ОТЧЕТ ОБ ИНСТРУМЕНТЕ',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: font)),
                  if (tool.isFavorite)
                    pw.Text('В ИЗБРАННОМ',
                        style: pw.TextStyle(
                            fontSize: 12, color: PdfColors.white, font: font)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Tool Details
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(tool.title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: font)),
                  pw.SizedBox(height: 12),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  _buildPdfRow('Бренд:', tool.brand, font),
                  pw.SizedBox(height: 6),
                  _buildPdfRow('Уникальный ID:', tool.uniqueId, font),
                  pw.SizedBox(height: 6),
                  _buildPdfRow('Описание:', tool.description.isNotEmpty ? tool.description : 'Не указано', font),
                  pw.SizedBox(height: 6),
                  _buildPdfRow('Текущее местоположение:', tool.currentLocationName, font),
                  pw.SizedBox(height: 6),
                  _buildPdfRow('Статус:', tool.isFavorite ? 'В избранном' : 'В наличии', font),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // Timeline
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ХРОНОЛОГИЯ', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: font)),
                  pw.SizedBox(height: 8),
                  _buildPdfRow('Дата добавления:', DateFormat('dd.MM.yyyy').format(tool.createdAt), font),
                  pw.SizedBox(height: 4),
                  _buildPdfRow('Последнее обновление:', DateFormat('dd.MM.yyyy HH:mm').format(tool.updatedAt), font),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // Location History
            if (tool.locationHistory.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text('ИСТОРИЯ ПЕРЕМЕЩЕНИЙ', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: font)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.blue300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.center,
                        child: pw.Text('№', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Местоположение', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Дата', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, font: font)),
                      ),
                    ],
                  ),
                  // Data Rows - Filter out consecutive duplicate locations
                  ..._filterDuplicateLocations(tool.locationHistory).reversed.take(15).toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final loc = entry.value;
                    return pw.TableRow(
                      decoration: idx % 2 == 0 ? pw.BoxDecoration(color: PdfColors.grey50) : null,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          alignment: pw.Alignment.center,
                          child: pw.Text('${idx + 1}', style: pw.TextStyle(fontSize: 8, font: font)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(loc.locationName, style: pw.TextStyle(fontSize: 8, font: font)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(DateFormat('dd.MM.yyyy HH:mm').format(loc.date), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, font: font)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              if (tool.locationHistory.length > 15)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 6),
                  child: pw.Text('... и еще ${tool.locationHistory.length - 15} перемещений', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, font: font, fontStyle: pw.FontStyle.italic)),
                ),
            ],
            
            pw.Spacer(),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Отчет сгенерирован: ${dateFormat.format(DateTime.now())}', 
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, font: font)),
                pw.Text('© Tooler App', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, font: font)),
              ],
            ),
          ],
        );
      },
    ));
    return await pdf.save();
  }

  static pw.Widget _buildPdfRow(String label, String value, pw.Font font) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 150,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, font: font)),
        ),
        pw.Expanded(
          child: pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: font)),
        ),
      ],
    );
  }

  static String _generateToolReportText(Tool tool) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final sb = StringBuffer();
    
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('🔧 ОТЧЕТ ОБ ИНСТРУМЕНТЕ');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln();
    
    // Main info
    sb.writeln('📌 ОСНОВНАЯ ИНФОРМАЦИЯ:');
    sb.writeln('─────────────────────');
    sb.writeln('• Название: ${tool.title}');
    sb.writeln('• Бренд: ${tool.brand}');
    sb.writeln('• ID: ${tool.uniqueId}');
    sb.writeln('• Описание: ${tool.description.isNotEmpty ? tool.description : 'Не указано'}');
    sb.writeln();
    
    // Location
    sb.writeln('📍 МЕСТОПОЛОЖЕНИЕ:');
    sb.writeln('─────────────────────');
    sb.writeln('• Текущее: ${tool.currentLocationName}');
    sb.writeln('• Статус: ${tool.isFavorite ? '⭐ В избранном' : '📦 В наличии'}');
    sb.writeln();
    
    // Timeline
    sb.writeln('📅 ХРОНОЛОГИЯ:');
    sb.writeln('─────────────────────');
    sb.writeln('• Дата добавления: ${DateFormat('dd.MM.yyyy').format(tool.createdAt)}');
    sb.writeln('• Последнее обновление: ${DateFormat('dd.MM.yyyy HH:mm').format(tool.updatedAt)}');
    sb.writeln();
    
    // Location history
    if (tool.locationHistory.isNotEmpty) {
      sb.writeln('📜 ИСТОРИЯ ПЕРЕМЕЩЕНИЙ:');
      sb.writeln('─────────────────────');
      final filteredHistory = _filterDuplicateLocations(tool.locationHistory);
      final recentHistory = filteredHistory.reversed.take(10).toList();
      for (var i = 0; i < recentHistory.length; i++) {
        final loc = recentHistory[i];
        sb.writeln('${i + 1}. ${loc.locationName} - ${DateFormat('dd.MM.yyyy HH:mm').format(loc.date)}');
      }
      if (filteredHistory.length > 10) {
        sb.writeln('   ... и еще ${filteredHistory.length - 10} перемещений');
      }
      sb.writeln();
    }
    
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('📅 Отчет сгенерирован: ${dateFormat.format(DateTime.now())}');
    sb.writeln('© Tooler App');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    return sb.toString();
  }

  static Future<void> shareToolReport(
      Tool tool, BuildContext context, ReportType reportType) async {
    try {
      if (reportType == ReportType.pdf) {
        final pdfBytes = await _generateToolReportPdf(tool);
        final tempDir = await getTemporaryDirectory();
        final fileName = 'Инструмент_${tool.title.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf';
        final pdfFile = File('${tempDir.path}/$fileName');
        await pdfFile.writeAsBytes(pdfBytes);
        await SharePlus.instance.share(ShareParams(
          files: [XFile(pdfFile.path)],
          text: '🔧 ОТЧЕТ ОБ ИНСТРУМЕНТЕ: ${tool.title}',
        ));
      } else {
        await SharePlus.instance.share(ShareParams(
          text: _generateToolReportText(tool),
        ));
      }
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
    }
  }

  static Future<void> shareObjectReport(ConstructionObject object,
      List<Tool> toolsOnObject, BuildContext context, ReportType reportType) async {
    try {
      if (reportType == ReportType.pdf) {
        final pdfBytes = await _generateObjectReportPdf(object, toolsOnObject);
        final tempDir = await getTemporaryDirectory();
        final fileName = 'Объект_${object.name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf';
        final pdfFile = File('${tempDir.path}/$fileName');
        await pdfFile.writeAsBytes(pdfBytes);
        await SharePlus.instance.share(ShareParams(
          files: [XFile(pdfFile.path)],
          text: '🏢 ОТЧЕТ ОБ ОБЪЕКТЕ: ${object.name}',
        ));
      } else {
        await SharePlus.instance.share(ShareParams(
          text: _generateObjectReportText(object, toolsOnObject),
        ));
      }
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
    }
  }

  static void showReportTypeDialog(
      BuildContext context, Tool tool, Function(ReportType) onTypeSelected) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Выберите тип отчета', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: const Text('PDF отчет'),
                    onTap: () {
                      Navigator.pop(context);
                      onTypeSelected(ReportType.pdf);
                    }),
                ListTile(
                    leading: const Icon(Icons.text_fields, color: Colors.blue),
                    title: const Text('Текстовый отчет'),
                    onTap: () {
                      Navigator.pop(context);
                      onTypeSelected(ReportType.text);
                    }),
              ])),
          );
        });
  }

  static void showObjectReportTypeDialog(
      BuildContext context, ConstructionObject object, List<Tool> tools, Function(ReportType) onTypeSelected) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Выберите тип отчета', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: const Text('PDF отчет'),
                    onTap: () {
                      Navigator.pop(context);
                      onTypeSelected(ReportType.pdf);
                    }),
                ListTile(
                    leading: const Icon(Icons.text_fields, color: Colors.blue),
                    title: const Text('Текстовый отчет'),
                    onTap: () {
                      Navigator.pop(context);
                      onTypeSelected(ReportType.text);
                    }),
              ])),
          );
        });
  }

  static Future<void> printToolReport(Tool tool, BuildContext context) async {
    try {
      final pdfBytes = await _generateToolReportPdf(tool);
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorDialog(context, 'Не удалось напечатать отчет: $e');
    }
  }

  static Future<void> printObjectReport(
      ConstructionObject object, List<Tool> toolsOnObject, BuildContext context) async {
    try {
      final pdfBytes = await _generateObjectReportPdf(object, toolsOnObject);
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorDialog(context, 'Не удалось напечатать отчет: $e');
    }
  }

  static Future<Uint8List> _generateObjectReportPdf(
      ConstructionObject object, List<Tool> toolsOnObject) async {
    final pdf = pw.Document();
    final primaryColor = PdfColors.orange700;
    final accentColor = PdfColors.orange600;
    final font = await _loadFont();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(10)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ОТЧЕТ ОБ ОБЪЕКТЕ',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: font)),
                  pw.Text(DateFormat('dd.MM.yyyy').format(DateTime.now()),
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.white, font: font)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Object Details
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.orange300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(object.name, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: font)),
                  pw.SizedBox(height: 10),
                  _buildPdfRow('Описание:', object.description.isNotEmpty ? object.description : 'Нет', font),
                  pw.SizedBox(height: 6),
                  _buildPdfRow('Дата создания:', DateFormat('dd.MM.yyyy').format(object.createdAt), font),
                  pw.SizedBox(height: 6),
                  _buildPdfRow('Инструментов на объекте:', '${toolsOnObject.length}', font),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tools Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('${toolsOnObject.length}',
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                              font: font)),
                      pw.Text('Всего инструментов',
                          style: pw.TextStyle(fontSize: 9, font: font)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('${toolsOnObject.where((t) => t.isFavorite).length}',
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red,
                              font: font)),
                      pw.Text('Избранных',
                          style: pw.TextStyle(fontSize: 9, font: font)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Tools Table
            if (toolsOnObject.isNotEmpty) ...[
              pw.Text('СПИСОК ИНСТРУМЕНТОВ НА ОБЪЕКТЕ',
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: accentColor,
                      font: font)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: accentColor, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.4),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(0.4),
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                        color: PdfColor(primaryColor.red, primaryColor.green,
                            primaryColor.blue, 0.1)),
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.center,
                        child: pw.Text('№',
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Название и бренд',
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('ID инструмента',
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.center,
                        child: pw.Text('Избр.',
                            style: pw.TextStyle(fontSize: 8, font: font)),
                      ),
                    ],
                  ),
                  // Data Rows
                  ...toolsOnObject.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tool = entry.value;
                    return pw.TableRow(
                      decoration: index % 2 == 0
                          ? const pw.BoxDecoration(color: PdfColors.grey50)
                          : null,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          alignment: pw.Alignment.center,
                          child: pw.Text('${index + 1}',
                              style: pw.TextStyle(fontSize: 8, font: font)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(tool.title,
                                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, font: font)),
                              pw.Text('${tool.brand}',
                                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600, font: font)),
                            ],
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(tool.uniqueId,
                              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600, font: font)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          alignment: pw.Alignment.center,
                          child: pw.Text(tool.isFavorite ? 'Да' : '',
                              style: pw.TextStyle(fontSize: 8, font: font)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ] else ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text('На этом объекте нет инструментов',
                    style: pw.TextStyle(fontSize: 12, font: font)),
              ),
            ],

            pw.Spacer(),
            pw.Divider(),
            pw.SizedBox(height: 6),
            pw.Text(
              '© Tooler App • Отчет сгенерирован ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              textAlign: pw.TextAlign.center,
            ),
          ],
        );
      },
    ));
    return await pdf.save();
  }

  static String _generateObjectReportText(ConstructionObject object, List<Tool> toolsOnObject) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    return '''
📋 ОТЧЕТ ОБ ОБЪЕКТЕ: ${object.name}

🏢 ОСНОВНАЯ ИНФОРМАЦИЯ:
─────────────────────
• Название: ${object.name}
• Описание: ${object.description.isNotEmpty ? object.description : 'Нет'}
• Инструментов: ${toolsOnObject.length}
• Создан: ${DateFormat('dd.MM.yyyy').format(object.createdAt)}

🛠️ ИНСТРУМЕНТЫ НА ОБЪЕКТЕ:
─────────────────────
${toolsOnObject.isEmpty ? 'Нет инструментов' : toolsOnObject.map((t) => '• ${t.title} (${t.brand})').join('\n')}

📅 Отчет сгенерирован: ${dateFormat.format(DateTime.now())}
© Tooler App
    ''';
  }

  // Multiple Tools Report Generation
  static Future<void> shareMultipleToolsReport(
      List<Tool> tools, BuildContext context, ReportType reportType) async {
    try {
      if (reportType == ReportType.pdf) {
        final pdfBytes = await _generateMultipleToolsReportPdf(tools).timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException('PDF generation took too long'),
        );
        final tempDir = await getTemporaryDirectory();
        final fileName = 'Инструменты_${tools.length}_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf';
        final pdfFile = File('${tempDir.path}/$fileName');
        await pdfFile.writeAsBytes(pdfBytes);
        
        // Share with timeout
        try {
          await SharePlus.instance.share(ShareParams(
            files: [XFile(pdfFile.path)],
            text: '🔧 ОТЧЕТ ПО ${tools.length} ИНСТРУМЕНТАМ',
          ));
        } catch (e) {
          // Ignore share errors - user may have cancelled
          print('Share error (ignored): $e');
        }
      } else {
        try {
          await SharePlus.instance.share(ShareParams(
            text: _generateMultipleToolsReportText(tools),
          ));
        } catch (e) {
          // Ignore share errors
          print('Share error (ignored): $e');
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
    }
  }

  static Future<Uint8List> _generateMultipleToolsReportPdf(List<Tool> tools) async {
    final pdf = pw.Document();
    final primaryColor = PdfColors.blue700;
    final accentColor = PdfColors.blue600;
    final font = await _loadFont();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ОТЧЕТ ПО ИНСТРУМЕНТАМ',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                  font: font)),
                          pw.SizedBox(height: 2),
                          pw.Text('Всего инструментов: ${tools.length}',
                              style: pw.TextStyle(
                                  fontSize: 12, color: PdfColors.white, font: font)),
                        ],
                      ),
                    ],
                  ),
                  pw.Text(DateFormat('dd.MM.yyyy').format(DateTime.now()),
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.white, font: font)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Summary Info
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('${tools.where((t) => t.currentLocation == "garage").length}',
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                              font: font)),
                      pw.Text('В гараже',
                          style: pw.TextStyle(fontSize: 9, font: font)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('${tools.where((t) => t.currentLocation != "garage").length}',
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange,
                              font: font)),
                      pw.Text('На объектах',
                          style: pw.TextStyle(fontSize: 9, font: font)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('${tools.where((t) => t.isFavorite).length}',
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red,
                              font: font)),
                      pw.Text('Избранных',
                          style: pw.TextStyle(fontSize: 9, font: font)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Tools Table
            pw.Text('СПИСОК ИНСТРУМЕНТОВ',
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                    font: font)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: accentColor, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.6),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(0.5),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: PdfColor(primaryColor.red, primaryColor.green,
                          primaryColor.blue, 0.1)),
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      alignment: pw.Alignment.center,
                      child: pw.Text('№',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              font: font)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Название',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              font: font)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Бренд',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              font: font)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Местоположение',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              font: font)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      alignment: pw.Alignment.center,
                      child: pw.Text('⭐',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
                // Data Rows
                ...tools.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tool = entry.value;
                  return pw.TableRow(
                    decoration: index % 2 == 0
                        ? const pw.BoxDecoration(color: PdfColors.grey50)
                        : null,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.center,
                        child: pw.Text('${index + 1}',
                            style: pw.TextStyle(fontSize: 8, font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(tool.title,
                            style: pw.TextStyle(fontSize: 8, font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(tool.brand,
                            style: pw.TextStyle(fontSize: 8, font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(tool.currentLocationName,
                            style: pw.TextStyle(fontSize: 8, font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.center,
                        child: pw.Text(tool.isFavorite ? '⭐' : '',
                            style: const pw.TextStyle(fontSize: 8)),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.Spacer(),
            pw.Divider(),
            pw.SizedBox(height: 6),
            pw.Text(
              '© Tooler App • Отчет сгенерирован ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              textAlign: pw.TextAlign.center,
            ),
          ],
        );
      },
    ));
    return await pdf.save();
  }

  static String _generateMultipleToolsReportText(List<Tool> tools) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final garageTools = tools.where((t) => t.currentLocation == 'garage').length;
    final onSiteTools = tools.where((t) => t.currentLocation != 'garage').length;
    final favoriteTools = tools.where((t) => t.isFavorite).length;

    final sb = StringBuffer();

    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('🔧 ОТЧЕТ ПО ИНСТРУМЕНТАМ');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln();

    sb.writeln('📊 СВОДКА:');
    sb.writeln('─────────────────────');
    sb.writeln('• Всего инструментов: ${tools.length}');
    sb.writeln('• В гараже: $garageTools');
    sb.writeln('• На объектах: $onSiteTools');
    sb.writeln('• Избранных: $favoriteTools');
    sb.writeln();

    sb.writeln('📋 СПИСОК ИНСТРУМЕНТОВ:');
    sb.writeln('─────────────────────');
    for (var i = 0; i < tools.length; i++) {
      final tool = tools[i];
      sb.writeln('${i + 1}. ${tool.title} (${tool.brand})');
      sb.writeln('   📍 ${tool.currentLocationName}${tool.isFavorite ? " ⭐" : ""}');
      if (i < tools.length - 1) sb.writeln();
    }
    sb.writeln();

    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('📅 Отчет сгенерирован: ${dateFormat.format(DateTime.now())}');
    sb.writeln('© Tooler App');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return sb.toString();
  }

  static Future<void> shareInventoryReport(List<Tool> tools, List<ConstructionObject> objects,
      BuildContext context, ReportType reportType) async {
    try {
      if (reportType == ReportType.pdf) {
        final pdfBytes = await _generateInventoryReportPdf(tools, objects);
        final tempDir = await getTemporaryDirectory();
        final fileName = 'Инвентаризация_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf';
        final pdfFile = File('${tempDir.path}/$fileName');
        await pdfFile.writeAsBytes(pdfBytes);
        await SharePlus.instance.share(ShareParams(
          files: [XFile(pdfFile.path)],
          text: '📊 ИНВЕНТАРИЗАЦИОННЫЙ ОТЧЕТ Tooler',
        ));
      } else {
        await SharePlus.instance.share(ShareParams(
          text: _generateInventoryReportText(tools, objects),
        ));
      }
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
    }
  }

  static Future<Uint8List> _generateInventoryReportPdf(List<Tool> tools, List<ConstructionObject> objects) async {
    final pdf = pw.Document();
    final primaryColor = PdfColors.green700;
    final font = await _loadFont();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(10)),
              child: pw.Row(children: [
                pw.Text('📊', style: const pw.TextStyle(fontSize: 40)),
                pw.SizedBox(width: 10),
                pw.Text('ИНВЕНТАРИЗАЦИОННЫЙ ОТЧЕТ',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: font)),
              ]),
            ),
            pw.SizedBox(height: 20),
            pw.Text('СВОДКА:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: font)),
            pw.SizedBox(height: 10),
            pw.Text('🛠️ Всего инструментов: ${tools.length}', style: pw.TextStyle(fontSize: 12, font: font)),
            pw.Text('🏢 Всего объектов: ${objects.length}', style: pw.TextStyle(fontSize: 12, font: font)),
            pw.SizedBox(height: 15),
            pw.Text('ИНСТРУМЕНТЫ:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: font)),
            ...tools.take(20).map((t) => pw.Text('• ${t.title} (${t.brand}) - ${t.currentLocationName}',
                style: pw.TextStyle(fontSize: 11, font: font))),
            if (tools.length > 20)
              pw.Text('... и еще ${tools.length - 20} инструментов',
                  style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, font: font)),
          ],
        );
      },
    ));
    return await pdf.save();
  }

  static String _generateInventoryReportText(List<Tool> tools, List<ConstructionObject> objects) {
    final garageTools = tools.where((t) => t.currentLocation == 'garage').length;
    final onSiteTools = tools.where((t) => t.currentLocation != 'garage').length;
    final favoriteTools = tools.where((t) => t.isFavorite).length;
    return '''
📊 ИНВЕНТАРИЗАЦИОННЫЙ ОТЧЕТ Tooler

📅 Дата: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}

📊 СВОДКА:
─────────────────────
🛠️ Всего инструментов: ${tools.length}
🏠 В гараже: $garageTools
🏗️ На объектах: $onSiteTools
⭐ Избранных: $favoriteTools
🏢 Всего объектов: ${objects.length}

📋 СПИСОК ИНСТРУМЕНТОВ:
─────────────────────
${tools.take(15).map((t) => '• ${t.title} (${t.brand}) - ${t.currentLocationName}${t.isFavorite ? " ⭐" : ""}').join('\n')}
${tools.length > 15 ? '\n... и еще ${tools.length - 15} инструментов' : ''}

🏢 СПИСОК ОБЪЕКТОВ:
─────────────────────
${objects.take(10).map((o) => '• ${o.name}').join('\n')}
${objects.length > 10 ? '\n... и еще ${objects.length - 10} объектов' : ''}

📅 Отчет создан: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}
© Tooler App
    ''';
  }

  /// Generate and share a professional profile report
  static Future<void> generateProfileReport(
    AuthProvider authProvider,
    ToolsProvider toolsProvider,
    ObjectsProvider objectsProvider,
    BuildContext context,
  ) async {
    try {
      final pdfBytes = await _generateProfileReportPdf(
        authProvider,
        toolsProvider,
        objectsProvider,
      );
      final tempDir = await getTemporaryDirectory();
      final fileName = 'Отчет_профиля_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf';
      final pdfFile = File('${tempDir.path}/$fileName');
      await pdfFile.writeAsBytes(pdfBytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(pdfFile.path)],
        text: '📋 ОТЧЕТ ПРОФИЛЯ Tooler',
      ));
      if (!context.mounted) return;
      ErrorHandler.showSuccessDialog(context, 'Отчет профиля успешно создан и загружен');
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showErrorDialog(context, 'Ошибка при создании отчета: $e');
    }
  }

  static Future<Uint8List> _generateProfileReportPdf(
    AuthProvider authProvider,
    ToolsProvider toolsProvider,
    ObjectsProvider objectsProvider,
  ) async {
    final pdf = pw.Document();
    final primaryColor = PdfColors.cyan700;
    final accentColor = PdfColors.cyan600;
    final font = await _loadFont();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final currentDate = DateTime.now();

    final garageTools = toolsProvider.tools.where((t) => t.currentLocation == 'garage').length;
    final onSiteTools = toolsProvider.tools.where((t) => t.currentLocation != 'garage').length;
    final favoriteTools = toolsProvider.tools.where((t) => t.isFavorite).length;
    final favoriteObjects = objectsProvider.objects.where((o) => o.isFavorite).length;

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with gradient effect
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ОТЧЕТ ПРОФИЛЯ',
                              style: pw.TextStyle(
                                  fontSize: 28,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                  font: font)),
                          pw.SizedBox(height: 5),
                          pw.Text('Tooler Application',
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey500,
                                  font: font)),
                        ],
                      ),
                      pw.Text('📋',
                          style: const pw.TextStyle(fontSize: 50)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // User Information Section
            pw.Text('👤 ИНФОРМАЦИЯ ПОЛЬЗОВАТЕЛЯ',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                    font: font)),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Email:',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                              font: font)),
                      pw.Text(authProvider.user?.email ?? 'Не указан',
                          style: pw.TextStyle(fontSize: 11, font: font)),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Роль:',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                              font: font)),
                      pw.Text(authProvider.role ?? 'Пользователь',
                          style: pw.TextStyle(fontSize: 11, font: font)),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Дата отчета:',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                              font: font)),
                      pw.Text(dateFormat.format(currentDate),
                          style: pw.TextStyle(fontSize: 11, font: font)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Statistics Section
            pw.Text('📊 СТАТИСТИКА',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                    font: font)),
            pw.SizedBox(height: 10),
            
            // Stats Grid
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.cyan50,
                      border: pw.Border.all(color: PdfColors.cyan200),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('🛠️',
                            style: const pw.TextStyle(fontSize: 30)),
                        pw.SizedBox(height: 5),
                        pw.Text('${toolsProvider.tools.length}',
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                font: font)),
                        pw.Text('Инструментов',
                            style: pw.TextStyle(fontSize: 9, font: font)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      border: pw.Border.all(color: PdfColors.green200),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('🏠',
                            style: const pw.TextStyle(fontSize: 30)),
                        pw.SizedBox(height: 5),
                        pw.Text('$garageTools',
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                font: font)),
                        pw.Text('В гараже',
                            style: pw.TextStyle(fontSize: 9, font: font)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange50,
                      border: pw.Border.all(color: PdfColors.orange200),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('⭐',
                            style: const pw.TextStyle(fontSize: 30)),
                        pw.SizedBox(height: 5),
                        pw.Text('${favoriteTools + favoriteObjects}',
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                font: font)),
                        pw.Text('Избранное',
                            style: pw.TextStyle(fontSize: 9, font: font)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),

            // Additional Stats
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.purple50,
                      border: pw.Border.all(color: PdfColors.purple200),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('🏗️',
                            style: const pw.TextStyle(fontSize: 30)),
                        pw.SizedBox(height: 5),
                        pw.Text('$onSiteTools',
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                font: font)),
                        pw.Text('На объектах',
                            style: pw.TextStyle(fontSize: 9, font: font)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.amber50,
                      border: pw.Border.all(color: PdfColors.amber200),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('🏢',
                            style: const pw.TextStyle(fontSize: 30)),
                        pw.SizedBox(height: 5),
                        pw.Text('${objectsProvider.objects.length}',
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                font: font)),
                        pw.Text('Объектов',
                            style: pw.TextStyle(fontSize: 9, font: font)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red50,
                      border: pw.Border.all(color: PdfColors.red200),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('❤️',
                            style: const pw.TextStyle(fontSize: 30)),
                        pw.SizedBox(height: 5),
                        pw.Text('$favoriteObjects',
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                font: font)),
                        pw.Text('Объектов',
                            style: pw.TextStyle(fontSize: 9, font: font)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Footer
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('© Tooler App ${DateTime.now().year}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, font: font)),
                pw.Text('Конфиденциальный отчет',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, font: font)),
              ],
            ),
          ],
        );
      },
    ));

    return await pdf.save();
  }
}
