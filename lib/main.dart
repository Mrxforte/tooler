// main.dart - Modern Tooler Construction Tool Management App (Multiuser, Admin Approval)
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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ========== CONSTANTS ==========
const String _adminSecret = 'admin123'; // Simple admin phrase
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ========== FIREBASE INITIALIZATION ==========
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize timezone for scheduled notifications
  tz.initializeTimeZones();

  try {
    await Hive.initFlutter();
    Hive.registerAdapter(ToolAdapter());
    Hive.registerAdapter(LocationHistoryAdapter());
    Hive.registerAdapter(ConstructionObjectAdapter());
    Hive.registerAdapter(SyncItemAdapter());
    Hive.registerAdapter(MoveRequestAdapter());
    Hive.registerAdapter(BatchMoveRequestAdapter());
    Hive.registerAdapter(NotificationAdapter());
    Hive.registerAdapter(WorkerAdapter());
    Hive.registerAdapter(SalaryEntryAdapter());
    Hive.registerAdapter(AdvanceAdapter());
    Hive.registerAdapter(PenaltyAdapter());

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyDummyKeyForDevelopment',
        appId: '1:1234567890:android:abcdef123456',
        messagingSenderId: '1234567890',
        projectId: 'tooler-dev',
        storageBucket: 'tooler-dev.appspot.com',
      ),
    );

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings);

    // Schedule daily notification at 7 PM


    // Initialize WorkManager for background tasks
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    Workmanager().registerPeriodicTask(
        'daily-salary-reminder', 'dailySalaryReminder',
        frequency: Duration(hours: 24),
        initialDelay: _getTimeUntil7PM());

    print('Firebase initialized successfully');
  } catch (e) {
    print('Initialization error: $e');
  }

  runApp(const MyApp());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return Future.value(true);
  });
}


Duration _getTimeUntil7PM() {
  final now = DateTime.now();
  var scheduledTime = DateTime(now.year, now.month, now.day, 19, 0, 0);
  if (scheduledTime.isBefore(now)) {
    scheduledTime = scheduledTime.add(Duration(days: 1));
  }
  return scheduledTime.difference(now);
}


// ========== HIVE ADAPTERS ==========
class ToolAdapter extends TypeAdapter<Tool> {
  @override
  final int typeId = 0;
  @override
  Tool read(BinaryReader reader) => Tool.fromJson(
      reader.readMap().map((key, value) => MapEntry(key.toString(), value)));
  @override
  void write(BinaryWriter writer, Tool obj) => writer.writeMap(obj.toJson());
}

class LocationHistoryAdapter extends TypeAdapter<LocationHistory> {
  @override
  final int typeId = 1;
  @override
  LocationHistory read(BinaryReader reader) => LocationHistory.fromJson(
      reader.readMap().map((key, value) => MapEntry(key.toString(), value)));
  @override
  void write(BinaryWriter writer, LocationHistory obj) =>
      writer.writeMap(obj.toJson());
}

class ConstructionObjectAdapter extends TypeAdapter<ConstructionObject> {
  @override
  final int typeId = 2;
  @override
  ConstructionObject read(BinaryReader reader) =>
      ConstructionObject.fromJson(
          reader.readMap().map((key, value) => MapEntry(key.toString(), value)));
  @override
  void write(BinaryWriter writer, ConstructionObject obj) =>
      writer.writeMap(obj.toJson());
}

