// main.dart - Modern Tooler Construction Tool Management App
// ignore_for_file: empty_catches, avoid_print, library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously, unnecessary_null_comparison

import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';

// ========== FIREBASE INITIALIZATION ==========
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // Initialize Hive
    await Hive.initFlutter();

    // Register Hive adapters
    Hive.registerAdapter(ToolAdapter());
    Hive.registerAdapter(LocationHistoryAdapter());
    Hive.registerAdapter(ConstructionObjectAdapter());
    Hive.registerAdapter(SyncItemAdapter());

    // Initialize Firebase
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyDummyKeyForDevelopment',
        appId: '1:1234567890:android:abcdef123456',
        messagingSenderId: '1234567890',
        projectId: 'tooler-dev',
        storageBucket: 'tooler-dev.appspot.com',
      ),
    );

    print('Firebase initialized successfully');
  } catch (e) {
    print('Initialization error: $e');
    // Continue with offline mode
  }

  runApp(const MyApp());
}

// ========== HIVE ADAPTERS ==========
class ToolAdapter extends TypeAdapter<Tool> {
  @override
  final int typeId = 0;

  @override
  Tool read(BinaryReader reader) {
    return Tool.fromJson(
      reader.readMap().map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  @override
  void write(BinaryWriter writer, Tool obj) {
    writer.writeMap(obj.toJson());
  }
}

class LocationHistoryAdapter extends TypeAdapter<LocationHistory> {
  @override
  final int typeId = 1;

  @override
  LocationHistory read(BinaryReader reader) {
    return LocationHistory.fromJson(
      reader.readMap().map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  @override
  void write(BinaryWriter writer, LocationHistory obj) {
    writer.writeMap(obj.toJson());
  }
}

class ConstructionObjectAdapter extends TypeAdapter<ConstructionObject> {
  @override
  final int typeId = 2;

  @override
  ConstructionObject read(BinaryReader reader) {
    return ConstructionObject.fromJson(
      reader.readMap().map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  @override
  void write(BinaryWriter writer, ConstructionObject obj) {
    writer.writeMap(obj.toJson());
  }
}

class SyncItemAdapter extends TypeAdapter<SyncItem> {
  @override
  final int typeId = 3;

  @override
  SyncItem read(BinaryReader reader) {
    final map = reader.readMap().map(
      (key, value) => MapEntry(key.toString(), value),
    );
    return SyncItem(
      id: map['id'] as String,
      action: map['action'] as String,
      collection: map['collection'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  @override
  void write(BinaryWriter writer, SyncItem obj) {
    writer.writeMap(obj.toJson());
  }
}

// ========== DATA MODELS ==========
class Tool {
  String id;
  String title;
  String description;
  String brand;
  String uniqueId;
  String? imageUrl;
  String? localImagePath;
  String currentLocation; // 'garage' or objectId
  String currentLocationName; // For display purposes
  List<LocationHistory> locationHistory;
  bool isFavorite;
  DateTime createdAt;
  DateTime updatedAt;
  bool isSelected;
  String userId;

  Tool({
    required this.id,
    required this.title,
    required this.description,
    required this.brand,
    required this.uniqueId,
    this.imageUrl,
    this.localImagePath,
    required this.currentLocation,
    required this.currentLocationName,
    List<LocationHistory>? locationHistory,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSelected = false,
    required this.userId,
  }) : locationHistory = locationHistory ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    brand: json['brand'] as String,
    uniqueId: json['uniqueId'] as String,
    imageUrl: json['imageUrl'] as String?,
    localImagePath: json['localImagePath'] as String?,
    currentLocation: json['currentLocation'] as String? ?? 'garage',
    currentLocationName: json['currentLocationName'] as String? ?? 'Гараж',
    locationHistory:
        (json['locationHistory'] as List?)
            ?.map((e) => LocationHistory.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [],
    isFavorite: json['isFavorite'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.now(),
    isSelected: json['isSelected'] as bool? ?? false,
    userId: json['userId'] as String? ?? 'unknown',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'brand': brand,
    'uniqueId': uniqueId,
    'imageUrl': imageUrl,
    'localImagePath': localImagePath,
    'currentLocation': currentLocation,
    'currentLocationName': currentLocationName,
    'locationHistory': locationHistory.map((e) => e.toJson()).toList(),
    'isFavorite': isFavorite,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isSelected': isSelected,
    'userId': userId,
  };

  Tool copyWith({
    String? id,
    String? title,
    String? description,
    String? brand,
    String? uniqueId,
    String? imageUrl,
    String? localImagePath,
    String? currentLocation,
    String? currentLocationName,
    List<LocationHistory>? locationHistory,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSelected,
    String? userId,
  }) {
    return Tool(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      uniqueId: uniqueId ?? this.uniqueId,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      currentLocation: currentLocation ?? this.currentLocation,
      currentLocationName: currentLocationName ?? this.currentLocationName,
      locationHistory: locationHistory ?? this.locationHistory,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSelected: isSelected ?? this.isSelected,
      userId: userId ?? this.userId,
    );
  }

  Tool duplicate(int copyNumber) => Tool(
    id: '${DateTime.now().millisecondsSinceEpoch}',
    title: '$title (Копия ${copyNumber > 1 ? copyNumber : ''})'.trim(),
    description: description,
    brand: brand,
    uniqueId: '${uniqueId}_copy_$copyNumber',
    imageUrl: imageUrl,
    localImagePath: localImagePath,
    currentLocation: currentLocation,
    currentLocationName: currentLocationName,
    locationHistory: List.from(locationHistory),
    isFavorite: isFavorite,
    userId: userId,
  );

  String? get displayImage {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      return localImagePath;
    }
    return null;
  }
}

class LocationHistory {
  DateTime date;
  String locationId;
  String locationName;

  LocationHistory({
    required this.date,
    required this.locationId,
    required this.locationName,
  });

  factory LocationHistory.fromJson(Map<String, dynamic> json) =>
      LocationHistory(
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        locationId: json['locationId'] as String,
        locationName: json['locationName'] as String,
      );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'locationId': locationId,
    'locationName': locationName,
  };
}

class ConstructionObject {
  String id;
  String name;
  String description;
  String? imageUrl;
  String? localImagePath;
  List<String> toolIds;
  DateTime createdAt;
  DateTime updatedAt;
  bool isSelected;
  String userId;

  ConstructionObject({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.localImagePath,
    List<String>? toolIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSelected = false,
    required this.userId,
  }) : toolIds = toolIds ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ConstructionObject.fromJson(Map<String, dynamic> json) =>
      ConstructionObject(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        imageUrl: json['imageUrl'] as String?,
        localImagePath: json['localImagePath'] as String?,
        toolIds: List<String>.from(json['toolIds'] ?? []),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
        isSelected: json['isSelected'] as bool? ?? false,
        userId: json['userId'] as String? ?? 'unknown',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'localImagePath': localImagePath,
    'toolIds': toolIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isSelected': isSelected,
    'userId': userId,
  };

  ConstructionObject copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? localImagePath,
    List<String>? toolIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSelected,
    String? userId,
  }) {
    return ConstructionObject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      toolIds: toolIds ?? this.toolIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSelected: isSelected ?? this.isSelected,
      userId: userId ?? this.userId,
    );
  }

  String? get displayImage {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      return localImagePath;
    }
    return null;
  }
}

// ========== ID GENERATOR ==========
class IdGenerator {
  static String generateToolId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(9999).toString().padLeft(4, '0');
    return 'TOOL-$timestamp-$randomNum';
  }

  static String generateObjectId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(9999).toString().padLeft(4, '0');
    return 'OBJ-$timestamp-$randomNum';
  }

  static String generateUniqueId() {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(8);
    final randomStr = List.generate(
      4,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    return '$timestamp-$randomStr';
  }
}

// ========== LOCAL DATABASE (HIVE) ==========
class LocalDatabase {
  static const String toolsBox = 'tools';
  static const String objectsBox = 'objects';
  static const String syncQueueBox = 'sync_queue';
  static const String appSettingsBox = 'app_settings';

  static Future<void> init() async {
    try {
      await Hive.openBox<Tool>(toolsBox);
      await Hive.openBox<ConstructionObject>(objectsBox);
      await Hive.openBox<SyncItem>(syncQueueBox);
      await Hive.openBox<String>(appSettingsBox);
      print('Hive boxes opened successfully');
    } catch (e) {
      print('Error opening Hive boxes: $e');
      try {
        await Hive.deleteBoxFromDisk(toolsBox);
        await Hive.deleteBoxFromDisk(objectsBox);
        await Hive.deleteBoxFromDisk(syncQueueBox);
        await Hive.deleteBoxFromDisk(appSettingsBox);

        await Hive.openBox<Tool>(toolsBox);
        await Hive.openBox<ConstructionObject>(objectsBox);
        await Hive.openBox<SyncItem>(syncQueueBox);
        await Hive.openBox<String>(appSettingsBox);
      } catch (e) {
        print('Error recreating boxes: $e');
      }
    }
  }

  static Box<Tool> get tools => Hive.box<Tool>(toolsBox);
  static Box<ConstructionObject> get objects =>
      Hive.box<ConstructionObject>(objectsBox);
  static Box<SyncItem> get syncQueue => Hive.box<SyncItem>(syncQueueBox);
  static Box<String> get appSettings => Hive.box<String>(appSettingsBox);

  static Future<void> saveCacheTimestamp() async {
    try {
      await appSettings.put(
        'last_cache_update',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Error saving cache timestamp: $e');
    }
  }

  static Future<DateTime?> getLastCacheUpdate() async {
    try {
      final timestamp = appSettings.get('last_cache_update');
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      print('Error getting cache timestamp: $e');
      return null;
    }
  }

  static Future<bool> shouldRefreshCache({
    Duration maxAge = const Duration(hours: 1),
  }) async {
    try {
      final lastUpdate = await getLastCacheUpdate();
      if (lastUpdate == null) return true;
      return DateTime.now().difference(lastUpdate) > maxAge;
    } catch (e) {
      print('Error checking cache refresh: $e');
      return true;
    }
  }
}

class SyncItem {
  String id;
  String action;
  String collection;
  Map<String, dynamic> data;
  DateTime timestamp;

  SyncItem({
    required this.id,
    required this.action,
    required this.collection,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'collection': collection,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };
}

// ========== IMAGE SERVICE ==========
class ImageService {
  static final ImagePicker _picker = ImagePicker();
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadImage(File image, String userId) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final ref = _storage.ref().child('users/$userId/images/$fileName');
      final uploadTask = await ref.putFile(image);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  static Future<File?> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print('Error picking image: $e');
    }
    return null;
  }

  static Future<File?> takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print('Error taking photo: $e');
    }
    return null;
  }
}

// ========== ENHANCED PDF REPORT SERVICE WITH SHARE AND PRINT ==========
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

