// main.dart - Complete Tooler Construction Tool Management App
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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:tooler/app_localizationd.dart';
import 'package:tooler/firebase_options.dart';

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

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('Firebase initialized successfully');
  } catch (e) {
    print('Initialization error: $e');
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
  };

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

  ConstructionObject({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.localImagePath,
    List<String>? toolIds,
    DateTime? createdAt,
    DateTime? updatedAt,
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
  };

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

  static Future<void> init() async {
    try {
      await Hive.openBox<Tool>(toolsBox);
      await Hive.openBox<ConstructionObject>(objectsBox);
      await Hive.openBox<SyncItem>(syncQueueBox);
      print('Hive boxes opened successfully');
    } catch (e) {
      print('Error opening Hive boxes: $e');
      // Try to delete corrupted boxes and recreate
      await Hive.deleteBoxFromDisk(toolsBox);
      await Hive.deleteBoxFromDisk(objectsBox);
      await Hive.deleteBoxFromDisk(syncQueueBox);

      await Hive.openBox<Tool>(toolsBox);
      await Hive.openBox<ConstructionObject>(objectsBox);
      await Hive.openBox<SyncItem>(syncQueueBox);
    }
  }

  static Box<Tool> get tools => Hive.box<Tool>(toolsBox);
  static Box<ConstructionObject> get objects =>
      Hive.box<ConstructionObject>(objectsBox);
  static Box<SyncItem> get syncQueue => Hive.box<SyncItem>(syncQueueBox);
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

// ========== ERROR HANDLER ==========
class ErrorHandler {
  static void showErrorDialog(BuildContext context, String message) {
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
  }

  static void showSuccessDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ========== STATE MANAGEMENT PROVIDERS ==========
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SharedPreferences _prefs;
  User? _user;
  bool _isLoading = true;
  bool _rememberMe = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get rememberMe => _rememberMe;

  AuthProvider(this._prefs) {
    _rememberMe = _prefs.getBool('remember_me') ?? false;
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) {
        _user = user;
        _isLoading = false;
        notifyListeners();

        if (user != null) {
          print('User logged in: ${user.email}');
        } else {
          print('User logged out');
        }
      });
    } catch (e) {
      print('Auth initialization error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;

      // Save email if remember me is enabled
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
      print('Unexpected error: $e');
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

      // Create user document in Firestore
      if (_user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .set({
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
              'userId': _user!.uid,
            });
      }

      // Save email if remember me is enabled
      if (_rememberMe) {
        await _prefs.setString('saved_email', email);
      }

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('Sign up error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    await _prefs.setBool('remember_me', value);

    if (!value) {
      await _prefs.remove('saved_email');
    }

    notifyListeners();
  }
}

class ToolsProvider with ChangeNotifier {
  List<Tool> _tools = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _sortAscending = false;

  List<Tool> get tools => _getFilteredTools();
  List<Tool> get garageTools =>
      _tools.where((t) => t.currentLocation == 'garage').toList();
  List<Tool> get favoriteTools => _tools.where((t) => t.isFavorite).toList();
  bool get isLoading => _isLoading;

  List<Tool> _getFilteredTools() {
    var filteredTools = _searchQuery.isEmpty
        ? List<Tool>.from(_tools)
        : _tools
              .where(
                (tool) =>
                    tool.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    tool.brand.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    tool.uniqueId.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    tool.description.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

    // Sort tools
    filteredTools.sort((a, b) {
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

    return filteredTools;
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

  Future<void> loadTools() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      await LocalDatabase.init();
      _tools = LocalDatabase.tools.values.toList();
      print('Loaded ${_tools.length} tools from local database');

      // Try to sync with Firebase if online
      await _syncWithFirebase();
    } catch (e) {
      print('Error loading tools: $e');
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось загрузить инструменты: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTool(Tool tool, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Upload image if provided
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          tool.imageUrl = imageUrl;
        } else {
          // Save locally if upload fails
          tool.localImagePath = imageFile.path;
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
    } catch (e) {
      print('Error adding tool: $e');
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

      // Upload new image if provided
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          tool.imageUrl = imageUrl;
          tool.localImagePath = null;
        } else {
          // Save locally if upload fails
          tool.localImagePath = imageFile.path;
          tool.imageUrl = null;
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
      }
    } catch (e) {
      print('Error updating tool: $e');
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
    } catch (e) {
      print('Error deleting tool: $e');
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось удалить инструмент: ${e.toString()}',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> duplicateTool(Tool original) async {
    final newTool = original.duplicate();
    await addTool(newTool);
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

      tool.locationHistory.add(
        LocationHistory(
          date: DateTime.now(),
          locationId: oldLocationId,
          locationName: oldLocationId == 'garage'
              ? 'Гараж'
              : 'Предыдущее местоположение',
        ),
      );
      tool.currentLocation = newLocationId;
      tool.updatedAt = DateTime.now();

      await updateTool(tool);

      ErrorHandler.showSuccessDialog(
        navigatorKey.currentContext!,
        'Инструмент перемещен в $newLocationName',
      );
    } catch (e) {
      print('Error moving tool: $e');
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось переместить инструмент: ${e.toString()}',
      );
    }
  }

  Future<void> toggleFavorite(String toolId) async {
    try {
      final toolIndex = _tools.indexWhere((t) => t.id == toolId);
      if (toolIndex == -1) return;

      final tool = _tools[toolIndex];
      tool.isFavorite = !tool.isFavorite;
      await updateTool(tool);
    } catch (e) {
      print('Error toggling favorite: $e');
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
      print('Syncing ${syncItems.length} items with Firebase');

      for (final item in syncItems) {
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
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }
}

class ObjectsProvider with ChangeNotifier {
  List<ConstructionObject> _objects = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;

  List<ConstructionObject> get objects => _getFilteredObjects();
  bool get isLoading => _isLoading;

  List<ConstructionObject> _getFilteredObjects() {
    var filteredObjects = _searchQuery.isEmpty
        ? List<ConstructionObject>.from(_objects)
        : _objects
              .where(
                (obj) =>
                    obj.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    obj.description.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

    // Sort objects
    filteredObjects.sort((a, b) {
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

    return filteredObjects;
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

  Future<void> loadObjects() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      await LocalDatabase.init();
      _objects = LocalDatabase.objects.values.toList();
      print('Loaded ${_objects.length} objects from local database');
    } catch (e) {
      print('Error loading objects: $e');
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось загрузить объекты: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addObject(ConstructionObject obj, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Upload image if provided
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          obj.imageUrl = imageUrl;
        } else {
          // Save locally if upload fails
          obj.localImagePath = imageFile.path;
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
    } catch (e) {
      print('Error adding object: $e');
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

      // Upload new image if provided
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          obj.imageUrl = imageUrl;
          obj.localImagePath = null;
        } else {
          // Save locally if upload fails
          obj.localImagePath = imageFile.path;
          obj.imageUrl = null;
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
    } catch (e) {
      print('Error updating object: $e');
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
    } catch (e) {
      print('Error deleting object: $e');
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось удалить объект: ${e.toString()}',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> addToolsToObject(String objectId, List<String> toolIds) async {
    try {
      final objectIndex = _objects.indexWhere((o) => o.id == objectId);
      if (objectIndex != -1) {
        final object = _objects[objectIndex];
        object.toolIds.addAll(toolIds);
        object.toolIds = object.toolIds.toSet().toList();
        await updateObject(object);
      }
    } catch (e) {
      print('Error adding tools to object: $e');
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось добавить инструменты в объект',
      );
    }
  }

  Future<void> removeToolsFromObject(
    String objectId,
    List<String> toolIds,
  ) async {
    try {
      final objectIndex = _objects.indexWhere((o) => o.id == objectId);
      if (objectIndex != -1) {
        final object = _objects[objectIndex];
        object.toolIds.removeWhere((id) => toolIds.contains(id));
        await updateObject(object);
      }
    } catch (e) {
      print('Error removing tools from object: $e');
      ErrorHandler.showErrorDialog(
        navigatorKey.currentContext!,
        'Не удалось удалить инструменты из объекта',
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
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = Locale('ru'); // Default to Russian
  final SharedPreferences _prefs;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  ThemeProvider(this._prefs) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final themeIndex = _prefs.getInt('theme_mode') ?? 0;
      _themeMode = ThemeMode.values[themeIndex];

      final languageCode =
          _prefs.getString('language') ?? 'ru'; // Default to Russian
      _locale = Locale(languageCode);

      notifyListeners();
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }

  void toggleTheme() {
    final newTheme = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    setTheme(newTheme);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _prefs.setString('language', locale.languageCode);
    notifyListeners();
  }

  void toggleLocale() {
    final newLocale = _locale.languageCode == 'en'
        ? Locale('ru')
        : Locale('en');
    setLocale(newLocale);
  }
}

// ========== PDF EXPORT SERVICE (RUSSIAN ONLY) ==========
class PDFExportService {
  static Future<Uint8List> generateInventoryPDF(List<Tool> tools) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Отчет по инвентаризации инструментов',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontBold: pw.Font.courierBold(),
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  ['ID', 'Название', 'Бренд', 'Местоположение', 'Статус'],
                  ...tools.map(
                    (tool) => [
                      tool.uniqueId,
                      tool.title,
                      tool.brand,
                      tool.currentLocation == 'garage' ? 'Гараж' : 'Объект',
                      tool.isFavorite ? 'Избранное' : 'Доступно',
                    ],
                  ),
                ],
                headerStyle: pw.TextStyle(fontBold: pw.Font.courierBold()),
                cellStyle: pw.TextStyle(font: pw.Font.courier()),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Сгенерировано: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}

// ========== SCREENSHOT SERVICE ==========
class ScreenshotService {
  static final ScreenshotController _controller = ScreenshotController();

  static ScreenshotController get controller => _controller;

  static Future<Uint8List?> capture() async {
    try {
      return await _controller.capture();
    } catch (e) {
      print('Screenshot error: $e');
      return null;
    }
  }
}

// ========== GLOBAL NAVIGATOR KEY ==========
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ========== WIDGETS ==========
class ToolCard extends StatelessWidget {
  final Tool tool;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const ToolCard({
    super.key,
    required this.tool,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: tool.displayImage != null
                      ? Image(
                          image: tool.displayImage!.startsWith('http')
                              ? NetworkImage(tool.displayImage!)
                              : FileImage(File(tool.displayImage!))
                                    as ImageProvider,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.build, size: 30, color: Colors.grey),
                        )
                      : Icon(Icons.build, size: 30, color: Colors.grey),
                ),
              ),
              SizedBox(width: 16),
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
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tool.isFavorite)
                          Icon(Icons.star, size: 16, color: Colors.amber),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      tool.brand,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.qr_code, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'ID: ${tool.uniqueId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          tool.currentLocation == 'garage'
                              ? 'Гараж'
                              : 'На объекте',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  tool.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: tool.isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: onFavoriteToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ObjectCard extends StatelessWidget {
  final ConstructionObject object;
  final int toolCount;
  final VoidCallback? onTap;

  const ObjectCard({
    super.key,
    required this.object,
    required this.toolCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: object.displayImage != null
                      ? Image(
                          image: object.displayImage!.startsWith('http')
                              ? NetworkImage(object.displayImage!)
                              : FileImage(File(object.displayImage!))
                                    as ImageProvider,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.location_city,
                            size: 35,
                            color: Colors.grey,
                          ),
                        )
                      : Icon(Icons.location_city, size: 35, color: Colors.grey),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      object.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Text(
                      object.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.build, size: 14, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                '$toolCount инструментов',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== SCREENS ==========
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Tooler',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Управление строительными инструментами',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      {
        'title': 'Добро пожаловать в Tooler',
        'description': 'Эффективно управляйте строительными инструментами',
        'image': Icons.build_circle,
        'color': Colors.blue,
      },
      {
        'title': 'Отслеживайте инструменты',
        'description': 'Перемещайте инструменты между строительными объектами',
        'image': Icons.move_to_inbox,
        'color': Colors.green,
      },
      {
        'title': 'Работайте офлайн',
        'description': 'Синхронизируйте данные при наличии интернета',
        'image': Icons.cloud_off,
        'color': Colors.orange,
      },
      {
        'title': 'Экспорт и обмен',
        'description': 'Создавайте PDF отчеты и делитесь инвентаризацией',
        'image': Icons.share,
        'color': Colors.purple,
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: pages[index]['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            pages[index]['image'] as IconData,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 40),
                        Text(
                          pages[index]['title'] as String,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Text(
                          pages[index]['description'] as String,
                          style: TextStyle(
                            fontSize: 18,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => Container(
                  margin: EdgeInsets.all(4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  if (_currentPage != 0)
                    TextButton(
                      onPressed: () {
                        _controller.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text('Назад'),
                    ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == pages.length - 1) {
                        widget.onComplete();
                      } else {
                        _controller.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _currentPage == pages.length - 1 ? 'Начать' : 'Далее',
                      style: TextStyle(fontSize: 16),
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

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.rememberMe) {
      _rememberMe = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tooler'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.locale.languageCode == 'ru'
                  ? Icons.language
                  : Icons.language_outlined,
            ),
            onPressed: () {
              themeProvider.toggleLocale();
            },
            tooltip: 'Сменить язык',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.build_circle,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 20),
                Text(
                  'Tooler',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Управление строительными инструментами',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 40),

                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Remember Me Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    Text('Запомнить меня'),
                  ],
                ),
                SizedBox(height: 20),

                // Loading or Button
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
                    ),
                  ),
                SizedBox(height: 20),

                // Switch between Login/Signup
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _authenticate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ErrorHandler.showErrorDialog(context, 'Пожалуйста, заполните все поля');
      return;
    }

    if (password.length < 6) {
      ErrorHandler.showErrorDialog(
        context,
        'Пароль должен содержать не менее 6 символов',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Set remember me preference
    await authProvider.setRememberMe(_rememberMe);

    bool success;
    if (_isLogin) {
      success = await authProvider.signInWithEmail(email, password);
    } else {
      success = await authProvider.signUpWithEmail(email, password);
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Load data after successful auth
      final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
      final objectsProvider = Provider.of<ObjectsProvider>(
        context,
        listen: false,
      );

      await toolsProvider.loadTools();
      await objectsProvider.loadObjects();

      // Navigate to main screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      ErrorHandler.showErrorDialog(
        context,
        _isLogin
            ? 'Ошибка входа. Проверьте ваши учетные данные.'
            : 'Ошибка регистрации. Попробуйте еще раз.',
      );
    }
  }
}

// ========== NEW SCREENS ==========

class ToolDetailsScreen extends StatelessWidget {
  final Tool tool;

  const ToolDetailsScreen({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tool.title),
        actions: [
          IconButton(
            icon: Icon(
              tool.isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            color: tool.isFavorite ? Colors.red : null,
            onPressed: () => toolsProvider.toggleFavorite(tool.id),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Редактировать'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditToolScreen(tool: tool),
                    ),
                  );
                },
              ),
              PopupMenuItem(
                child: Text('Дублировать'),
                onTap: () {
                  Navigator.pop(context);
                  toolsProvider.duplicateTool(tool);
                },
              ),
              PopupMenuItem(
                child: Text('Переместить'),
                onTap: () =>
                    _showMoveDialog(context, tool, objectsProvider.objects),
              ),
              PopupMenuItem(
                child: Text('Удалить', style: TextStyle(color: Colors.red)),
                onTap: () => _showDeleteConfirmation(context, tool.id, true),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (tool.displayImage != null)
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: tool.displayImage!.startsWith('http')
                        ? NetworkImage(tool.displayImage!)
                        : FileImage(File(tool.displayImage!)) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            SizedBox(height: 24),

            // Basic Info
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Название', tool.title),
                    _buildInfoRow('Бренд', tool.brand),
                    _buildInfoRow('Уникальный ID', tool.uniqueId),
                    _buildInfoRow(
                      'Местоположение',
                      tool.currentLocation == 'garage' ? 'Гараж' : 'На объекте',
                    ),
                    _buildInfoRow('Избранное', tool.isFavorite ? 'Да' : 'Нет'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Description
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Описание',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      tool.description,
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Location History
            if (tool.locationHistory.isNotEmpty)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'История перемещений',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      ...tool.locationHistory.map((history) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 16, color: Colors.grey),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${DateFormat('dd.MM.yyyy HH:mm').format(history.date)} - ${history.locationName}',
                                  style: TextStyle(fontSize: 12),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(
    BuildContext context,
    Tool tool,
    List<ConstructionObject> objects,
  ) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);

    String? selectedLocationId = tool.currentLocation;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Переместить ${tool.title}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Выберите новое местоположение:'),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedLocationId,
                  items: [
                    DropdownMenuItem(value: 'garage', child: Text('Гараж')),
                    ...objects.map((obj) {
                      return DropdownMenuItem(
                        value: obj.id,
                        child: Text(obj.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    selectedLocationId = value;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Местоположение',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedLocationId != null) {
                  String locationName = 'Гараж';
                  if (selectedLocationId != 'garage') {
                    final object = objects.firstWhere(
                      (o) => o.id == selectedLocationId,
                      orElse: () => ConstructionObject(
                        id: 'garage',
                        name: 'Гараж',
                        description: '',
                      ),
                    );
                    locationName = object.name;
                  }

                  await toolsProvider.moveTool(
                    tool.id,
                    selectedLocationId!,
                    locationName,
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              child: Text('Переместить'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id, bool isTool) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить этот инструмент? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (isTool) {
                final toolsProvider = Provider.of<ToolsProvider>(
                  context,
                  listen: false,
                );
                await toolsProvider.deleteTool(id);
              } else {
                final objectsProvider = Provider.of<ObjectsProvider>(
                  context,
                  listen: false,
                );
                await objectsProvider.deleteObject(id);
              }
              Navigator.pop(context);
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ObjectDetailsScreen extends StatelessWidget {
  final ConstructionObject object;
  final int toolCount;

  const ObjectDetailsScreen({
    super.key,
    required this.object,
    required this.toolCount,
  });

  @override
  Widget build(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectTools = toolsProvider.tools
        .where((t) => t.currentLocation == object.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(object.name),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Редактировать'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditObjectScreen(object: object),
                    ),
                  );
                },
              ),
              PopupMenuItem(
                child: Text('Добавить инструменты'),
                onTap: () =>
                    _showAddToolsDialog(context, object, toolsProvider),
              ),
              PopupMenuItem(
                child: Text('Удалить', style: TextStyle(color: Colors.red)),
                onTap: () => _showDeleteConfirmation(context, object.id, false),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (object.displayImage != null)
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: object.displayImage!.startsWith('http')
                        ? NetworkImage(object.displayImage!)
                        : FileImage(File(object.displayImage!))
                              as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            SizedBox(height: 24),

            // Basic Info
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Название', object.name),
                    _buildInfoRow('Количество инструментов', '$toolCount'),
                    _buildInfoRow(
                      'Создан',
                      DateFormat('dd.MM.yyyy').format(object.createdAt),
                    ),
                    _buildInfoRow(
                      'Обновлен',
                      DateFormat('dd.MM.yyyy').format(object.updatedAt),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Description
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Описание',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      object.description,
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Tools at this location
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Инструменты на объекте',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _showAddToolsDialog(
                            context,
                            object,
                            toolsProvider,
                          ),
                          icon: Icon(Icons.add, size: 18),
                          label: Text('Добавить'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (objectTools.isEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.build,
                              size: 50,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Нет инструментов на объекте',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    else
                      ...objectTools.map((tool) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[100],
                              ),
                              child: tool.displayImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image(
                                        image:
                                            tool.displayImage!.startsWith(
                                              'http',
                                            )
                                            ? NetworkImage(tool.displayImage!)
                                            : FileImage(
                                                    File(tool.displayImage!),
                                                  )
                                                  as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.build,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                            ),
                            title: Text(
                              tool.title,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(tool.brand),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: Text('Посмотреть детали'),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ToolDetailsScreen(tool: tool),
                                      ),
                                    );
                                  },
                                ),
                                PopupMenuItem(
                                  child: Text('Переместить в гараж'),
                                  onTap: () {
                                    final toolsProvider =
                                        Provider.of<ToolsProvider>(
                                          context,
                                          listen: false,
                                        );
                                    toolsProvider.moveTool(
                                      tool.id,
                                      'garage',
                                      'Гараж',
                                    );
                                  },
                                ),
                                PopupMenuItem(
                                  child: Text('Удалить с объекта'),
                                  onTap: () async {
                                    await toolsProvider.moveTool(
                                      tool.id,
                                      'garage',
                                      'Гараж',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showAddToolsDialog(
    BuildContext context,
    ConstructionObject object,
    ToolsProvider toolsProvider,
  ) {
    final availableTools = toolsProvider.tools
        .where((t) => t.currentLocation == 'garage')
        .toList();
    final selectedTools = <String>{};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Добавить инструменты'),
              content: Container(
                width: double.maxFinite,
                height: 400,
                child: availableTools.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.build,
                              size: 50,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Нет доступных инструментов в гараже',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: availableTools.length,
                        itemBuilder: (context, index) {
                          final tool = availableTools[index];
                          return CheckboxListTile(
                            value: selectedTools.contains(tool.id),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedTools.add(tool.id);
                                } else {
                                  selectedTools.remove(tool.id);
                                }
                              });
                            },
                            title: Text(tool.title),
                            subtitle: Text(tool.brand),
                            secondary: tool.displayImage != null
                                ? Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      image: DecorationImage(
                                        image:
                                            tool.displayImage!.startsWith(
                                              'http',
                                            )
                                            ? NetworkImage(tool.displayImage!)
                                            : FileImage(
                                                    File(tool.displayImage!),
                                                  )
                                                  as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : Icon(Icons.build),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedTools.isNotEmpty) {
                      for (var toolId in selectedTools) {
                        await toolsProvider.moveTool(
                          toolId,
                          object.id,
                          object.name,
                        );
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Добавить (${selectedTools.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id, bool isTool) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить этот объект? Это действие нельзя отменить.',
        ),
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
              await objectsProvider.deleteObject(id);
              Navigator.pop(context);
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchTools = true;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Поиск...',
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                      if (_searchTools) {
                        toolsProvider.setSearchQuery('');
                      } else {
                        objectsProvider.setSearchQuery('');
                      }
                    },
                  )
                : Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            if (_searchTools) {
              toolsProvider.setSearchQuery(value);
            } else {
              objectsProvider.setSearchQuery(value);
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('Инструменты (${toolsProvider.tools.length})'),
                    selected: _searchTools,
                    onSelected: (selected) {
                      setState(() {
                        _searchTools = selected;
                        _searchController.clear();
                        toolsProvider.setSearchQuery('');
                        objectsProvider.setSearchQuery('');
                        _searchQuery = '';
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Объекты (${objectsProvider.objects.length})'),
                    selected: !_searchTools,
                    onSelected: (selected) {
                      setState(() {
                        _searchTools = !selected;
                        _searchController.clear();
                        toolsProvider.setSearchQuery('');
                        objectsProvider.setSearchQuery('');
                        _searchQuery = '';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _searchTools
          ? _buildToolsList(toolsProvider)
          : _buildObjectsList(objectsProvider, toolsProvider),
    );
  }

  Widget _buildToolsList(ToolsProvider toolsProvider) {
    if (toolsProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final tools = _searchQuery.isEmpty
        ? toolsProvider.tools
        : toolsProvider.tools;

    if (tools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.build : Icons.search,
              size: 80,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Нет инструментов'
                  : 'Инструменты не найдены',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return ToolCard(
          tool: tool,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ToolDetailsScreen(tool: tool),
              ),
            );
          },
          onFavoriteToggle: () {
            toolsProvider.toggleFavorite(tool.id);
          },
        );
      },
    );
  }

  Widget _buildObjectsList(
    ObjectsProvider objectsProvider,
    ToolsProvider toolsProvider,
  ) {
    if (objectsProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final objects = _searchQuery.isEmpty
        ? objectsProvider.objects
        : objectsProvider.objects;

    if (objects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.location_city : Icons.search,
              size: 80,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'Нет объектов' : 'Объекты не найдены',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: objects.length,
      itemBuilder: (context, index) {
        final object = objects[index];
        final toolCount = toolsProvider.tools
            .where((t) => t.currentLocation == object.id)
            .length;
        return ObjectCard(
          object: object,
          toolCount: toolCount,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ObjectDetailsScreen(object: object, toolCount: toolCount),
              ),
            );
          },
        );
      },
    );
  }
}

// ========== UPDATED EXISTING SCREENS ==========

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Гараж'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              final parts = value.split('_');
              toolsProvider.setSort(parts[0], parts[1] == 'asc');
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'name_asc', child: Text('По имени (А-Я)')),
              PopupMenuItem(value: 'name_desc', child: Text('По имени (Я-А)')),
              PopupMenuItem(value: 'date_asc', child: Text('По дате (старые)')),
              PopupMenuItem(value: 'date_desc', child: Text('По дате (новые)')),
              PopupMenuItem(value: 'brand_asc', child: Text('По бренду (А-Я)')),
              PopupMenuItem(
                value: 'brand_desc',
                child: Text('По бренду (Я-А)'),
              ),
            ],
          ),
        ],
      ),
      body: toolsProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : toolsProvider.garageTools.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.garage, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text(
                    'В гараже нет инструментов',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Добавьте инструменты, чтобы увидеть их здесь',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => toolsProvider.loadTools(),
              child: ListView.builder(
                itemCount: toolsProvider.garageTools.length,
                itemBuilder: (context, index) {
                  final tool = toolsProvider.garageTools[index];
                  return ToolCard(
                    tool: tool,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ToolDetailsScreen(tool: tool),
                        ),
                      );
                    },
                    onFavoriteToggle: () {
                      toolsProvider.toggleFavorite(tool.id);
                    },
                  );
                },
              ),
            ),
    );
  }
}

class ToolsListScreen extends StatelessWidget {
  const ToolsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Все инструменты'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              final parts = value.split('_');
              toolsProvider.setSort(parts[0], parts[1] == 'asc');
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'name_asc', child: Text('По имени (А-Я)')),
              PopupMenuItem(value: 'name_desc', child: Text('По имени (Я-А)')),
              PopupMenuItem(value: 'date_asc', child: Text('По дате (старые)')),
              PopupMenuItem(value: 'date_desc', child: Text('По дате (новые)')),
              PopupMenuItem(value: 'brand_asc', child: Text('По бренду (А-Я)')),
              PopupMenuItem(
                value: 'brand_desc',
                child: Text('По бренду (Я-А)'),
              ),
            ],
          ),
        ],
      ),
      body: toolsProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : toolsProvider.tools.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text(
                    'Нет инструментов',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Добавьте первый инструмент',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => toolsProvider.loadTools(),
              child: ListView.builder(
                itemCount: toolsProvider.tools.length,
                itemBuilder: (context, index) {
                  final tool = toolsProvider.tools[index];
                  return ToolCard(
                    tool: tool,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ToolDetailsScreen(tool: tool),
                        ),
                      );
                    },
                    onFavoriteToggle: () {
                      toolsProvider.toggleFavorite(tool.id);
                    },
                  );
                },
              ),
            ),
    );
  }
}