class SyncItemAdapter extends TypeAdapter<SyncItem> {
  @override
  final int typeId = 3;
  @override
  SyncItem read(BinaryReader reader) {
    final map = reader.readMap()
        .map((key, value) => MapEntry(key.toString(), value));
    return SyncItem(
      id: map['id'] as String,
      action: map['action'] as String,
      collection: map['collection'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
  @override
  void write(BinaryWriter writer, SyncItem obj) => writer.writeMap(obj.toJson());
}

class MoveRequestAdapter extends TypeAdapter<MoveRequest> {
  @override
  final int typeId = 4;
  @override
  MoveRequest read(BinaryReader reader) {
    final map = reader.readMap()
        .map((key, value) => MapEntry(key.toString(), value));
    return MoveRequest(
      id: map['id'] as String,
      toolId: map['toolId'] as String,
      fromLocationId: map['fromLocationId'] as String,
      fromLocationName: map['fromLocationName'] as String,
      toLocationId: map['toLocationId'] as String,
      toLocationName: map['toLocationName'] as String,
      requestedBy: map['requestedBy'] as String,
      status: map['status'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
  @override
  void write(BinaryWriter writer, MoveRequest obj) => writer.writeMap(obj.toJson());
}

class BatchMoveRequestAdapter extends TypeAdapter<BatchMoveRequest> {
  @override
  final int typeId = 6;
  @override
  BatchMoveRequest read(BinaryReader reader) {
    final map = reader.readMap()
        .map((key, value) => MapEntry(key.toString(), value));
    return BatchMoveRequest(
      id: map['id'] as String,
      toolIds: List<String>.from(map['toolIds']),
      fromLocationId: map['fromLocationId'] as String,
      fromLocationName: map['fromLocationName'] as String,
      toLocationId: map['toLocationId'] as String,
      toLocationName: map['toLocationName'] as String,
      requestedBy: map['requestedBy'] as String,
      status: map['status'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
  @override
  void write(BinaryWriter writer, BatchMoveRequest obj) =>
      writer.writeMap(obj.toJson());
}

class NotificationAdapter extends TypeAdapter<AppNotification> {
  @override
  final int typeId = 5;
  @override
  AppNotification read(BinaryReader reader) {
    final map = reader.readMap()
        .map((key, value) => MapEntry(key.toString(), value));
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String,
      relatedId: map['relatedId'] as String?,
      userId: map['userId'] as String,
      read: map['read'] as bool? ?? false,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
  @override
  void write(BinaryWriter writer, AppNotification obj) =>
      writer.writeMap(obj.toJson());
}

class WorkerAdapter extends TypeAdapter<Worker> {
  @override
  final int typeId = 7;
  @override
  Worker read(BinaryReader reader) => Worker.fromJson(
      reader.readMap().map((key, value) => MapEntry(key.toString(), value)));
  @override
  void write(BinaryWriter writer, Worker obj) => writer.writeMap(obj.toJson());
}

class SalaryEntryAdapter extends TypeAdapter<SalaryEntry> {
  @override
  final int typeId = 8;
  @override
  SalaryEntry read(BinaryReader reader) => SalaryEntry.fromJson(
      reader.readMap().map((key, value) => MapEntry(key.toString(), value)));
  @override
  void write(BinaryWriter writer, SalaryEntry obj) =>
      writer.writeMap(obj.toJson());
}

class AdvanceAdapter extends TypeAdapter<Advance> {
  @override
  final int typeId = 9;
  @override
  Advance read(BinaryReader reader) => Advance.fromJson(
      reader.readMap().map((key, value) => MapEntry(key.toString(), value)));
  @override
  void write(BinaryWriter writer, Advance obj) => writer.writeMap(obj.toJson());
}

class PenaltyAdapter extends TypeAdapter<Penalty> {
  @override
  final int typeId = 10;
  @override
  Penalty read(BinaryReader reader) => Penalty.fromJson(
      reader.readMap().map((key, value) => MapEntry(key.toString(), value)));
  @override
  void write(BinaryWriter writer, Penalty obj) => writer.writeMap(obj.toJson());
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
  String currentLocation;
  String currentLocationName;
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
  })  : locationHistory = locationHistory ?? [],
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
        locationHistory: (json['locationHistory'] as List?)
                ?.map((e) => LocationHistory.fromJson(
                    Map<String, dynamic>.from(e)))
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

  Tool copyWith(
      {String? id,
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
      String? userId}) {
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

  String? get displayImage =>
      imageUrl?.isNotEmpty == true ? imageUrl : localImagePath?.isNotEmpty == true ? localImagePath : null;
}

class LocationHistory {
  DateTime date;
  String locationId;
  String locationName;
  LocationHistory(
      {required this.date,
      required this.locationId,
      required this.locationName});
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
        'locationName': locationName
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
  })  : toolIds = toolIds ?? [],
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

  ConstructionObject copyWith(
      {String? id,
      String? name,
      String? description,
      String? imageUrl,
      String? localImagePath,
      List<String>? toolIds,
      DateTime? createdAt,
      DateTime? updatedAt,
      bool? isSelected,
      String? userId}) {
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

  String? get displayImage =>
      imageUrl?.isNotEmpty == true ? imageUrl : localImagePath?.isNotEmpty == true ? localImagePath : null;
}

class MoveRequest {
  String id;
  String toolId;
  String fromLocationId;
  String fromLocationName;
  String toLocationId;
  String toLocationName;
  String requestedBy;
  String status;
  DateTime timestamp;

  MoveRequest({
    required this.id,
    required this.toolId,
    required this.fromLocationId,
    required this.fromLocationName,
    required this.toLocationId,
    required this.toLocationName,
    required this.requestedBy,
    required this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolId': toolId,
        'fromLocationId': fromLocationId,
        'fromLocationName': fromLocationName,
        'toLocationId': toLocationId,
        'toLocationName': toLocationName,
        'requestedBy': requestedBy,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MoveRequest.fromJson(Map<String, dynamic> json) => MoveRequest(
        id: json['id'] as String,
        toolId: json['toolId'] as String,
        fromLocationId: json['fromLocationId'] as String,
        fromLocationName: json['fromLocationName'] as String,
        toLocationId: json['toLocationId'] as String,
        toLocationName: json['toLocationName'] as String,
        requestedBy: json['requestedBy'] as String,
        status: json['status'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class BatchMoveRequest {
  String id;
  List<String> toolIds;
  String fromLocationId;
  String fromLocationName;
  String toLocationId;
  String toLocationName;
  String requestedBy;
  String status;
  DateTime timestamp;

  BatchMoveRequest({
    required this.id,
    required this.toolIds,
    required this.fromLocationId,
    required this.fromLocationName,
    required this.toLocationId,
    required this.toLocationName,
    required this.requestedBy,
    required this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolIds': toolIds,
        'fromLocationId': fromLocationId,
        'fromLocationName': fromLocationName,
        'toLocationId': toLocationId,
        'toLocationName': toLocationName,
        'requestedBy': requestedBy,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BatchMoveRequest.fromJson(Map<String, dynamic> json) =>
      BatchMoveRequest(
        id: json['id'] as String,
        toolIds: List<String>.from(json['toolIds']),
        fromLocationId: json['fromLocationId'] as String,
        fromLocationName: json['fromLocationName'] as String,
        toLocationId: json['toLocationId'] as String,
        toLocationName: json['toLocationName'] as String,
        requestedBy: json['requestedBy'] as String,
        status: json['status'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class AppNotification {
  String id;
  String title;
  String body;
  String type;
  String? relatedId;
  String userId;
  bool read;
  DateTime timestamp;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.userId,
    this.read = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'userId': userId,
        'read': read,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        relatedId: json['relatedId'] as String?,
        userId: json['userId'] as String,
        read: json['read'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class Worker {
  String id;
  String email;
  String name;
  String? nickname;
  String? phone;
  String? assignedObjectId;
  String role;
  double hourlyRate;
  double dailyRate;
  DateTime createdAt;

  Worker({
    required this.id,
    required this.email,
    required this.name,
    this.nickname,
    this.phone,
    this.assignedObjectId,
    this.role = 'worker',
    this.hourlyRate = 0.0,
    this.dailyRate = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        nickname: json['nickname'] as String?,
        phone: json['phone'] as String?,
        assignedObjectId: json['assignedObjectId'] as String?,
        role: json['role'] as String? ?? 'worker',
        hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
        dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'nickname': nickname,
        'phone': phone,
        'assignedObjectId': assignedObjectId,
        'role': role,
        'hourlyRate': hourlyRate,
        'dailyRate': dailyRate,
        'createdAt': createdAt.toIso8601String(),
      };
}

class SalaryEntry {
  String id;
  String workerId;
  DateTime date;
  double hoursWorked;
  double amount;
  String? notes;

  SalaryEntry({
    required this.id,
    required this.workerId,
    required this.date,
    this.hoursWorked = 0,
    this.amount = 0,
    this.notes,
  });

  factory SalaryEntry.fromJson(Map<String, dynamic> json) => SalaryEntry(
        id: json['id'] as String,
        workerId: json['workerId'] as String,
        date: DateTime.parse(json['date'] as String),
        hoursWorked: (json['hoursWorked'] as num?)?.toDouble() ?? 0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'date': date.toIso8601String(),
        'hoursWorked': hoursWorked,
        'amount': amount,
        'notes': notes,
      };
}

class Advance {
  String id;
  String workerId;
  DateTime date;
  double amount;
  String? reason;
  bool repaid;

  Advance({
    required this.id,
    required this.workerId,
    required this.date,
    required this.amount,
    this.reason,
    this.repaid = false,
  });

  factory Advance.fromJson(Map<String, dynamic> json) => Advance(
        id: json['id'] as String,
        workerId: json['workerId'] as String,
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        reason: json['reason'] as String?,
        repaid: json['repaid'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'date': date.toIso8601String(),
        'amount': amount,
        'reason': reason,
        'repaid': repaid,
      };
}

class Penalty {
  String id;
  String workerId;
  DateTime date;
  double amount;
  String? reason;

  Penalty({
    required this.id,
    required this.workerId,
    required this.date,
    required this.amount,
    this.reason,
  });

  factory Penalty.fromJson(Map<String, dynamic> json) => Penalty(
        id: json['id'] as String,
        workerId: json['workerId'] as String,
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        reason: json['reason'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'date': date.toIso8601String(),
        'amount': amount,
        'reason': reason,
      };
}

// ========== ID GENERATOR ==========
class IdGenerator {
  static String generateToolId() =>
      'TOOL-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999).toString().padLeft(4, '0')}';
  static String generateObjectId() =>
      'OBJ-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999).toString().padLeft(4, '0')}';
  static String generateUniqueId() {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final randomStr =
        List.generate(4, (index) => chars[Random().nextInt(chars.length)]).join();
    return '$timestamp-$randomStr';
  }
  static String generateRequestId() =>
      'REQ-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  static String generateBatchRequestId() =>
      'BATCH-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  static String generateNotificationId() =>
      'NOT-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  static String generateWorkerId() =>
      'WRK-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  static String generateSalaryId() =>
      'SAL-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  static String generateAdvanceId() =>
      'ADV-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  static String generatePenaltyId() =>
      'PEN-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
}

// ========== LOCAL DATABASE (HIVE) ==========
class LocalDatabase {
  static const String toolsBox = 'tools';
  static const String objectsBox = 'objects';
  static const String syncQueueBox = 'sync_queue';
  static const String appSettingsBox = 'app_settings';
  static const String moveRequestsBox = 'move_requests';
  static const String batchMoveRequestsBox = 'batch_move_requests';
  static const String notificationsBox = 'notifications';
  static const String workersBox = 'workers';
  static const String salariesBox = 'salaries';
  static const String advancesBox = 'advances';
  static const String penaltiesBox = 'penalties';

  static Future<void> init() async {
    try {
      await Hive.openBox<Tool>(toolsBox);
      await Hive.openBox<ConstructionObject>(objectsBox);
      await Hive.openBox<SyncItem>(syncQueueBox);
      await Hive.openBox<String>(appSettingsBox);
      await Hive.openBox<MoveRequest>(moveRequestsBox);
      await Hive.openBox<BatchMoveRequest>(batchMoveRequestsBox);
      await Hive.openBox<AppNotification>(notificationsBox);
      await Hive.openBox<Worker>(workersBox);
      await Hive.openBox<SalaryEntry>(salariesBox);
      await Hive.openBox<Advance>(advancesBox);
      await Hive.openBox<Penalty>(penaltiesBox);
    } catch (e) {
      print('Error opening Hive boxes: $e');
    }
  }

  static Box<Tool> get tools => Hive.box<Tool>(toolsBox);
  static Box<ConstructionObject> get objects => Hive.box<ConstructionObject>(objectsBox);
  static Box<SyncItem> get syncQueue => Hive.box<SyncItem>(syncQueueBox);
  static Box<String> get appSettings => Hive.box<String>(appSettingsBox);
  static Box<MoveRequest> get moveRequests => Hive.box<MoveRequest>(moveRequestsBox);
  static Box<BatchMoveRequest> get batchMoveRequests =>
      Hive.box<BatchMoveRequest>(batchMoveRequestsBox);
  static Box<AppNotification> get notifications => Hive.box<AppNotification>(notificationsBox);
  static Box<Worker> get workers => Hive.box<Worker>(workersBox);
  static Box<SalaryEntry> get salaries => Hive.box<SalaryEntry>(salariesBox);
  static Box<Advance> get advances => Hive.box<Advance>(advancesBox);
  static Box<Penalty> get penalties => Hive.box<Penalty>(penaltiesBox);

  static Future<void> saveCacheTimestamp() async {
    try {
      await appSettings.put('last_cache_update', DateTime.now().toIso8601String());
    } catch (e) {}
  }
  static Future<DateTime?> getLastCacheUpdate() async {
    try {
      final ts = appSettings.get('last_cache_update');
      return ts != null ? DateTime.parse(ts) : null;
    } catch (e) {
      return null;
    }
  }
  static Future<bool> shouldRefreshCache({Duration maxAge = const Duration(hours: 1)}) async {
    try {
      final last = await getLastCacheUpdate();
      return last == null || DateTime.now().difference(last) > maxAge;
    } catch (e) {
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
  SyncItem(
      {required this.id,
      required this.action,
      required this.collection,
      required this.data,
      DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'collection': collection,
        'data': data,
        'timestamp': timestamp.toIso8601String()
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
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
  static Future<File?> pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      return picked != null ? File(picked.path) : null;
    } catch (e) {
      return null;
    }
  }
  static Future<File?> takePhoto() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      return picked != null ? File(picked.path) : null;
    } catch (e) {
      return null;
    }
  }
}

// ========== REPORT TYPES ==========
enum ReportType { pdf, text, screenshot }

// ========== ENHANCED PDF REPORT SERVICE WITH COLOR AND STYLE ==========
class ReportService {
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
    final secondaryColor = PdfColors.orange600;

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                children: [
                  pw.Text(_iconToString(Icons.build),
                      style: pw.TextStyle(fontSize: 40, color: PdfColors.white)),
                  pw.SizedBox(width: 10),
                  pw.Text('TOOLER - ОТЧЕТ ОБ ИНСТРУМЕНТЕ',
                      style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ОСНОВНАЯ ИНФОРМАЦИЯ',
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor)),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    context: context,
                    data: [
                      ['Название:', tool.title],
                      ['Бренд:', tool.brand],
                      ['Уникальный ID:', tool.uniqueId],
                      ['Модель:', tool.description.isNotEmpty ? tool.description : 'Не указана'],
                      ['Местоположение:', tool.currentLocationName],
                      ['Статус:', tool.isFavorite ? '⭐ В избранном' : '📦 В наличии'],
                      ['Дата добавления:', DateFormat('dd.MM.yyyy').format(tool.createdAt)],
                      ['Последнее обновление:', DateFormat('dd.MM.yyyy').format(tool.updatedAt)],
                    ],
                    cellStyle: const pw.TextStyle(fontSize: 12),
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    headerDecoration: pw.BoxDecoration(color: primaryColor),
                    cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
                  ),
                ],
              ),
            ),
            if (tool.locationHistory.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ИСТОРИЯ ПЕРЕМЕЩЕНИЙ',
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: secondaryColor)),
                    pw.SizedBox(height: 10),
                    ...tool.locationHistory.map((history) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Row(
                            children: [
                              pw.Text('• ',
                                  style: pw.TextStyle(color: secondaryColor, fontSize: 16)),
                              pw.Expanded(
                                child: pw.Text(
                                  '${history.locationName} (${DateFormat('dd.MM.yyyy').format(history.date)})',
                                  style: const pw.TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
            pw.Spacer(),
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 30),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Center(
                child: pw.Text(
                  '© ${DateTime.now().year} Tooler App - Система управления строительными инструментами\n'
                  'Генерация отчета: ${dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    ));
    return await pdf.save();
  }

  static String _generateToolReportText(Tool tool) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    String report = '''
📋 **ОТЧЕТ ОБ ИНСТРУМЕНТЕ - ${tool.title}**

🛠️ **ОСНОВНАЯ ИНФОРМАЦИЯ:**
─────────────────────
• Название: **${tool.title}**
• Бренд: **${tool.brand}**
• Уникальный ID: ` ${tool.uniqueId}`
• Модель: ${tool.description.isNotEmpty ? tool.description : 'Не указана'}
• Местоположение: **${tool.currentLocationName}**
• Статус: ${tool.isFavorite ? '⭐ В избранном' : '📦 В наличии'}
• Дата добавления: ${DateFormat('dd.MM.yyyy').format(tool.createdAt)}
• Последнее обновление: ${DateFormat('dd.MM.yyyy').format(tool.updatedAt)}
''';
    if (tool.locationHistory.isNotEmpty) {
      report += '''
      
📜 **ИСТОРИЯ ПЕРЕМЕЩЕНИЙ:**
─────────────────────
${tool.locationHistory.map((history) => '• ${history.locationName} (${DateFormat('dd.MM.yyyy').format(history.date)})').join('\n')}
''';
    }
    report += '''
      
📅 Отчет сгенерирован: ${dateFormat.format(DateTime.now())}
© ${DateTime.now().year} Tooler App
''';
    return report;
  }

  static Future<Uint8List> _generateObjectReportPdf(
      ConstructionObject object, List<Tool> toolsOnObject) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final primaryColor = PdfColors.orange700;
    final secondaryColor = PdfColors.green600;

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                children: [
                  pw.Text(_iconToString(Icons.location_city),
                      style: pw.TextStyle(fontSize: 40, color: PdfColors.white)),
                  pw.SizedBox(width: 10),
                  pw.Text('TOOLER - ОТЧЕТ ОБ ОБЪЕКТЕ',
                      style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ОСНОВНАЯ ИНФОРМАЦИЯ',
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor)),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    context: context,
                    data: [
                      ['Название:', object.name],
                      ['Описание:', object.description.isNotEmpty ? object.description : 'Нет'],
                      ['Инструментов:', '${toolsOnObject.length}'],
                      ['Создан:', DateFormat('dd.MM.yyyy').format(object.createdAt)],
                    ],
                    cellStyle: const pw.TextStyle(fontSize: 12),
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    headerDecoration: pw.BoxDecoration(color: primaryColor),
                    cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ИНСТРУМЕНТЫ НА ОБЪЕКТЕ',
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: secondaryColor)),
                  pw.SizedBox(height: 10),
                  if (toolsOnObject.isEmpty)
                    pw.Text('Нет инструментов',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey))
                  else
                    ...toolsOnObject.map((t) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Row(
                            children: [
                              pw.Text('• ',
                                  style: pw.TextStyle(color: secondaryColor, fontSize: 16)),
                              pw.Expanded(
                                child: pw.Text(
                                  '${t.title} (${t.brand})${t.isFavorite ? ' ⭐' : ''}',
                                  style: const pw.TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 30),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Center(
                child: pw.Text(
                  '© ${DateTime.now().year} Tooler App - Система управления строительными инструментами\n'
                  'Генерация отчета: ${dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    ));
    return await pdf.save();
  }

  static String _generateObjectReportText(
      ConstructionObject object, List<Tool> toolsOnObject) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    return '''
📋 **ОТЧЕТ ОБ ОБЪЕКТЕ - ${object.name}**

🏢 **ОСНОВНАЯ ИНФОРМАЦИЯ:**
─────────────────────
• Название: **${object.name}**
• Описание: ${object.description.isNotEmpty ? object.description : 'Нет'}
• Инструментов на объекте: **${toolsOnObject.length}**
• Создан: ${DateFormat('dd.MM.yyyy').format(object.createdAt)}
• Обновлен: ${DateFormat('dd.MM.yyyy').format(object.updatedAt)}

🛠️ **ИНСТРУМЕНТЫ НА ОБЪЕКТЕ:**
─────────────────────
${toolsOnObject.isEmpty ? 'Нет инструментов' : toolsOnObject.map((t) => '• ${t.title} (${t.brand})${t.isFavorite ? ' ⭐' : ''}').join('\n')}

📅 Отчет сгенерирован: ${dateFormat.format(DateTime.now())}
© ${DateTime.now().year} Tooler App
''';
  }

  static Future<Uint8List> _generateInventoryReportPdf(
      List<Tool> tools, List<ConstructionObject> objects) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final primaryColor = PdfColors.green700;
    final secondaryColor = PdfColors.purple600;

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                children: [
                  pw.Text(_iconToString(Icons.inventory),
                      style: pw.TextStyle(fontSize: 40, color: PdfColors.white)),
                  pw.SizedBox(width: 10),
                  pw.Text('TOOLER - ИНВЕНТАРИЗАЦИОННЫЙ ОТЧЕТ',
                      style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('СВОДКА',
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor)),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    context: context,
                    data: [
                      ['Всего инструментов', '${tools.length}'],
                      ['В гараже', '${tools.where((t) => t.currentLocation == "garage").length}'],
                      ['На объектах', '${tools.where((t) => t.currentLocation != "garage").length}'],
                      ['Избранных', '${tools.where((t) => t.isFavorite).length}'],
                      ['Всего объектов', '${objects.length}'],
                      ['С инструментами', '${objects.where((o) => o.toolIds.isNotEmpty).length}'],
                      ['Пустых', '${objects.where((o) => o.toolIds.isEmpty).length}'],
                    ],
                    cellStyle: const pw.TextStyle(fontSize: 12),
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    headerDecoration: pw.BoxDecoration(color: primaryColor),
                    cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('СПИСОК ИНСТРУМЕНТОВ',
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: secondaryColor)),
                  pw.SizedBox(height: 10),
                  ...tools.take(50).map((tool) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(
                          children: [
                            pw.Text('• ',
                                style: pw.TextStyle(color: secondaryColor, fontSize: 16)),
                            pw.Expanded(
                              child: pw.Text(
                                '${tool.title} (${tool.brand}) - ${tool.currentLocationName}${tool.isFavorite ? " ⭐" : ""}',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (tools.length > 50)
                    pw.Text('... и еще ${tools.length - 50} инструментов',
                        style: pw.TextStyle(
                            fontSize: 12, fontStyle: pw.FontStyle.italic)),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 30),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Center(
                child: pw.Text(
                  '© ${DateTime.now().year} Tooler App - Система управления строительными инструментами\n'
                  'Генерация отчета: ${dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    ));
    return await pdf.save();
  }

  static String _generateInventoryReportText(
      List<Tool> tools, List<ConstructionObject> objects) {
    final garageTools = tools.where((t) => t.currentLocation == 'garage').length;
    final onSiteTools = tools.where((t) => t.currentLocation != 'garage').length;
    final favoriteTools = tools.where((t) => t.isFavorite).length;
    final objectsWithTools = objects.where((o) => o.toolIds.isNotEmpty).length;
    return '''
📊 **ИНВЕНТАРИЗАЦИОННЫЙ ОТЧЕТ Tooler**

📅 Дата: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}
📊 **СВОДКА:**
─────────────────────
🛠️ Всего инструментов: **${tools.length}**
🏠 В гараже: **$garageTools**
🏗️ На объектах: **$onSiteTools**
⭐ Избранных: **$favoriteTools**
🏢 Всего объектов: **${objects.length}**
📦 Объектов с инструментами: **$objectsWithTools**

📋 **СПИСОК ИНСТРУМЕНТОВ:**
─────────────────────
${tools.take(15).map((t) => '• ${t.title} (${t.brand}) - ${t.currentLocationName}${t.isFavorite ? " ⭐" : ""}').join('\n')}
${tools.length > 15 ? '\n... и еще ${tools.length - 15} инструментов' : ''}

🏢 **СПИСОК ОБЪЕКТОВ:**
─────────────────────
${objects.take(10).map((o) => '• ${o.name} - ${o.toolIds.length} инструментов').join('\n')}
${objects.length > 10 ? '\n... и еще ${objects.length - 10} объектов' : ''}

📅 Отчет создан: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}
© ${DateTime.now().year} Tooler App
''';
  }

  static Future<void> shareToolReport(
      Tool tool, BuildContext context, ReportType reportType) async {
    try {
      switch (reportType) {
        case ReportType.pdf:
          final pdfBytes = await _generateToolReportPdf(tool);
          final tempDir = await getTemporaryDirectory();
          final pdfFile = File('${tempDir.path}/tool_report_${tool.id}.pdf');
          await pdfFile.writeAsBytes(pdfBytes);
          await Share.shareXFiles([XFile(pdfFile.path)],
              text: '📋 Отчет об инструменте: ${tool.title}');
          break;
        case ReportType.text:
        case ReportType.screenshot:
          await Share.share(_generateToolReportText(tool));
          break;
      }
    } catch (e) {
      await Share.share(_generateToolReportText(tool));
    }
  }

  static Future<void> shareObjectReport(ConstructionObject object,
      List<Tool> toolsOnObject, BuildContext context, ReportType reportType) async {
    try {
      switch (reportType) {
        case ReportType.pdf:
          final pdfBytes = await _generateObjectReportPdf(object, toolsOnObject);
          final tempDir = await getTemporaryDirectory();
          final pdfFile = File('${tempDir.path}/object_report_${object.id}.pdf');
          await pdfFile.writeAsBytes(pdfBytes);
          await Share.shareXFiles([XFile(pdfFile.path)],
              text: '📋 Отчет об объекте: ${object.name}');
          break;
        case ReportType.text:
        case ReportType.screenshot:
          await Share.share(_generateObjectReportText(object, toolsOnObject));
          break;
      }
    } catch (e) {
      await Share.share(_generateObjectReportText(object, toolsOnObject));
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
                const Text('Выберите тип отчета',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                ListTile(
                    leading: const Icon(Icons.screenshot, color: Colors.green),
                    title: const Text('Скриншот отчета'),
                    onTap: () {
                      Navigator.pop(context);
                      onTypeSelected(ReportType.screenshot);
                    }),
              ]));
        });
  }

  static void showObjectReportTypeDialog(BuildContext context,
      ConstructionObject object, List<Tool> toolsOnObject,
      Function(ReportType) onTypeSelected) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Выберите тип отчета',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  static Future<void> shareInventoryReport(List<Tool> tools,
      List<ConstructionObject> objects, BuildContext context,
      ReportType reportType) async {
    if (reportType == ReportType.pdf) {
      final pdfBytes = await _generateInventoryReportPdf(tools, objects);
      final tempDir = await getTemporaryDirectory();
      final pdfFile = File(
          '${tempDir.path}/inventory_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await pdfFile.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(pdfFile.path)],
          text: '📊 ИНВЕНТАРИЗАЦИОННЫЙ ОТЧЕТ Tooler');
    } else {
      await Share.share(_generateInventoryReportText(tools, objects));
    }
  }
}

// ========== ERROR HANDLER (with Russian messages) ==========
class ErrorHandler {
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text('Ошибка'),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: const Text('OK'))
            ]));
  }
  static void showSuccessDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2)));
  }
  static void showWarningDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2)));
  }
  static void handleError(Object error, StackTrace stackTrace) {
    print('Error: $error');
    print('Stack trace: $stackTrace');
  }
  static String getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован.';
      case 'invalid-email':
        return 'Некорректный email адрес.';
      case 'operation-not-allowed':
        return 'Операция не разрешена.';
      case 'weak-password':
        return 'Слишком простой пароль.';
      case 'user-disabled':
        return 'Пользователь отключен.';
      case 'user-not-found':
        return 'Пользователь не найден.';
      case 'wrong-password':
        return 'Неверный пароль.';
      default:
        return 'Ошибка: ${e.message}';
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ========== THEME PROVIDER ==========
class ThemeProvider extends ChangeNotifier {
  String _themeMode = 'light';
  String get themeMode => _themeMode;
  set themeMode(String value) {
    _themeMode = value;
    notifyListeners();
  }
}

// ========== NOTIFICATION PROVIDER ==========
class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool get hasUnread => _notifications.any((n) => !n.read);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  Future<void> loadNotifications(String userId) async {
    await LocalDatabase.init();
    _notifications = LocalDatabase.notifications.values
        .where((n) => n.userId == userId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    await LocalDatabase.notifications.put(notification.id, notification);
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      await LocalDatabase.notifications.put(id, _notifications[index]);
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
      await LocalDatabase.notifications.put(_notifications[i].id, _notifications[i]);
    }
    notifyListeners();
  }
}

extension NotificationCopy on AppNotification {
  AppNotification copyWith(
      {String? id,
      String? title,
      String? body,
      String? type,
      String? relatedId,
      String? userId,
      bool? read,
      DateTime? timestamp}) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      userId: userId ?? this.userId,
      read: read ?? this.read,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

// ========== MOVE REQUEST PROVIDER (single) ==========
class MoveRequestProvider with ChangeNotifier {
  List<MoveRequest> _requests = [];

  List<MoveRequest> get pendingRequests =>
      _requests.where((r) => r.status == 'pending').toList();
  List<MoveRequest> get userRequests =>
      _requests.where((r) => r.requestedBy == FirebaseAuth.instance.currentUser?.uid).toList();

  Future<void> loadRequests() async {
    await LocalDatabase.init();
    _requests = LocalDatabase.moveRequests.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> createRequest(MoveRequest request) async {
    _requests.add(request);
    await LocalDatabase.moveRequests.put(request.id, request);
    notifyListeners();
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = MoveRequest(
        id: _requests[index].id,
        toolId: _requests[index].toolId,
        fromLocationId: _requests[index].fromLocationId,
        fromLocationName: _requests[index].fromLocationName,
        toLocationId: _requests[index].toLocationId,
        toLocationName: _requests[index].toLocationName,
        requestedBy: _requests[index].requestedBy,
        status: status,
        timestamp: _requests[index].timestamp,
      );
      await LocalDatabase.moveRequests.put(requestId, _requests[index]);
      notifyListeners();
    }
  }
}

// ========== BATCH MOVE REQUEST PROVIDER (multiple tools) ==========
class BatchMoveRequestProvider with ChangeNotifier {
  List<BatchMoveRequest> _requests = [];

  List<BatchMoveRequest> get pendingRequests =>
      _requests.where((r) => r.status == 'pending').toList();
  List<BatchMoveRequest> get userRequests =>
      _requests.where((r) => r.requestedBy == FirebaseAuth.instance.currentUser?.uid).toList();

  Future<void> loadRequests() async {
    await LocalDatabase.init();
    _requests = LocalDatabase.batchMoveRequests.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> createRequest(BatchMoveRequest request) async {
    _requests.add(request);
    await LocalDatabase.batchMoveRequests.put(request.id, request);
    notifyListeners();
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = BatchMoveRequest(
        id: _requests[index].id,
        toolIds: _requests[index].toolIds,
        fromLocationId: _requests[index].fromLocationId,
        fromLocationName: _requests[index].fromLocationName,
        toLocationId: _requests[index].toLocationId,
        toLocationName: _requests[index].toLocationName,
        requestedBy: _requests[index].requestedBy,
        status: status,
        timestamp: _requests[index].timestamp,
      );
      await LocalDatabase.batchMoveRequests.put(requestId, _requests[index]);
      notifyListeners();
    }
  }
}

// ========== USER MODEL WITH PERMISSIONS ==========
class AppUser {
  final String uid;
  final String email;
  final String role;
  final bool canMoveTools;
  final bool canControlObjects;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.canMoveTools = false,
    this.canControlObjects = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      canMoveTools: data['canMoveTools'] ?? false,
      canControlObjects: data['canControlObjects'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'role': role,
        'canMoveTools': canMoveTools,
        'canControlObjects': canControlObjects,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ========== USERS PROVIDER (for admin) ==========
class UsersProvider with ChangeNotifier {
  List<AppUser> _users = [];
  bool _isLoading = false;

  List<AppUser> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      _users = snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList()
        ..sort((a, b) => a.email.compareTo(b.email));
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserPermissions(String uid,
      {bool? canMoveTools, bool? canControlObjects}) async {
    try {
      final Map<String, dynamic> updates = {};
      if (canMoveTools != null) updates['canMoveTools'] = canMoveTools;
      if (canControlObjects != null) updates['canControlObjects'] = canControlObjects;
      await FirebaseFirestore.instance.collection('users').doc(uid).update(updates);
      final index = _users.indexWhere((u) => u.uid == uid);
      if (index != -1) {
        _users[index] = AppUser(
          uid: _users[index].uid,
          email: _users[index].email,
          role: _users[index].role,
          canMoveTools: canMoveTools ?? _users[index].canMoveTools,
          canControlObjects: canControlObjects ?? _users[index].canControlObjects,
          createdAt: _users[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error updating user permissions: $e');
    }
  }
}

// ========== AUTH PROVIDER with ROLE and PERMISSIONS ==========
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SharedPreferences _prefs;
  User? _user;
  bool _isLoading = false;
  bool _rememberMe = false;
  File? _profileImage;
  String? _role;
  bool _canMoveTools = false;
  bool _canControlObjects = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get rememberMe => _rememberMe;
  File? get profileImage => _profileImage;
  String? get role => _role;
  bool get isAdmin => _role == 'admin';
  bool get canMoveTools => _canMoveTools || isAdmin;
  bool get canControlObjects => _canControlObjects || isAdmin;

  AuthProvider(this._prefs) {
    _rememberMe = _prefs.getBool('remember_me') ?? false;
    _initializeAuth();
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _fetchUserData(user.uid);
      } else {
        _role = null;
        _canMoveTools = false;
        _canControlObjects = false;
      }
      notifyListeners();
    });
  }

  Future<void> _initializeAuth() async {
    try {
      _isLoading = true;
      notifyListeners();
      final savedUser = _auth.currentUser;
      if (savedUser != null && _rememberMe) {
        _user = savedUser;
        await _fetchUserData(savedUser.uid);
      }
    } catch (e) {
      print('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _role = data['role'] ?? 'user';
        _canMoveTools = data['canMoveTools'] ?? false;
        _canControlObjects = data['canControlObjects'] ?? false;
      } else {
        // Create default user doc if missing
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': _user!.email,
          'role': 'user',
          'canMoveTools': false,
          'canControlObjects': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _role = 'user';
        _canMoveTools = false;
        _canControlObjects = false;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _role = 'user';
    }
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      final userCredential =
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      _user = userCredential.user;
      if (_user != null) await _fetchUserData(_user!.uid);
      if (_rememberMe) await _prefs.setString('saved_email', email);
      return true;
    } on FirebaseAuthException catch (e) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, ErrorHandler.getFirebaseErrorMessage(e));
      return false;
    } catch (e) {
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Неизвестная ошибка');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUpWithEmail(String email, String password,
      {File? profileImage, String? adminPhrase}) async {
    try {
      _isLoading = true;
      notifyListeners();
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      _user = userCredential.user;
      if (profileImage != null && _user != null) {
        final imageUrl = await ImageService.uploadImage(profileImage, _user!.uid);
        if (imageUrl != null) _profileImage = profileImage;
      }
      if (_user != null) {
        final role = (adminPhrase == _adminSecret) ? 'admin' : 'user';
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
          'email': email,
          'role': role,
          'canMoveTools': false,
          'canControlObjects': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _role = role;
        _canMoveTools = false;
        _canControlObjects = false;
      }
      if (_rememberMe) await _prefs.setString('saved_email', email);
      return true;
    } on FirebaseAuthException catch (e) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, ErrorHandler.getFirebaseErrorMessage(e));
      return false;
    } catch (e) {
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Неизвестная ошибка');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _profileImage = null;
    _role = null;
    _canMoveTools = false;
    _canControlObjects = false;
    notifyListeners();
  }

  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    await _prefs.setBool('remember_me', value);
    if (!value) await _prefs.remove('saved_email');
    notifyListeners();
  }

  Future<void> setProfileImage(File image) async {
    _profileImage = image;
    if (_user != null) {
      final imageUrl = await ImageService.uploadImage(image, _user!.uid);
      if (imageUrl != null) await _prefs.setString('profile_image_url', imageUrl);
    }
    notifyListeners();
  }

  // Forgot password
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}

// ========== WORKER PROVIDER ==========
class WorkerProvider with ChangeNotifier {
  List<Worker> _workers = [];
  bool _isLoading = false;

  List<Worker> get workers => List.unmodifiable(_workers);
  bool get isLoading => _isLoading;

  Future<void> loadWorkers() async {
    _isLoading = true;
    notifyListeners();
    await LocalDatabase.init();
    _workers = LocalDatabase.workers.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addWorker(Worker worker) async {
    _workers.add(worker);
    await LocalDatabase.workers.put(worker.id, worker);
    notifyListeners();
  }

  Future<void> updateWorker(Worker worker) async {
    final index = _workers.indexWhere((w) => w.id == worker.id);
    if (index != -1) {
      _workers[index] = worker;
      await LocalDatabase.workers.put(worker.id, worker);
      notifyListeners();
    }
  }

  Future<void> deleteWorker(String id) async {
    _workers.removeWhere((w) => w.id == id);
    await LocalDatabase.workers.delete(id);
    notifyListeners();
  }

  List<Worker> getWorkersOnObject(String objectId) {
    return _workers.where((w) => w.assignedObjectId == objectId).toList();
  }
}

// ========== SALARY PROVIDER ==========
class SalaryProvider with ChangeNotifier {
  List<SalaryEntry> _salaries = [];
  List<Advance> _advances = [];
  List<Penalty> _penalties = [];

  Future<void> loadData() async {
    await LocalDatabase.init();
    _salaries = LocalDatabase.salaries.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    _advances = LocalDatabase.advances.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    _penalties = LocalDatabase.penalties.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  List<SalaryEntry> getSalariesForWorker(String workerId) {
    return _salaries.where((s) => s.workerId == workerId).toList();
  }

  List<Advance> getAdvancesForWorker(String workerId) {
    return _advances.where((a) => a.workerId == workerId).toList();
  }

  List<Penalty> getPenaltiesForWorker(String workerId) {
    return _penalties.where((p) => p.workerId == workerId).toList();
  }

  Future<void> addSalary(SalaryEntry salary) async {
    _salaries.add(salary);
    await LocalDatabase.salaries.put(salary.id, salary);
    notifyListeners();
  }

  Future<void> addAdvance(Advance advance) async {
    _advances.add(advance);
    await LocalDatabase.advances.put(advance.id, advance);
    notifyListeners();
  }

  Future<void> addPenalty(Penalty penalty) async {
    _penalties.add(penalty);
    await LocalDatabase.penalties.put(penalty.id, penalty);
    notifyListeners();
  }

  Future<void> deleteSalary(String id) async {
    _salaries.removeWhere((s) => s.id == id);
    await LocalDatabase.salaries.delete(id);
    notifyListeners();
  }

  Future<void> deleteAdvance(String id) async {
    _advances.removeWhere((a) => a.id == id);
    await LocalDatabase.advances.delete(id);
    notifyListeners();
  }

  Future<void> deletePenalty(String id) async {
    _penalties.removeWhere((p) => p.id == id);
    await LocalDatabase.penalties.delete(id);
    notifyListeners();
  }
}

// ========== ENHANCED TOOLS PROVIDER (with permission checks) ==========
class ToolsProvider with ChangeNotifier {
  List<Tool> _tools = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _sortAscending = false;
  bool _selectionMode = false;
  String _filterLocation = 'all';
  String _filterBrand = 'all';
  bool _filterFavorites = false;

  List<Tool> get tools => _getFilteredTools();
  List<Tool> get garageTools => _tools.where((t) => t.currentLocation == 'garage').toList();
  List<Tool> get favoriteTools => _tools.where((t) => t.isFavorite).toList();
  List<Tool> get selectedTools => _tools.where((t) => t.isSelected).toList();
  bool get isLoading => _isLoading;
  bool get selectionMode => _selectionMode;
  bool get hasSelectedTools => _tools.any((t) => t.isSelected);
  int get totalTools => _tools.length;
  String get filterLocation => _filterLocation;
  String get filterBrand => _filterBrand;
  bool get filterFavorites => _filterFavorites;

  List<String> get uniqueBrands {
    final brands = _tools.map((t) => t.brand).toSet().toList();
    brands.sort();
    return ['all', ...brands];
  }

  void toggleSelectionMode() {
    _selectionMode = !_selectionMode;
    if (!_selectionMode) _deselectAllTools();
    notifyListeners();
  }
  void toggleToolSelection(String toolId) {
    final index = _tools.indexWhere((t) => t.id == toolId);
    if (index != -1) {
      _tools[index] = _tools[index].copyWith(isSelected: !_tools[index].isSelected);
      notifyListeners();
    }
  }
  void selectAllTools() {
    for (var i = 0; i < _tools.length; i++) {
      _tools[i] = _tools[i].copyWith(isSelected: true);
    }
    notifyListeners();
  }
  void _deselectAllTools() {
    for (var i = 0; i < _tools.length; i++) {
      _tools[i] = _tools[i].copyWith(isSelected: false);
    }
    notifyListeners();
  }

  void setFilterLocation(String location) {
    _filterLocation = location;
    notifyListeners();
  }
  void setFilterBrand(String brand) {
    _filterBrand = brand;
    notifyListeners();
  }
  void setFilterFavorites(bool value) {
    _filterFavorites = value;
    notifyListeners();
  }
  void clearAllFilters() {
    _filterLocation = 'all';
    _filterBrand = 'all';
    _filterFavorites = false;
    _searchQuery = '';
    notifyListeners();
  }

  List<Tool> _getFilteredTools() {
    try {
      List<Tool> filtered = List.from(_tools);
      if (_filterLocation != 'all') {
        filtered = filtered.where((tool) => tool.currentLocation == _filterLocation).toList();
      }
      if (_filterBrand != 'all') {
        filtered = filtered.where((tool) => tool.brand == _filterBrand).toList();
      }
      if (_filterFavorites) {
        filtered = filtered.where((tool) => tool.isFavorite).toList();
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered.where((tool) =>
            tool.title.toLowerCase().contains(query) ||
            tool.brand.toLowerCase().contains(query) ||
            tool.uniqueId.toLowerCase().contains(query) ||
            tool.description.toLowerCase().contains(query)).toList();
      }
      return _sortTools(filtered);
    } catch (e) {
      return _sortTools(List.from(_tools));
    }
  }

  List<Tool> _sortTools(List<Tool> tools) {
    tools.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'name':
          cmp = a.title.compareTo(b.title);
          break;
        case 'date':
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
        case 'brand':
          cmp = a.brand.compareTo(b.brand);
          break;
        default:
          cmp = a.createdAt.compareTo(b.createdAt);
      }
      return _sortAscending ? cmp : -cmp;
    });
    return tools;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  void setSort(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    notifyListeners();
  }

  Future<void> loadTools({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      await LocalDatabase.init();
      final cached = LocalDatabase.tools.values.toList();
      if (cached.isNotEmpty) _tools = cached.where((t) => t != null).toList();
      if (forceRefresh || await LocalDatabase.shouldRefreshCache()) await _syncWithFirebase();
    } catch (e) {
      print('Error loading tools: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTool(Tool tool, {File? imageFile}) async {
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.isAdmin) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'Только администратор может добавлять инструменты');
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();
      if (tool.title.isEmpty || tool.brand.isEmpty || tool.uniqueId.isEmpty) {
        throw Exception('Заполните обязательные поля');
      }
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final url = await ImageService.uploadImage(imageFile, userId);
        if (url != null) {
          tool = tool.copyWith(imageUrl: url);
        } else {
          tool = tool.copyWith(localImagePath: imageFile.path);
        }
      }
      _tools.add(tool);
      await LocalDatabase.tools.put(tool.id, tool);
      await _addToSyncQueue(action: 'create', collection: 'tools', data: tool.toJson());
      ErrorHandler.showSuccessDialog(navigatorKey.currentContext!, 'Инструмент добавлен');
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTool(Tool tool, {File? imageFile}) async {
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.isAdmin) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'Только администратор может редактировать инструменты');
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();
      if (tool.title.isEmpty || tool.brand.isEmpty || tool.uniqueId.isEmpty) {
        throw Exception('Заполните обязательные поля');
      }
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final url = await ImageService.uploadImage(imageFile, userId);
        if (url != null) {
          tool = tool.copyWith(imageUrl: url, localImagePath: null);
        } else {
          tool = tool.copyWith(localImagePath: imageFile.path, imageUrl: null);
        }
      }
      final index = _tools.indexWhere((t) => t.id == tool.id);
      if (index != -1) {
        _tools[index] = tool;
        await LocalDatabase.tools.put(tool.id, tool);
        await _addToSyncQueue(action: 'update', collection: 'tools', data: tool.toJson());
        ErrorHandler.showSuccessDialog(navigatorKey.currentContext!, 'Инструмент обновлён');
      } else {
        throw Exception('Инструмент не найден');
      }
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTool(String toolId) async {
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.isAdmin) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'Только администратор может удалять инструменты');
      return;
    }
    try {
      final index = _tools.indexWhere((t) => t.id == toolId);
      if (index == -1) {
        ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Инструмент не найден');
        return;
      }
      _tools.removeAt(index);
      await LocalDatabase.tools.delete(toolId);
      await _addToSyncQueue(action: 'delete', collection: 'tools', data: {'id': toolId});
      ErrorHandler.showSuccessDialog(navigatorKey.currentContext!, 'Инструмент удалён');
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteSelectedTools() async {
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.isAdmin) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'Только администратор может удалять инструменты');
      return;
    }
    try {
      final selected = _tools.where((t) => t.isSelected).toList();
      if (selected.isEmpty) {
        ErrorHandler.showWarningDialog(
            navigatorKey.currentContext!, 'Выберите инструменты');
        return;
      }
      for (final tool in selected) {
        await LocalDatabase.tools.delete(tool.id);
        await _addToSyncQueue(action: 'delete', collection: 'tools', data: {'id': tool.id});
      }
      _tools.removeWhere((t) => t.isSelected);
      _selectionMode = false;
      ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext!, 'Удалено ${selected.length} инструментов');
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> duplicateTool(Tool original) async {
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.isAdmin) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'Только администратор может копировать инструменты');
      return;
    }
    try {
      final copyCount = _tools
              .where((t) =>
                  t.title.startsWith(original.title) && t.title.contains('Копия'))
              .length +
          1;
      final newTool = original.duplicate(copyCount);
      await addTool(newTool);
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    }
  }

  // Favorites - available to all users
  Future<void> toggleFavorite(String toolId) async {
    final index = _tools.indexWhere((t) => t.id == toolId);
    if (index == -1) return;
    final updated = _tools[index].copyWith(isFavorite: !_tools[index].isFavorite);
    _tools[index] = updated;
    await LocalDatabase.tools.put(updated.id, updated);
    await _addToSyncQueue(action: 'update', collection: 'tools', data: updated.toJson());
    notifyListeners();
  }

  Future<void> toggleFavoriteForSelected() async {
    final selected = _tools.where((t) => t.isSelected).toList();
    if (selected.isEmpty) {
      ErrorHandler.showWarningDialog(navigatorKey.currentContext!, 'Выберите инструменты');
      return;
    }
    for (final tool in selected) {
      final updated = tool.copyWith(isFavorite: !tool.isFavorite);
      await LocalDatabase.tools.put(updated.id, updated);
      await _addToSyncQueue(action: 'update', collection: 'tools', data: updated.toJson());
    }
    await loadTools();
    ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!, 'Обновлено ${selected.length} инструментов');
  }

  // Move logic with permissions
  Future<void> requestMoveTool(
      String toolId, String toLocationId, String toLocationName) async {
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (auth.canMoveTools) {
      // User has permission to move directly
      await moveTool(toolId, toLocationId, toLocationName);
      return;
    }
    final toolIndex = _tools.indexWhere((t) => t.id == toolId);
    if (toolIndex == -1) {
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Инструмент не найден');
      return;
    }
    final tool = _tools[toolIndex];
    final request = MoveRequest(
      id: IdGenerator.generateRequestId(),
      toolId: toolId,
      fromLocationId: tool.currentLocation,
      fromLocationName: tool.currentLocationName,
      toLocationId: toLocationId,
      toLocationName: toLocationName,
      requestedBy: auth.user!.uid,
      status: 'pending',
    );
    final reqProvider =
        Provider.of<MoveRequestProvider>(navigatorKey.currentContext!, listen: false);
    await reqProvider.createRequest(request);
    final adminSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();
    for (var doc in adminSnapshot.docs) {
      final notif = AppNotification(
        id: IdGenerator.generateNotificationId(),
        title: 'Новый запрос на перемещение',
        body: '${tool.title} запрошен на $toLocationName',
        type: 'move_request',
        relatedId: request.id,
        userId: doc.id,
      );
      await Provider.of<NotificationProvider>(navigatorKey.currentContext!, listen: false)
          .addNotification(notif);
    }
    ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!, 'Запрос отправлен администратору');
  }