  static Future<void> shareToolReport(Tool tool, BuildContext context) async {
    try {
      final pdfBytes = await _generateToolReportPdf(tool);
      final tempDir = await getTemporaryDirectory();
      final pdfFile = File('${tempDir.path}/tool_report_${tool.id}.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text:
            '📋 Отчет об инструменте: ${tool.title}\n\n'
            'Название: ${tool.title}\n'
            'Бренд: ${tool.brand}\n'
            'ID: ${tool.uniqueId}\n'
            'Местоположение: ${tool.currentLocationName}\n'
            'Статус: ${tool.isFavorite ? "⭐ В избранном" : "📦 В наличии"}\n'
            'Добавлен: ${DateFormat('dd.MM.yyyy').format(tool.createdAt)}',
      );
    } catch (e, s) {
      print('Error sharing report: $e\n$s');
      // Fallback to text sharing
      await Share.share(
        '📋 Отчет об инструменте: ${tool.title}\n\n'
        'Название: ${tool.title}\n'
        'Бренд: ${tool.brand}\n'
        'Уникальный ID: ${tool.uniqueId}\n'
        'Описание: ${tool.description.isNotEmpty ? tool.description : "Не указано"}\n'
        'Местоположение: ${tool.currentLocationName}\n'
        'Статус: ${tool.isFavorite ? "⭐ В избранном" : "📦 В наличии"}\n'
        'Добавлен: ${DateFormat('dd.MM.yyyy').format(tool.createdAt)}\n'
        'Обновлен: ${DateFormat('dd.MM.yyyy').format(tool.updatedAt)}\n\n'
        'История перемещений:\n${tool.locationHistory.map((h) => '• ${h.locationName} (${DateFormat('dd.MM.yyyy').format(h.date)})').join('\n')}\n\n'
        '— Отчет создан в Tooler App —',
      );
    }
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

  static Future<void> shareInventoryReport(
    List<Tool> tools,
    List<ConstructionObject> objects,
    BuildContext context,
  ) async {
    try {
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
                pw.Text('Сгенерировано: ${dateFormat.format(DateTime.now())}'),
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
                    ['Избранных', '${tools.where((t) => t.isFavorite).length}'],
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

      final garageTools = tools
          .where((t) => t.currentLocation == 'garage')
          .length;
      final onSiteTools = tools
          .where((t) => t.currentLocation != 'garage')
          .length;
      final favoriteTools = tools.where((t) => t.isFavorite).length;
      final objectsWithTools = objects
          .where((o) => o.toolIds.isNotEmpty)
          .length;

      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text:
            '📊 ИНВЕНТАРИЗАЦИОННЫЙ ОТЧЕТ Tooler\n\n'
            '📅 Дата: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}\n'
            '🛠️ Всего инструментов: ${tools.length}\n'
            '🏠 В гараже: $garageTools\n'
            '🏗️ На объектах: $onSiteTools\n'
            '⭐ Избранных: $favoriteTools\n'
            '🏢 Всего объектов: ${objects.length}\n'
            '📦 Объектов с инструментами: $objectsWithTools\n\n'
            'Топ инструментов:\n${tools.take(5).map((t) => '• ${t.title} (${t.brand}) - ${t.currentLocationName}').join('\n')}\n\n'
            '— Отчет создан в Tooler App —',
      );
    } catch (e, s) {
      print('Error sharing inventory report: $e\n$s');
      final garageTools = tools
          .where((t) => t.currentLocation == 'garage')
          .length;
      final onSiteTools = tools
          .where((t) => t.currentLocation != 'garage')
          .length;
      final favoriteTools = tools.where((t) => t.isFavorite).length;
      final objectsWithTools = objects
          .where((o) => o.toolIds.isNotEmpty)
          .length;

      await Share.share(
        '📊 ИНВЕНТАРИЗАЦИОННЫЙ ОТЧЕТ Tooler\n\n'
        '📅 Дата: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}\n'
        '🛠️ Всего инструментов: ${tools.length}\n'
        '🏠 В гараже: $garageTools\n'
        '🏗️ На объектах: $onSiteTools\n'
        '⭐ Избранных: $favoriteTools\n'
        '🏢 Всего объектов: ${objects.length}\n'
        '📦 Объектов с инструментами: $objectsWithTools\n\n'
        'Список инструментов:\n${tools.take(10).map((t) => '• ${t.title} (${t.brand}) - ${t.currentLocationName}${t.isFavorite ? " ⭐" : ""}').join('\n')}\n\n'
        '— Отчет создан в Tooler App —',
      );
    }
  }
}

