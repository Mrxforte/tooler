// ignore_for_file: unused_import, unused_element

import 'dart:io';
import 'dart:typed_data';
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
import '../models/worker.dart';
import '../models/salary.dart';
import '../../core/utils/error_handler.dart';

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
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                children: [
                  pw.Text('🔧', style: const pw.TextStyle(fontSize: 40)),
                  pw.SizedBox(width: 10),
                  pw.Text('ОТЧЕТ ОБ ИНСТРУМЕНТЕ',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: font)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('${tool.title}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font)),
            pw.SizedBox(height: 10),
            pw.Text('Бренд: ${tool.brand}', style: pw.TextStyle(fontSize: 12, font: font)),
            pw.Text('ID: ${tool.uniqueId}', style: pw.TextStyle(fontSize: 12, font: font)),
            pw.Text('Местоположение: ${tool.currentLocationName}', style: pw.TextStyle(fontSize: 12, font: font)),
            pw.Text('Дата: ${dateFormat.format(DateTime.now())}', style: pw.TextStyle(fontSize: 12, font: font)),
          ],
        );
      },
    ));
    return await pdf.save();
  }

  static String _generateToolReportText(Tool tool) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    return '''
📋 ОТЧЕТ ОБ ИНСТРУМЕНТЕ: ${tool.title}

🔧 ОСНОВНАЯ ИНФОРМАЦИЯ:
─────────────────────
• Название: ${tool.title}
• Бренд: ${tool.brand}
• ID: ${tool.uniqueId}
• Описание: ${tool.description.isNotEmpty ? tool.description : 'Не указано'}
• Местоположение: ${tool.currentLocationName}
• Статус: ${tool.isFavorite ? '⭐ В избранном' : '📦 В наличии'}
• Дата добавления: ${DateFormat('dd.MM.yyyy').format(tool.createdAt)}
• Последнее обновление: ${DateFormat('dd.MM.yyyy').format(tool.updatedAt)}

📅 Отчет сгенерирован: ${dateFormat.format(DateTime.now())}
© Tooler App
    ''';
  }

  static Future<void> shareToolReport(
      Tool tool, BuildContext context, ReportType reportType) async {
    try {
      if (reportType == ReportType.pdf) {
        final pdfBytes = await _generateToolReportPdf(tool);
        final tempDir = await getTemporaryDirectory();
        final pdfFile = File('${tempDir.path}/tool_report_${tool.id}.pdf');
        await pdfFile.writeAsBytes(pdfBytes);
        await Share.shareXFiles([XFile(pdfFile.path)],
            text: '🔧 ОТЧЕТ ОБ ИНСТРУМЕНТЕ: ${tool.title}');
      } else {
        await Share.share(_generateToolReportText(tool));
      }
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
    }
  }

  static Future<void> shareObjectReport(ConstructionObject object,
      List<Tool> toolsOnObject, BuildContext context, ReportType reportType) async {
    try {
      if (reportType == ReportType.pdf) {
        final pdfBytes = await _generateObjectReportPdf(object, toolsOnObject);
        final tempDir = await getTemporaryDirectory();
        final pdfFile = File('${tempDir.path}/object_report_${object.id}.pdf');
        await pdfFile.writeAsBytes(pdfBytes);
        await Share.shareXFiles([XFile(pdfFile.path)],
            text: '🏢 ОТЧЕТ ОБ ОБЪЕКТЕ: ${object.name}');
      } else {
        await Share.share(_generateObjectReportText(object, toolsOnObject));
      }
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
    }
  }

  static Future<void> shareWorkerReport(
      Worker worker,
      List<SalaryEntry> salaries,
      List<Advance> advances,
      List<Penalty> penalties,
      BuildContext context,
      ReportType reportType,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      if (reportType == ReportType.pdf) {
        final pdfBytes = await _generateWorkerReportPdf(
            worker, salaries, advances, penalties, startDate ?? DateTime(2020), endDate ?? DateTime.now());
        final tempDir = await getTemporaryDirectory();
        final pdfFile = File('${tempDir.path}/worker_report_${worker.id}.pdf');
        await pdfFile.writeAsBytes(pdfBytes);
        await Share.shareXFiles([XFile(pdfFile.path)], text: '👤 ОТЧЕТ ПО РАБОТНИКУ: ${worker.name}');
      } else {
        await Share.share(_generateWorkerReportText(worker, salaries, advances, penalties));
      }
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
    }
  }

  static void showReportTypeDialog(
      BuildContext context, Tool tool, Function(ReportType) onTypeSelected) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
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
              ]));
        });
  }

  static void showObjectReportTypeDialog(
      BuildContext context, ConstructionObject object, List<Tool> tools, Function(ReportType) onTypeSelected) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
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
              ]));
        });
  }

  static Future<void> printToolReport(Tool tool, BuildContext context) async {
    try {
      final pdfBytes = await _generateToolReportPdf(tool);
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Не удалось напечатать отчет: $e');
    }
  }

  static Future<Uint8List> _generateObjectReportPdf(
      ConstructionObject object, List<Tool> toolsOnObject) async {
    final pdf = pw.Document();
    final primaryColor = PdfColors.orange700;
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
              child: pw.Row(
                children: [
                  pw.Text('🏢', style: const pw.TextStyle(fontSize: 40)),
                  pw.SizedBox(width: 10),
                  pw.Text('ОТЧЕТ ОБ ОБЪЕКТЕ',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: font)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('${object.name}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font)),
            pw.SizedBox(height: 10),
            pw.Text('Описание: ${object.description.isNotEmpty ? object.description : 'Нет'}',
                style: pw.TextStyle(fontSize: 12, font: font)),
            pw.Text('Инструментов: ${toolsOnObject.length}', style: pw.TextStyle(fontSize: 12, font: font)),
            pw.Text('Дата создания: ${DateFormat('dd.MM.yyyy').format(object.createdAt)}',
                style: pw.TextStyle(fontSize: 12, font: font)),
            pw.SizedBox(height: 15),
            pw.Text('Инструменты на объекте:',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: font)),
            ...toolsOnObject.map((t) => pw.Text('• ${t.title} (${t.brand})',
                style: pw.TextStyle(fontSize: 11, font: font))),
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

  static Future<Uint8List> _generateWorkerReportPdf(Worker worker, List<SalaryEntry> salaries,
      List<Advance> advances, List<Penalty> penalties, DateTime startDate, DateTime endDate) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy');
    final primaryColor = PdfColors.teal700;
    final font = await _loadFont();

    double totalSalaries = salaries.fold(0, (sum, e) => sum + e.amount);
    double totalAdvances = advances.fold(0, (sum, e) => sum + (e.repaid ? 0 : e.amount));
    double totalPenalties = penalties.fold(0, (sum, e) => sum + e.amount);
    double balance = totalSalaries - totalAdvances - totalPenalties;

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(10)),
              child: pw.Row(
                children: [
                  pw.Text('👤', style: const pw.TextStyle(fontSize: 40)),
                  pw.SizedBox(width: 10),
                  pw.Text('ОТЧЕТ ПО РАБОТНИКУ',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: font)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('${worker.name}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font)),
            pw.SizedBox(height: 10),
            pw.Text('Email: ${worker.email}', style: pw.TextStyle(fontSize: 12, font: font)),
            pw.Text('Роль: ${worker.role}', style: pw.TextStyle(fontSize: 12, font: font)),
            pw.SizedBox(height: 15),
            pw.Text('ФИНАНСЫ:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: font)),
            pw.Text('Зарплата: ${totalSalaries.toStringAsFixed(2)} ₽', style: pw.TextStyle(fontSize: 12, font: font)),
            pw.Text('Авансы: ${totalAdvances.toStringAsFixed(2)} ₽', style: pw.TextStyle(fontSize: 12, font: font)),
            pw.Text('Штрафы: ${totalPenalties.toStringAsFixed(2)} ₽', style: pw.TextStyle(fontSize: 12, font: font)),
            pw.Text('ИТОГО: ${balance.toStringAsFixed(2)} ₽',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: font)),
          ],
        );
      },
    ));
    return await pdf.save();
  }

  static String _generateWorkerReportText(
      Worker worker, List<SalaryEntry> salaries, List<Advance> advances, List<Penalty> penalties) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    double totalSalaries = salaries.fold(0, (sum, e) => sum + e.amount);
    double totalAdvances = advances.fold(0, (sum, e) => sum + (e.repaid ? 0 : e.amount));
    double totalPenalties = penalties.fold(0, (sum, e) => sum + e.amount);
    double balance = totalSalaries - totalAdvances - totalPenalties;
    return '''
📋 ОТЧЕТ ПО РАБОТНИКУ: ${worker.name}

👤 ОСНОВНАЯ ИНФОРМАЦИЯ:
─────────────────────
• Имя: ${worker.name}
• Email: ${worker.email}
• Роль: ${worker.role}
• Почасовая ставка: ${worker.hourlyRate.toStringAsFixed(2)} ₽
• Дневная ставка: ${worker.dailyRate.toStringAsFixed(2)} ₽

💰 ФИНАНСОВАЯ ИНФОРМАЦИЯ:
─────────────────────
• Зарплата: ${totalSalaries.toStringAsFixed(2)} ₽
• Авансы: ${totalAdvances.toStringAsFixed(2)} ₽
• Штрафы: ${totalPenalties.toStringAsFixed(2)} ₽
• ИТОГО: ${balance.toStringAsFixed(2)} ₽

📅 Отчет сгенерирован: ${dateFormat.format(DateTime.now())}
© Tooler App
    ''';
  }

  static Future<void> shareInventoryReport(List<Tool> tools, List<ConstructionObject> objects,
      BuildContext context, ReportType reportType) async {
    try {
      if (reportType == ReportType.pdf) {
        final pdfBytes = await _generateInventoryReportPdf(tools, objects);
        final tempDir = await getTemporaryDirectory();
        final pdfFile = File('${tempDir.path}/inventory_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await pdfFile.writeAsBytes(pdfBytes);
        await Share.shareXFiles([XFile(pdfFile.path)], text: '📊 ИНВЕНТАРИЗАЦИОННЫЙ ОТЧЕТ Tooler');
      } else {
        await Share.share(_generateInventoryReportText(tools, objects));
      }
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
    }
  }

  static Future<Uint8List> _generateInventoryReportPdf(List<Tool> tools, List<ConstructionObject> objects) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
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
}
