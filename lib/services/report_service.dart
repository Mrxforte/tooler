import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/tool.dart';
import '../models/construction_object.dart';
import 'error_handler.dart';

enum ReportType { pdf, text, screenshot }

class ReportService {
  static Future<Uint8List> _generateToolReportPdf(Tool tool) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'TOOLER - ОТЧЕТ ОБ ИНСТРУМЕНТЕ',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text('Сгенерировано: ${dateFormat.format(DateTime.now())}'),
              pw.SizedBox(height: 20),

              pw.Text(
                'ОСНОВНАЯ ИНФОРМАЦИЯ',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['Название:', tool.title],
                  ['Бренд:', tool.brand],
                  ['Уникальный ID:', tool.uniqueId],
                  [
                    'Модель:',
                    tool.description.isNotEmpty
                        ? tool.description
                        : 'Не указана',
                  ],
                  ['Местоположение:', tool.currentLocationName],
                  [
                    'Статус:',
                    tool.isFavorite ? '⭐ В избранном' : '📦 В наличии',
                  ],
                  [
                    'Дата добавления:',
                    DateFormat('dd.MM.yyyy').format(tool.createdAt),
                  ],
                  [
                    'Последнее обновление:',
                    DateFormat('dd.MM.yyyy').format(tool.updatedAt),
                  ],
                ],
              ),

              if (tool.locationHistory.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'ИСТОРИЯ ПЕРЕМЕЩЕНИЙ',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...tool.locationHistory.map(
                  (history) => pw.Padding(
                    padding: pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      children: [
                        pw.Text('• '),
                        pw.Expanded(
                          child: pw.Text(
                            '${history.locationName} (${DateFormat('dd.MM.yyyy').format(history.date)})',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              pw.Spacer(),
              pw.Container(
                margin: pw.EdgeInsets.only(top: 30),
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '© ${DateTime.now().year} Tooler App - Система управления строительными инструментами\nГенерация отчета: ${dateFormat.format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static String _generateToolReportText(Tool tool) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    String report =
        '''
📋 ОТЧЕТ ОБ ИНСТРУМЕНТЕ - ${tool.title}

🛠️ ОСНОВНАЯ ИНФОРМАЦИЯ:
─────────────────────
• Название: ${tool.title}
• Бренд: ${tool.brand}
• Уникальный ID: ${tool.uniqueId}
• Модель: ${tool.description.isNotEmpty ? tool.description : 'Не указана'}
• Местоположение: ${tool.currentLocationName}
• Статус: ${tool.isFavorite ? '⭐ В избранном' : '📦 В наличии'}
• Дата добавления: ${DateFormat('dd.MM.yyyy').format(tool.createdAt)}
• Последнее обновление: ${DateFormat('dd.MM.yyyy').format(tool.updatedAt)}
''';

    if (tool.locationHistory.isNotEmpty) {
      report +=
          '''
      
📜 ИСТОРИЯ ПЕРЕМЕЩЕНИЙ:
─────────────────────
${tool.locationHistory.map((history) => '• ${history.locationName} (${DateFormat('dd.MM.yyyy').format(history.date)})').join('\n')}
''';
    }

    report +=
        '''
      
📅 Отчет сгенерирован: ${dateFormat.format(DateTime.now())}
© ${DateTime.now().year} Tooler App
''';

    return report;
  }

  static Future<void> shareToolReport(
    Tool tool,
    BuildContext context,
    ReportType reportType,
  ) async {
    try {
      switch (reportType) {
        case ReportType.pdf:
          final pdfBytes = await _generateToolReportPdf(tool);
          final tempDir = await getTemporaryDirectory();
          final pdfFile = File('${tempDir.path}/tool_report_${tool.id}.pdf');
          await pdfFile.writeAsBytes(pdfBytes);

          await Share.shareXFiles([
            XFile(pdfFile.path),
          ], text: '📋 Отчет об инструменте: ${tool.title}');
          break;

        case ReportType.text:
          final textReport = _generateToolReportText(tool);
          await Share.share(textReport);
          break;

        case ReportType.screenshot:
          // For screenshot, we'll share the text report
          final textReport = _generateToolReportText(tool);
          await Share.share(textReport);
          break;
      }
    } catch (e, s) {
      print('Error sharing report: $e\n$s');
      // Fallback to text sharing
      final textReport = _generateToolReportText(tool);
      await Share.share(textReport);
    }
  }

  static void showReportTypeDialog(
    BuildContext context,
    Tool tool,
    Function(ReportType) onTypeSelected,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Выберите тип отчета',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF отчет'),
                subtitle: const Text('С возможностью печати'),
                onTap: () {
                  Navigator.pop(context);
                  onTypeSelected(ReportType.pdf);
                },
              ),

              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.blue),
                title: const Text('Текстовый отчет'),
                subtitle: const Text('Быстрая отправка в мессенджеры'),
                onTap: () {
                  Navigator.pop(context);
                  onTypeSelected(ReportType.text);
                },
              ),

              ListTile(
                leading: const Icon(Icons.screenshot, color: Colors.green),
                title: const Text('Скриншот отчета'),
                subtitle: const Text('Изображение для быстрого просмотра'),
                onTap: () {
                  Navigator.pop(context);
                  onTypeSelected(ReportType.screenshot);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> printToolReport(Tool tool, BuildContext context) async {
    try {
      final pdfBytes = await _generateToolReportPdf(tool);
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    } catch (e) {
      print('Error printing report: $e');
      ErrorHandler.showErrorDialog(context, 'Не удалось напечатать отчет: $e');
    }
  }

  static String _generateInventoryReportText(
    List<Tool> tools,
    List<ConstructionObject> objects,
  ) {
    final garageTools = tools
        .where((t) => t.currentLocation == 'garage')
        .length;
    final onSiteTools = tools
        .where((t) => t.currentLocation != 'garage')
        .length;
    final favoriteTools = tools.where((t) => t.isFavorite).length;
    final objectsWithTools = objects.where((o) => o.toolIds.isNotEmpty).length;

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
📦 Объектов с инструментами: $objectsWithTools

📋 СПИСОК ИНСТРУМЕНТОВ:
─────────────────────
${tools.take(15).map((t) => '• ${t.title} (${t.brand}) - ${t.currentLocationName}${t.isFavorite ? " ⭐" : ""}').join('\n')}
${tools.length > 15 ? '\n... и еще ${tools.length - 15} инструментов' : ''}

🏢 СПИСОК ОБЪЕКТОВ:
─────────────────────
${objects.take(10).map((o) => '• ${o.name} - ${o.toolIds.length} инструментов').join('\n')}
${objects.length > 10 ? '\n... и еще ${objects.length - 10} объектов' : ''}

📅 Отчет создан: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}
© ${DateTime.now().year} Tooler App
''';
  }

  static Future<void> shareInventoryReport(
    List<Tool> tools,
    List<ConstructionObject> objects,
    BuildContext context,
    ReportType reportType,
  ) async {
    try {
      switch (reportType) {
        case ReportType.pdf:
          final pdf = pw.Document();
          final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Header(
                      level: 0,
                      child: pw.Text(
                        'TOOLER - ИНВЕНТАРИЗАЦИОННЫЙ ОТЧЕТ',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Text(
                      'Сгенерировано: ${dateFormat.format(DateTime.now())}',
                    ),
                    pw.SizedBox(height: 20),

                    pw.Text(
                      'СВОДКА ИНВЕНТАРИЗАЦИИ',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 15),

                    pw.Table.fromTextArray(
                      context: context,
                      data: [
                        ['Всего инструментов', '${tools.length}'],
                        [
                          'В гараже',
                          '${tools.where((t) => t.currentLocation == "garage").length}',
                        ],
                        [
                          'На объектах',
                          '${tools.where((t) => t.currentLocation != "garage").length}',
                        ],
                        [
                          'Избранных',
                          '${tools.where((t) => t.isFavorite).length}',
                        ],
                        ['Всего объектов', '${objects.length}'],
                        [
                          'С инструментами',
                          '${objects.where((o) => o.toolIds.isNotEmpty).length}',
                        ],
                        [
                          'Пустых',
                          '${objects.where((o) => o.toolIds.isEmpty).length}',
                        ],
                      ],
                    ),

                    pw.SizedBox(height: 30),
                    pw.Text(
                      'СПИСОК ИНСТРУМЕНТОВ',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),

                    ...tools
                        .take(50)
                        .map(
                          (tool) => pw.Padding(
                            padding: pw.EdgeInsets.only(bottom: 8),
                            child: pw.Row(
                              children: [
                                pw.Text('• '),
                                pw.Expanded(
                                  child: pw.Text(
                                    '${tool.title} (${tool.brand}) - ${tool.currentLocationName}${tool.isFavorite ? " ⭐" : ""}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                    if (tools.length > 50)
                      pw.Text(
                        '... и еще ${tools.length - 50} инструментов',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                  ],
                );
              },
            ),
          );

          final pdfBytes = await pdf.save();
          final tempDir = await getTemporaryDirectory();
          final pdfFile = File(
            '${tempDir.path}/inventory_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
          await pdfFile.writeAsBytes(pdfBytes);

          await Share.shareXFiles([
            XFile(pdfFile.path),
          ], text: '📊 ИНВЕНТАРИЗАЦИОННЫЙ ОТЧЕТ Tooler');
          break;

        case ReportType.text:
        case ReportType.screenshot:
          final textReport = _generateInventoryReportText(tools, objects);
          await Share.share(textReport);
          break;
      }
    } catch (e, s) {
      print('Error sharing inventory report: $e\n$s');
      final textReport = _generateInventoryReportText(tools, objects);
      await Share.share(textReport);
    }
  }
}