// ========== ERROR HANDLER ==========
class ErrorHandler {
  static void showErrorDialog(BuildContext context, String message) {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ошибка'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing error dialog: $e');
    }
  }

  static void showSuccessDialog(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error showing success dialog: $e');
    }
  }

  static void showWarningDialog(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error showing warning dialog: $e');
    }
  }

  static void handleError(Object error, StackTrace stackTrace) {
    print('Error: $error');
    print('Stack trace: $stackTrace');
  }
}

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ========== STATE MANAGEMENT PROVIDERS ==========
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SharedPreferences _prefs;
  User? _user;
  bool _isLoading = false;
  bool _rememberMe = false;
  File? _profileImage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get rememberMe => _rememberMe;
  File? get profileImage => _profileImage;

  AuthProvider(this._prefs) {
    _rememberMe = _prefs.getBool('remember_me') ?? false;
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _isLoading = true;
      final savedUser = _auth.currentUser;
      if (savedUser != null && _rememberMe) {
        _user = savedUser;
      }
      notifyListeners();
    } catch (e) {
      print('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;

      if (_rememberMe) {
        await _prefs.setString('saved_email', email);
      } else {
        await _prefs.remove('saved_email');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Sign in error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Unexpected auth error: $e');
      return false;
    }
  }

  Future<bool> signUpWithEmail(
    String email,
    String password, {
    File? profileImage,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;

      // Save profile image
      if (profileImage != null && _user != null) {
        final imageUrl = await ImageService.uploadImage(
          profileImage,
          _user!.uid,
        );
        if (imageUrl != null) {
          _profileImage = profileImage;
          await _prefs.setString('profile_image_url', imageUrl);
        }
      }

      if (_user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .set({
                'email': email,
                'createdAt': FieldValue.serverTimestamp(),
                'userId': _user!.uid,
                'profileImageUrl': _profileImage != null
                    ? await ImageService.uploadImage(_profileImage!, _user!.uid)
                    : null,
              });
        } catch (e) {
          print('Firestore user creation error: $e');
        }
      }

      if (_rememberMe) {
        await _prefs.setString('saved_email', email);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Sign up error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Unexpected signup error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _profileImage = null;
      await _prefs.remove('profile_image_url');
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> setRememberMe(bool value) async {
    try {
      _rememberMe = value;
      await _prefs.setBool('remember_me', value);

      if (!value) {
        await _prefs.remove('saved_email');
      }

      notifyListeners();
    } catch (e) {
      print('Error setting remember me: $e');
    }
  }

  Future<void> setProfileImage(File image) async {
    _profileImage = image;
    if (_user != null) {
      final imageUrl = await ImageService.uploadImage(image, _user!.uid);
      if (imageUrl != null) {
        await _prefs.setString('profile_image_url', imageUrl);
      }
    }
    notifyListeners();
  }
}

// ========== ENHANCED TOOLS PROVIDER ==========
class ToolsProvider with ChangeNotifier {
  List<Tool> _tools = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _sortAscending = false;
  bool _selectionMode = false;

  // Filter properties
  String _filterLocation = 'all';
  String _filterBrand = 'all';
  bool _filterFavorites = false;

  List<Tool> get tools => _getFilteredTools();
  List<Tool> get garageTools =>
      _tools.where((t) => t.currentLocation == 'garage').toList();
  List<Tool> get favoriteTools => _tools.where((t) => t.isFavorite).toList();
  List<Tool> get selectedTools => _tools.where((t) => t.isSelected).toList();
  bool get isLoading => _isLoading;
  bool get selectionMode => _selectionMode;
  bool get hasSelectedTools => _tools.any((t) => t.isSelected);
  int get totalTools => _tools.length;

  // Filter getters
  String get filterLocation => _filterLocation;
  String get filterBrand => _filterBrand;
  bool get filterFavorites => _filterFavorites;

  // Get unique brands for filter
  List<String> get uniqueBrands {
    final brands = _tools.map((t) => t.brand).toSet().toList();
    brands.sort();
    return ['all', ...brands];
  }

  void toggleSelectionMode() {
    _selectionMode = !_selectionMode;
    if (!_selectionMode) {
      _deselectAllTools();
    }
    notifyListeners();
  }

  void toggleToolSelection(String toolId) {
    try {
      final index = _tools.indexWhere((t) => t.id == toolId);
      if (index != -1) {
        _tools[index] = _tools[index].copyWith(
          isSelected: !_tools[index].isSelected,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling tool selection: $e');
    }
  }

  void selectAllTools() {
    try {
      for (var i = 0; i < _tools.length; i++) {
        _tools[i] = _tools[i].copyWith(isSelected: true);
      }
      notifyListeners();
    } catch (e) {
      print('Error selecting all tools: $e');
    }
  }

  void _deselectAllTools() {
    try {
      for (var i = 0; i < _tools.length; i++) {
        _tools[i] = _tools[i].copyWith(isSelected: false);
      }
      notifyListeners();
    } catch (e) {
      print('Error deselecting all tools: $e');
    }
  }

  // Filter methods
  void setFilterLocation(String location) {
    try {
      _filterLocation = location;
      notifyListeners();
    } catch (e) {
      print('Error setting filter location: $e');
    }
  }

  void setFilterBrand(String brand) {
    try {
      _filterBrand = brand;
      notifyListeners();
    } catch (e) {
      print('Error setting filter brand: $e');
    }
  }

  void setFilterFavorites(bool value) {
    try {
      _filterFavorites = value;
      notifyListeners();
    } catch (e) {
      print('Error setting filter favorites: $e');
    }
  }

  void clearAllFilters() {
    try {
      _filterLocation = 'all';
      _filterBrand = 'all';
      _filterFavorites = false;
      _searchQuery = '';
      notifyListeners();
    } catch (e) {
      print('Error clearing filters: $e');
    }
  }

  List<Tool> _getFilteredTools() {
    try {
      List<Tool> filtered = List.from(_tools);

      // Apply location filter
      if (_filterLocation != 'all') {
        filtered = filtered
            .where((tool) => tool.currentLocation == _filterLocation)
            .toList();
      }

      // Apply brand filter
      if (_filterBrand != 'all') {
        filtered = filtered
            .where((tool) => tool.brand == _filterBrand)
            .toList();
      }

      // Apply favorites filter
      if (_filterFavorites) {
        filtered = filtered.where((tool) => tool.isFavorite).toList();
      }

      // Apply search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered.where((tool) {
          return tool.title.toLowerCase().contains(query) ||
              tool.brand.toLowerCase().contains(query) ||
              tool.uniqueId.toLowerCase().contains(query) ||
              tool.description.toLowerCase().contains(query);
        }).toList();
      }

      return _sortTools(filtered);
    } catch (e) {
      print('Error filtering tools: $e');
      return _sortTools(List.from(_tools));
    }
  }

  List<Tool> _sortTools(List<Tool> tools) {
    try {
      tools.sort((a, b) {
        int comparison;
        switch (_sortBy) {
          case 'name':
            comparison = a.title.compareTo(b.title);
            break;
          case 'date':
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
          case 'brand':
            comparison = a.brand.compareTo(b.brand);
            break;
          default:
            comparison = a.createdAt.compareTo(b.createdAt);
        }
        return _sortAscending ? comparison : -comparison;
      });

      return tools;
    } catch (e) {
      print('Error sorting tools: $e');
      return tools;
    }
  }

  void setSearchQuery(String query) {
    try {
      _searchQuery = query;
      notifyListeners();
    } catch (e) {
      print('Error setting search query: $e');
    }
  }

  void setSort(String sortBy, bool ascending) {
    try {
      _sortBy = sortBy;
      _sortAscending = ascending;
      notifyListeners();
    } catch (e) {
      print('Error setting sort: $e');
    }
  }

  Future<void> loadTools({bool forceRefresh = false}) async {
    if (_isLoading) return;
    //  ════════ Exception caught by foundation library ════════════════════════════════
    // setState() or markNeedsBuild() called during build.
    //  improve this snippet
    //  and infinity loading  make improviments
    _isLoading = true;
    notifyListeners();

    try {
      await LocalDatabase.init();

      // Lazy loading - show cached data first
      final cachedTools = LocalDatabase.tools.values.toList();
      if (cachedTools.isNotEmpty) {
        _tools = cachedTools.where((tool) => tool != null).toList();
        notifyListeners(); // Update UI immediately
      }

      // Then sync with Firebase in background
      if (forceRefresh || await LocalDatabase.shouldRefreshCache()) {
        await _syncWithFirebase();
        await LocalDatabase.saveCacheTimestamp();
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      print('Error loading tools: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTool(Tool tool, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate
      if (tool.title.isEmpty || tool.brand.isEmpty || tool.uniqueId.isEmpty) {
        throw Exception('Заполните все обязательные поля');
      }

      // Upload image
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          tool = tool.copyWith(imageUrl: imageUrl);
        } else {
          tool = tool.copyWith(localImagePath: imageFile.path);
        }
      }

      _tools.add(tool);
      await LocalDatabase.tools.put(tool.id, tool);

      await _addToSyncQueue(
        action: 'create',
        collection: 'tools',
        data: tool.toJson(),
      );

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Инструмент успешно добавлен',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось добавить инструмент: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTool(Tool tool, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate
      if (tool.title.isEmpty || tool.brand.isEmpty || tool.uniqueId.isEmpty) {
        throw Exception('Заполните все обязательные поля');
      }

      // Upload new image
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          tool = tool.copyWith(imageUrl: imageUrl, localImagePath: null);
        } else {
          tool = tool.copyWith(localImagePath: imageFile.path, imageUrl: null);
        }
      }

      final index = _tools.indexWhere((t) => t.id == tool.id);
      if (index != -1) {
        _tools[index] = tool;
        await LocalDatabase.tools.put(tool.id, tool);

        await _addToSyncQueue(
          action: 'update',
          collection: 'tools',
          data: tool.toJson(),
        );

        ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext!,
          'Инструмент успешно обновлен',
        );
      } else {
        throw Exception('Инструмент не найден');
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось обновить инструмент: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTool(String toolId) async {
    try {
      final toolIndex = _tools.indexWhere((t) => t.id == toolId);
      if (toolIndex == -1) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Инструмент не найден',
        );
        return;
      }

      _tools.removeAt(toolIndex);
      await LocalDatabase.tools.delete(toolId);

      await _addToSyncQueue(
        action: 'delete',
        collection: 'tools',
        data: {'id': toolId},
      );

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Инструмент успешно удален',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось удалить инструмент: ${e.toString()}',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteSelectedTools() async {
    try {
      final selectedTools = _tools.where((t) => t.isSelected).toList();

      if (selectedTools.isEmpty) {
        ErrorHandler.showWarningDialog(
          navigatorKey.currentContext!,
          'Выберите инструменты для удаления',
        );
        return;
      }

      for (final tool in selectedTools) {
        await LocalDatabase.tools.delete(tool.id);
        await _addToSyncQueue(
          action: 'delete',
          collection: 'tools',
          data: {'id': tool.id},
        );
      }

      _tools.removeWhere((t) => t.isSelected);
      _selectionMode = false;

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Удалено ${selectedTools.length} инструментов',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось удалить инструменты: ${e.toString()}',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> duplicateTool(Tool original) async {
    try {
      // Count how many copies already exist
      final copyCount =
          _tools
              .where(
                (t) =>
                    t.title.startsWith(original.title) &&
                    t.title.contains('Копия'),
              )
              .length +
          1;

      final newTool = original.duplicate(copyCount);
      await addTool(newTool);
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось дублировать инструмент: ${e.toString()}',
      );
    }
  }

  Future<void> moveTool(
    String toolId,
    String newLocationId,
    String newLocationName,
  ) async {
    try {
      final toolIndex = _tools.indexWhere((t) => t.id == toolId);
      if (toolIndex == -1) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Инструмент не найден',
        );
        return;
      }

      final tool = _tools[toolIndex];
      final oldLocationId = tool.currentLocation;
      final oldLocationName = tool.currentLocationName;

      final updatedTool = tool.copyWith(
        locationHistory: [
          ...tool.locationHistory,
          LocationHistory(
            date: DateTime.now(),
            locationId: oldLocationId,
            locationName: oldLocationName,
          ),
        ],
        currentLocation: newLocationId,
        currentLocationName: newLocationName,
        updatedAt: DateTime.now(),
        isSelected: false,
      );

      await updateTool(updatedTool);

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Инструмент перемещен в $newLocationName',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось переместить инструмент: ${e.toString()}',
      );
    }
  }

  Future<void> moveSelectedTools(
    String newLocationId,
    String newLocationName,
  ) async {
    try {
      final selectedTools = _tools.where((t) => t.isSelected).toList();

      if (selectedTools.isEmpty) {
        ErrorHandler.showWarningDialog(
          navigatorKey.currentContext!,
          'Выберите инструменты для перемещения',
        );
        return;
      }

      for (final tool in selectedTools) {
        final oldLocationId = tool.currentLocation;
        final oldLocationName = tool.currentLocationName;
        final updatedTool = tool.copyWith(
          locationHistory: [
            ...tool.locationHistory,
            LocationHistory(
              date: DateTime.now(),
              locationId: oldLocationId,
              locationName: oldLocationName,
            ),
          ],
          currentLocation: newLocationId,
          currentLocationName: newLocationName,
          updatedAt: DateTime.now(),
          isSelected: false,
        );

        await LocalDatabase.tools.put(updatedTool.id, updatedTool);
        await _addToSyncQueue(
          action: 'update',
          collection: 'tools',
          data: updatedTool.toJson(),
        );
      }

      await loadTools();
      _selectionMode = false;

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Перемещено ${selectedTools.length} инструментов в $newLocationName',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось переместить инструменты: ${e.toString()}',
      );
    }
  }

  Future<void> toggleFavorite(String toolId) async {
    try {
      final toolIndex = _tools.indexWhere((t) => t.id == toolId);
      if (toolIndex == -1) return;

      final tool = _tools[toolIndex];
      final updatedTool = tool.copyWith(isFavorite: !tool.isFavorite);
      await updateTool(updatedTool);
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось обновить статус избранного',
      );
    }
  }

  Future<void> toggleFavoriteForSelected() async {
    try {
      final selectedTools = _tools.where((t) => t.isSelected).toList();
      if (selectedTools.isEmpty) {
        ErrorHandler.showWarningDialog(
          navigatorKey.currentContext!,
          'Выберите инструменты',
        );
        return;
      }

      for (final tool in selectedTools) {
        final updatedTool = tool.copyWith(isFavorite: !tool.isFavorite);
        await LocalDatabase.tools.put(updatedTool.id, updatedTool);
        await _addToSyncQueue(
          action: 'update',
          collection: 'tools',
          data: updatedTool.toJson(),
        );
      }

      await loadTools();
      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Обновлено ${selectedTools.length} инструментов',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось обновить статус избранного',
      );
    }
  }

  Future<void> _addToSyncQueue({
    required String action,
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      final syncItem = SyncItem(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        action: action,
        collection: collection,
        data: data,
      );
      await LocalDatabase.syncQueue.put(syncItem.id, syncItem);
    } catch (e) {
      print('Error adding to sync queue: $e');
    }
  }

  Future<void> _syncWithFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final syncItems = LocalDatabase.syncQueue.values.toList();

      // Send local changes to Firebase
      for (final item in syncItems) {
        try {
          final docRef = FirebaseFirestore.instance
              .collection('tools')
              .doc(item.data['id'] as String);

          switch (item.action) {
            case 'create':
            case 'update':
              await docRef.set(item.data, SetOptions(merge: true));
              break;
            case 'delete':
              await docRef.delete();
              break;
          }

          await LocalDatabase.syncQueue.delete(item.id);
        } catch (e) {
          print('Error syncing item ${item.id}: $e');
        }
      }

      // Pull changes from Firebase
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('tools')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (final doc in snapshot.docs) {
          final toolData = doc.data();
          final tool = Tool.fromJson({...toolData, 'id': doc.id});
          await LocalDatabase.tools.put(tool.id, tool);
        }
      } catch (e) {
        print('Error pulling from Firebase: $e');
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }
}

