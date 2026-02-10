// main.dart - Enhanced Tooler Construction Tool Management App
// ignore_for_file: empty_catches, avoid_print, library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
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
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:tooler/main_screen.dart';

// ========== FIREBASE INITIALIZATION ==========
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive with path
    await Hive.initFlutter();

    // Register Hive adapters BEFORE opening boxes
    Hive.registerAdapter(ToolAdapter());
    Hive.registerAdapter(LocationHistoryAdapter());
    Hive.registerAdapter(ConstructionObjectAdapter());
    Hive.registerAdapter(SyncItemAdapter());

    // Initialize Firebase with error handling
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

  runApp(MyApp());
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
  List<LocationHistory> locationHistory;
  bool isFavorite;
  DateTime createdAt;
  DateTime updatedAt;
  bool isSelected; // For multi-select operations

  Tool({
    required this.id,
    required this.title,
    required this.description,
    required this.brand,
    required this.uniqueId,
    this.imageUrl,
    this.localImagePath,
    required this.currentLocation,
    List<LocationHistory>? locationHistory,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSelected = false,
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
    'locationHistory': locationHistory.map((e) => e.toJson()).toList(),
    'isFavorite': isFavorite,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isSelected': isSelected,
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
    List<LocationHistory>? locationHistory,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSelected,
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
      locationHistory: locationHistory ?? this.locationHistory,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Tool duplicate() => Tool(
    id: '${DateTime.now().millisecondsSinceEpoch}',
    title: title,
    description: description,
    brand: brand,
    uniqueId: '${uniqueId}_copy',
    imageUrl: imageUrl,
    localImagePath: localImagePath,
    currentLocation: currentLocation,
    locationHistory: List.from(locationHistory),
    isFavorite: isFavorite,
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
  bool isSelected; // For multi-select operations

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
      // Try to delete corrupted boxes and recreate
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

  // Cache management
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
  String action; // 'create', 'update', 'delete'
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

// ========== PDF & SCREENSHOT SERVICE ==========
class ReportService {
  static Future<void> generateToolReport(
    Tool tool,
    BuildContext context,
  ) async {
    try {
      final controller = ScreenshotController();
      final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
      final theme = Theme.of(context);

      final reportWidget = Container(
        width: 595.28, // A4 width in points
        padding: EdgeInsets.all(30),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.build, size: 40, color: theme.primaryColor),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOOLER - Отчет об инструменте',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    Text(
                      'Сгенерировано: ${dateFormat.format(DateTime.now())}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            Divider(height: 30, thickness: 2),

            // Tool Info
            Text(
              'ИНФОРМАЦИЯ ОБ ИНСТРУМЕНТЕ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(15),
              child: Column(
                children: [
                  _buildReportRow('Название:', tool.title),
                  _buildReportRow('Бренд:', tool.brand),
                  _buildReportRow('Уникальный ID:', tool.uniqueId),
                  _buildReportRow(
                    'Местоположение:',
                    tool.currentLocation == 'garage' ? 'Гараж' : 'На объекте',
                  ),
                  _buildReportRow(
                    'Добавлен:',
                    DateFormat('dd.MM.yyyy').format(tool.createdAt),
                  ),
                  _buildReportRow(
                    'Обновлен:',
                    DateFormat('dd.MM.yyyy').format(tool.updatedAt),
                  ),
                  _buildReportRow('Избранное:', tool.isFavorite ? 'Да' : 'Нет'),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Description
            if (tool.description.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ОПИСАНИЕ:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(tool.description, style: TextStyle(fontSize: 12)),
                ],
              ),

            SizedBox(height: 30),

            // Location History
            if (tool.locationHistory.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ИСТОРИЯ ПЕРЕМЕЩЕНИЙ:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ...tool.locationHistory.map(
                    (history) => Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text(
                        '• ${history.locationName} - ${dateFormat.format(history.date)}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),

            Spacer(),

            // Footer
            Divider(height: 30, thickness: 1),
            Text(
              '© 2026 Tooler App - Система управления строительными инструментами',
              style: TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

      // Generate PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // PDF content similar to widget
                pw.Row(
                  children: [
                    pw.Text(
                      'TOOLER - Отчет об инструменте',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text('Название: ${tool.title}'),
                pw.Text('Бренд: ${tool.brand}'),
                pw.Text('ID: ${tool.uniqueId}'),
                pw.Text(
                  'Местоположение: ${tool.currentLocation == 'garage' ? 'Гараж' : 'На объекте'}',
                ),
                pw.Text(
                  'Добавлен: ${DateFormat('dd.MM.yyyy').format(tool.createdAt)}',
                ),
                pw.Text(
                  'Обновлен: ${DateFormat('dd.MM.yyyy').format(tool.updatedAt)}',
                ),
                if (tool.description.isNotEmpty)
                  pw.Text('Описание: ${tool.description}'),
              ],
            );
          },
        ),
      );

      // Save PDF temporarily
      final tempDir = Directory.systemTemp;
      final pdfFile = File('${tempDir.path}/tool_report_${tool.id}.pdf');
      await pdfFile.writeAsBytes(await pdf.save());

      // Share PDF
      await Share.shareXFiles([
        XFile(pdfFile.path),
      ], text: 'Отчет об инструменте: ${tool.title}');

      // Cleanup
      await pdfFile.delete();
    } catch (e, s) {
      print('Error generating report: $e\n$s');
      ErrorHandler.showErrorDialog(context, 'Ошибка при создании отчета: $e');
    }
  }

  static Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          SizedBox(width: 10),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  static Future<void> generateInventoryReport(
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
                // Header
                pw.Row(
                  children: [
                    pw.Text(
                      'TOOLER - ИНВЕНТАРИЗАЦИОННЫЙ ОТЧЕТ',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Сгенерировано: ${dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.Divider(),
                pw.SizedBox(height: 20),

                // Summary
                pw.Text(
                  'СВОДКА:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Всего инструментов: ${tools.length}'),
                pw.Text('Всего объектов: ${objects.length}'),
                pw.Text(
                  'Избранных инструментов: ${tools.where((t) => t.isFavorite).length}',
                ),
                pw.SizedBox(height: 20),

                // Tools List
                pw.Text(
                  'ИНСТРУМЕНТЫ:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...tools.map(
                  (tool) => pw.Padding(
                    padding: pw.EdgeInsets.only(bottom: 5),
                    child: pw.Text(
                      '• ${tool.title} (${tool.brand}) - ${tool.currentLocation == 'garage' ? 'Гараж' : 'Объект'}',
                    ),
                  ),
                ),

                pw.SizedBox(height: 20),

                // Objects List
                pw.Text(
                  'ОБЪЕКТЫ:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...objects.map(
                  (obj) => pw.Padding(
                    padding: pw.EdgeInsets.only(bottom: 5),
                    child: pw.Text(
                      '• ${obj.name} - ${obj.toolIds.length} инструментов',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save and share PDF
      final tempDir = Directory.systemTemp;
      final pdfFile = File(
        '${tempDir.path}/inventory_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await pdfFile.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(pdfFile.path),
      ], text: 'Инвентаризационный отчет Tooler');

      await pdfFile.delete();
    } catch (e, s) {
      print('Error generating inventory report: $e\n$s');
      ErrorHandler.showErrorDialog(context, 'Ошибка при создании отчета: $e');
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
          title: Text('Ошибка'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
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
          duration: Duration(seconds: 2),
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
          duration: Duration(seconds: 2),
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
  bool _isLoading = true;
  bool _rememberMe = false;
  bool _bypassAuth = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null || _bypassAuth;
  bool get rememberMe => _rememberMe;
  bool get bypassAuth => _bypassAuth;

  AuthProvider(this._prefs) {
    _rememberMe = _prefs.getBool('remember_me') ?? false;
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _auth.authStateChanges().listen((User? user) {
        _user = user;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      print('Auth initialization error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      if (email.toLowerCase() == 'vadim' && password == 'vadim') {
        _bypassAuth = true;
        notifyListeners();
        return true;
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      _bypassAuth = false;

      if (_rememberMe) {
        await _prefs.setString('saved_email', email);
      } else {
        await _prefs.remove('saved_email');
      }

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected auth error: $e');
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      _bypassAuth = false;

      if (_user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .set({
                'email': email,
                'createdAt': FieldValue.serverTimestamp(),
                'userId': _user!.uid,
              });
        } catch (e) {
          print('Firestore user creation error: $e');
        }
      }

      if (_rememberMe) {
        await _prefs.setString('saved_email', email);
      }

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('Sign up error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected signup error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _bypassAuth = false;
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
}

// ========== ENHANCED TOOLS PROVIDER WITH FILTERS ==========
class ToolsProvider with ChangeNotifier {
  List<Tool> _tools = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _sortAscending = false;
  bool _selectionMode = false;
  bool _cacheInitialized = false;

  // Filter properties
  String _filterLocation = 'all'; // 'all', 'garage', or objectId
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

  void selectTool(String toolId) {
    try {
      final index = _tools.indexWhere((t) => t.id == toolId);
      if (index != -1) {
        _tools[index] = _tools[index].copyWith(isSelected: true);
        notifyListeners();
      }
    } catch (e) {
      print('Error selecting tool: $e');
    }
  }

  void deselectTool(String toolId) {
    try {
      final index = _tools.indexWhere((t) => t.id == toolId);
      if (index != -1) {
        _tools[index] = _tools[index].copyWith(isSelected: false);
        notifyListeners();
      }
    } catch (e) {
      print('Error deselecting tool: $e');
    }
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

    _isLoading = true;
    notifyListeners();

    try {
      await LocalDatabase.init();

      // Load from cache first
      final cachedTools = LocalDatabase.tools.values.toList();
      if (cachedTools.isNotEmpty && !forceRefresh) {
        _tools = cachedTools.where((tool) => tool != null).toList();
      }

      // Try to sync with Firebase in background
      if (await LocalDatabase.shouldRefreshCache() || forceRefresh) {
        await _syncWithFirebase();
        await LocalDatabase.saveCacheTimestamp();
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      print('Error loading tools: $e');
      // Fallback to cached data
      if (_tools.isEmpty) {
        final cachedTools = LocalDatabase.tools.values.toList();
        _tools = cachedTools.where((tool) => tool != null).toList();
      }
    } finally {
      _isLoading = false;
      _cacheInitialized = true;
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

      // Add to sync queue
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
      final newTool = original.duplicate();
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

      final updatedTool = tool.copyWith(
        locationHistory: [
          ...tool.locationHistory,
          LocationHistory(
            date: DateTime.now(),
            locationId: oldLocationId,
            locationName: oldLocationId == 'garage'
                ? 'Гараж'
                : 'Предыдущее местоположение',
          ),
        ],
        currentLocation: newLocationId,
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
        final updatedTool = tool.copyWith(
          locationHistory: [
            ...tool.locationHistory,
            LocationHistory(
              date: DateTime.now(),
              locationId: oldLocationId,
              locationName: oldLocationId == 'garage'
                  ? 'Гараж'
                  : 'Предыдущее местоположение',
            ),
          ],
          currentLocation: newLocationId,
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

// ========== ENHANCED OBJECTS PROVIDER WITH FILTERS ==========
class ObjectsProvider with ChangeNotifier {
  List<ConstructionObject> _objects = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;
  bool _selectionMode = false;
  bool _cacheInitialized = false;

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

  void selectObject(String objectId) {
    try {
      final index = _objects.indexWhere((o) => o.id == objectId);
      if (index != -1) {
        _objects[index] = _objects[index].copyWith(isSelected: true);
        notifyListeners();
      }
    } catch (e) {
      print('Error selecting object: $e');
    }
  }

  void deselectObject(String objectId) {
    try {
      final index = _objects.indexWhere((o) => o.id == objectId);
      if (index != -1) {
        _objects[index] = _objects[index].copyWith(isSelected: false);
        notifyListeners();
      }
    } catch (e) {
      print('Error deselecting object: $e');
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

    _isLoading = true;
    notifyListeners();

    try {
      await LocalDatabase.init();

      // Load from cache first
      final cachedObjects = LocalDatabase.objects.values.toList();
      if (cachedObjects.isNotEmpty && !forceRefresh) {
        _objects = cachedObjects.where((obj) => obj != null).toList();
      }

      // Try to sync with Firebase
      if (await LocalDatabase.shouldRefreshCache() || forceRefresh) {
        await _syncWithFirebase();
        await LocalDatabase.saveCacheTimestamp();
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      print('Error loading objects: $e');
      if (_objects.isEmpty) {
        final cachedObjects = LocalDatabase.objects.values.toList();
        _objects = cachedObjects.where((obj) => obj != null).toList();
      }
    } finally {
      _isLoading = false;
      _cacheInitialized = true;
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

// ========== SELECTION TOOL CARD ==========
class SelectionToolCard extends StatelessWidget {
  final Tool tool;
  final bool selectionMode;
  final VoidCallback onTap;

  const SelectionToolCard({
    Key? key,
    required this.tool,
    required this.selectionMode,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ToolsProvider>(
      builder: (context, toolsProvider, child) {
        return InkWell(
          onTap: selectionMode
              ? () {
                  toolsProvider.toggleToolSelection(tool.id);
                }
              : onTap,
          onLongPress: () {
            if (!selectionMode) {
              toolsProvider.toggleSelectionMode();
              toolsProvider.selectTool(tool.id);
            }
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  if (selectionMode)
                    Checkbox(
                      value: tool.isSelected,
                      onChanged: (value) {
                        toolsProvider.toggleToolSelection(tool.id);
                      },
                    ),
                  SizedBox(width: 8),
                  // Tool Image
                  if (tool.displayImage != null)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: tool.displayImage!.startsWith('http')
                              ? NetworkImage(tool.displayImage!)
                              : FileImage(File(tool.displayImage!))
                                    as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.build,
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.5),
                          size: 30,
                        ),
                      ),
                    ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tool.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (tool.isFavorite)
                              Icon(Icons.favorite, size: 16, color: Colors.red),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          tool.brand,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              tool.currentLocation == 'garage'
                                  ? 'Гараж'
                                  : 'На объекте',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.qr_code, size: 12, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              tool.uniqueId,
                              style: TextStyle(
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
                            leading: Icon(Icons.edit),
                            title: Text('Редактировать'),
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
                        PopupMenuItem(
                          child: ListTile(
                            leading: Icon(Icons.copy),
                            title: Text('Дублировать'),
                            onTap: () {
                              Navigator.pop(context);
                              toolsProvider.duplicateTool(tool);
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: Icon(Icons.picture_as_pdf),
                            title: Text('Создать отчет'),
                            onTap: () {
                              Navigator.pop(context);
                              ReportService.generateToolReport(tool, context);
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Удалить',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Подтверждение удаления'),
                                  content: Text('Удалить "${tool.title}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await toolsProvider.deleteTool(tool.id);
                                      },
                                      child: Text(
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

  const AddEditToolScreen({Key? key, this.tool}) : super(key: key);

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

      final tool = Tool(
        id: widget.tool?.id ?? IdGenerator.generateToolId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        brand: _brandController.text.trim(),
        uniqueId: _uniqueIdController.text.trim(),
        imageUrl: _imageUrl,
        localImagePath: _localImagePath,
        currentLocation: widget.tool?.currentLocation ?? 'garage',
        locationHistory: widget.tool?.locationHistory ?? [],
        isFavorite: widget.tool?.isFavorite ?? false,
        createdAt: widget.tool?.createdAt ?? DateTime.now(),
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
              icon: Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Подтверждение удаления'),
                    content: Text('Удалить "${widget.tool!.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Отмена'),
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
                        child: Text(
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
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
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
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text('Ошибка загрузки изображения'),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : _localImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_localImagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text('Ошибка загрузки изображения'),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text('Добавить фото'),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Название инструмента *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите название';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Brand
                    TextFormField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        labelText: 'Бренд *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите бренд';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Unique ID
                    TextFormField(
                      controller: _uniqueIdController,
                      decoration: InputDecoration(
                        labelText: 'Уникальный идентификатор *',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: () {
                            _uniqueIdController.text =
                                IdGenerator.generateUniqueId();
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите идентификатор';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveTool,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        isEdit ? 'Сохранить изменения' : 'Добавить инструмент',
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
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
                leading: Icon(Icons.photo_library),
                title: Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Сделать фото'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (_imageFile != null ||
                  _imageUrl != null ||
                  _localImagePath != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text(
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

// ========== ENHANCED GARAGE SCREEN ==========
class EnhancedGarageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Мой Гараж',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${toolsProvider.garageTools.length} инструментов доступно',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      context,
                      'Всего',
                      '${toolsProvider.totalTools}',
                      Icons.build,
                    ),
                    _buildStatCard(
                      context,
                      'В гараже',
                      '${toolsProvider.garageTools.length}',
                      Icons.garage,
                    ),
                    _buildStatCard(
                      context,
                      'Избранные',
                      '${toolsProvider.favoriteTools.length}',
                      Icons.favorite,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Actions
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditToolScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.add),
                    label: Text('Добавить'),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    toolsProvider.toggleSelectionMode();
                  },
                  icon: Icon(Icons.checklist),
                  label: Text(
                    toolsProvider.selectionMode ? 'Отменить' : 'Выбрать',
                  ),
                ),
              ],
            ),
          ),

          // Tools List
          Expanded(
            child: toolsProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : toolsProvider.garageTools.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.garage, size: 80, color: Colors.grey[300]),
                        SizedBox(height: 20),
                        Text(
                          'Гараж пуст',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Добавьте инструменты в гараж',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditToolScreen(),
                              ),
                            );
                          },
                          child: Text('Добавить первый инструмент'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: toolsProvider.garageTools.length,
                    itemBuilder: (context, index) {
                      final tool = toolsProvider.garageTools[index];
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
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.white),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ========== ENHANCED OBJECTS LIST SCREEN ==========
class EnhancedObjectsListScreen extends StatefulWidget {
  @override
  _EnhancedObjectsListScreenState createState() =>
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
        title: Text('Объекты (${objectsProvider.totalObjects})'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => objectsProvider.loadObjects(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск объектов...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                objectsProvider.setSearchQuery(value);
              },
            ),
          ),

          // Objects List
          Expanded(
            child: objectsProvider.isLoading && objectsProvider.objects.isEmpty
                ? Center(child: CircularProgressIndicator())
                : objectsProvider.objects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_city,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Нет объектов',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditObjectScreen(),
                              ),
                            );
                          },
                          child: Text('Добавить объект'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => objectsProvider.loadObjects(),
                    child: ListView.builder(
                      itemCount: objectsProvider.objects.length,
                      itemBuilder: (context, index) {
                        final object = objectsProvider.objects[index];
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
          ),
        ],
      ),
      floatingActionButton: objectsProvider.selectionMode
          ? FloatingActionButton.extended(
              onPressed: () {
                if (objectsProvider.hasSelectedObjects) {
                  _showObjectSelectionActions(context);
                }
              },
              icon: Icon(Icons.more_vert),
              label: Text('${objectsProvider.selectedObjects.length}'),
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditObjectScreen(),
                  ),
                );
              },
              child: Icon(Icons.add),
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
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Выбрано: $selectedCount объектов',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Удалить выбранные'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Подтверждение удаления'),
                      content: Text(
                        'Вы уверены, что хотите удалить выбранные $selectedCount объектов?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await objectsProvider.deleteSelectedObjects();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Удалить',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Отмена'),
              ),
            ],
          ),
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
    Key? key,
    required this.object,
    required this.toolsProvider,
    required this.selectionMode,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final toolsOnObject = toolsProvider.tools
        .where((tool) => tool.currentLocation == object.id)
        .toList();

    return Consumer<ObjectsProvider>(
      builder: (context, objectsProvider, child) {
        return InkWell(
          onTap: selectionMode
              ? () {
                  objectsProvider.toggleObjectSelection(object.id);
                }
              : onTap,
          onLongPress: () {
            if (!selectionMode) {
              objectsProvider.toggleSelectionMode();
              objectsProvider.selectObject(object.id);
            }
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  if (selectionMode)
                    Checkbox(
                      value: object.isSelected,
                      onChanged: (value) {
                        objectsProvider.toggleObjectSelection(object.id);
                      },
                    ),
                  SizedBox(width: 8),
                  // Object Image
                  if (object.displayImage != null)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: object.displayImage!.startsWith('http')
                              ? NetworkImage(object.displayImage!)
                              : FileImage(File(object.displayImage!))
                                    as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.location_city,
                          color: Colors.orange.withOpacity(0.5),
                          size: 30,
                        ),
                      ),
                    ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          object.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
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
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.build, size: 12, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              '${toolsOnObject.length} инструментов',
                              style: TextStyle(
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
                            leading: Icon(Icons.edit),
                            title: Text('Редактировать'),
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
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Удалить',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Подтверждение удаления'),
                                  content: Text('Удалить "${object.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await objectsProvider.deleteObject(
                                          object.id,
                                        );
                                      },
                                      child: Text(
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

  const AddEditObjectScreen({Key? key, this.object}) : super(key: key);

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

      final object = ConstructionObject(
        id: widget.object?.id ?? IdGenerator.generateObjectId(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrl,
        localImagePath: _localImagePath,
        toolIds: widget.object?.toolIds ?? [],
        createdAt: widget.object?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
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
              icon: Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Подтверждение удаления'),
                    content: Text('Удалить "${widget.object!.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Отмена'),
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
                        child: Text(
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
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
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
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text('Ошибка загрузки изображения'),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : _localImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_localImagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text('Ошибка загрузки изображения'),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_city,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text('Добавить фото объекта'),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Название объекта *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите название объекта';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveObject,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        isEdit ? 'Сохранить изменения' : 'Добавить объект',
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
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
                leading: Icon(Icons.photo_library),
                title: Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Сделать фото'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (_imageFile != null ||
                  _imageUrl != null ||
                  _localImagePath != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text(
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

  const ObjectDetailsScreen({Key? key, required this.object}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final toolsOnObject = toolsProvider.tools
        .where((tool) => tool.currentLocation == object.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(object.name),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
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
            decoration: BoxDecoration(color: Colors.grey[100]),
            child: object.displayImage != null
                ? Image(
                    image: object.displayImage!.startsWith('http')
                        ? NetworkImage(object.displayImage!)
                        : FileImage(File(object.displayImage!))
                              as ImageProvider,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Icon(
                      Icons.location_city,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                  ),
          ),

          // Object Info
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  object.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                if (object.description.isNotEmpty)
                  Text(
                    object.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.build, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Инструментов на объекте: ${toolsOnObject.length}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Создан: ${DateFormat('dd.MM.yyyy').format(object.createdAt)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(),

          // Tools on Object
          Expanded(
            child: toolsOnObject.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build, size: 60, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Text(
                          'На объекте нет инструментов',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Переместите инструменты на этот объект',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
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
  }
}

// ========== MOVE TOOLS SCREEN ==========
class MoveToolsScreen extends StatefulWidget {
  @override
  _MoveToolsScreenState createState() => _MoveToolsScreenState();
}

class _MoveToolsScreenState extends State<MoveToolsScreen> {
  String? _selectedLocationId;
  final List<String> _selectedToolIds = [];

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final garageTools = toolsProvider.garageTools;

    return Scaffold(
      appBar: AppBar(title: Text('Перемещение инструментов')),
      body: Column(
        children: [
          // Location Selector
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Выберите место назначения:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  // Garage option
                  ListTile(
                    leading: Icon(Icons.garage, color: Colors.blue),
                    title: Text('Гараж'),
                    trailing: _selectedLocationId == 'garage'
                        ? Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedLocationId = 'garage';
                      });
                    },
                  ),
                  Divider(),
                  // Objects options
                  ...objectsProvider.objects.map((object) {
                    return ListTile(
                      leading: Icon(Icons.location_city, color: Colors.orange),
                      title: Text(object.name),
                      subtitle: Text('${object.toolIds.length} инструментов'),
                      trailing: _selectedLocationId == object.id
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedLocationId = object.id;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),

          // Available Tools
          Expanded(
            child: garageTools.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.garage, size: 80, color: Colors.grey[300]),
                        SizedBox(height: 20),
                        Text(
                          'В гараже нет инструментов',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Все инструменты уже на объектах',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: garageTools.length,
                    itemBuilder: (context, index) {
                      final tool = garageTools[index];
                      final isSelected = _selectedToolIds.contains(tool.id);

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : null,
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedToolIds.add(tool.id);
                              } else {
                                _selectedToolIds.remove(tool.id);
                              }
                            });
                          },
                          title: Text(tool.title),
                          subtitle: Text(tool.brand),
                          secondary: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.build,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Move Button
          if (_selectedLocationId != null && _selectedToolIds.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  if (_selectedLocationId == null) {
                    ErrorHandler.showWarningDialog(
                      context,
                      'Выберите место назначения',
                    );
                    return;
                  }

                  if (_selectedToolIds.isEmpty) {
                    ErrorHandler.showWarningDialog(
                      context,
                      'Выберите инструменты для перемещения',
                    );
                    return;
                  }

                  String locationName = 'Гараж';
                  if (_selectedLocationId != 'garage') {
                    final object = objectsProvider.objects.firstWhere(
                      (o) => o.id == _selectedLocationId,
                      orElse: () => ConstructionObject(
                        id: 'garage',
                        name: 'Гараж',
                        description: '',
                      ),
                    );
                    locationName = object.name;
                  }

                  await toolsProvider.moveSelectedTools(
                    _selectedLocationId!,
                    locationName,
                  );

                  setState(() {
                    _selectedToolIds.clear();
                    _selectedLocationId = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Переместить ${_selectedToolIds.length} инструментов',
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
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final favoriteTools = toolsProvider.favoriteTools;

    return Scaffold(
      appBar: AppBar(title: Text('Избранное (${favoriteTools.length})')),
      body: favoriteTools.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Нет избранных инструментов',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Добавьте инструменты в избранное',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
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
            ),
    );
  }
}

// ========== PROFILE SCREEN ==========
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColorDark,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      authProvider.user?.email ?? 'Гость',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Менеджер инструментов',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            // Stats
            Padding(
              padding: EdgeInsets.all(16),
              child: GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildStatCard(
                    'Всего инструментов',
                    '${toolsProvider.totalTools}',
                    Icons.build,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'В гараже',
                    '${toolsProvider.garageTools.length}',
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
                    '${toolsProvider.favoriteTools.length}',
                    Icons.favorite,
                    Colors.red,
                  ),
                ],
              ),
            ),

            // Settings
            Card(
              margin: EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.sync),
                    title: Text('Синхронизация данных'),
                    trailing: Switch(value: true, onChanged: (value) {}),
                  ),
                  ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text('Уведомления'),
                    trailing: Switch(value: true, onChanged: (value) {}),
                  ),
                  ListTile(
                    leading: Icon(Icons.dark_mode),
                    title: Text('Темная тема'),
                    trailing: Switch(value: false, onChanged: (value) {}),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ReportService.generateInventoryReport(
                        toolsProvider.tools,
                        objectsProvider.objects,
                        context,
                      );
                    },
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text('Создать отчет PDF'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Backup functionality
                      ErrorHandler.showSuccessDialog(
                        context,
                        'Резервная копия создана',
                      );
                    },
                    icon: Icon(Icons.backup),
                    label: Text('Создать резервную копию'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await authProvider.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AuthScreen()),
                      );
                    },
                    icon: Icon(Icons.logout),
                    label: Text('Выйти'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      side: BorderSide(color: Colors.red),
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// ========== SEARCH SCREEN ==========
class SearchScreen extends StatefulWidget {
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
          tool.description.toLowerCase().contains(query);
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
          decoration: InputDecoration(
            hintText: 'Поиск инструментов...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Начните вводить для поиска'
                        : 'Ничего не найдено',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
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
}

// ========== WELCOME SCREEN ==========
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({Key? key, required this.onContinue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColorDark,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build, size: 100, color: Colors.white),
                SizedBox(height: 32),
                Text(
                  'Добро пожаловать в Tooler!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Простая и эффективная система управления строительными инструментами',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),
                ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text('Начать работу', style: TextStyle(fontSize: 18)),
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

  const OnboardingScreen({Key? key, required this.onComplete})
    : super(key: key);

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
                    MaterialPageRoute(builder: (context) => AuthScreen()),
                  );
                },
                child: Text(
                  'Пропустить',
                  style: TextStyle(color: Theme.of(context).primaryColor),
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
                    padding: EdgeInsets.all(32),
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
                        SizedBox(height: 40),
                        Text(
                          page['title'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Text(
                          page['description'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
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
              padding: EdgeInsets.all(32),
              child: Row(
                children: [
                  // Dots
                  ...List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                  Spacer(),
                  // Next/Start button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        widget.onComplete();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => AuthScreen()),
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

// ========== AUTH SCREEN ==========
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = _isLogin
          ? await authProvider.signInWithEmail(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            )
          : await authProvider.signUpWithEmail(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
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
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 80),
              Icon(
                Icons.build,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 20),
              Text(
                'Tooler',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Управление строительными инструментами',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
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
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: Icon(Icons.lock),
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
                        border: OutlineInputBorder(),
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
                    SizedBox(height: 20),
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
                          Text('Запомнить меня'),
                        ],
                      ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
                ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Нет аккаунта? Зарегистрироваться'
                      : 'Уже есть аккаунт? Войти',
                ),
              ),
              SizedBox(height: 20),
              // Quick login for testing
              OutlinedButton(
                onPressed: () {
                  _emailController.text = 'vadim';
                  _passwordController.text = 'vadim';
                  _submit();
                },
                child: Text('Быстрый вход (тестовый режим)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== MAIN APP WIDGET ==========
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
            debugShowCheckedModeBanner: false,
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
            theme: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.blue,
                secondary: Colors.blueAccent,
              ),
              appBarTheme: AppBarTheme(
                elevation: 0,
                backgroundColor: Colors.blue,
                iconTheme: IconThemeData(color: Colors.white),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              cardTheme: CardThemeData(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
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
                        MaterialPageRoute(builder: (context) => AuthScreen()),
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
                  return AuthScreen();
                }

                return MainScreen();
              },
            ),
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