  // Internal move method
  Future<void> moveTool(
      String toolId, String newLocationId, String newLocationName) async {
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.canMoveTools) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'У вас нет прав на перемещение');
      return;
    }
    final toolIndex = _tools.indexWhere((t) => t.id == toolId);
    if (toolIndex == -1) {
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Инструмент не найден');
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
            locationName: oldLocationName)
      ],
      currentLocation: newLocationId,
      currentLocationName: newLocationName,
      updatedAt: DateTime.now(),
      isSelected: false,
    );
    _tools[toolIndex] = updatedTool;
    await LocalDatabase.tools.put(updatedTool.id, updatedTool);
    await _addToSyncQueue(action: 'update', collection: 'tools', data: updatedTool.toJson());
    ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!, 'Инструмент перемещён в $newLocationName');
  }

  Future<void> moveSelectedTools(
      String newLocationId, String newLocationName) async {
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.canMoveTools) {
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!,
          'У вас нет прав на перемещение нескольких инструментов');
      return;
    }
    final selected = _tools.where((t) => t.isSelected).toList();
    if (selected.isEmpty) {
      ErrorHandler.showWarningDialog(
          navigatorKey.currentContext!, 'Выберите инструменты');
      return;
    }
    for (final tool in selected) {
      final updatedTool = tool.copyWith(
        locationHistory: [
          ...tool.locationHistory,
          LocationHistory(
              date: DateTime.now(),
              locationId: tool.currentLocation,
              locationName: tool.currentLocationName)
        ],
        currentLocation: newLocationId,
        currentLocationName: newLocationName,
        updatedAt: DateTime.now(),
        isSelected: false,
      );
      await LocalDatabase.tools.put(updatedTool.id, updatedTool);
      await _addToSyncQueue(action: 'update', collection: 'tools', data: updatedTool.toJson());
    }
    await loadTools();
    _selectionMode = false;
    ErrorHandler.showSuccessDialog(navigatorKey.currentContext!,
        'Перемещено ${selected.length} инструментов в $newLocationName');
  }

  Future<void> requestMoveSelectedTools(List<Tool> selectedTools,
      String toLocationId, String toLocationName) async {
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (auth.canMoveTools) {
      // User can move directly
      await moveSelectedTools(toLocationId, toLocationName);
      return;
    }
    // Create batch request
    final request = BatchMoveRequest(
      id: IdGenerator.generateBatchRequestId(),
      toolIds: selectedTools.map((t) => t.id).toList(),
      fromLocationId: 'multiple',
      fromLocationName: 'Разные',
      toLocationId: toLocationId,
      toLocationName: toLocationName,
      requestedBy: auth.user!.uid,
      status: 'pending',
    );
    final batchProvider =
        Provider.of<BatchMoveRequestProvider>(navigatorKey.currentContext!, listen: false);
    await batchProvider.createRequest(request);
    // Notify admins
    final adminSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();
    for (var doc in adminSnapshot.docs) {
      final notif = AppNotification(
        id: IdGenerator.generateNotificationId(),
        title: 'Новый групповой запрос',
        body: '${selectedTools.length} инструментов → $toLocationName',
        type: 'batch_move_request',
        relatedId: request.id,
        userId: doc.id,
      );
      await Provider.of<NotificationProvider>(navigatorKey.currentContext!, listen: false)
          .addNotification(notif);
    }
    ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!, 'Запрос отправлен администратору');
  }

  Future<void> _addToSyncQueue(
      {required String action,
      required String collection,
      required Map<String, dynamic> data}) async {
    try {
      await LocalDatabase.syncQueue.put('${DateTime.now().millisecondsSinceEpoch}',
          SyncItem(
              id: '${DateTime.now().millisecondsSinceEpoch}',
              action: action,
              collection: collection,
              data: data));
    } catch (e) {
      print('Sync queue error: $e');
    }
  }

  Future<void> _syncWithFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Sync queue
      for (final item in LocalDatabase.syncQueue.values) {
        try {
          final doc = FirebaseFirestore.instance
              .collection(item.collection)
              .doc(item.data['id'] as String);
          if (item.action == 'delete') {
            await doc.delete();
          } else {
            await doc.set(item.data, SetOptions(merge: true));
          }
          await LocalDatabase.syncQueue.delete(item.id);
        } catch (e) {
          print('Sync item error: $e');
        }
      }

      // Determine if current user is admin
      bool isAdmin = false;
      try {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          isAdmin = (userDoc.data()?['role'] ?? 'user') == 'admin';
        }
      } catch (e) {
        print('Error checking admin status: $e');
      }

      // For admin: load all tools, for regular users: load only their tools
      Query query = FirebaseFirestore.instance.collection('tools');
      if (!isAdmin) {
        query = query.where('userId', isEqualTo: user.uid);
      }
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
       }
    } catch (e) {
      print('Sync error: $e');
    }
  }
}