// ========== ENHANCED OBJECTS PROVIDER ==========
class ObjectsProvider with ChangeNotifier {
  List<ConstructionObject> _objects = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;
  bool _selectionMode = false;

  List<ConstructionObject> get objects => _getFilteredObjects();
  bool get isLoading => _isLoading;
  bool get selectionMode => _selectionMode;
  List<ConstructionObject> get selectedObjects =>
      _objects.where((o) => o.isSelected).toList();
  bool get hasSelectedObjects => _objects.any((o) => o.isSelected);
  int get totalObjects => _objects.length;

  void toggleSelectionMode() {
    try {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _deselectAllObjects();
      }
      notifyListeners();
    } catch (e) {
      print('Error toggling selection mode: $e');
    }
  }

  void toggleObjectSelection(String objectId) {
    try {
      final index = _objects.indexWhere((o) => o.id == objectId);
      if (index != -1) {
        _objects[index] = _objects[index].copyWith(
          isSelected: !_objects[index].isSelected,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling object selection: $e');
    }
  }

  void selectAllObjects() {
    try {
      for (var i = 0; i < _objects.length; i++) {
        _objects[i] = _objects[i].copyWith(isSelected: true);
      }
      notifyListeners();
    } catch (e) {
      print('Error selecting all objects: $e');
    }
  }

  void _deselectAllObjects() {
    try {
      for (var i = 0; i < _objects.length; i++) {
        _objects[i] = _objects[i].copyWith(isSelected: false);
      }
      notifyListeners();
    } catch (e) {
      print('Error deselecting all objects: $e');
    }
  }

  List<ConstructionObject> _getFilteredObjects() {
    try {
      if (_searchQuery.isEmpty) {
        return _sortObjects(List.from(_objects));
      }

      final query = _searchQuery.toLowerCase();
      final filtered = _objects.where((obj) {
        return obj.name.toLowerCase().contains(query) ||
            obj.description.toLowerCase().contains(query);
      }).toList();

      return _sortObjects(filtered);
    } catch (e) {
      print('Error filtering objects: $e');
      return _sortObjects(List.from(_objects));
    }
  }

  List<ConstructionObject> _sortObjects(List<ConstructionObject> objects) {
    try {
      objects.sort((a, b) {
        int comparison;
        switch (_sortBy) {
          case 'name':
            comparison = a.name.compareTo(b.name);
            break;
          case 'date':
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
          case 'toolCount':
            comparison = a.toolIds.length.compareTo(b.toolIds.length);
            break;
          default:
            comparison = a.name.compareTo(b.name);
        }
        return _sortAscending ? comparison : -comparison;
      });

      return objects;
    } catch (e) {
      print('Error sorting objects: $e');
      return objects;
    }
  }

  void setSearchQuery(String query) {
    try {
      _searchQuery = query;
      notifyListeners();
    } catch (e) {
      print('Error setting search query: $e');
    }
  }

  void setSort(String sortBy, bool ascending) {
    try {
      _sortBy = sortBy;
      _sortAscending = ascending;
      notifyListeners();
    } catch (e) {
      print('Error setting sort: $e');
    }
  }

  Future<void> loadObjects({bool forceRefresh = false}) async {
    if (_isLoading) return;

    // _isLoading = true;
    // notifyListeners();

    try {
      await LocalDatabase.init();

      // Lazy loading
      final cachedObjects = LocalDatabase.objects.values.toList();
      if (cachedObjects.isNotEmpty) {
        _objects = cachedObjects.where((obj) => obj != null).toList();
        notifyListeners();
      }

      if (forceRefresh || await LocalDatabase.shouldRefreshCache()) {
        await _syncWithFirebase();
        await LocalDatabase.saveCacheTimestamp();
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      print('Error loading objects: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addObject(ConstructionObject obj, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate
      if (obj.name.isEmpty) {
        throw Exception('Название объекта обязательно');
      }

      // Upload image
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          obj = obj.copyWith(imageUrl: imageUrl);
        } else {
          obj = obj.copyWith(localImagePath: imageFile.path);
        }
      }

      _objects.add(obj);
      await LocalDatabase.objects.put(obj.id, obj);

      await _addToSyncQueue(
        action: 'create',
        collection: 'objects',
        data: obj.toJson(),
      );

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Объект успешно добавлен',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось добавить объект: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateObject(ConstructionObject obj, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate
      if (obj.name.isEmpty) {
        throw Exception('Название объекта обязательно');
      }

      // Upload new image
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          obj = obj.copyWith(imageUrl: imageUrl, localImagePath: null);
        } else {
          obj = obj.copyWith(localImagePath: imageFile.path, imageUrl: null);
        }
      }

      final index = _objects.indexWhere((o) => o.id == obj.id);
      if (index == -1) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Объект не найден',
        );
        return;
      }

      _objects[index] = obj;
      await LocalDatabase.objects.put(obj.id, obj);

      await _addToSyncQueue(
        action: 'update',
        collection: 'objects',
        data: obj.toJson(),
      );

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Объект успешно обновлен',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось обновить объект: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteObject(String objectId) async {
    try {
      final objectIndex = _objects.indexWhere((o) => o.id == objectId);
      if (objectIndex == -1) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Объект не найден',
        );
        return;
      }

      _objects.removeAt(objectIndex);
      await LocalDatabase.objects.delete(objectId);

      await _addToSyncQueue(
        action: 'delete',
        collection: 'objects',
        data: {'id': objectId},
      );

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Объект успешно удален',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось удалить объект: ${e.toString()}',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteSelectedObjects() async {
    try {
      final selectedObjects = _objects.where((o) => o.isSelected).toList();

      if (selectedObjects.isEmpty) {
        ErrorHandler.showWarningDialog(
          navigatorKey.currentContext!,
          'Выберите объекты для удаления',
        );
        return;
      }

      for (final object in selectedObjects) {
        await LocalDatabase.objects.delete(object.id);
        await _addToSyncQueue(
          action: 'delete',
          collection: 'objects',
          data: {'id': object.id},
        );
      }

      _objects.removeWhere((o) => o.isSelected);
      _selectionMode = false;

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Удалено ${selectedObjects.length} объектов',
      );
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось удалить объекты: ${e.toString()}',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> _addToSyncQueue({
    required String action,
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      final syncItem = SyncItem(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        action: action,
        collection: collection,
        data: data,
      );
      await LocalDatabase.syncQueue.put(syncItem.id, syncItem);
    } catch (e) {
      print('Error adding to sync queue: $e');
    }
  }

  Future<void> _syncWithFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Pull changes from Firebase
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('objects')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (final doc in snapshot.docs) {
          final objectData = doc.data();
          final object = ConstructionObject.fromJson({
            ...objectData,
            'id': doc.id,
          });
          await LocalDatabase.objects.put(object.id, object);
        }
      } catch (e) {
        print('Firebase sync error: $e');
      }
    } catch (e) {
      print('Objects sync error: $e');
    }
  }
}

// ========== MODERN SELECTION TOOL CARD ==========
class SelectionToolCard extends StatelessWidget {
  final Tool tool;
  final bool selectionMode;
  final VoidCallback onTap;