class ObjectsListScreen extends StatelessWidget {
  const ObjectsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Объекты'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              final parts = value.split('_');
              objectsProvider.setSort(parts[0], parts[1] == 'asc');
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'name_asc', child: Text('По имени (А-Я)')),
              PopupMenuItem(value: 'name_desc', child: Text('По имени (Я-А)')),
              PopupMenuItem(value: 'date_asc', child: Text('По дате (старые)')),
              PopupMenuItem(value: 'date_desc', child: Text('По дате (новые)')),
              PopupMenuItem(
                value: 'toolCount_asc',
                child: Text('По количеству инструментов (меньше)'),
              ),
              PopupMenuItem(
                value: 'toolCount_desc',
                child: Text('По количеству инструментов (больше)'),
              ),
            ],
          ),
        ],
      ),
      body: objectsProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : objectsProvider.objects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_city, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text(
                    'Нет строительных объектов',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Добавьте первый строительный объект',
                    style: TextStyle(color: Colors.grey[500]),
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
                  final toolCount = toolsProvider.tools
                      .where((t) => t.currentLocation == object.id)
                      .length;

                  return ObjectCard(
                    object: object,
                    toolCount: toolCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ObjectDetailsScreen(
                            object: object,
                            toolCount: toolCount,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class MoveToolsScreen extends StatelessWidget {
  const MoveToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Перемещение инструментов')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Выберите инструмент для перемещения в другое местоположение',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Expanded(
              child: toolsProvider.isLoading || objectsProvider.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async {
                        await toolsProvider.loadTools();
                        await objectsProvider.loadObjects();
                      },
                      child: ListView(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Доступные инструменты:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ...toolsProvider.tools.map((tool) {
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: Icon(Icons.build, color: Colors.blue),
                                title: Text(
                                  tool.title,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  'Текущее местоположение: ${tool.currentLocation == 'garage' ? 'Гараж' : 'Объект'}',
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  _showMoveDialog(
                                    context,
                                    tool,
                                    objectsProvider.objects,
                                  );
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveDialog(
    BuildContext context,
    Tool tool,
    List<ConstructionObject> objects,
  ) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);

    String? selectedLocationId = tool.currentLocation;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Переместить ${tool.title}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Выберите новое местоположение:'),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedLocationId,
                  items: [
                    DropdownMenuItem(value: 'garage', child: Text('Гараж')),
                    ...objects.map((obj) {
                      return DropdownMenuItem(
                        value: obj.id,
                        child: Text(obj.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    selectedLocationId = value;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Местоположение',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedLocationId != null) {
                  String locationName = 'Гараж';
                  if (selectedLocationId != 'garage') {
                    final object = objects.firstWhere(
                      (o) => o.id == selectedLocationId,
                      orElse: () => ConstructionObject(
                        id: 'garage',
                        name: 'Гараж',
                        description: '',
                      ),
                    );
                    locationName = object.name;
                  }

                  await toolsProvider.moveTool(
                    tool.id,
                    selectedLocationId!,
                    locationName,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Переместить'),
            ),
          ],
        );
      },
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Избранные инструменты')),
      body: toolsProvider.favoriteTools.isEmpty
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
                    'Отмечайте инструменты как избранные, чтобы видеть их здесь',
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => toolsProvider.loadTools(),
              child: ListView.builder(
                itemCount: toolsProvider.favoriteTools.length,
                itemBuilder: (context, index) {
                  final tool = toolsProvider.favoriteTools[index];
                  return ToolCard(
                    tool: tool,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ToolDetailsScreen(tool: tool),
                        ),
                      );
                    },
                    onFavoriteToggle: () {
                      toolsProvider.toggleFavorite(tool.id);
                    },
                  );
                },
              ),
            ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Профиль')),
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              authProvider.user?.email ?? 'Гость',
              style: TextStyle(fontSize: 18),
            ),
            accountEmail: Text(
              'Менеджер строительных инструментов',
              style: TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          ),
          SwitchListTile(
            title: Text('Темная тема'),
            subtitle: Text('Включить темный режим'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.setTheme(value ? ThemeMode.dark : ThemeMode.light);
            },
            secondary: Icon(Icons.dark_mode),
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Язык'),
            subtitle: Text(
              themeProvider.locale.languageCode == 'en' ? 'English' : 'Русский',
            ),
            onTap: () {
              themeProvider.toggleLocale();
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Экспорт в PDF'),
            subtitle: Text('Создать отчет по инвентаризации'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PDFPreviewScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.screenshot),
            title: Text('Сделать скриншот'),
            subtitle: Text('Скриншот текущего экрана'),
            onTap: () async {
              final image = await ScreenshotService.capture();
              if (image != null) {
                ErrorHandler.showSuccessDialog(context, 'Скриншот сохранен');
              }
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Выйти'),
            onTap: () async {
              await authProvider.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ========== UPDATED AddEditToolScreen ==========
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
  File? _selectedImage;
  bool _isLoading = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    if (widget.tool != null) {
      _titleController.text = widget.tool!.title;
      _descriptionController.text = widget.tool!.description;
      _brandController.text = widget.tool!.brand;
      _uniqueIdController.text = widget.tool!.uniqueId;
      _isFavorite = widget.tool!.isFavorite;
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
    final action = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Выберите источник изображения'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'gallery'),
            child: Text('Галерея'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'camera'),
            child: Text('Камера'),
          ),
        ],
      ),
    );

    if (action == 'gallery') {
      final image = await ImageService.pickImage();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } else if (action == 'camera') {
      final image = await ImageService.takePhoto();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    }
  }

  Future<void> _saveTool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);

      final tool = Tool(
        id: widget.tool?.id ?? IdGenerator.generateToolId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        brand: _brandController.text.trim(),
        uniqueId: _uniqueIdController.text.trim(),
        currentLocation: widget.tool?.currentLocation ?? 'garage',
        isFavorite: _isFavorite,
        imageUrl: widget.tool?.imageUrl,
        localImagePath: widget.tool?.localImagePath,
        locationHistory: widget.tool?.locationHistory ?? [],
        createdAt: widget.tool?.createdAt ?? DateTime.now(),
      );

      if (widget.tool == null) {
        await toolsProvider.addTool(tool, imageFile: _selectedImage);
      } else {
        await toolsProvider.updateTool(tool, imageFile: _selectedImage);
      }

      Navigator.pop(context);

      ErrorHandler.showSuccessDialog(
        context,
        widget.tool == null
            ? 'Инструмент успешно добавлен'
            : 'Инструмент успешно обновлен',
      );
    } catch (e) {
      ErrorHandler.showErrorDialog(
        context,
        'Не удалось сохранить инструмент: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tool == null
              ? 'Добавить инструмент'
              : 'Редактировать инструмент',
        ),
        actions: [
          if (widget.tool != null)
            IconButton(
              icon: Icon(Icons.favorite),
              color: _isFavorite ? Colors.red : null,
              onPressed: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });
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
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.tool?.displayImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image(
                                  image:
                                      widget.tool!.displayImage!.startsWith(
                                        'http',
                                      )
                                      ? NetworkImage(widget.tool!.displayImage!)
                                      : FileImage(
                                              File(widget.tool!.displayImage!),
                                            )
                                            as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: Colors.grey[500],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Добавить фото',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Название инструмента',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.build),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите название инструмента';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        labelText: 'Бренд',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.branding_watermark),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _uniqueIdController,
                      decoration: InputDecoration(
                        labelText: 'Уникальный ID',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      readOnly: widget.tool != null,
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveTool,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          widget.tool == null ? 'Добавить' : 'Сохранить',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    if (widget.tool != null)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            _showDeleteConfirmation(context, widget.tool!.id);
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(color: Colors.red),
                          ),
                          child: Text(
                            'Удалить',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить этот инструмент? Это действие нельзя отменить.',
        ),
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
              await toolsProvider.deleteTool(id);
              Navigator.pop(context);
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ========== UPDATED AddEditObjectScreen ==========
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
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.object != null) {
      _nameController.text = widget.object!.name;
      _descriptionController.text = widget.object!.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final action = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Выберите источник изображения'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'gallery'),
            child: Text('Галерея'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'camera'),
            child: Text('Камера'),
          ),
        ],
      ),
    );

    if (action == 'gallery') {
      final image = await ImageService.pickImage();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } else if (action == 'camera') {
      final image = await ImageService.takePhoto();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    }
  }

  Future<void> _saveObject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final objectsProvider = Provider.of<ObjectsProvider>(
        context,
        listen: false,
      );

      final object = ConstructionObject(
        id: widget.object?.id ?? IdGenerator.generateObjectId(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: widget.object?.imageUrl,
        localImagePath: widget.object?.localImagePath,
        toolIds: widget.object?.toolIds ?? [],
        createdAt: widget.object?.createdAt ?? DateTime.now(),
      );

      if (widget.object == null) {
        await objectsProvider.addObject(object, imageFile: _selectedImage);
      } else {
        await objectsProvider.updateObject(object, imageFile: _selectedImage);
      }

      Navigator.pop(context);

      ErrorHandler.showSuccessDialog(
        context,
        widget.object == null
            ? 'Объект успешно добавлен'
            : 'Объект успешно обновлен',
      );
    } catch (e) {
      ErrorHandler.showErrorDialog(
        context,
        'Не удалось сохранить объект: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.object == null ? 'Добавить объект' : 'Редактировать объект',
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.object?.displayImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image(
                                  image:
                                      widget.object!.displayImage!.startsWith(
                                        'http',
                                      )
                                      ? NetworkImage(
                                          widget.object!.displayImage!,
                                        )
                                      : FileImage(
                                              File(
                                                widget.object!.displayImage!,
                                              ),
                                            )
                                            as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: Colors.grey[500],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Добавить фото',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Название объекта',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите название объекта';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveObject,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          widget.object == null ? 'Добавить' : 'Сохранить',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    if (widget.object != null)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            _showDeleteConfirmation(context, widget.object!.id);
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(color: Colors.red),
                          ),
                          child: Text(
                            'Удалить',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить этот объект? Это действие нельзя отменить.',
        ),
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
              await objectsProvider.deleteObject(id);
              Navigator.pop(context);
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class PDFPreviewScreen extends StatelessWidget {
  const PDFPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Предпросмотр PDF'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () async {
              try {
                await PDFExportService.generateInventoryPDF(
                  toolsProvider.tools,
                );
                ErrorHandler.showSuccessDialog(
                  context,
                  'PDF успешно сгенерирован',
                );
              } catch (e) {
                ErrorHandler.showErrorDialog(
                  context,
                  'Не удалось сгенерировать PDF: ${e.toString()}',
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              try {
                final pdfBytes = await PDFExportService.generateInventoryPDF(
                  toolsProvider.tools,
                );
                await Printing.layoutPdf(onLayout: (format) => pdfBytes);
              } catch (e) {
                ErrorHandler.showErrorDialog(
                  context,
                  'Не удалось распечатать: ${e.toString()}',
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: PDFExportService.generateInventoryPDF(toolsProvider.tools),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Генерация PDF...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка генерации PDF: ${snapshot.error}'),
            );
          }

          return PdfPreview(build: (format) => snapshot.data!);
        },
      ),
    );
  }
}