// ========== ENHANCED OBJECTS PROVIDER (with permission checks) ==========
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
    _selectionMode = !_selectionMode;
    if (!_selectionMode) _deselectAllObjects();
    notifyListeners();
  }
  void toggleObjectSelection(String objectId) {
    final index = _objects.indexWhere((o) => o.id == objectId);
    if (index != -1) {
      _objects[index] =
          _objects[index].copyWith(isSelected: !_objects[index].isSelected);
      notifyListeners();
    }
  }
  void selectAllObjects() {
    for (var i = 0; i < _objects.length; i++) {
      _objects[i] = _objects[i].copyWith(isSelected: true);
    }
    notifyListeners();
  }
  void _deselectAllObjects() {
    for (var i = 0; i < _objects.length; i++) {
      _objects[i] = _objects[i].copyWith(isSelected: false);
    }
    notifyListeners();
  }

  List<ConstructionObject> _getFilteredObjects() {
    if (_searchQuery.isEmpty) return _sortObjects(List.from(_objects));
    final q = _searchQuery.toLowerCase();
    return _sortObjects(_objects
        .where((o) =>
            o.name.toLowerCase().contains(q) ||
            o.description.toLowerCase().contains(q))
        .toList());
  }

  List<ConstructionObject> _sortObjects(List<ConstructionObject> list) {
    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'name':
          cmp = a.name.compareTo(b.name);
          break;
        case 'date':
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
        case 'toolCount':
          cmp = a.toolIds.length.compareTo(b.toolIds.length);
          break;
        default:
          cmp = a.name.compareTo(b.name);
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  void setSort(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    notifyListeners();
  }

  Future<void> loadObjects({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      await LocalDatabase.init();
      final cached = LocalDatabase.objects.values.toList();
      if (cached.isNotEmpty) _objects = cached.where((o) => o != null).toList();
      if (forceRefresh || await LocalDatabase.shouldRefreshCache()) {
        await _syncWithFirebase();
      }
    } catch (e) {
      print('Error loading objects: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addObject(ConstructionObject obj, {File? imageFile}) async {
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.canControlObjects) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'У вас нет прав на добавление объектов');
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();
      if (obj.name.isEmpty) throw Exception('Введите название');
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final url = await ImageService.uploadImage(imageFile, userId);
        if (url != null) {
          obj = obj.copyWith(imageUrl: url);
        } else {
          obj = obj.copyWith(localImagePath: imageFile.path);
        }
      }
      _objects.add(obj);
      await LocalDatabase.objects.put(obj.id, obj);
      await _addToSyncQueue(action: 'create', collection: 'objects', data: obj.toJson());
      ErrorHandler.showSuccessDialog(navigatorKey.currentContext!, 'Объект добавлен');
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateObject(ConstructionObject obj, {File? imageFile}) async {
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.canControlObjects) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'У вас нет прав на редактирование объектов');
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();
      if (obj.name.isEmpty) throw Exception('Введите название');
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final url = await ImageService.uploadImage(imageFile, userId);
        if (url != null) {
          obj = obj.copyWith(imageUrl: url, localImagePath: null);
        } else {
          obj = obj.copyWith(localImagePath: imageFile.path, imageUrl: null);
        }
      }
      final index = _objects.indexWhere((o) => o.id == obj.id);
      if (index == -1) {
        ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Объект не найден');
        return;
      }
      _objects[index] = obj;
      await LocalDatabase.objects.put(obj.id, obj);
      await _addToSyncQueue(action: 'update', collection: 'objects', data: obj.toJson());
      ErrorHandler.showSuccessDialog(navigatorKey.currentContext!, 'Объект обновлён');
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteObject(String objectId) async {
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.canControlObjects) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'У вас нет прав на удаление объектов');
      return;
    }
    try {
      final index = _objects.indexWhere((o) => o.id == objectId);
      if (index == -1) {
        ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Объект не найден');
        return;
      }
      _objects.removeAt(index);
      await LocalDatabase.objects.delete(objectId);
      await _addToSyncQueue(action: 'delete', collection: 'objects', data: {'id': objectId});
      ErrorHandler.showSuccessDialog(navigatorKey.currentContext!, 'Объект удалён');
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteSelectedObjects() async {
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.canControlObjects) {
      ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!, 'У вас нет прав на удаление объектов');
      return;
    }
    try {
      final selected = _objects.where((o) => o.isSelected).toList();
      if (selected.isEmpty) {
        ErrorHandler.showWarningDialog(
            navigatorKey.currentContext!, 'Выберите объекты');
        return;
      }
      for (final obj in selected) {
        await LocalDatabase.objects.delete(obj.id);
        await _addToSyncQueue(action: 'delete', collection: 'objects', data: {'id': obj.id});
      }
      _objects.removeWhere((o) => o.isSelected);
      _selectionMode = false;
      ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext!, 'Удалено ${selected.length} объектов');
    } catch (e, s) {
      ErrorHandler.handleError(e, s);
      ErrorHandler.showErrorDialog(navigatorKey.currentContext!, 'Ошибка: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _addToSyncQueue(
      {required String action,
      required String collection,
      required Map<String, dynamic> data}) async {
    try {
      await LocalDatabase.syncQueue.put('${DateTime.now().millisecondsSinceEpoch}',
          SyncItem(
              id: '${DateTime.now().millisecondsSinceEpoch}',
              action: action,
              collection: collection,
              data: data));
    } catch (e) {
      print('Sync queue error: $e');
    }
  }

  Future<void> _syncWithFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Determine if admin
      bool isAdmin = false;
      try {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          isAdmin = (userDoc.data()?['role'] ?? 'user') == 'admin';
        }
      } catch (e) {
        print('Error checking admin status: $e');
      }

      // Admin sees all objects, others only their own
      Query query = FirebaseFirestore.instance.collection('objects');
      if (!isAdmin) {
        query = query.where('userId', isEqualTo: user.uid);
      }
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
       }
    } catch (e) {
      print('Objects sync error: $e');
    }
  }
}