  const SelectionToolCard({
    super.key,
    required this.tool,
    required this.selectionMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ToolsProvider>(
      builder: (context, toolsProvider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: selectionMode
                ? () {
                    toolsProvider.toggleToolSelection(tool.id);
                  }
                : onTap,
            onLongPress: () {
              if (!selectionMode) {
                toolsProvider.toggleSelectionMode();
                toolsProvider.toggleToolSelection(tool.id);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  if (selectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Checkbox(
                        value: tool.isSelected,
                        onChanged: (value) {
                          toolsProvider.toggleToolSelection(tool.id);
                        },
                        shape: const CircleBorder(),
                      ),
                    ),

                  // Tool Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: tool.displayImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image(
                              image: tool.displayImage!.startsWith('http')
                                  ? NetworkImage(tool.displayImage!)
                                        as ImageProvider
                                  : FileImage(File(tool.displayImage!)),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.build,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.build,
                              color: Theme.of(context).colorScheme.primary,
                              size: 30,
                            ),
                          ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tool.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!selectionMode)
                              IconButton(
                                icon: Icon(
                                  tool.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: tool.isFavorite
                                      ? Colors.red
                                      : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  toolsProvider.toggleFavorite(tool.id);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          tool.brand,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tool.currentLocationName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (!selectionMode)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('Редактировать'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditToolScreen(tool: tool),
                                ),
                              );
                            },
                          ),
                        ),
                        if (tool.currentLocation == 'garage')
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(Icons.copy),
                              title: const Text('Дублировать'),
                              onTap: () {
                                Navigator.pop(context);
                                toolsProvider.duplicateTool(tool);
                              },
                            ),
                          ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(Icons.share),
                            title: const Text('Поделиться отчетом'),
                            onTap: () {
                              Navigator.pop(context);
                              ReportService.shareToolReport(tool, context);
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(Icons.print),
                            title: const Text('Печать отчета'),
                            onTap: () {
                              Navigator.pop(context);
                              ReportService.printToolReport(tool, context);
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            title: const Text(
                              'Удалить',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Подтверждение удаления'),
                                  content: Text('Удалить "${tool.title}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await toolsProvider.deleteTool(tool.id);
                                      },
                                      child: const Text(
                                        'Удалить',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ========== ADD/EDIT TOOL SCREEN ==========
class AddEditToolScreen extends StatefulWidget {
  final Tool? tool;

  const AddEditToolScreen({super.key, this.tool});

  @override
  _AddEditToolScreenState createState() => _AddEditToolScreenState();
}

class _AddEditToolScreenState extends State<AddEditToolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _uniqueIdController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  String? _imageUrl;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.tool != null) {
      _titleController.text = widget.tool!.title;
      _descriptionController.text = widget.tool!.description;
      _brandController.text = widget.tool!.brand;
      _uniqueIdController.text = widget.tool!.uniqueId;
      _imageUrl = widget.tool!.imageUrl;
      _localImagePath = widget.tool!.localImagePath;
    } else {
      _uniqueIdController.text = IdGenerator.generateUniqueId();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _uniqueIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImageService.pickImage();
    if (file != null) {
      setState(() {
        _imageFile = file;
        _imageUrl = null;
        _localImagePath = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    final file = await ImageService.takePhoto();
    if (file != null) {
      setState(() {
        _imageFile = file;
        _imageUrl = null;
        _localImagePath = null;
      });
    }
  }

  Future<void> _saveTool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final tool = Tool(
        id: widget.tool?.id ?? IdGenerator.generateToolId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        brand: _brandController.text.trim(),
        uniqueId: _uniqueIdController.text.trim(),
        imageUrl: _imageUrl,
        localImagePath: _localImagePath,
        currentLocation: widget.tool?.currentLocation ?? 'garage',
        currentLocationName: widget.tool?.currentLocationName ?? 'Гараж',
        locationHistory: widget.tool?.locationHistory ?? [],
        isFavorite: widget.tool?.isFavorite ?? false,
        createdAt: widget.tool?.createdAt ?? DateTime.now(),
        userId: authProvider.user?.uid ?? 'local',
      );

      if (widget.tool == null) {
        await toolsProvider.addTool(tool, imageFile: _imageFile);
      } else {
        await toolsProvider.updateTool(tool, imageFile: _imageFile);
      }

      Navigator.pop(context);
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка сохранения: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.tool != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Редактировать инструмент' : 'Добавить инструмент',
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Подтверждение удаления'),
                    content: Text('Удалить "${widget.tool!.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final toolsProvider = Provider.of<ToolsProvider>(
                            context,
                            listen: false,
                          );
                          await toolsProvider.deleteTool(widget.tool!.id);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Удалить',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _showImagePickerDialog,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              Theme.of(
                                context,
                              ).colorScheme.secondary.withOpacity(0.1),
                            ],
                          ),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _getImageWidget(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Название инструмента *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите название';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Brand
                    TextFormField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        labelText: 'Бренд *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.branding_watermark),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите бренд';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Unique ID
                    TextFormField(
                      controller: _uniqueIdController,
                      decoration: InputDecoration(
                        labelText: 'Уникальный идентификатор *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.qr_code),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            _uniqueIdController.text =
                                IdGenerator.generateUniqueId();
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите идентификатор';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.description),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveTool,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEdit ? 'Сохранить изменения' : 'Добавить инструмент',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _getImageWidget() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_imageFile!, fit: BoxFit.cover),
      );
    } else if (_imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    } else if (_localImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(_localImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Добавить фото инструмента',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Сделать фото'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (_imageFile != null ||
                  _imageUrl != null ||
                  _localImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Удалить фото',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imageFile = null;
                      _imageUrl = null;
                      _localImagePath = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// ========== MODERN GARAGE SCREEN ==========
class EnhancedGarageScreen extends StatefulWidget {
  const EnhancedGarageScreen({super.key});

  @override
  State<EnhancedGarageScreen> createState() => _EnhancedGarageScreenState();
}

class _EnhancedGarageScreenState extends State<EnhancedGarageScreen> {
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      body: StreamBuilder<List<Tool>>(
        stream: _getToolsStream(toolsProvider),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          if (snapshot.hasError) {
            return _buildErrorScreen(snapshot.error.toString());
          }

          final tools = snapshot.data ?? [];
          final garageTools = tools
              .where((t) => t.currentLocation == 'garage')
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Мой Гараж',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${garageTools.length} инструментов доступно',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats cards
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatCard(
                            context,
                            'Всего',
                            '${tools.length}',
                            Icons.build,
                            Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(width: 10),
                          _buildStatCard(
                            context,
                            'В гараже',
                            '${garageTools.length}',
                            Icons.garage,
                            Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(width: 10),
                          _buildStatCard(
                            context,
                            'Избранные',
                            '${tools.where((t) => t.isFavorite).length}',
                            Icons.favorite,
                            Colors.white.withOpacity(0.2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddEditToolScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        toolsProvider.toggleSelectionMode();
                      },
                      icon: const Icon(Icons.checklist),
                      label: Text(
                        toolsProvider.selectionMode ? 'Отменить' : 'Выбрать',
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tools List
              Expanded(
                child: garageTools.isEmpty
                    ? _buildEmptyGarage()
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: garageTools.length,
                        itemBuilder: (context, index) {
                          final tool = garageTools[index];
                          return SelectionToolCard(
                            tool: tool,
                            selectionMode: toolsProvider.selectionMode,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EnhancedToolDetailsScreen(tool: tool),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton:
          toolsProvider.selectionMode && toolsProvider.hasSelectedTools
          ? FloatingActionButton.extended(
              onPressed: () {
                _showGarageSelectionActions(context);
              },
              icon: const Icon(Icons.more_vert),
              label: Text('${toolsProvider.selectedTools.length}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Stream<List<Tool>> _getToolsStream(ToolsProvider provider) {
    return Stream.fromFuture(
      provider.loadTools(),
    ).asyncMap((_) => provider.tools);
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Загрузка гаража...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<ToolsProvider>(
                  context,
                  listen: false,
                );
                provider.loadTools(forceRefresh: true);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGarage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.garage, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'Гараж пуст',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Text(
            'Добавьте инструменты в гараж',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditToolScreen(),
                ),
              );
            },
            child: const Text('Добавить первый инструмент'),
          ),
        ],
      ),
    );
  }

  void _showGarageSelectionActions(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final selectedCount = toolsProvider.selectedTools.length;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Выбрано: $selectedCount инструментов',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('Добавить в избранное'),
                onTap: () {
                  Navigator.pop(context);
                  toolsProvider.toggleFavoriteForSelected();
                },
              ),

              ListTile(
                leading: const Icon(Icons.move_to_inbox, color: Colors.blue),
                title: const Text('Переместить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MoveToolsScreen(
                        selectedTools: toolsProvider.selectedTools,
                      ),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Поделиться отчетами'),
                onTap: () async {
                  Navigator.pop(context);
                  // Share each tool report
                  for (final tool in toolsProvider.selectedTools) {
                    await ReportService.shareToolReport(tool, context);
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Подтверждение удаления'),
                      content: Text(
                        'Удалить выбранные $selectedCount инструментов?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await toolsProvider.deleteSelectedTools();
                          },
                          child: const Text(
                            'Удалить',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ========== TOOLS LIST SCREEN WITH STREAM BUILDER ==========
class ToolsListScreen extends StatefulWidget {
  const ToolsListScreen({super.key});

  @override
  State<ToolsListScreen> createState() => _ToolsListScreenState();
}

class _ToolsListScreenState extends State<ToolsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<int>(
          stream: Stream.fromFuture(
            toolsProvider.loadTools(),
          ).asyncMap((_) => toolsProvider.totalTools),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Text('Все инструменты ($count)');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => toolsProvider.loadTools(forceRefresh: true),
          ),
        ],
      ),
      body: StreamBuilder<List<Tool>>(
        stream: _getToolsStream(toolsProvider),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          if (snapshot.hasError) {
            return _buildErrorScreen(snapshot.error.toString());
          }

          final tools = snapshot.data ?? [];

          return Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск инструментов...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    toolsProvider.setSearchQuery(value);
                  },
                ),
              ),

              // Active filters indicator
              if (toolsProvider.filterLocation != 'all' ||
                  toolsProvider.filterBrand != 'all' ||
                  toolsProvider.filterFavorites)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getActiveFiltersText(toolsProvider),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => toolsProvider.clearAllFilters(),
                        child: const Text(
                          'Очистить',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: tools.isEmpty
                    ? _buildEmptyToolsScreen()
                    : ListView.builder(
                        itemCount: tools.length,
                        itemBuilder: (context, index) {
                          final tool = tools[index];
                          return SelectionToolCard(
                            tool: tool,
                            selectionMode: toolsProvider.selectionMode,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EnhancedToolDetailsScreen(tool: tool),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: toolsProvider.selectionMode
          ? FloatingActionButton.extended(
              onPressed: () {
                if (toolsProvider.hasSelectedTools) {
                  _showSelectionActions(context);
                }
              },
              icon: const Icon(Icons.more_vert),
              label: Text('${toolsProvider.selectedTools.length}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditToolScreen(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Stream<List<Tool>> _getToolsStream(ToolsProvider provider) {
    return Stream.fromFuture(
      provider.loadTools(),
    ).asyncMap((_) => provider.tools);
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Загрузка инструментов...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<ToolsProvider>(
                  context,
                  listen: false,
                );
                provider.loadTools(forceRefresh: true);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyToolsScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            'Нет инструментов',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditToolScreen(),
                ),
              );
            },
            child: const Text('Добавить инструмент'),
          ),
        ],
      ),
    );
  }

  String _getActiveFiltersText(ToolsProvider provider) {
    final filters = <String>[];

    if (provider.filterLocation != 'all') {
      filters.add(
        provider.filterLocation == 'garage' ? 'В гараже' : 'На объекте',
      );
    }

    if (provider.filterBrand != 'all') {
      filters.add('Бренд: ${provider.filterBrand}');
    }

    if (provider.filterFavorites) {
      filters.add('Избранные');
    }

    return filters.join(', ');
  }

  void _showFilterDialog(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Фильтры инструментов',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Location filter
                  ExpansionTile(
                    title: const Text('Местоположение'),
                    children: [
                      RadioListTile<String>(
                        title: const Text('Все'),
                        value: 'all',
                        groupValue: toolsProvider.filterLocation,
                        onChanged: (value) {
                          setState(() {});
                          toolsProvider.setFilterLocation(value!);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Гараж'),
                        value: 'garage',
                        groupValue: toolsProvider.filterLocation,
                        onChanged: (value) {
                          setState(() {});
                          toolsProvider.setFilterLocation(value!);
                        },
                      ),
                      ...objectsProvider.objects.map(
                        (object) => RadioListTile<String>(
                          title: Text(object.name),
                          value: object.id,
                          groupValue: toolsProvider.filterLocation,
                          onChanged: (value) {
                            setState(() {});
                            toolsProvider.setFilterLocation(value!);
                          },
                        ),
                      ),
                    ],
                  ),

                  // Brand filter
                  ExpansionTile(
                    title: const Text('Бренд'),
                    children: toolsProvider.uniqueBrands
                        .map(
                          (brand) => RadioListTile<String>(
                            title: Text(brand == 'all' ? 'Все' : brand),
                            value: brand,
                            groupValue: toolsProvider.filterBrand,
                            onChanged: (value) {
                              setState(() {});
                              toolsProvider.setFilterBrand(value!);
                            },
                          ),
                        )
                        .toList(),
                  ),

                  // Favorites filter
                  SwitchListTile(
                    title: const Text('Только избранные'),
                    value: toolsProvider.filterFavorites,
                    onChanged: (value) {
                      toolsProvider.setFilterFavorites(value);
                    },
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => toolsProvider.clearAllFilters(),
                          child: const Text('Сбросить все'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Применить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSelectionActions(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final selectedCount = toolsProvider.selectedTools.length;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Выбрано: $selectedCount инструментов',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('Добавить в избранное'),
                onTap: () {
                  Navigator.pop(context);
                  toolsProvider.toggleFavoriteForSelected();
                },
              ),

              ListTile(
                leading: const Icon(Icons.move_to_inbox, color: Colors.blue),
                title: const Text('Переместить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MoveToolsScreen(
                        selectedTools: toolsProvider.selectedTools,
                      ),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Поделиться отчетами'),
                onTap: () async {
                  Navigator.pop(context);
                  for (final tool in toolsProvider.selectedTools) {
                    await ReportService.shareToolReport(tool, context);
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  _showMultiDeleteDialog(context);
                },
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMultiDeleteDialog(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final selectedCount = toolsProvider.selectedTools.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить выбранные $selectedCount инструментов?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await toolsProvider.deleteSelectedTools();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ========== ENHANCED TOOL DETAILS SCREEN ==========
class EnhancedToolDetailsScreen extends StatelessWidget {
  final Tool tool;

  const EnhancedToolDetailsScreen({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'tool-${tool.id}',
                child: tool.displayImage != null
                    ? Image(
                        image: tool.displayImage!.startsWith('http')
                            ? NetworkImage(tool.displayImage!) as ImageProvider
                            : FileImage(File(tool.displayImage!)),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.2),
                              theme.colorScheme.secondary.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.build,
                            size: 100,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                      ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => ReportService.shareToolReport(tool, context),
              ),
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () => ReportService.printToolReport(tool, context),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Редактировать'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditToolScreen(tool: tool),
                          ),
                        );
                      },
                    ),
                  ),
                  if (tool.currentLocation == 'garage')
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.copy),
                        title: const Text('Дублировать'),
                        onTap: () {
                          Navigator.pop(context);
                          final toolsProvider = Provider.of<ToolsProvider>(
                            context,
                            listen: false,
                          );
                          toolsProvider.duplicateTool(tool);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text(
                        'Удалить',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () => _showDeleteConfirmation(context),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tool.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Consumer<ToolsProvider>(
                        builder: (context, toolsProvider, child) {
                          return IconButton(
                            icon: Icon(
                              tool.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: tool.isFavorite ? Colors.red : null,
                              size: 30,
                            ),
                            onPressed: () {
                              toolsProvider.toggleFavorite(tool.id);
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.1),
                              theme.colorScheme.secondary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tool.brand,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        tool.uniqueId,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Description
                  if (tool.description.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Описание',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tool.description,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Details Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildDetailCard(
                        icon: Icons.location_on,
                        title: 'Местоположение',
                        value: tool.currentLocationName,
                        color: Colors.blue,
                      ),
                      _buildDetailCard(
                        icon: Icons.calendar_today,
                        title: 'Добавлен',
                        value: DateFormat('dd.MM.yyyy').format(tool.createdAt),
                        color: Colors.green,
                      ),
                      _buildDetailCard(
                        icon: Icons.update,
                        title: 'Обновлен',
                        value: DateFormat('dd.MM.yyyy').format(tool.updatedAt),
                        color: Colors.orange,
                      ),
                      _buildDetailCard(
                        icon: Icons.star,
                        title: 'Статус',
                        value: tool.isFavorite ? 'Избранный' : 'Обычный',
                        color: Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Location History
                  if (tool.locationHistory.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, color: Colors.purple),
                                const SizedBox(width: 10),
                                Text(
                                  'История перемещений',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...tool.locationHistory.map((history) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.purple,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            history.locationName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat(
                                              'dd.MM.yyyy HH:mm',
                                            ).format(history.date),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Consumer<ToolsProvider>(
          builder: (context, toolsProvider, child) {
            return ElevatedButton.icon(
              onPressed: () => _showMoveDialog(context, tool),
              icon: const Icon(Icons.move_to_inbox),
              label: const Text('Переместить инструмент'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить "${tool.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final toolsProvider = Provider.of<ToolsProvider>(
                context,
                listen: false,
              );
              await toolsProvider.deleteTool(tool.id);
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(BuildContext context, Tool tool) {
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String? selectedLocationId = tool.currentLocation;
        String? selectedLocationName = tool.currentLocationName;
        final objects = objectsProvider.objects;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Переместить инструмент',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Garage option
                  ListTile(
                    leading: const Icon(Icons.garage, color: Colors.blue),
                    title: const Text('Гараж'),
                    trailing: selectedLocationId == 'garage'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedLocationId = 'garage';
                        selectedLocationName = 'Гараж';
                      });
                    },
                  ),

                  const Divider(),

                  // Objects options
                  ...objects.map((object) {
                    return ListTile(
                      leading: const Icon(
                        Icons.location_city,
                        color: Colors.orange,
                      ),
                      title: Text(object.name),
                      subtitle: Text('${object.toolIds.length} инструментов'),
                      trailing: selectedLocationId == object.id
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedLocationId = object.id;
                          selectedLocationName = object.name;
                        });
                      },
                    );
                  }),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedLocationId != null &&
                                selectedLocationName != null) {
                              await toolsProvider.moveTool(
                                tool.id,
                                selectedLocationId!,
                                selectedLocationName!,
                              );
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Переместить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ========== OBJECT CARD ==========
class ObjectCard extends StatelessWidget {
  final ConstructionObject object;
  final ToolsProvider toolsProvider;
  final bool selectionMode;
  final VoidCallback onTap;

  const ObjectCard({
    super.key,
    required this.object,
    required this.toolsProvider,
    required this.selectionMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final toolsOnObject = toolsProvider.tools
        .where((tool) => tool.currentLocation == object.id)
        .toList();

    return Consumer<ObjectsProvider>(
      builder: (context, objectsProvider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: selectionMode
                ? () {
                    objectsProvider.toggleObjectSelection(object.id);
                  }
                : onTap,
            onLongPress: () {
              if (!selectionMode) {
                objectsProvider.toggleSelectionMode();
                objectsProvider.toggleObjectSelection(object.id);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  if (selectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Checkbox(
                        value: object.isSelected,
                        onChanged: (value) {
                          objectsProvider.toggleObjectSelection(object.id);
                        },
                        shape: const CircleBorder(),
                      ),
                    ),

                  // Object Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.withOpacity(0.1),
                          Colors.orange.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: object.displayImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image(
                              image: object.displayImage!.startsWith('http')
                                  ? NetworkImage(object.displayImage!)
                                        as ImageProvider
                                  : FileImage(File(object.displayImage!)),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.location_city,
                                    color: Colors.orange,
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.location_city,
                              color: Colors.orange,
                              size: 30,
                            ),
                          ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          object.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        if (object.description.isNotEmpty)
                          Text(
                            object.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            const Icon(
                              Icons.build,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${toolsOnObject.length} инструментов',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (!selectionMode)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('Редактировать'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditObjectScreen(object: object),
                                ),
                              );
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            title: const Text(
                              'Удалить',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Подтверждение удаления'),
                                  content: Text('Удалить "${object.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await objectsProvider.deleteObject(
                                          object.id,
                                        );
                                      },
                                      child: const Text(
                                        'Удалить',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ========== ADD/EDIT OBJECT SCREEN ==========
class AddEditObjectScreen extends StatefulWidget {
  final ConstructionObject? object;

  const AddEditObjectScreen({super.key, this.object});

  @override
  _AddEditObjectScreenState createState() => _AddEditObjectScreenState();
}

class _AddEditObjectScreenState extends State<AddEditObjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  String? _imageUrl;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.object != null) {
      _nameController.text = widget.object!.name;
      _descriptionController.text = widget.object!.description;
      _imageUrl = widget.object!.imageUrl;
      _localImagePath = widget.object!.localImagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImageService.pickImage();
    if (file != null) {
      setState(() {
        _imageFile = file;
        _imageUrl = null;
        _localImagePath = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    final file = await ImageService.takePhoto();
    if (file != null) {
      setState(() {
        _imageFile = file;
        _imageUrl = null;
        _localImagePath = null;
      });
    }
  }

  Future<void> _saveObject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final objectsProvider = Provider.of<ObjectsProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final object = ConstructionObject(
        id: widget.object?.id ?? IdGenerator.generateObjectId(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrl,
        localImagePath: _localImagePath,
        toolIds: widget.object?.toolIds ?? [],
        createdAt: widget.object?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        userId: authProvider.user?.uid ?? 'local',
      );

      if (widget.object == null) {
        await objectsProvider.addObject(object, imageFile: _imageFile);
      } else {
        await objectsProvider.updateObject(object, imageFile: _imageFile);
      }

      Navigator.pop(context);
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка сохранения: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.object != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактировать объект' : 'Добавить объект'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Подтверждение удаления'),
                    content: Text('Удалить "${widget.object!.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final objectsProvider = Provider.of<ObjectsProvider>(
                            context,
                            listen: false,
                          );
                          await objectsProvider.deleteObject(widget.object!.id);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Удалить',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _showImagePickerDialog,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              Theme.of(
                                context,
                              ).colorScheme.secondary.withOpacity(0.1),
                            ],
                          ),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _getImageWidget(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Название объекта *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите название объекта';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.description),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveObject,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEdit ? 'Сохранить изменения' : 'Добавить объект',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _getImageWidget() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_imageFile!, fit: BoxFit.cover),
      );
    } else if (_imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    } else if (_localImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(_localImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_city, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Добавить фото объекта',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Сделать фото'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (_imageFile != null ||
                  _imageUrl != null ||
                  _localImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Удалить фото',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imageFile = null;
                      _imageUrl = null;
                      _localImagePath = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// ========== OBJECT DETAILS SCREEN ==========
class ObjectDetailsScreen extends StatelessWidget {
  final ConstructionObject object;

  const ObjectDetailsScreen({super.key, required this.object});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Tool>>(
      stream: _getToolsStream(context),
      builder: (context, snapshot) {
        Provider.of<ToolsProvider>(context);
        final toolsOnObject =
            snapshot.data
                ?.where((tool) => tool.currentLocation == object.id)
                .toList() ??
            [];

        return Scaffold(
          appBar: AppBar(
            title: Text(object.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditObjectScreen(object: object),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Object Image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.grey.shade100, Colors.grey.shade200],
                  ),
                ),
                child: object.displayImage != null
                    ? Image(
                        image: object.displayImage!.startsWith('http')
                            ? NetworkImage(object.displayImage!)
                                  as ImageProvider
                            : FileImage(File(object.displayImage!)),
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Icon(
                          Icons.location_city,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                      ),
              ),

              // Object Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      object.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (object.description.isNotEmpty)
                      Text(
                        object.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.build, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Инструментов на объекте: ${toolsOnObject.length}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Создан: ${DateFormat('dd.MM.yyyy').format(object.createdAt)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Tools on Object
              Expanded(
                child: toolsOnObject.isEmpty
                    ? _buildEmptyObjectTools()
                    : ListView.builder(
                        itemCount: toolsOnObject.length,
                        itemBuilder: (context, index) {
                          final tool = toolsOnObject[index];
                          return SelectionToolCard(
                            tool: tool,
                            selectionMode: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EnhancedToolDetailsScreen(tool: tool),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Stream<List<Tool>> _getToolsStream(BuildContext context) {
    final provider = Provider.of<ToolsProvider>(context, listen: false);
    return Stream.fromFuture(
      provider.loadTools(),
    ).asyncMap((_) => provider.tools);
  }

  Widget _buildEmptyObjectTools() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'На объекте нет инструментов',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Переместите инструменты на этот объект',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ========== ENHANCED OBJECTS LIST SCREEN WITH STREAM BUILDER ==========
class EnhancedObjectsListScreen extends StatefulWidget {
  const EnhancedObjectsListScreen({super.key});

  @override
  State<EnhancedObjectsListScreen> createState() =>
      _EnhancedObjectsListScreenState();
}

class _EnhancedObjectsListScreenState extends State<EnhancedObjectsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ObjectsProvider>(context, listen: false);
      provider.loadObjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<int>(
          stream: Stream.fromFuture(
            objectsProvider.loadObjects(),
          ).asyncMap((_) => objectsProvider.totalObjects),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Text('Объекты ($count)');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => objectsProvider.loadObjects(forceRefresh: true),
          ),
        ],
      ),
      body: StreamBuilder<List<ConstructionObject>>(
        stream: _getObjectsStream(objectsProvider),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          if (snapshot.hasError) {
            return _buildErrorScreen(snapshot.error.toString());
          }

          final objects = snapshot.data ?? [];

          return Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск объектов...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    objectsProvider.setSearchQuery(value);
                  },
                ),
              ),

              // Objects List
              Expanded(
                child: objects.isEmpty
                    ? _buildEmptyObjectsScreen()
                    : ListView.builder(
                        itemCount: objects.length,
                        itemBuilder: (context, index) {
                          final object = objects[index];
                          return ObjectCard(
                            object: object,
                            toolsProvider: toolsProvider,
                            selectionMode: objectsProvider.selectionMode,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ObjectDetailsScreen(object: object),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: objectsProvider.selectionMode
          ? FloatingActionButton.extended(
              onPressed: () {
                if (objectsProvider.hasSelectedObjects) {
                  _showObjectSelectionActions(context);
                }
              },
              icon: const Icon(Icons.more_vert),
              label: Text('${objectsProvider.selectedObjects.length}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditObjectScreen(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Stream<List<ConstructionObject>> _getObjectsStream(ObjectsProvider provider) {
    return Stream.fromFuture(
      provider.loadObjects(),
    ).asyncMap((_) => provider.objects);
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Загрузка объектов...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<ObjectsProvider>(
                  context,
                  listen: false,
                );
                provider.loadObjects(forceRefresh: true);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyObjectsScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_city, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            'Нет объектов',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditObjectScreen(),
                ),
              );
            },
            child: const Text('Добавить объект'),
          ),
        ],
      ),
    );
  }

  void _showObjectSelectionActions(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );
    final selectedCount = objectsProvider.selectedObjects.length;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Выбрано: $selectedCount объектов',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  _showObjectsDeleteDialog(context);
                },
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showObjectsDeleteDialog(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );
    final selectedCount = objectsProvider.selectedObjects.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить выбранные $selectedCount объектов?\n\nВнимание: Инструменты на этих объектах будут перемещены в гараж.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await objectsProvider.deleteSelectedObjects();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ========== MOVE TOOLS SCREEN ==========
class MoveToolsScreen extends StatefulWidget {
  final List<Tool> selectedTools;

  const MoveToolsScreen({super.key, required this.selectedTools});

  @override
  _MoveToolsScreenState createState() => _MoveToolsScreenState();
}

class _MoveToolsScreenState extends State<MoveToolsScreen> {
  String? _selectedLocationId;
  String? _selectedLocationName;

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Перемещение ${widget.selectedTools.length} инструментов'),
      ),
      body: Column(
        children: [
          // Location Selector
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Выберите место назначения:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // Garage option
                  ListTile(
                    leading: const Icon(Icons.garage, color: Colors.blue),
                    title: const Text('Гараж'),
                    trailing: _selectedLocationId == 'garage'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedLocationId = 'garage';
                        _selectedLocationName = 'Гараж';
                      });
                    },
                  ),

                  const Divider(),

                  // Objects options
                  ...objectsProvider.objects.map((object) {
                    return ListTile(
                      leading: const Icon(
                        Icons.location_city,
                        color: Colors.orange,
                      ),
                      title: Text(object.name),
                      subtitle: Text('${object.toolIds.length} инструментов'),
                      trailing: _selectedLocationId == object.id
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedLocationId = object.id;
                          _selectedLocationName = object.name;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),

          // Selected Tools List
          Expanded(
            child: ListView.builder(
              itemCount: widget.selectedTools.length,
              itemBuilder: (context, index) {
                final tool = widget.selectedTools[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.build,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(tool.title),
                    subtitle: Text(tool.brand),
                    trailing: Text(
                      tool.currentLocationName,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),

          // Move Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: ElevatedButton(
              onPressed: () async {
                if (_selectedLocationId == null ||
                    _selectedLocationName == null) {
                  ErrorHandler.showWarningDialog(
                    context,
                    'Выберите место назначения',
                  );
                  return;
                }

                await toolsProvider.moveSelectedTools(
                  _selectedLocationId!,
                  _selectedLocationName!,
                );

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Переместить ${widget.selectedTools.length} инструментов',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== FAVORITES SCREEN ==========
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<List<Tool>>(
          stream: _getToolsStream(toolsProvider),
          builder: (context, snapshot) {
            final favoriteTools = toolsProvider.favoriteTools;
            return Text('Избранное (${favoriteTools.length})');
          },
        ),
      ),
      body: StreamBuilder<List<Tool>>(
        stream: _getToolsStream(toolsProvider),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          final favoriteTools = toolsProvider.favoriteTools;

          return favoriteTools.isEmpty
              ? _buildEmptyFavoritesScreen()
              : ListView.builder(
                  itemCount: favoriteTools.length,
                  itemBuilder: (context, index) {
                    final tool = favoriteTools[index];
                    return SelectionToolCard(
                      tool: tool,
                      selectionMode: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EnhancedToolDetailsScreen(tool: tool),
                          ),
                        );
                      },
                    );
                  },
                );
        },
      ),
    );
  }

  Stream<List<Tool>> _getToolsStream(ToolsProvider provider) {
    return Stream.fromFuture(
      provider.loadTools(),
    ).asyncMap((_) => provider.tools);
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Загрузка избранного...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFavoritesScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            'Нет избранных инструментов',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Добавьте инструменты в избранное',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ========== MODERN PROFILE SCREEN ==========
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _syncEnabled = true;
  bool _notificationsEnabled = true;
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _syncEnabled = prefs.getBool('sync_enabled') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      final themeIndex = prefs.getInt('theme_mode') ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  Future<void> _changeTheme(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    await _saveSetting('theme_mode', mode.index);
    // You can add theme switching logic here
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header with gradient
            Container(
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: authProvider.profileImage != null
                              ? FileImage(authProvider.profileImage!)
                              : null,
                          child: authProvider.profileImage == null
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                size: 15,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () => _pickProfileImage(authProvider),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      authProvider.user?.email ?? 'Гость',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Менеджер инструментов',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            // Stats Grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<List<Tool>>(
                stream: _getToolsStream(toolsProvider),
                builder: (context, snapshot) {
                  final totalTools = toolsProvider.totalTools;
                  final garageTools = toolsProvider.garageTools.length;
                  final favoriteTools = toolsProvider.favoriteTools.length;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildStatCard(
                        'Всего инструментов',
                        '$totalTools',
                        Icons.build,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'В гараже',
                        '$garageTools',
                        Icons.garage,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Объектов',
                        '${objectsProvider.totalObjects}',
                        Icons.location_city,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Избранных',
                        '$favoriteTools',
                        Icons.favorite,
                        Colors.red,
                      ),
                    ],
                  );
                },
              ),
            ),

            // Settings
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Настройки',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('Синхронизация данных'),
                      trailing: Switch(
                        value: _syncEnabled,
                        onChanged: (value) {
                          setState(() {
                            _syncEnabled = value;
                          });
                          _saveSetting('sync_enabled', value);
                          ErrorHandler.showSuccessDialog(
                            context,
                            value
                                ? 'Синхронизация включена'
                                : 'Синхронизация выключена',
                          );
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Уведомления'),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                          _saveSetting('notifications_enabled', value);
                          ErrorHandler.showSuccessDialog(
                            context,
                            value
                                ? 'Уведомления включены'
                                : 'Уведомления выключены',
                          );
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.color_lens),
                      title: const Text('Тема приложения'),
                      trailing: DropdownButton<ThemeMode>(
                        value: _themeMode,
                        onChanged: (value) {
                          if (value != null) {
                            _changeTheme(value);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Светлая'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Темная'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('Системная'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ReportService.shareInventoryReport(
                        toolsProvider.tools,
                        objectsProvider.objects,
                        context,
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Поделиться отчетом'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _createBackup(
                        context,
                        toolsProvider,
                        objectsProvider,
                      );
                    },
                    icon: const Icon(Icons.backup),
                    label: const Text('Создать резервную копию'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await authProvider.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Выйти'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Stream<List<Tool>> _getToolsStream(ToolsProvider provider) {
    return Stream.fromFuture(
      provider.loadTools(),
    ).asyncMap((_) => provider.tools);
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfileImage(AuthProvider authProvider) async {
    final file = await ImageService.pickImage();
    if (file != null) {
      await authProvider.setProfileImage(file);
      ErrorHandler.showSuccessDialog(context, 'Фото профиля обновлено');
    }
  }

  Future<void> _createBackup(
    BuildContext context,
    ToolsProvider toolsProvider,
    ObjectsProvider objectsProvider,
  ) async {
    try {
      final backupData = {
        'tools': toolsProvider.tools.map((t) => t.toJson()).toList(),
        'objects': objectsProvider.objects.map((o) => o.toJson()).toList(),
        'createdAt': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      final jsonString = jsonEncode(backupData);
      final tempDir = await getTemporaryDirectory();
      final backupFile = File(
        '${tempDir.path}/tooler_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await backupFile.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        text:
            '📱 Резервная копия Tooler\n\n'
            '📅 Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}\n'
            '🛠️ Инструментов: ${toolsProvider.tools.length}\n'
            '🏢 Объектов: ${objectsProvider.objects.length}\n\n'
            '— Создано в Tooler App —',
      );

      ErrorHandler.showSuccessDialog(context, 'Резервная копия создана');
    } catch (e) {
      ErrorHandler.showErrorDialog(
        context,
        'Ошибка при создании резервной копии: $e',
      );
    }
  }
}

// ========== SEARCH SCREEN ==========
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Tool> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final results = toolsProvider.tools.where((tool) {
      return tool.title.toLowerCase().contains(query) ||
          tool.brand.toLowerCase().contains(query) ||
          tool.uniqueId.toLowerCase().contains(query) ||
          tool.description.toLowerCase().contains(query) ||
          tool.currentLocationName.toLowerCase().contains(query);
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Поиск инструментов...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchResults = [];
              });
            },
          ),
        ],
      ),
      body: _searchResults.isEmpty
          ? _buildEmptySearchScreen()
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final tool = _searchResults[index];
                return SelectionToolCard(
                  tool: tool,
                  selectionMode: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EnhancedToolDetailsScreen(tool: tool),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptySearchScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isEmpty
                ? 'Начните вводить для поиска'
                : 'Ничего не найдено',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ========== WELCOME SCREEN ==========
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build, size: 100, color: Colors.white),
                const SizedBox(height: 32),
                const Text(
                  'Добро пожаловать в Tooler!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Простая и эффективная система управления строительными инструментами',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Начать работу',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== ONBOARDING SCREEN ==========
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Управление инструментами',
      'description':
          'Легко добавляйте, редактируйте и отслеживайте все ваши строительные инструменты',
      'icon': Icons.build,
      'color': Colors.blue,
    },
    {
      'title': 'Работа с объектами',
      'description':
          'Создавайте объекты и перемещайте инструменты между гаражом и объектами',
      'icon': Icons.location_city,
      'color': Colors.orange,
    },
    {
      'title': 'Отчеты и PDF',
      'description': 'Создавайте подробные отчеты и делитесь ими с коллегами',
      'icon': Icons.picture_as_pdf,
      'color': Colors.green,
    },
    {
      'title': 'Работа офлайн',
      'description':
          'Продолжайте работу даже без интернета, данные синхронизируются автоматически',
      'icon': Icons.wifi_off,
      'color': Colors.purple,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  widget.onComplete();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                },
                child: Text(
                  'Пропустить',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: page['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page['icon'],
                            size: 70,
                            color: page['color'],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page['title'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          page['description'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots and Next button
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                children: [
                  // Dots
                  ...List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Next/Start button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        widget.onComplete();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AuthScreen(),
                          ),
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Начать' : 'Далее',
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
}

// ========== MODERN AUTH SCREEN ==========
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final file = await ImageService.pickImage();
    if (file != null) {
      setState(() {
        _profileImage = file;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!_isLogin &&
          _passwordController.text != _confirmPasswordController.text) {
        throw Exception('Пароли не совпадают');
      }

      final success = _isLogin
          ? await authProvider.signInWithEmail(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            )
          : await authProvider.signUpWithEmail(
              _emailController.text.trim(),
              _passwordController.text.trim(),
              profileImage: _profileImage,
            );

      if (success) {
        // Navigate directly to main screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        ErrorHandler.showErrorDialog(
          context,
          _isLogin ? 'Неверный email или пароль' : 'Не удалось создать аккаунт',
        );
      }
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo with gradient
              Center(
                child: Column(
                  children: [
                    if (!_isLogin && _profileImage != null)
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: FileImage(_profileImage!),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: IconButton(
                                icon: Icon(
                                  Icons.camera_alt,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                onPressed: _pickProfileImage,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (!_isLogin)
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 30,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Фото',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.build,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    SizedBox(height: _isLogin ? 20 : 10),
                    Text(
                      'Tooler',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Управление строительными инструментами',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите email';
                        }
                        if (!value.contains('@')) {
                          return 'Введите корректный email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите пароль';
                        }
                        if (value.length < 6) {
                          return 'Пароль должен быть не менее 6 символов';
                        }
                        return null;
                      },
                    ),

                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Подтвердите пароль',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Подтвердите пароль';
                          }
                          if (value != _passwordController.text) {
                            return 'Пароли не совпадают';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 20),

                    if (_isLogin)
                      Row(
                        children: [
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return Checkbox(
                                value: authProvider.rememberMe,
                                onChanged: (value) {
                                  authProvider.setRememberMe(value!);
                                },
                              );
                            },
                          ),
                          const Text('Запомнить меня'),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isLogin ? 'Войти' : 'Зарегистрироваться',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _profileImage = null;
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Нет аккаунта? Зарегистрироваться'
                      : 'Уже есть аккаунт? Войти',
                ),
              ),

              const SizedBox(height: 20),

              // Remove quick login button
            ],
          ),
        ),
      ),
    );
  }
}

// ========== MAIN SCREEN ==========
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const EnhancedGarageScreen(),
    const ToolsListScreen(),
    const EnhancedObjectsListScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = [
    'Гараж',
    'Инструменты',
    'Объекты',
    'Избранное',
    'Профиль',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: _selectedIndex == 0 || _selectedIndex == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _generateInventoryReport(context),
                ),
              ]
            : null,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.garage), label: 'Гараж'),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Инструменты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city),
            label: 'Объекты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Избранное',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }

  Future<void> _generateInventoryReport(BuildContext context) async {
    try {
      final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
      final objectsProvider = Provider.of<ObjectsProvider>(
        context,
        listen: false,
      );

      await ReportService.shareInventoryReport(
        toolsProvider.tools,
        objectsProvider.objects,
        context,
      );
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка при создании отчета: $e');
    }
  }
}

// ========== MAIN APP WIDGET ==========
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
            debugShowCheckedModeBanner: false,
            theme: _buildThemeData(),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Ошибка загрузки приложения')),
            ),
            debugShowCheckedModeBanner: false,
          );
        }

        final prefs = snapshot.data!;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
            ChangeNotifierProvider(create: (_) => ToolsProvider()),
            ChangeNotifierProvider(create: (_) => ObjectsProvider()),
            Provider.value(value: prefs),
          ],
          child: MaterialApp(
            title: 'Tooler',
            theme: _buildThemeData(),
            navigatorKey: navigatorKey,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isLoading) {
                  return Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final seenWelcome = prefs.getBool('seen_welcome') ?? false;
                if (!seenWelcome) {
                  return WelcomeScreen(
                    onContinue: () async {
                      await prefs.setBool('seen_welcome', true);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                      );
                    },
                  );
                }

                if (!authProvider.isLoggedIn) {
                  final seenOnboarding =
                      prefs.getBool('seen_onboarding') ?? false;
                  if (!seenOnboarding) {
                    return OnboardingScreen(
                      onComplete: () async {
                        await prefs.setBool('seen_onboarding', true);
                      },
                    );
                  }
                  return const AuthScreen();
                }

                return const MainScreen();
              },
            ),
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }

  ThemeData _buildThemeData() {
    return ThemeData(
      primaryColor: const Color(0xFF4A6FA5),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4A6FA5),
        secondary: Color(0xFF6B8E23),
        surface: Colors.white,
        background: Color(0xFFF5F7FA),
        error: Color(0xFFE63946),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF2D3748),
        onBackground: Color(0xFF2D3748),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF4A6FA5),
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF4A6FA5),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A6FA5), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Color(0xFF4A6FA5)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }
}