// ========== UPDATED MainScreen ==========
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load data when main screen starts
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
      final objectsProvider = Provider.of<ObjectsProvider>(
        context,
        listen: false,
      );

      await toolsProvider.loadTools();
      await objectsProvider.loadObjects();
    });
  }

  final List<Widget> _screens = [
    GarageScreen(),
    ToolsListScreen(),
    ObjectsListScreen(),
    MoveToolsScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Tooler'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _screens[_selectedIndex],
      floatingActionButton:
          _selectedIndex == 0 || _selectedIndex == 1 || _selectedIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                if (_selectedIndex == 0 || _selectedIndex == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditToolScreen(),
                    ),
                  );
                } else if (_selectedIndex == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditObjectScreen(),
                    ),
                  );
                }
              },
              child: Icon(Icons.add),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
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
            icon: Icon(Icons.move_to_inbox),
            label: 'Переместить',
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

  Widget _buildDrawer(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).primaryColor,
                  ),
                  radius: 30,
                ),
                SizedBox(height: 12),
                Text(
                  authProvider.user?.email ?? 'Гость',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Менеджер строительных инструментов',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildDrawerItem(context, Icons.garage, 'Гараж', 0),
          _buildDrawerItem(context, Icons.build, 'Инструменты', 1),
          _buildDrawerItem(context, Icons.location_city, 'Объекты', 2),
          _buildDrawerItem(context, Icons.move_to_inbox, 'Переместить', 3),
          _buildDrawerItem(context, Icons.favorite, 'Избранное', 4),
          _buildDrawerItem(context, Icons.person, 'Профиль', 5),
          Divider(),
          SwitchListTile(
            title: Text('Темная тема'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.setTheme(value ? ThemeMode.dark : ThemeMode.light);
            },
            secondary: Icon(Icons.dark_mode),
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Язык'),
            subtitle: Text(
              themeProvider.locale.languageCode == 'en' ? 'English' : 'Русский',
            ),
            onTap: () {
              themeProvider.toggleLocale();
              Navigator.pop(context);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Выйти'),
            onTap: () async {
              await authProvider.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    int index,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
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
            home: SplashScreen(),
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
            ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
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
                darkTheme: ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: Colors.blue,
                    secondary: Colors.blueAccent,
                  ),
                  appBarTheme: AppBarTheme(
                    elevation: 0,
                    backgroundColor: Colors.blue[800],
                    iconTheme: IconThemeData(color: Colors.white),
                  ),
                  floatingActionButtonTheme: FloatingActionButtonThemeData(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                  cardTheme: CardThemeData(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                themeMode: themeProvider.themeMode,
                locale: themeProvider.locale,
                supportedLocales: [Locale('en'), Locale('ru')],
                localizationsDelegates: [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                navigatorKey: navigatorKey,
                home: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.isLoading) {
                      return SplashScreen();
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
              );
            },
          ),
        );
      },
    );
  }
}