// ========== SELECTION TOOL CARD (updated with permission checks) ==========
class SelectionToolCard extends StatelessWidget {
  final Tool tool;
  final bool selectionMode;
  final VoidCallback onTap;
  const SelectionToolCard(
      {super.key, required this.tool, required this.selectionMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ToolsProvider, AuthProvider>(
      builder: (context, toolsProvider, authProvider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: selectionMode
                ? () => toolsProvider.toggleToolSelection(tool.id)
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
                        onChanged: (value) =>
                            toolsProvider.toggleToolSelection(tool.id),
                        shape: const CircleBorder(),
                      ),
                    ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          Theme.of(context).colorScheme.primary.withOpacity(0.05),
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
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.build,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 30),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.build,
                                color: Theme.of(context).colorScheme.primary,
                                size: 30),
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
                                    fontSize: 16, fontWeight: FontWeight.w600),
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
                                  color: tool.isFavorite ? Colors.red : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () => toolsProvider.toggleFavorite(tool.id),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tool.brand,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tool.currentLocationName,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                      onSelected: (value) async {
                        switch (value) {
                          case 'edit':
                            if (authProvider.isAdmin) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditToolScreen(tool: tool),
                                ),
                              );
                            }
                            break;
                          case 'duplicate':
                            if (tool.currentLocation == 'garage' &&
                                authProvider.isAdmin) {
                              toolsProvider.duplicateTool(tool);
                            }
                            break;
                          case 'share':
                            ReportService.showReportTypeDialog(
                                context, tool, (type) =>
                                ReportService.shareToolReport(tool, context, type));
                            break;
                          case 'print':
                            ReportService.printToolReport(tool, context);
                            break;
                          case 'move':
                            _showMoveDialog(context, tool, authProvider);
                            break;
                          case 'delete':
                            if (authProvider.isAdmin) {
                              _showDeleteDialog(context, tool);
                            }
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        List<PopupMenuEntry> items = [];
                        if (authProvider.isAdmin) {
                          items.add(
                              const PopupMenuItem(value: 'edit', child: Text('Редактировать')));
                        }
                        if (tool.currentLocation == 'garage' && authProvider.isAdmin) {
                          items.add(const PopupMenuItem(
                              value: 'duplicate', child: Text('Дублировать')));
                        }
                        items.add(const PopupMenuItem(
                            value: 'share', child: Text('Поделиться отчетом')));
                        items.add(const PopupMenuItem(
                            value: 'print', child: Text('Печать отчета')));
                        items.add(PopupMenuItem(
                            value: 'move',
                            child: Text(authProvider.canMoveTools
                                ? 'Переместить'
                                : 'Запросить перемещение')));
                        if (authProvider.isAdmin) {
                            items.add(const PopupMenuItem(
                              value: 'delete',
                              child: Text('Удалить', style: TextStyle(color: Colors.red))));
                        }
                        return items;
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMoveDialog(BuildContext context, Tool tool, AuthProvider auth) {
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    String? selectedId = tool.currentLocation;
    String? selectedName = tool.currentLocationName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade100],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    auth.canMoveTools ? 'Переместить инструмент' : 'Запросить перемещение',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.garage, color: Colors.blue),
                    title: const Text('Гараж'),
                    trailing: selectedId == 'garage'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedId = 'garage';
                        selectedName = 'Гараж';
                      });
                    },
                  ),
                  const Divider(),
                  ...objectsProvider.objects.map((obj) => ListTile(
                        leading: const Icon(Icons.location_city, color: Colors.orange),
                        title: Text(obj.name),
                        subtitle: Text('${obj.toolIds.length} инструментов'),
                        trailing: selectedId == obj.id
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          setState(() {
                            selectedId = obj.id;
                            selectedName = obj.name;
                          });
                        },
                      )),
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
                            if (selectedId != null && selectedName != null) {
                              if (auth.canMoveTools) {
                                await toolsProvider.moveTool(
                                    tool.id, selectedId!, selectedName!);
                              } else {
                                await toolsProvider.requestMoveTool(
                                    tool.id, selectedId!, selectedName!);
                              }
                              Navigator.pop(context);
                            }
                          },
                          child: Text(auth.canMoveTools ? 'Переместить' : 'Отправить запрос'),
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

  void _showDeleteDialog(BuildContext context, Tool tool) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAdmin) {
      ErrorHandler.showErrorDialog(context, 'Только администратор может удалять');
      return;
    }
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
              await Provider.of<ToolsProvider>(context, listen: false)
                  .deleteTool(tool.id);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ========== ADD/EDIT TOOL SCREEN (admin only) ==========
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
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAdmin) {
      return const Scaffold(
          body: Center(child: Text('Только администратор может редактировать инструменты')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактировать инструмент' : 'Добавить инструмент'),
        actions: [
          if (isEdit && auth.isAdmin)
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
                          await Provider.of<ToolsProvider>(context, listen: false)
                              .deleteTool(widget.tool!.id);
                          Navigator.pop(context);
                        },
                        child: const Text('Удалить', style: TextStyle(color: Colors.red)),
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
                              Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            ],
                          ),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _getImageWidget(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Название инструмента *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.title),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        labelText: 'Бренд *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.branding_watermark),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Введите бренд' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _uniqueIdController,
                      decoration: InputDecoration(
                        labelText: 'Уникальный идентификатор *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.qr_code),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () =>
                              _uniqueIdController.text = IdGenerator.generateUniqueId(),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Введите идентификатор' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.description),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveTool,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          child: Image.file(_imageFile!, fit: BoxFit.cover));
    }
    if (_imageUrl != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(_imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder()));
    }
    if (_localImagePath != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(File(_localImagePath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder()));
    }
    return _buildPlaceholder();
  }
  Widget _buildPlaceholder() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('Добавить фото инструмента', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
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
            if (_imageFile != null || _imageUrl != null || _localImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить фото', style: TextStyle(color: Colors.red)),
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
      ),
    );
  }
}

// ========== ENHANCED GARAGE SCREEN ==========
class EnhancedGarageScreen extends StatefulWidget {
  const EnhancedGarageScreen({super.key});
  @override
  State<EnhancedGarageScreen> createState() => _EnhancedGarageScreenState();
}
class _EnhancedGarageScreenState extends State<EnhancedGarageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ToolsProvider>(context, listen: false).loadTools();
    });
  }
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final garageTools = toolsProvider.garageTools;
    return Scaffold(
      body: toolsProvider.isLoading && garageTools.isEmpty
          ? _buildLoadingScreen()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        bottomRight: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Мой Гараж',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('${garageTools.length} инструментов доступно',
                          style: const TextStyle(fontSize: 16, color: Colors.white70)),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard(context, '    Всего    ',
                                  '${toolsProvider.totalTools}', Icons.build,
                                  Colors.white.withOpacity(0.2)),
                              const SizedBox(width: 10),
                              _buildStatCard(context, 'В гараже',
                                  '${garageTools.length}', Icons.garage,
                                  Colors.white.withOpacity(0.2)),
                              const SizedBox(width: 10),
                              _buildStatCard(context, 'Избранные',
                                  '${toolsProvider.favoriteTools.length}',
                                  Icons.favorite, Colors.white.withOpacity(0.2)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (authProvider.isAdmin)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const AddEditToolScreen())),
                            icon: const Icon(Icons.add),
                            label: const Text('Добавить'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      if (authProvider.isAdmin) const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: toolsProvider.toggleSelectionMode,
                        icon: const Icon(Icons.checklist),
                        label: Text(toolsProvider.selectionMode ? 'Отменить' : 'Выбрать'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: garageTools.isEmpty
                      ? _buildEmptyGarage(authProvider.isAdmin)
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: garageTools.length,
                          itemBuilder: (context, index) {
                            final tool = garageTools[index];
                            return SelectionToolCard(
                              tool: tool,
                              selectionMode: toolsProvider.selectionMode,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EnhancedToolDetailsScreen(tool: tool))),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: toolsProvider.selectionMode && toolsProvider.hasSelectedTools
          ? FloatingActionButton.extended(
              onPressed: () => _showGarageSelectionActions(context),
              icon: const Icon(Icons.more_vert),
              label: Text('${toolsProvider.selectedTools.length}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  Widget _buildLoadingScreen() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 20),
            Text('Загрузка гаража...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
  Widget _buildStatCard(BuildContext context, String title, String value,
          IconData icon, Color backgroundColor) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.white),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      );
  Widget _buildEmptyGarage(bool isAdmin) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.garage, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text('Гараж пуст',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 10),
            Text('Добавьте инструменты в гараж',
                style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 20),
            if (isAdmin)
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddEditToolScreen())),
                child: const Text('Добавить первый инструмент'),
              ),
          ],
        ),
      );
  void _showGarageSelectionActions(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
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
              Text('Выбрано: $selectedCount инструментов',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('Добавить в избранное'),
                onTap: () {
                  Navigator.pop(context);
                  toolsProvider.toggleFavoriteForSelected();
                },
              ),
              if (auth.canMoveTools) ...[
                ListTile(
                  leading: const Icon(Icons.move_to_inbox, color: Colors.blue),
                  title: const Text('Переместить выбранные'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                MoveToolsScreen(selectedTools: toolsProvider.selectedTools)));
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.move_to_inbox, color: Colors.orange),
                  title: const Text('Запросить перемещение'),
                  onTap: () {
                    Navigator.pop(context);
                    _showBatchMoveRequestDialog(context, toolsProvider.selectedTools);
                  },
                ),
              ],
              if (auth.isAdmin) ...[
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Удалить выбранные'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMultiDeleteDialog(context);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Поделиться отчетами'),
                onTap: () async {
                  Navigator.pop(context);
                  for (final tool in toolsProvider.selectedTools) {
                    await ReportService.shareToolReport(tool, context, ReportType.text);
                  }
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content:
            Text('Удалить выбранные ${toolsProvider.selectedTools.length} инструментов?'),
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
  void _showBatchMoveRequestDialog(BuildContext context, List<Tool> selectedTools) {
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    String? selectedId;
    String? selectedName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
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
              Text('Запрос перемещения (${selectedTools.length} инструментов)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...selectedTools.take(5).map((t) =>
                  Text('• ${t.title} (${t.currentLocationName})')).toList(),
              if (selectedTools.length > 5) Text('... и еще ${selectedTools.length - 5}'),
              const Divider(height: 30),
              ListTile(
                leading: const Icon(Icons.garage, color: Colors.blue),
                title: const Text('Гараж'),
                trailing: selectedId == 'garage' ? const Icon(Icons.check) : null,
                onTap: () => setState(() {
                  selectedId = 'garage';
                  selectedName = 'Гараж';
                }),
              ),
              ...objectsProvider.objects.map((obj) => ListTile(
                    leading: const Icon(Icons.location_city, color: Colors.orange),
                    title: Text(obj.name),
                    trailing: selectedId == obj.id ? const Icon(Icons.check) : null,
                    onTap: () => setState(() {
                      selectedId = obj.id;
                      selectedName = obj.name;
                    }),
                  )),
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
                      onPressed: selectedId == null
                          ? null
                          : () async {
                              await toolsProvider.requestMoveSelectedTools(
                                  selectedTools, selectedId!, selectedName!);
                              Navigator.pop(context);
                            },
                      child: const Text('Отправить запрос'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    final auth = Provider.of<AuthProvider>(context);
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
                onPressed: () => ReportService.showReportTypeDialog(
                  context,
                  tool,
                  (type) => ReportService.shareToolReport(tool, context, type),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () => ReportService.printToolReport(tool, context),
              ),
              PopupMenuButton(
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      if (auth.isAdmin) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditToolScreen(tool: tool),
                          ),
                        );
                      }
                      break;
                    case 'duplicate':
                      if (tool.currentLocation == 'garage' && auth.isAdmin) {
                        Provider.of<ToolsProvider>(context, listen: false)
                            .duplicateTool(tool);
                        Navigator.pop(context);
                      }
                      break;
                    case 'delete':
                      if (auth.isAdmin) {
                        _showDeleteConfirmation(context);
                      }
                      break;
                  }
                },
                itemBuilder: (context) {
                  List<PopupMenuItem> items = [];
                  if (auth.isAdmin) {
                    items.add(const PopupMenuItem(
                        value: 'edit', child: Text('Редактировать')));
                  }
                  if (tool.currentLocation == 'garage' && auth.isAdmin) {
                    items.add(const PopupMenuItem(
                        value: 'duplicate', child: Text('Дублировать')));
                  }
                  if (auth.isAdmin) {
                    items.add(const PopupMenuItem(
                        value: 'delete',
                        child: Text('Удалить', style: TextStyle(color: Colors.red))));
                  }
                  return items;
                },
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
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Consumer<ToolsProvider>(
                        builder: (context, tp, _) => IconButton(
                          icon: Icon(
                            tool.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: tool.isFavorite ? Colors.red : null,
                            size: 30,
                          ),
                          onPressed: () => tp.toggleFavorite(tool.id),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(tool.uniqueId, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (tool.description.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
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
                                  color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tool.description,
                              style: TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
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
                          color: Colors.blue),
                      _buildDetailCard(
                          icon: Icons.calendar_today,
                          title: 'Добавлен',
                          value: DateFormat('dd.MM.yyyy').format(tool.createdAt),
                          color: Colors.green),
                      _buildDetailCard(
                          icon: Icons.update,
                          title: 'Обновлен',
                          value: DateFormat('dd.MM.yyyy').format(tool.updatedAt),
                          color: Colors.orange),
                      _buildDetailCard(
                          icon: Icons.star,
                          title: 'Статус',
                          value: tool.isFavorite ? 'Избранный' : 'Обычный',
                          color: Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (tool.locationHistory.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
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
                                      color: theme.colorScheme.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...tool.locationHistory.map(
                              (history) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(history.locationName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('dd.MM.yyyy HH:mm')
                                                .format(history.date),
                                            style: const TextStyle(
                                                fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
        child: Consumer2<ToolsProvider, AuthProvider>(
          builder: (context, tp, auth, _) => ElevatedButton.icon(
            onPressed: () => _showMoveDialog(context, tool, auth),
            icon: const Icon(Icons.move_to_inbox),
            label: Text(auth.canMoveTools ? 'Переместить инструмент' : 'Запросить перемещение'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildDetailCard(
          {required IconData icon,
          required String title,
          required String value,
          required Color color}) =>
      Card(
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
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      );
  void _showDeleteConfirmation(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAdmin) {
      ErrorHandler.showErrorDialog(context, 'Только администратор может удалять');
      return;
    }
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
              await Provider.of<ToolsProvider>(context, listen: false)
                  .deleteTool(tool.id);
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  void _showMoveDialog(BuildContext context, Tool tool, AuthProvider auth) {
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    String? selectedId = tool.currentLocation;
    String? selectedName = tool.currentLocationName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    auth.canMoveTools ? 'Переместить инструмент' : 'Запросить перемещение',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.garage, color: Colors.blue),
                    title: const Text('Гараж'),
                    trailing: selectedId == 'garage'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedId = 'garage';
                        selectedName = 'Гараж';
                      });
                    },
                  ),
                  const Divider(),
                  ...objectsProvider.objects.map((obj) => ListTile(
                        leading: const Icon(Icons.location_city, color: Colors.orange),
                        title: Text(obj.name),
                        subtitle: Text('${obj.toolIds.length} инструментов'),
                        trailing: selectedId == obj.id
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          setState(() {
                            selectedId = obj.id;
                            selectedName = obj.name;
                          });
                        },
                      )),
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
                            if (selectedId != null && selectedName != null) {
                              if (auth.canMoveTools) {
                                await toolsProvider.moveTool(
                                    tool.id, selectedId!, selectedName!);
                              } else {
                                await toolsProvider.requestMoveTool(
                                    tool.id, selectedId!, selectedName!);
                              }
                              Navigator.pop(context);
                            }
                          },
                          child: Text(auth.canMoveTools ? 'Переместить' : 'Отправить запрос'),
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
  const ObjectCard(
      {super.key,
      required this.object,
      required this.toolsProvider,
      required this.selectionMode,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final toolsOnObject =
        toolsProvider.tools.where((tool) => tool.currentLocation == object.id).toList();
    final auth = Provider.of<AuthProvider>(context);
    return Consumer<ObjectsProvider>(
      builder: (context, objectsProvider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: selectionMode
                ? () => objectsProvider.toggleObjectSelection(object.id)
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
                        onChanged: (value) =>
                            objectsProvider.toggleObjectSelection(object.id),
                        shape: const CircleBorder(),
                      ),
                    ),
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
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.location_city,
                                    color: Colors.orange, size: 30),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.location_city,
                                color: Colors.orange, size: 30),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          object.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (object.description.isNotEmpty) const SizedBox(height: 4),
                        if (object.description.isNotEmpty)
                          Text(
                            object.description,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.build, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${toolsOnObject.length} инструментов',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!selectionMode)
                    PopupMenuButton(
                      onSelected: (value) async {
                        switch (value) {
                          case 'edit':
                            if (auth.canControlObjects) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditObjectScreen(object: object),
                                ),
                              );
                            }
                            break;
                          case 'share':
                            ReportService.showObjectReportTypeDialog(
                                context, object, toolsOnObject, (type) =>
                                ReportService.shareObjectReport(
                                    object, toolsOnObject, context, type));
                            break;
                          case 'delete':
                            if (auth.canControlObjects) {
                              _showDeleteDialog(context, object);
                            }
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        List<PopupMenuItem> items = [];
                        if (auth.canControlObjects) {
                          items.add(const PopupMenuItem(
                              value: 'edit', child: Text('Редактировать')));
                        }
                        items.add(const PopupMenuItem(
                            value: 'share', child: Text('Поделиться отчетом')));
                        if (auth.canControlObjects) {
                          items.add(const PopupMenuItem(
                              value: 'delete',
                              child: Text('Удалить', style: TextStyle(color: Colors.red))));
                        }
                        return items;
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  void _showDeleteDialog(BuildContext context, ConstructionObject object) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.canControlObjects) {
      ErrorHandler.showErrorDialog(
          context, 'У вас нет прав на удаление объектов');
      return;
    }
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
              await Provider.of<ObjectsProvider>(context, listen: false)
                  .deleteObject(object.id);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
      final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
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
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.canControlObjects) {
      return const Scaffold(
          body: Center(child: Text('У вас нет прав на редактирование объектов')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактировать объект' : 'Добавить объект'),
        actions: [
          if (isEdit && auth.canControlObjects)
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
                          await Provider.of<ObjectsProvider>(context, listen: false)
                              .deleteObject(widget.object!.id);
                          Navigator.pop(context);
                        },
                        child: const Text('Удалить', style: TextStyle(color: Colors.red)),
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
                              Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            ],
                          ),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _getImageWidget(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Название объекта *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.title),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.description),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveObject,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
          child: Image.file(_imageFile!, fit: BoxFit.cover));
    }
    if (_imageUrl != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(_imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder()));
    }
    if (_localImagePath != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(File(_localImagePath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder()));
    }
    return _buildPlaceholder();
  }
  Widget _buildPlaceholder() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('Добавить фото объекта', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
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
            if (_imageFile != null || _imageUrl != null || _localImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить фото', style: TextStyle(color: Colors.red)),
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
      ),
    );
  }
}

// ========== OBJECT DETAILS SCREEN ==========
class ObjectDetailsScreen extends StatelessWidget {
  final ConstructionObject object;
  const ObjectDetailsScreen({super.key, required this.object});
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final toolsOnObject =
        toolsProvider.tools.where((tool) => tool.currentLocation == object.id).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(object.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => ReportService.showObjectReportTypeDialog(
                context, object, toolsOnObject, (type) =>
                ReportService.shareObjectReport(object, toolsOnObject, context, type)),
          ),
          if (auth.canControlObjects)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AddEditObjectScreen(object: object))),
            ),
        ],
      ),
      body: Column(
        children: [
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
                        ? NetworkImage(object.displayImage!) as ImageProvider
                        : FileImage(File(object.displayImage!)),
                    fit: BoxFit.cover)
                : Center(
                    child: Icon(Icons.location_city,
                        size: 80, color: Colors.grey.shade300),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(object.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (object.description.isNotEmpty)
                  Text(object.description,
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.build, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Инструментов на объекте: ${toolsOnObject.length}',
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                        'Создан: ${DateFormat('dd.MM.yyyy').format(object.createdAt)}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
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
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EnhancedToolDetailsScreen(tool: tool))),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyObjectTools() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('На объекте нет инструментов',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Переместите инструменты на этот объект',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
}

// ========== ENHANCED OBJECTS LIST SCREEN ==========
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
      Provider.of<ObjectsProvider>(context, listen: false).loadObjects();
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
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Объекты (${objectsProvider.totalObjects})'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => objectsProvider.loadObjects(forceRefresh: true))
        ],
      ),
      body: objectsProvider.isLoading && objectsProvider.objects.isEmpty
          ? _buildLoadingScreen()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск объектов...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: objectsProvider.setSearchQuery,
                  ),
                ),
                Expanded(
                  child: objectsProvider.objects.isEmpty
                      ? _buildEmptyObjectsScreen(auth.canControlObjects)
                      : ListView.builder(
                          itemCount: objectsProvider.objects.length,
                          itemBuilder: (context, index) {
                            final object = objectsProvider.objects[index];
                            return ObjectCard(
                              object: object,
                              toolsProvider: toolsProvider,
                              selectionMode: objectsProvider.selectionMode,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ObjectDetailsScreen(object: object))),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: objectsProvider.selectionMode
          ? FloatingActionButton.extended(
              onPressed: objectsProvider.hasSelectedObjects
                  ? () => _showObjectSelectionActions(context)
                  : null,
              icon: const Icon(Icons.more_vert),
              label: Text('${objectsProvider.selectedObjects.length}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : (auth.canControlObjects
              ? FloatingActionButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddEditObjectScreen())),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.add),
                )
              : null),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  Widget _buildLoadingScreen() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 20),
            Text('Загрузка объектов...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
  Widget _buildEmptyObjectsScreen(bool canControl) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text('Нет объектов',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 10),
            if (canControl)
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddEditObjectScreen())),
                child: const Text('Добавить объект'),
              ),
          ],
        ),
      );
  void _showObjectSelectionActions(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
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
              Text('Выбрано: $selectedCount объектов',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (auth.canControlObjects)
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
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
            'Удалить выбранные ${objectsProvider.selectedObjects.length} объектов?\n\nИнструменты на этих объектах будут перемещены в гараж.'),
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
      appBar: AppBar(title: Text('Перемещение ${widget.selectedTools.length} инструментов')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Выберите место назначения:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
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
                  ...objectsProvider.objects.map((obj) => ListTile(
                        leading: const Icon(Icons.location_city, color: Colors.orange),
                        title: Text(obj.name),
                        subtitle: Text('${obj.toolIds.length} инструментов'),
                        trailing: _selectedLocationId == obj.id
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedLocationId = obj.id;
                            _selectedLocationName = obj.name;
                          });
                        },
                      )),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.selectedTools.length,
              itemBuilder: (context, index) {
                final tool = widget.selectedTools[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Icon(Icons.build,
                            color: Theme.of(context).colorScheme.primary)),
                    title: Text(tool.title),
                    subtitle: Text(tool.brand),
                    trailing: Text(tool.currentLocationName,
                        style: const TextStyle(color: Colors.grey)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: ElevatedButton(
              onPressed: () async {
                if (_selectedLocationId == null || _selectedLocationName == null) {
                  ErrorHandler.showWarningDialog(context, 'Выберите место назначения');
                  return;
                }
                await toolsProvider.moveSelectedTools(
                    _selectedLocationId!, _selectedLocationName!);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Переместить ${widget.selectedTools.length} инструментов'),
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
    final favoriteTools = toolsProvider.favoriteTools;
    return Scaffold(
      appBar: AppBar(title: Text('Избранное (${favoriteTools.length})')),
      body: favoriteTools.isEmpty
          ? _buildEmptyFavoritesScreen()
          : ListView.builder(
              itemCount: favoriteTools.length,
              itemBuilder: (context, index) {
                final tool = favoriteTools[index];
                return SelectionToolCard(
                  tool: tool,
                  selectionMode: false,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EnhancedToolDetailsScreen(tool: tool))),
                );
              },
            ),
    );
  }
  Widget _buildEmptyFavoritesScreen() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text('Нет избранных инструментов',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 10),
            const Text('Добавьте инструменты в избранное',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
}

// ========== ADMIN MOVE REQUESTS SCREEN (single) ==========
class AdminMoveRequestsScreen extends StatelessWidget {
  const AdminMoveRequestsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final reqProvider = Provider.of<MoveRequestProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final pending = reqProvider.pendingRequests;
    return Scaffold(
      appBar: AppBar(title: Text('Запросы на перемещение (${pending.length})')),
      body: pending.isEmpty
          ? const Center(child: Text('Нет ожидающих запросов'))
          : ListView.builder(
              itemCount: pending.length,
              itemBuilder: (context, index) {
                final req = pending[index];
                Tool? tool;
                try {
                  tool = toolsProvider.tools.firstWhere((t) => t.id == req.toolId);
                } catch (e) {
                  tool = null;
                }
                if (tool == null) return const SizedBox.shrink();
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(tool.title),
                    subtitle:
                        Text('${req.fromLocationName} → ${req.toLocationName} от ${req.requestedBy}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await toolsProvider.moveTool(
                                req.toolId, req.toLocationId, req.toLocationName);
                            await reqProvider.updateRequestStatus(req.id, 'approved');
                            final notif = AppNotification(
                              id: IdGenerator.generateNotificationId(),
                              title: 'Запрос одобрен',
                              body: 'Перемещение ${tool!.title} в ${req.toLocationName} подтверждено',
                              type: 'move_approved',
                              relatedId: req.id,
                              userId: req.requestedBy,
                            );
                            await notifProvider.addNotification(notif);
                            ErrorHandler.showSuccessDialog(context, 'Запрос одобрен');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await reqProvider.updateRequestStatus(req.id, 'rejected');
                            final notif = AppNotification(
                              id: IdGenerator.generateNotificationId(),
                              title: 'Запрос отклонен',
                              body: 'Перемещение ${tool!.title} в ${req.toLocationName} отклонено',
                              type: 'move_rejected',
                              relatedId: req.id,
                              userId: req.requestedBy,
                            );
                            await notifProvider.addNotification(notif);
                            ErrorHandler.showWarningDialog(context, 'Запрос отклонен');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ========== ADMIN BATCH MOVE REQUESTS SCREEN ==========
class AdminBatchMoveRequestsScreen extends StatelessWidget {
  const AdminBatchMoveRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final batchProvider = Provider.of<BatchMoveRequestProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final pending = batchProvider.pendingRequests;

    return Scaffold(
      appBar: AppBar(title: Text('Групповые запросы (${pending.length})')),
      body: pending.isEmpty
          ? const Center(child: Text('Нет ожидающих групповых запросов'))
          : ListView.builder(
              itemCount: pending.length,
              itemBuilder: (context, index) {
                final req = pending[index];
                final tools =
                    toolsProvider.tools.where((t) => req.toolIds.contains(t.id)).toList();
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    title:
                        Text('${req.toolIds.length} инструментов → ${req.toLocationName}'),
                    subtitle: Text('от ${req.requestedBy}'),
                    children: [
                      ...tools.map((t) => ListTile(
                            leading: const Icon(Icons.build, size: 20),
                            title: Text(t.title),
                            subtitle: Text('Текущее: ${t.currentLocationName}'),
                          )),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Отклонить'),
                            onPressed: () async {
                              await batchProvider.updateRequestStatus(req.id, 'rejected');
                              final notif = AppNotification(
                                id: IdGenerator.generateNotificationId(),
                                title: 'Групповой запрос отклонён',
                                body:
                                    'Перемещение ${tools.length} инструментов в ${req.toLocationName} отклонено',
                                type: 'batch_move_rejected',
                                relatedId: req.id,
                                userId: req.requestedBy,
                              );
                              await notifProvider.addNotification(notif);
                              ErrorHandler.showWarningDialog(context, 'Запрос отклонён');
                            },
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('Одобрить'),
                            onPressed: () async {
                              for (final tool in tools) {
                                await toolsProvider.moveTool(
                                    tool.id, req.toLocationId, req.toLocationName);
                              }
                              await batchProvider.updateRequestStatus(req.id, 'approved');
                              final notif = AppNotification(
                                id: IdGenerator.generateNotificationId(),
                                title: 'Групповой запрос одобрен',
                                body:
                                    '${tools.length} инструментов перемещены в ${req.toLocationName}',
                                type: 'batch_move_approved',
                                relatedId: req.id,
                                userId: req.requestedBy,
                              );
                              await notifProvider.addNotification(notif);
                              ErrorHandler.showSuccessDialog(
                                  context, 'Запрос одобрен, инструменты перемещены');
                            },
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ========== ADMIN USERS SCREEN ==========
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Пользователи')),
        body: const Center(child: Text('Только администратор может просматривать пользователей')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление пользователями'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => usersProvider.loadUsers(),
          ),
        ],
      ),
      body: usersProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : usersProvider.users.isEmpty
              ? const Center(child: Text('Нет пользователей'))
              : ListView.builder(
                  itemCount: usersProvider.users.length,
                  itemBuilder: (context, index) {
                    final user = usersProvider.users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              user.role == 'admin' ? Colors.red : Colors.blue,
                          child: Text(user.email[0].toUpperCase()),
                        ),
                        title: Text(user.email),
                        subtitle: Text('Роль: ${user.role}'),
                        children: [
                          SwitchListTile(
                            title: const Text('Может перемещать инструменты'),
                            value: user.canMoveTools,
                            onChanged: (value) {
                              usersProvider.updateUserPermissions(user.uid,
                                  canMoveTools: value);
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Может управлять объектами'),
                            value: user.canControlObjects,
                            onChanged: (value) {
                              usersProvider.updateUserPermissions(user.uid,
                                  canControlObjects: value);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ========== USER NOTIFICATIONS SCREEN ==========
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          if (notifProvider.hasUnread)
            TextButton(
                onPressed: () => notifProvider.markAllRead(),
                child: const Text('Прочитать все'))
        ],
      ),
      body: notifProvider.notifications.isEmpty
          ? const Center(child: Text('Нет уведомлений'))
          : ListView.builder(
              itemCount: notifProvider.notifications.length,
              itemBuilder: (context, index) {
                final notif = notifProvider.notifications[index];
                return ListTile(
                  leading: Icon(notif.read ? Icons.notifications_none : Icons.notifications_active,
                      color: notif.read ? Colors.grey : Colors.blue),
                  title: Text(notif.title,
                      style: TextStyle(
                          fontWeight: notif.read ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text(notif.body),
                  trailing: Text(DateFormat('dd.MM HH:mm').format(notif.timestamp)),
                  onTap: () => notifProvider.markAsRead(notif.id),
                );
              },
            ),
    );
  }
}

// ========== WORKERS LIST SCREEN ==========
class WorkersListScreen extends StatefulWidget {
  const WorkersListScreen({super.key});

  @override
  State<WorkersListScreen> createState() => _WorkersListScreenState();
}

class _WorkersListScreenState extends State<WorkersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerProvider>(context, listen: false).loadWorkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final workerProvider = Provider.of<WorkerProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Работники')),
        body: const Center(child: Text('Только администратор может просматривать работников')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление работниками'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => const AddEditWorkerScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => workerProvider.loadWorkers(),
          ),
        ],
      ),
      body: workerProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : workerProvider.workers.isEmpty
              ? const Center(child: Text('Нет работников'))
              : ListView.builder(
                  itemCount: workerProvider.workers.length,
                  itemBuilder: (context, index) {
                    final worker = workerProvider.workers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(worker.name[0].toUpperCase())),
                        title: Text(worker.name),
                        subtitle: Text(
                            '${worker.role} · ${worker.assignedObjectId != null ? 'На объекте' : 'В гараже'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.payments, color: Colors.green),
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          WorkerSalaryScreen(worker: worker))),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          AddEditWorkerScreen(worker: worker))),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ========== ADD/EDIT WORKER SCREEN ==========
class AddEditWorkerScreen extends StatefulWidget {
  final Worker? worker;
  const AddEditWorkerScreen({super.key, this.worker});

  @override
  State<AddEditWorkerScreen> createState() => _AddEditWorkerScreenState();
}

class _AddEditWorkerScreenState extends State<AddEditWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _dailyRateController = TextEditingController();
  String _role = 'worker';
  String? _selectedObjectId;

  @override
  void initState() {
    super.initState();
    if (widget.worker != null) {
      _nameController.text = widget.worker!.name;
      _emailController.text = widget.worker!.email;
      _nicknameController.text = widget.worker!.nickname ?? '';
      _phoneController.text = widget.worker!.phone ?? '';
      _hourlyRateController.text = widget.worker!.hourlyRate.toString();
      _dailyRateController.text = widget.worker!.dailyRate.toString();
      _role = widget.worker!.role;
      _selectedObjectId = widget.worker!.assignedObjectId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.worker == null ? 'Добавить работника' : 'Редактировать работника')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Имя *', prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Введите имя' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email *', prefixIcon: Icon(Icons.email)),
                validator: (v) => v!.isEmpty ? 'Введите email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                    labelText: 'Псевдоним', prefixIcon: Icon(Icons.alternate_email)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                    labelText: 'Телефон', prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                    labelText: 'Роль', prefixIcon: Icon(Icons.work)),
                items: const [
                  DropdownMenuItem(value: 'worker', child: Text('Рабочий')),
                  DropdownMenuItem(value: 'brigadir', child: Text('Бригадир')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedObjectId,
                decoration: const InputDecoration(
                    labelText: 'Привязка к объекту', prefixIcon: Icon(Icons.location_city)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Не привязан (Гараж)')),
                  ...objectsProvider.objects.map((obj) =>
                      DropdownMenuItem(value: obj.id, child: Text(obj.name))),
                ],
                onChanged: (v) => setState(() => _selectedObjectId = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hourlyRateController,
                decoration: const InputDecoration(
                    labelText: 'Почасовая ставка', prefixIcon: Icon(Icons.timer)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dailyRateController,
                decoration: const InputDecoration(
                    labelText: 'Дневная ставка', prefixIcon: Icon(Icons.calendar_today)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveWorker,
                child: Text(widget.worker == null ? 'Добавить' : 'Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveWorker() async {
    if (!_formKey.currentState!.validate()) return;

    final worker = Worker(
      id: widget.worker?.id ?? IdGenerator.generateWorkerId(),
      email: _emailController.text.trim(),
      name: _nameController.text.trim(),
      nickname: _nicknameController.text.isNotEmpty ? _nicknameController.text.trim() : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text.trim() : null,
      assignedObjectId: _selectedObjectId,
      role: _role,
      hourlyRate: double.tryParse(_hourlyRateController.text) ?? 0,
      dailyRate: double.tryParse(_dailyRateController.text) ?? 0,
    );

    final provider = Provider.of<WorkerProvider>(context, listen: false);
    if (widget.worker == null) {
      await provider.addWorker(worker);
    } else {
      await provider.updateWorker(worker);
    }
    Navigator.pop(context);
  }
}

// ========== WORKER SALARY SCREEN ==========
class WorkerSalaryScreen extends StatefulWidget {
  final Worker worker;
  const WorkerSalaryScreen({super.key, required this.worker});

  @override
  State<WorkerSalaryScreen> createState() => _WorkerSalaryScreenState();
}

class _WorkerSalaryScreenState extends State<WorkerSalaryScreen> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _entryType = 'salary'; // salary, advance, penalty
  double _hoursWorked = 0;

  @override
  void initState() {
    super.initState();
    Provider.of<SalaryProvider>(context, listen: false).loadData();
  }

  @override
  Widget build(BuildContext context) {
    final salaryProvider = Provider.of<SalaryProvider>(context);
    final salaries = salaryProvider.getSalariesForWorker(widget.worker.id);
    final advances = salaryProvider.getAdvancesForWorker(widget.worker.id);
    final penalties = salaryProvider.getPenaltiesForWorker(widget.worker.id);

    double totalSalaries = salaries.fold(0, (total, e) => total + e.amount);
    double totalAdvances = advances.fold(0, (total, e) => total + (e.repaid ? 0 : e.amount));
    double totalPenalties = penalties.fold(0, (total, e) => total + e.amount);
    double balance = totalSalaries - totalAdvances - totalPenalties;

    return Scaffold(
      appBar: AppBar(
        title: Text('Зарплата: ${widget.worker.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEntryDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Начислено:', style: TextStyle(fontSize: 16)),
                      Text('${totalSalaries.toStringAsFixed(2)} ₽',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Авансы:', style: TextStyle(fontSize: 16)),
                      Text('${totalAdvances.toStringAsFixed(2)} ₽',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Штрафы:', style: TextStyle(fontSize: 16)),
                      Text('${totalPenalties.toStringAsFixed(2)} ₽',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Баланс:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        '${balance.toStringAsFixed(2)} ₽',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Зарплата'),
                      Tab(text: 'Авансы'),
                      Tab(text: 'Штрафы'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildSalaryList(salaries),
                        _buildAdvancesList(advances),
                        _buildPenaltiesList(penalties),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryList(List<SalaryEntry> salaries) {
    return salaries.isEmpty
        ? const Center(child: Text('Нет записей'))
        : ListView.builder(
            itemCount: salaries.length,
            itemBuilder: (context, index) {
              final s = salaries[index];
              return ListTile(
                title: Text('${DateFormat('dd.MM.yyyy').format(s.date)} — ${s.amount} ₽'),
                subtitle: Text(
                    'Часов: ${s.hoursWorked}${s.notes != null ? ' · ${s.notes}' : ''}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      Provider.of<SalaryProvider>(context, listen: false).deleteSalary(s.id),
                ),
              );
            },
          );
  }

  Widget _buildAdvancesList(List<Advance> advances) {
    return advances.isEmpty
        ? const Center(child: Text('Нет авансов'))
        : ListView.builder(
            itemCount: advances.length,
            itemBuilder: (context, index) {
              final a = advances[index];
              return ListTile(
                title: Text('${DateFormat('dd.MM.yyyy').format(a.date)} — ${a.amount} ₽'),
                subtitle: Text('${a.reason ?? 'Без причины'}${a.repaid ? ' (Погашен)' : ''}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      Provider.of<SalaryProvider>(context, listen: false).deleteAdvance(a.id),
                ),
              );
            },
          );
  }

  Widget _buildPenaltiesList(List<Penalty> penalties) {
    return penalties.isEmpty
        ? const Center(child: Text('Нет штрафов'))
        : ListView.builder(
            itemCount: penalties.length,
            itemBuilder: (context, index) {
              final p = penalties[index];
              return ListTile(
                title: Text('${DateFormat('dd.MM.yyyy').format(p.date)} — ${p.amount} ₽'),
                subtitle: Text(p.reason ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      Provider.of<SalaryProvider>(context, listen: false).deletePenalty(p.id),
                ),
              );
            },
          );
  }

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить запись'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _entryType,
                  items: const [
                    DropdownMenuItem(value: 'salary', child: Text('Зарплата')),
                    DropdownMenuItem(value: 'advance', child: Text('Аванс')),
                    DropdownMenuItem(value: 'penalty', child: Text('Штраф')),
                  ],
                  onChanged: (v) => setState(() => _entryType = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Сумма'),
                  keyboardType: TextInputType.number,
                ),
                if (_entryType == 'salary') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Количество часов'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _hoursWorked = double.tryParse(v) ?? 0,
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                      labelText: _entryType == 'salary' ? 'Примечание' : 'Причина'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text('Дата: ${DateFormat('dd.MM.yyyy').format(_selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                final amount = double.tryParse(_amountController.text) ?? 0;
                if (amount <= 0) return;

                final salaryProvider =
                    Provider.of<SalaryProvider>(context, listen: false);

                if (_entryType == 'salary') {
                  await salaryProvider.addSalary(SalaryEntry(
                    id: IdGenerator.generateSalaryId(),
                    workerId: widget.worker.id,
                    date: _selectedDate,
                    hoursWorked: _hoursWorked,
                    amount: amount,
                    notes: _reasonController.text,
                  ));
                } else if (_entryType == 'advance') {
                  await salaryProvider.addAdvance(Advance(
                    id: IdGenerator.generateAdvanceId(),
                    workerId: widget.worker.id,
                    date: _selectedDate,
                    amount: amount,
                    reason: _reasonController.text,
                  ));
                } else if (_entryType == 'penalty') {
                  await salaryProvider.addPenalty(Penalty(
                    id: IdGenerator.generatePenaltyId(),
                    workerId: widget.worker.id,
                    date: _selectedDate,
                    amount: amount,
                    reason: _reasonController.text,
                  ));
                }

                _amountController.clear();
                _reasonController.clear();
                _hoursWorked = 0;
                Navigator.pop(context);
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== PROFILE SCREEN (updated with admin panel link and bell icon) ==========
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  bool _syncEnabled = true;
  bool _notificationsEnabled = true;
  String _themeMode = 'light';

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
      _themeMode = prefs.getString('theme_mode') ?? 'light';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) prefs.setBool(key, value);
    else if (value is String) prefs.setString(key, value);
  }

  Future<void> _changeTheme(String mode) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.themeMode = mode;
    await _saveSetting('theme_mode', mode);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen())),
              ),
              if (notifProvider.hasUnread)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                              ? Icon(Icons.person, size: 60,
                                  color: Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: Icon(Icons.camera_alt, size: 15,
                                  color: Theme.of(context).colorScheme.primary),
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
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text('Менеджер инструментов', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildStatCard('Всего инструментов', '${toolsProvider.totalTools}',
                      Icons.build, Colors.blue),
                  _buildStatCard('В гараже', '${toolsProvider.garageTools.length}',
                      Icons.garage, Colors.green),
                  _buildStatCard('Объектов', '${objectsProvider.totalObjects}',
                      Icons.location_city, Colors.orange),
                  _buildStatCard('Избранных', '${toolsProvider.favoriteTools.length}',
                      Icons.favorite, Colors.red),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Настройки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('Синхронизация данных'),
                      trailing: Switch(
                        value: _syncEnabled,
                        onChanged: (v) {
                          setState(() => _syncEnabled = v);
                          _saveSetting('sync_enabled', v);
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Уведомления'),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (v) {
                          setState(() => _notificationsEnabled = v);
                          _saveSetting('notifications_enabled', v);
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.color_lens),
                      title: const Text('Тема приложения'),
                      trailing: DropdownButton<String>(
                        value: _themeMode,
                        onChanged: (v) {
                          if (v != null) _changeTheme(v);
                        },
                        items: const [
                          DropdownMenuItem(value: 'light', child: Text('Светлая')),
                          DropdownMenuItem(value: 'dark', child: Text('Темная')),
                          DropdownMenuItem(value: 'system', child: Text('Системная')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (authProvider.isAdmin) ...[
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminMoveRequestsScreen())),
                      icon: const Icon(Icons.pending_actions),
                      label: const Text('Запросы на перемещение'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminBatchMoveRequestsScreen())),
                      icon: const Icon(Icons.group_work),
                      label: const Text('Групповые запросы'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminUsersScreen())),
                      icon: const Icon(Icons.people),
                      label: const Text('Управление пользователями'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WorkersListScreen())),
                      icon: const Icon(Icons.engineering),
                      label: const Text('Управление работниками'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                    icon: const Icon(Icons.notifications),
                    label: Text('Уведомления ${notifProvider.hasUnread ? '(Новые)' : ''}'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      ReportService.showReportTypeDialog(
                          context,
                          Tool(
                              id: 'inventory',
                              title: 'Инвентаризация',
                              description: '',
                              brand: '',
                              uniqueId: '',
                              currentLocation: '',
                              currentLocationName: '',
                              userId: authProvider.user?.uid ?? 'local'),
                          (type) async {
                        await ReportService.shareInventoryReport(
                            toolsProvider.tools, objectsProvider.objects, context, type);
                      });
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Поделиться отчетом'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async => await _createBackup(
                        context, toolsProvider, objectsProvider),
                    icon: const Icon(Icons.backup),
                    label: const Text('Создать резервную копию'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await authProvider.signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Выйти'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) => Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Future<void> _pickProfileImage(AuthProvider auth) async {
    final file = await ImageService.pickImage();
    if (file != null) {
      await auth.setProfileImage(file);
      ErrorHandler.showSuccessDialog(context, 'Фото профиля обновлено');
    }
  }

  Future<void> _createBackup(BuildContext context, ToolsProvider tp, ObjectsProvider op) async {
    try {
      final backupData = {
        'tools': tp.tools.map((t) => t.toJson()).toList(),
        'objects': op.objects.map((o) => o.toJson()).toList(),
        'createdAt': DateTime.now().toIso8601String(),
        'version': '1.0'
      };
      final jsonStr = jsonEncode(backupData);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tooler_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(file.path)],
          text:
              '📱 Резервная копия Tooler\n\n📅 Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}\n🛠️ Инструментов: ${tp.tools.length}\n🏢 Объектов: ${op.objects.length}\n\n— Создано в Tooler App —');
      ErrorHandler.showSuccessDialog(context, 'Резервная копия создана');
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
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
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    setState(() => _searchResults = toolsProvider.tools
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.brand.toLowerCase().contains(q) ||
            t.uniqueId.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.currentLocationName.toLowerCase().contains(q))
        .toList());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
                hintText: 'Поиск инструментов...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70)),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchResults = []);
                })
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
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                EnhancedToolDetailsScreen(tool: tool))),
                  );
                },
              ),
      );

  Widget _buildEmptySearchScreen() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              _searchController.text.isEmpty ? 'Начните вводить для поиска' : 'Ничего не найдено',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
}

// ========== WELCOME SCREEN ==========
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;
  const WelcomeScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  const Text('Добро пожаловать в Tooler!',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  const Text(
                      'Простая и эффективная система управления строительными инструментами',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Начать работу', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
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
      'description': 'Легко добавляйте, редактируйте и отслеживайте все ваши строительные инструменты',
      'icon': Icons.build,
      'color': Colors.blue
    },
    {
      'title': 'Работа с объектами',
      'description': 'Создавайте объекты и перемещаете инструменты между гаражом и объектами',
      'icon': Icons.location_city,
      'color': Colors.orange
    },
    {
      'title': 'Отчеты и PDF',
      'description': 'Создавайте подробные отчеты и делитесь ими с коллегами',
      'icon': Icons.picture_as_pdf,
      'color': Colors.green
    },
    {
      'title': 'Работа офлайн',
      'description': 'Продолжайте работу даже без интернета, данные синхронизируются автоматически',
      'icon': Icons.wifi_off,
      'color': Colors.purple
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    widget.onComplete();
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => const AuthScreen()));
                  },
                  child: Text('Пропустить',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: p['color'].withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(p['icon'], size: 70, color: p['color']),
                          ),
                          const SizedBox(height: 40),
                          Text(p['title'],
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          Text(p['description'],
                              style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  children: [
                    ...List.generate(_pages.length, (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == i
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300],
                          ),
                        )),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        } else {
                          widget.onComplete();
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (context) => const AuthScreen()));
                        }
                      },
                      child: Text(_currentPage == _pages.length - 1 ? 'Начать' : 'Далее'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ========== AUTH SCREEN (added admin phrase and forgot password) ==========
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
  final _adminPhraseController = TextEditingController();
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
    setState(() {
      _emailController.text = prefs.getString('saved_email') ?? '';
    });
  }

  Future<void> _pickProfileImage() async {
    final file = await ImageService.pickImage();
    if (file != null) setState(() => _profileImage = file);
  }

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс пароля'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
              labelText: 'Email', hintText: 'Введите ваш email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: emailController.text.trim());
                ErrorHandler.showSuccessDialog(context, 'Письмо для сброса пароля отправлено');
                Navigator.pop(context);
              } catch (e) {
                ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!_isLogin && _passwordController.text != _confirmPasswordController.text) {
        throw Exception('Пароли не совпадают');
      }
      final success = _isLogin
          ? await auth.signInWithEmail(
              _emailController.text.trim(), _passwordController.text.trim())
          : await auth.signUpWithEmail(
              _emailController.text.trim(), _passwordController.text.trim(),
              profileImage: _profileImage,
              adminPhrase: _adminPhraseController.text.trim().isNotEmpty
                  ? _adminPhraseController.text.trim()
                  : null);
      if (!success) return;
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    if (!_isLogin && _profileImage != null)
                      Stack(
                        children: [
                          CircleAvatar(radius: 60, backgroundImage: FileImage(_profileImage!)),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: IconButton(
                                icon: Icon(Icons.camera_alt, size: 15, color: Colors.white),
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
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 30,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(height: 8),
                              Text('Фото',
                                  style: TextStyle(
                                      fontSize: 12, color: Theme.of(context).colorScheme.primary)),
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
                        child: const Icon(Icons.build, size: 60, color: Colors.white),
                      ),
                    const SizedBox(height: 10),
                    Text('Tooler',
                        style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 5),
                    const Text('Управление строительными инструментами',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Введите email' : v!.contains('@') ? null : 'Введите корректный email',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      obscureText: _obscurePassword,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Введите пароль' : v!.length >= 6 ? null : 'Минимум 6 символов',
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Подтвердите пароль',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(
                                () => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (v) => v != _passwordController.text ? 'Пароли не совпадают' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _adminPhraseController,
                        decoration: InputDecoration(
                          labelText: 'Код администратора (если есть)',
                          prefixIcon: const Icon(Icons.admin_panel_settings),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ],
                    if (_isLogin) ...[
                      Row(
                        children: [
                          Checkbox(
                            value: authProvider.rememberMe,
                            onChanged: (v) => authProvider.setRememberMe(v!),
                          ),
                          const Text('Запомнить меня'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text('Забыли пароль?'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_isLogin ? 'Войти' : 'Зарегистрироваться',
                      style: const TextStyle(fontSize: 16)),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _profileImage = null;
                    _adminPhraseController.clear();
                  });
                },
                child: Text(_isLogin ? 'Нет аккаунта? Зарегистрироваться' : 'Уже есть аккаунт? Войти'),
              ),
              const SizedBox(height: 20),
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
  final List<String> _titles = ['Гараж', 'Инструменты', 'Объекты', 'Избранное', 'Профиль'];

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: _selectedIndex == 0 || _selectedIndex == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const SearchScreen())),
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
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.garage), label: 'Гараж'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Инструменты'),
          BottomNavigationBarItem(icon: Icon(Icons.location_city), label: 'Объекты'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Избранное'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }

  Future<void> _generateInventoryReport(BuildContext context) async {
    final tp = Provider.of<ToolsProvider>(context, listen: false);
    final op = Provider.of<ObjectsProvider>(context, listen: false);
    ReportService.showReportTypeDialog(
        context,
        Tool(
            id: 'inventory',
            title: 'Инвентаризация',
            description: '',
            brand: '',
            uniqueId: '',
            currentLocation: '',
            currentLocationName: '',
            userId: FirebaseAuth.instance.currentUser?.uid ?? 'local'),
        (type) async {
      await ReportService.shareInventoryReport(tp.tools, op.objects, context, type);
    });
  }
}

// ========== TOOLS LIST SCREEN ==========
class ToolsListScreen extends StatefulWidget {
  const ToolsListScreen({super.key});
  @override
  _ToolsListScreenState createState() => _ToolsListScreenState();
}
class _ToolsListScreenState extends State<ToolsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ToolsProvider>(context, listen: false).loadTools();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ToolsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Все инструменты (${tp.totalTools})'),
        actions: [
          IconButton(
              icon: const Icon(Icons.filter_list), onPressed: () => _showFilterDialog(context)),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => tp.loadTools(forceRefresh: true)),
        ],
      ),
      body: tp.isLoading && tp.tools.isEmpty
          ? _buildLoadingScreen()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск инструментов...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: tp.setSearchQuery,
                  ),
                ),
                if (tp.filterLocation != 'all' ||
                    tp.filterBrand != 'all' ||
                    tp.filterFavorites)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt,
                            size: 16, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getActiveFiltersText(tp),
                            style: TextStyle(
                                fontSize: 12, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        TextButton(
                          onPressed: tp.clearAllFilters,
                          child: const Text('Очистить', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: tp.tools.isEmpty
                      ? _buildEmptyToolsScreen(auth.isAdmin)
                      : ListView.builder(
                          itemCount: tp.tools.length,
                          itemBuilder: (context, i) {
                            final tool = tp.tools[i];
                            return SelectionToolCard(
                              tool: tool,
                              selectionMode: tp.selectionMode,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EnhancedToolDetailsScreen(tool: tool))),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: tp.selectionMode
          ? FloatingActionButton.extended(
              onPressed: tp.hasSelectedTools ? () => _showSelectionActions(context) : null,
              icon: const Icon(Icons.more_vert),
              label: Text('${tp.selectedTools.length}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : (auth.isAdmin
              ? FloatingActionButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const AddEditToolScreen())),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.add),
                )
              : null),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLoadingScreen() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 20),
            Text('Загрузка инструментов...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );

  Widget _buildEmptyToolsScreen(bool isAdmin) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text('Нет инструментов',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 10),
            if (isAdmin)
              ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const AddEditToolScreen())),
                child: const Text('Добавить инструмент'),
              ),
          ],
        ),
      );

  String _getActiveFiltersText(ToolsProvider p) {
    List<String> f = [];
    if (p.filterLocation != 'all') {
      f.add(p.filterLocation == 'garage' ? 'В гараже' : 'На объекте');
    }
    if (p.filterBrand != 'all') {
      f.add('Бренд: ${p.filterBrand}');
    }
    if (p.filterFavorites) {
      f.add('Избранные');
    }
    return f.join(', ');
  }

  void _showFilterDialog(BuildContext context) {
    final tp = Provider.of<ToolsProvider>(context, listen: false);
    final op = Provider.of<ObjectsProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  Text('Фильтры инструментов',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 20),
                  ExpansionTile(
                    title: const Text('Местоположение'),
                    children: [
                      RadioListTile<String>(
                        title: const Text('Все'),
                        value: 'all',
                        groupValue: tp.filterLocation,
                        onChanged: (v) {
                          setState(() {});
                          tp.setFilterLocation(v!);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Гараж'),
                        value: 'garage',
                        groupValue: tp.filterLocation,
                        onChanged: (v) {
                          setState(() {});
                          tp.setFilterLocation(v!);
                        },
                      ),
                      ...op.objects.map((obj) => RadioListTile<String>(
                            title: Text(obj.name),
                            value: obj.id,
                            groupValue: tp.filterLocation,
                            onChanged: (v) {
                              setState(() {});
                              tp.setFilterLocation(v!);
                            },
                          )),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('Бренд'),
                    children: tp.uniqueBrands
                        .map((b) => RadioListTile<String>(
                              title: Text(b == 'all' ? 'Все' : b),
                              value: b,
                              groupValue: tp.filterBrand,
                              onChanged: (v) {
                                setState(() {});
                                tp.setFilterBrand(v!);
                              },
                            ))
                        .toList(),
                  ),
                  SwitchListTile(
                    title: const Text('Только избранные'),
                    value: tp.filterFavorites,
                    onChanged: tp.setFilterFavorites,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: tp.clearAllFilters,
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
    final tp = Provider.of<ToolsProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final selectedCount = tp.selectedTools.length;
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
              Text('Выбрано: $selectedCount инструментов',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('Добавить в избранное'),
                onTap: () {
                  Navigator.pop(context);
                  tp.toggleFavoriteForSelected();
                },
              ),
              if (auth.canMoveTools) ...[
                ListTile(
                  leading: const Icon(Icons.move_to_inbox, color: Colors.blue),
                  title: const Text('Переместить выбранные'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                MoveToolsScreen(selectedTools: tp.selectedTools)));
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.move_to_inbox, color: Colors.orange),
                  title: const Text('Запросить перемещение'),
                  onTap: () {
                    Navigator.pop(context);
                    _showBatchMoveRequestDialog(context, tp.selectedTools);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Поделиться отчетами'),
                onTap: () async {
                  Navigator.pop(context);
                  for (final tool in tp.selectedTools) {
                    await ReportService.shareToolReport(tool, context, ReportType.text);
                  }
                },
              ),
              if (auth.isAdmin)
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
    final tp = Provider.of<ToolsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Удалить выбранные ${tp.selectedTools.length} инструментов?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await tp.deleteSelectedTools();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBatchMoveRequestDialog(BuildContext context, List<Tool> selectedTools) {
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    String? selectedId;
    String? selectedName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
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
              Text('Запрос перемещения (${selectedTools.length} инструментов)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...selectedTools.take(5).map((t) =>
                  Text('• ${t.title} (${t.currentLocationName})')).toList(),
              if (selectedTools.length > 5) Text('... и еще ${selectedTools.length - 5}'),
              const Divider(height: 30),
              ListTile(
                leading: const Icon(Icons.garage, color: Colors.blue),
                title: const Text('Гараж'),
                trailing: selectedId == 'garage' ? const Icon(Icons.check) : null,
                onTap: () => setState(() {
                  selectedId = 'garage';
                  selectedName = 'Гараж';
                }),
              ),
              ...objectsProvider.objects.map((obj) => ListTile(
                    leading: const Icon(Icons.location_city, color: Colors.orange),
                    title: Text(obj.name),
                    trailing: selectedId == obj.id ? const Icon(Icons.check) : null,
                    onTap: () => setState(() {
                      selectedId = obj.id;
                      selectedName = obj.name;
                    }),
                  )),
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
                      onPressed: selectedId == null
                          ? null
                          : () async {
                              await toolsProvider.requestMoveSelectedTools(
                                  selectedTools, selectedId!, selectedName!);
                              Navigator.pop(context);
                            },
                      child: const Text('Отправить запрос'),
                    ),
                  ),
                ],
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
          );
        }
        final prefs = snapshot.data!;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
            ChangeNotifierProvider(create: (_) => ToolsProvider()),
            ChangeNotifierProvider(create: (_) => ObjectsProvider()),
            ChangeNotifierProvider(create: (_) => MoveRequestProvider()),
            ChangeNotifierProvider(create: (_) => BatchMoveRequestProvider()),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider(create: (_) => UsersProvider()),
            ChangeNotifierProvider(create: (_) => WorkerProvider()),
            ChangeNotifierProvider(create: (_) => SalaryProvider()),
            ChangeNotifierProvider(
                create: (_) => ThemeProvider()..themeMode = prefs.getString('theme_mode') ?? 'light'),
            Provider.value(value: prefs),
          ],
          child: Consumer2<AuthProvider, ThemeProvider>(
            builder: (context, authProvider, themeProvider, _) {
              return MaterialApp(
                title: 'Tooler',
                theme: _buildLightTheme(),
                darkTheme: _buildDarkTheme(),
                themeMode: themeProvider.themeMode == 'dark'
                    ? ThemeMode.dark
                    : themeProvider.themeMode == 'system'
                        ? ThemeMode.system
                        : ThemeMode.light,
                navigatorKey: navigatorKey,
                home: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Scaffold(body: Center(child: CircularProgressIndicator()));
                    }
                    final user = snapshot.data;
                    if (user == null) {
                      final seenWelcome = prefs.getBool('seen_welcome') ?? false;
                      if (!seenWelcome) {
                        return WelcomeScreen(
                            onContinue: () async {
                              await prefs.setBool('seen_welcome', true);
                            });
                      }
                      final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
                      if (!seenOnboarding) {
                        return OnboardingScreen(
                            onComplete: () async {
                              await prefs.setBool('seen_onboarding', true);
                            });
                      }
                      return const AuthScreen();
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Provider.of<NotificationProvider>(context, listen: false)
                          .loadNotifications(user.uid);
                      Provider.of<MoveRequestProvider>(context, listen: false).loadRequests();
                      Provider.of<BatchMoveRequestProvider>(context, listen: false)
                          .loadRequests();
                      Provider.of<UsersProvider>(context, listen: false).loadUsers();
                      Provider.of<WorkerProvider>(context, listen: false).loadWorkers();
                      Provider.of<SalaryProvider>(context, listen: false).loadData();
                    });
                    return const MainScreen();
                  },
                ),
                debugShowCheckedModeBanner: false,
              );
            },
          ),
        );
      },
    );
  }

  ThemeData _buildLightTheme() => ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF24292e),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF24292e),
          secondary: Color(0xFF0366d6),
          surface: Color(0xFFffffff),
          background: Color(0xFFf6f8fa),
          error: Color(0xFFd73a49),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF24292e),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF0366d6),
          unselectedItemColor: Color(0xFF586069),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2ea44f),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF2ea44f),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFe1e4e8))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFe1e4e8))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF0366d6), width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Color(0xFFe1e4e8))),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFe1e4e8),
          thickness: 1,
          space: 0,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              color: Color(0xFF24292e), fontWeight: FontWeight.w600, fontSize: 32),
          displayMedium: TextStyle(
              color: Color(0xFF24292e), fontWeight: FontWeight.w600, fontSize: 24),
          displaySmall: TextStyle(
              color: Color(0xFF24292e), fontWeight: FontWeight.w600, fontSize: 20),
          titleLarge: TextStyle(
              color: Color(0xFF24292e), fontWeight: FontWeight.w600, fontSize: 18),
          titleMedium: TextStyle(
              color: Color(0xFF24292e), fontWeight: FontWeight.w500, fontSize: 16),
          titleSmall: TextStyle(
              color: Color(0xFF586069), fontWeight: FontWeight.w500, fontSize: 14),
          bodyLarge: TextStyle(color: Color(0xFF24292e), fontSize: 16, height: 1.5),
          bodyMedium: TextStyle(color: Color(0xFF24292e), fontSize: 14, height: 1.5),
          bodySmall: TextStyle(color: Color(0xFF586069), fontSize: 12, height: 1.5),
          labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFf6f8fa),
          labelStyle: const TextStyle(color: Color(0xFF24292e), fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Color(0xFFe1e4e8))),
        ),
      );

  ThemeData _buildDarkTheme() => ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0d1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF58a6ff),
          secondary: Color(0xFF1f6feb),
          surface: Color(0xFF161b22),
          background: Color(0xFF0d1117),
          error: Color(0xFFf85149),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF161b22),
          iconTheme: IconThemeData(color: Color(0xFFc9d1d9)),
          titleTextStyle: TextStyle(
              color: Color(0xFFc9d1d9), fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF161b22),
          selectedItemColor: Color(0xFF58a6ff),
          unselectedItemColor: Color(0xFF8b949e),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF238636),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF238636),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0d1117),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF30363d))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF30363d))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF58a6ff), width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF161b22),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Color(0xFF30363d))),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF21262d),
          thickness: 1,
          space: 0,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              color: Color(0xFFc9d1d9), fontWeight: FontWeight.w600, fontSize: 32),
          displayMedium: TextStyle(
              color: Color(0xFFc9d1d9), fontWeight: FontWeight.w600, fontSize: 24),
          displaySmall: TextStyle(
              color: Color(0xFFc9d1d9), fontWeight: FontWeight.w600, fontSize: 20),
          titleLarge: TextStyle(
              color: Color(0xFFc9d1d9), fontWeight: FontWeight.w600, fontSize: 18),
          titleMedium: TextStyle(
              color: Color(0xFFc9d1d9), fontWeight: FontWeight.w500, fontSize: 16),
          titleSmall: TextStyle(
              color: Color(0xFF8b949e), fontWeight: FontWeight.w500, fontSize: 14),
          bodyLarge: TextStyle(color: Color(0xFFc9d1d9), fontSize: 16, height: 1.5),
          bodyMedium: TextStyle(color: Color(0xFFc9d1d9), fontSize: 14, height: 1.5),
          bodySmall: TextStyle(color: Color(0xFF8b949e), fontSize: 12, height: 1.5),
          labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF21262d),
          labelStyle: const TextStyle(color: Color(0xFFc9d1d9), fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Color(0xFF30363d))),
        ),
      );
}