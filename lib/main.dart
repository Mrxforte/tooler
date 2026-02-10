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
    await Firebase.initializeApp();

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

  static void showWarningDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
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
      // Secret bypass for demonstration
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
      _bypassAuth = false;

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
      _bypassAuth = false;
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
  bool _selectionMode = false;

  List<Tool> get tools => _getFilteredTools();
  List<Tool> get garageTools =>
      _tools.where((t) => t.currentLocation == 'garage').toList();
  List<Tool> get favoriteTools => _tools.where((t) => t.isFavorite).toList();
  List<Tool> get selectedTools => _tools.where((t) => t.isSelected).toList();
  bool get isLoading => _isLoading;
  bool get selectionMode => _selectionMode;
  bool get hasSelectedTools => _tools.any((t) => t.isSelected);

  void toggleSelectionMode() {
    _selectionMode = !_selectionMode;
    if (!_selectionMode) {
      _deselectAllTools();
    }
    notifyListeners();
  }

  void selectTool(String toolId) {
    final index = _tools.indexWhere((t) => t.id == toolId);
    if (index != -1) {
      _tools[index] = _tools[index].copyWith(isSelected: true);
      notifyListeners();
    }
  }

  void deselectTool(String toolId) {
    final index = _tools.indexWhere((t) => t.id == toolId);
    if (index != -1) {
      _tools[index] = _tools[index].copyWith(isSelected: false);
      notifyListeners();
    }
  }

  void toggleToolSelection(String toolId) {
    final index = _tools.indexWhere((t) => t.id == toolId);
    if (index != -1) {
      _tools[index] = _tools[index].copyWith(
        isSelected: !_tools[index].isSelected,
      );
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
      final loadedTools = LocalDatabase.tools.values.toList();

      // Validate and filter out null tools
      _tools = loadedTools.where((tool) => tool != null).toList();

      print('Loaded ${_tools.length} tools from local database');

      // Try to sync with Firebase if online
      await _syncWithFirebase();
    } catch (e) {
      print('Error loading tools: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось загрузить инструменты: ${e.toString()}',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTool(Tool tool, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate tool data
      if (tool.title.isEmpty || tool.brand.isEmpty || tool.uniqueId.isEmpty) {
        throw Exception('Заполните все обязательные поля');
      }

      // Upload image if provided
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          tool = tool.copyWith(imageUrl: imageUrl);
        } else {
          // Save locally if upload fails
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

      if (navigatorKey.currentContext != null) {
        ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext!,
          'Инструмент успешно добавлен',
        );
      }
    } catch (e) {
      print('Error adding tool: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось добавить инструмент: ${e.toString()}',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTool(Tool tool, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate tool data
      if (tool.title.isEmpty || tool.brand.isEmpty || tool.uniqueId.isEmpty) {
        throw Exception('Заполните все обязательные поля');
      }

      // Upload new image if provided
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          tool = tool.copyWith(imageUrl: imageUrl, localImagePath: null);
        } else {
          // Save locally if upload fails
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

        if (navigatorKey.currentContext != null) {
          ErrorHandler.showSuccessDialog(
            navigatorKey.currentContext!,
            'Инструмент успешно обновлен',
          );
        }
      } else {
        throw Exception('Инструмент не найден');
      }
    } catch (e) {
      print('Error updating tool: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось обновить инструмент: ${e.toString()}',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTool(String toolId) async {
    try {
      final toolIndex = _tools.indexWhere((t) => t.id == toolId);
      if (toolIndex == -1) {
        if (navigatorKey.currentContext != null) {
          ErrorHandler.showErrorDialog(
            navigatorKey.currentContext!,
            'Инструмент не найден',
          );
        }
        return;
      }

      _tools.removeAt(toolIndex);
      await LocalDatabase.tools.delete(toolId);

      await _addToSyncQueue(
        action: 'delete',
        collection: 'tools',
        data: {'id': toolId},
      );

      if (navigatorKey.currentContext != null) {
        ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext!,
          'Инструмент успешно удален',
        );
      }
    } catch (e) {
      print('Error deleting tool: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось удалить инструмент: ${e.toString()}',
        );
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteSelectedTools() async {
    try {
      final selectedTools = _tools.where((t) => t.isSelected).toList();

      if (selectedTools.isEmpty) {
        if (navigatorKey.currentContext != null) {
          ErrorHandler.showWarningDialog(
            navigatorKey.currentContext!,
            'Выберите инструменты для удаления',
          );
        }
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

      if (navigatorKey.currentContext != null) {
        ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext!,
          'Удалено ${selectedTools.length} инструментов',
        );
      }
    } catch (e) {
      print('Error deleting selected tools: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось удалить инструменты: ${e.toString()}',
        );
      }
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
        if (navigatorKey.currentContext != null) {
          ErrorHandler.showErrorDialog(
            navigatorKey.currentContext!,
            'Инструмент не найден',
          );
        }
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

      if (navigatorKey.currentContext != null) {
        ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext!,
          'Инструмент перемещен в $newLocationName',
        );
      }
    } catch (e) {
      print('Error moving tool: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось переместить инструмент: ${e.toString()}',
        );
      }
    }
  }

  Future<void> moveSelectedTools(
    String newLocationId,
    String newLocationName,
  ) async {
    try {
      final selectedTools = _tools.where((t) => t.isSelected).toList();

      if (selectedTools.isEmpty) {
        if (navigatorKey.currentContext != null) {
          ErrorHandler.showWarningDialog(
            navigatorKey.currentContext!,
            'Выберите инструменты для перемещения',
          );
        }
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

      // Update local list
      await loadTools();
      _selectionMode = false;

      if (navigatorKey.currentContext != null) {
        ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext!,
          'Перемещено ${selectedTools.length} инструментов в $newLocationName',
        );
      }
    } catch (e) {
      print('Error moving selected tools: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось переместить инструменты: ${e.toString()}',
        );
      }
    }
  }

  Future<void> toggleFavorite(String toolId) async {
    try {
      final toolIndex = _tools.indexWhere((t) => t.id == toolId);
      if (toolIndex == -1) return;

      final tool = _tools[toolIndex];
      final updatedTool = tool.copyWith(isFavorite: !tool.isFavorite);
      await updateTool(updatedTool);
    } catch (e) {
      print('Error toggling favorite: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось обновить статус избранного',
        );
      }
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
  bool _selectionMode = false;

  List<ConstructionObject> get objects => _getFilteredObjects();
  bool get isLoading => _isLoading;
  bool get selectionMode => _selectionMode;
  List<ConstructionObject> get selectedObjects =>
      _objects.where((o) => o.isSelected).toList();
  bool get hasSelectedObjects => _objects.any((o) => o.isSelected);

  void toggleSelectionMode() {
    _selectionMode = !_selectionMode;
    if (!_selectionMode) {
      _deselectAllObjects();
    }
    notifyListeners();
  }

  void selectObject(String objectId) {
    final index = _objects.indexWhere((o) => o.id == objectId);
    if (index != -1) {
      _objects[index] = _objects[index].copyWith(isSelected: true);
      notifyListeners();
    }
  }

  void deselectObject(String objectId) {
    final index = _objects.indexWhere((o) => o.id == objectId);
    if (index != -1) {
      _objects[index] = _objects[index].copyWith(isSelected: false);
      notifyListeners();
    }
  }

  void toggleObjectSelection(String objectId) {
    final index = _objects.indexWhere((o) => o.id == objectId);
    if (index != -1) {
      _objects[index] = _objects[index].copyWith(
        isSelected: !_objects[index].isSelected,
      );
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
      final loadedObjects = LocalDatabase.objects.values.toList();

      // Validate and filter out null objects
      _objects = loadedObjects.where((obj) => obj != null).toList();

      print('Loaded ${_objects.length} objects from local database');
    } catch (e) {
      print('Error loading objects: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось загрузить объекты: ${e.toString()}',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addObject(ConstructionObject obj, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate object data
      if (obj.name.isEmpty) {
        throw Exception('Название объекта обязательно');
      }

      // Upload image if provided
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          obj = obj.copyWith(imageUrl: imageUrl);
        } else {
          // Save locally if upload fails
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

      if (navigatorKey.currentContext != null) {
        ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext!,
          'Объект успешно добавлен',
        );
      }
    } catch (e) {
      print('Error adding object: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось добавить объект: ${e.toString()}',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateObject(ConstructionObject obj, {File? imageFile}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate object data
      if (obj.name.isEmpty) {
        throw Exception('Название объекта обязательно');
      }

      // Upload new image if provided
      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        final imageUrl = await ImageService.uploadImage(imageFile, userId);
        if (imageUrl != null) {
          obj = obj.copyWith(imageUrl: imageUrl, localImagePath: null);
        } else {
          // Save locally if upload fails
          obj = obj.copyWith(localImagePath: imageFile.path, imageUrl: null);
        }
      }

      final index = _objects.indexWhere((o) => o.id == obj.id);
      if (index == -1) {
        if (navigatorKey.currentContext != null) {
          ErrorHandler.showErrorDialog(
            navigatorKey.currentContext!,
            'Объект не найден',
          );
        }
        return;
      }

      _objects[index] = obj;
      await LocalDatabase.objects.put(obj.id, obj);

      await _addToSyncQueue(
        action: 'update',
        collection: 'objects',
        data: obj.toJson(),
      );

      if (navigatorKey.currentContext != null) {
        ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext!,
          'Объект успешно обновлен',
        );
      }
    } catch (e) {
      print('Error updating object: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось обновить объект: ${e.toString()}',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteObject(String objectId) async {
    try {
      final objectIndex = _objects.indexWhere((o) => o.id == objectId);
      if (objectIndex == -1) {
        if (navigatorKey.currentContext != null) {
          ErrorHandler.showErrorDialog(
            navigatorKey.currentContext!,
            'Объект не найден',
          );
        }
        return;
      }

      _objects.removeAt(objectIndex);
      await LocalDatabase.objects.delete(objectId);

      await _addToSyncQueue(
        action: 'delete',
        collection: 'objects',
        data: {'id': objectId},
      );

      if (navigatorKey.currentContext != null) {
        ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext!,
          'Объект успешно удален',
        );
      }
    } catch (e) {
      print('Error deleting object: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось удалить объект: ${e.toString()}',
        );
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteSelectedObjects() async {
    try {
      final selectedObjects = _objects.where((o) => o.isSelected).toList();

      if (selectedObjects.isEmpty) {
        if (navigatorKey.currentContext != null) {
          ErrorHandler.showWarningDialog(
            navigatorKey.currentContext!,
            'Выберите объекты для удаления',
          );
        }
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

      if (navigatorKey.currentContext != null) {
        ErrorHandler.showSuccessDialog(
          navigatorKey.currentContext!,
          'Удалено ${selectedObjects.length} объектов',
        );
      }
    } catch (e) {
      print('Error deleting selected objects: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось удалить объекты: ${e.toString()}',
        );
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> addToolsToObject(String objectId, List<String> toolIds) async {
    try {
      final objectIndex = _objects.indexWhere((o) => o.id == objectId);
      if (objectIndex != -1) {
        final object = _objects[objectIndex];
        final updatedToolIds = List<String>.from(object.toolIds)
          ..addAll(toolIds);
        final updatedObject = object.copyWith(
          toolIds: updatedToolIds.toSet().toList(),
        );
        await updateObject(updatedObject);
      }
    } catch (e) {
      print('Error adding tools to object: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось добавить инструменты в объект',
        );
      }
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
        final updatedToolIds = List<String>.from(object.toolIds)
          ..removeWhere((id) => toolIds.contains(id));
        final updatedObject = object.copyWith(toolIds: updatedToolIds);
        await updateObject(updatedObject);
      }
    } catch (e) {
      print('Error removing tools from object: $e');
      if (navigatorKey.currentContext != null) {
        ErrorHandler.showErrorDialog(
          navigatorKey.currentContext!,
          'Не удалось удалить инструменты из объекта',
        );
      }
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

// ========== MISSING SCREENS ==========

// Splash Screen
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'TOOLER',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// Onboarding Screen
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

  final List<Map<String, String>> _onboardingPages = [
    {
      'title': 'Добро пожаловать в Tooler',
      'description':
          'Управляйте строительными инструментами легко и эффективно',
      'image': '🎯',
    },
    {
      'title': 'Отслеживание местоположения',
      'description':
          'Знайте где находится каждый инструмент в реальном времени',
      'image': '📍',
    },
    {
      'title': 'Офлайн доступ',
      'description':
          'Работайте без интернета, данные синхронизируются автоматически',
      'image': '📱',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingPages.length,
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
                        Text(
                          _onboardingPages[index]['image']!,
                          style: TextStyle(fontSize: 100),
                        ),
                        SizedBox(height: 40),
                        Text(
                          _onboardingPages[index]['title']!,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Text(
                          _onboardingPages[index]['description']!,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  if (_currentPage < _onboardingPages.length - 1)
                    TextButton(
                      onPressed: () {
                        widget.onComplete();
                      },
                      child: Text('Пропустить'),
                    ),

                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingPages.length,
                      (index) => Container(
                        width: 10,
                        height: 10,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),

                  // Next/Start button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _onboardingPages.length - 1) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      } else {
                        widget.onComplete();
                      }
                    },
                    child: Text(
                      _currentPage == _onboardingPages.length - 1
                          ? 'Начать'
                          : 'Далее',
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

// Auth Screen
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

  @override
  void initState() {
    super.initState();
    final prefs = context.read<SharedPreferences>();
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null) {
      _emailController.text = savedEmail;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Icon(Icons.build_circle, size: 80, color: theme.primaryColor),
                SizedBox(height: 20),
                Text(
                  'TOOLER',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Управление строительными инструментами',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите пароль';
                              }
                              if (value.length < 6) {
                                return 'Пароль должен содержать минимум 6 символов';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return SwitchListTile(
                                title: Text('Запомнить меня'),
                                value: authProvider.rememberMe,
                                onChanged: (value) {
                                  authProvider.setRememberMe(value);
                                },
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          if (_isLoading)
                            CircularProgressIndicator()
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                child: Text(
                                  _isLogin ? 'Войти' : 'Зарегистрироваться',
                                  style: TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
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
                                  ? 'Нет аккаунта? Зарегистрируйтесь'
                                  : 'Уже есть аккаунт? Войдите',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Для тестирования:\nEmail: vadim\nПароль: vadim',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool success;
    if (_isLogin) {
      success = await authProvider.signInWithEmail(email, password);
    } else {
      success = await authProvider.signUpWithEmail(email, password);
    }

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      String errorMessage = _isLogin
          ? 'Ошибка входа. Проверьте email и пароль.'
          : 'Ошибка регистрации. Пользователь может уже существовать.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Welcome Screen
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({Key? key, required this.onContinue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ],
              ),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.build_circle,
                      size: 70,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  SizedBox(height: 40),

                  // App Name
                  Text(
                    'TOOLER',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),

                  SizedBox(height: 10),

                  // Tagline
                  Text(
                    'Управление строительными инструментами',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 60),

                  // Features
                  _buildFeature(
                    icon: Icons.verified_user,
                    text: 'Безопасное хранение данных',
                  ),
                  SizedBox(height: 20),
                  _buildFeature(
                    icon: Icons.sync,
                    text: 'Офлайн и онлайн синхронизация',
                  ),
                  SizedBox(height: 20),
                  _buildFeature(
                    icon: Icons.qr_code_scanner,
                    text: 'QR коды для быстрого доступа',
                  ),

                  SizedBox(height: 60),

                  // Start Button
                  ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'НАЧАТЬ РАБОТУ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Developer Info
                  Text(
                    '© 2024 Tooler App\nРазработано для строительных компаний',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature({required IconData icon, required String text}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}

// Tools List Screen
class ToolsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Все инструменты'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ToolSearchDelegate(toolsProvider.tools),
              );
            },
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
                ],
              ),
            )
          : ListView.builder(
              itemCount: toolsProvider.tools.length,
              itemBuilder: (context, index) {
                final tool = toolsProvider.tools[index];
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

// Add/Edit Tool Screen
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

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tool != null) {
      _titleController.text = widget.tool!.title;
      _descriptionController.text = widget.tool!.description;
      _brandController.text = widget.tool!.brand;
      _uniqueIdController.text = widget.tool!.uniqueId;
    } else {
      _uniqueIdController.text = IdGenerator.generateUniqueId();
    }
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tool == null
              ? 'Добавить инструмент'
              : 'Редактировать инструмент',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _isLoading ? null : _saveTool,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.tool?.displayImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
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
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.photo_camera,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                ),
                              )
                            : Icon(
                                Icons.photo_camera,
                                size: 50,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Название *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите название';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),

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
                    SizedBox(height: 15),

                    // Unique ID
                    TextFormField(
                      controller: _uniqueIdController,
                      decoration: InputDecoration(
                        labelText: 'Уникальный ID *',
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
                          return 'Введите уникальный ID';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),

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
                    SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveTool,
                        icon: Icon(Icons.save),
                        label: Text(
                          widget.tool == null ? 'Добавить' : 'Сохранить',
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _pickImage() async {
    final imageService = ImageService();
    final result = await showModalBottomSheet<File?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Выбрать из галереи'),
              onTap: () async {
                final image = await ImageService.pickImage();
                Navigator.pop(context, image);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Сделать фото'),
              onTap: () async {
                final image = await ImageService.takePhoto();
                Navigator.pop(context, image);
              },
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedImage = result;
      });
    }
  }

  Future<void> _saveTool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final toolsProvider = context.read<ToolsProvider>();
      final tool = Tool(
        id: widget.tool?.id ?? IdGenerator.generateToolId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        brand: _brandController.text.trim(),
        uniqueId: _uniqueIdController.text.trim(),
        currentLocation: widget.tool?.currentLocation ?? 'garage',
        isFavorite: widget.tool?.isFavorite ?? false,
        locationHistory: widget.tool?.locationHistory ?? [],
        createdAt: widget.tool?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.tool == null) {
        await toolsProvider.addTool(tool, imageFile: _selectedImage);
      } else {
        await toolsProvider.updateTool(tool, imageFile: _selectedImage);
      }

      Navigator.pop(context);
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
}

// Object Details Screen
class ObjectDetailsScreen extends StatelessWidget {
  final ConstructionObject object;
  final int toolCount;

  const ObjectDetailsScreen({
    Key? key,
    required this.object,
    required this.toolCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final toolsInObject = toolsProvider.tools
        .where((t) => t.currentLocation == object.id)
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200]),
              child: object.displayImage != null
                  ? Image(
                      image: object.displayImage!.startsWith('http')
                          ? NetworkImage(object.displayImage!)
                          : FileImage(File(object.displayImage!))
                                as ImageProvider,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.location_city,
                        size: 80,
                        color: Colors.grey,
                      ),
                    )
                  : Icon(Icons.location_city, size: 80, color: Colors.grey),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Object Name
                  Text(
                    object.name,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // Description
                  Text(
                    object.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),

                  // Stats Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.build,
                            label: 'Инструменты',
                            value: '$toolCount',
                          ),
                          _buildStatItem(
                            icon: Icons.calendar_today,
                            label: 'Создан',
                            value: DateFormat(
                              'dd.MM.yyyy',
                            ).format(object.createdAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Tools List
                  Text(
                    'Инструменты на объекте',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  if (toolsInObject.isEmpty)
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'На объекте нет инструментов',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    ...toolsInObject.map((tool) {
                      return Card(
                        margin: EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[100],
                            ),
                            child: tool.displayImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image(
                                      image:
                                          tool.displayImage!.startsWith('http')
                                          ? NetworkImage(tool.displayImage!)
                                          : FileImage(File(tool.displayImage!))
                                                as ImageProvider,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.build,
                                            size: 24,
                                            color: Colors.grey,
                                          ),
                                    ),
                                  )
                                : Icon(
                                    Icons.build,
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                          ),
                          title: Text(tool.title),
                          subtitle: Text(tool.brand),
                          trailing: IconButton(
                            icon: Icon(Icons.arrow_back),
                            onPressed: () {
                              toolsProvider.moveTool(
                                tool.id,
                                'garage',
                                'Гараж',
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EnhancedToolDetailsScreen(tool: tool),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

// Add/Edit Object Screen
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.object == null ? 'Добавить объект' : 'Редактировать объект',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _isLoading ? null : _saveObject,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.object?.displayImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
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
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.photo_camera,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                ),
                              )
                            : Icon(
                                Icons.photo_camera,
                                size: 50,
                                color: Colors.grey,
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
                    SizedBox(height: 15),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Описание объекта',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveObject,
                        icon: Icon(Icons.save),
                        label: Text(
                          widget.object == null
                              ? 'Добавить объект'
                              : 'Сохранить изменения',
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _pickImage() async {
    final imageService = ImageService();
    final result = await showModalBottomSheet<File?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Выбрать из галереи'),
              onTap: () async {
                final image = await ImageService.pickImage();
                Navigator.pop(context, image);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Сделать фото'),
              onTap: () async {
                final image = await ImageService.takePhoto();
                Navigator.pop(context, image);
              },
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedImage = result;
      });
    }
  }

  Future<void> _saveObject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final objectsProvider = context.read<ObjectsProvider>();
      final object = ConstructionObject(
        id: widget.object?.id ?? IdGenerator.generateObjectId(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        toolIds: widget.object?.toolIds ?? [],
        createdAt: widget.object?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.object == null) {
        await objectsProvider.addObject(object, imageFile: _selectedImage);
      } else {
        await objectsProvider.updateObject(object, imageFile: _selectedImage);
      }

      Navigator.pop(context);
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// Move Tools Screen
class MoveToolsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Перемещение инструментов')),
      body: toolsProvider.isLoading || objectsProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      // Garage Tools
                      _buildLocationSection(
                        context,
                        title: 'Гараж',
                        icon: Icons.garage,
                        tools: toolsProvider.garageTools,
                        onMove: (tool) => _showMoveDialog(context, tool),
                      ),

                      // Object Tools
                      ...objectsProvider.objects.map((object) {
                        final toolsInObject = toolsProvider.tools
                            .where((t) => t.currentLocation == object.id)
                            .toList();

                        return _buildLocationSection(
                          context,
                          title: object.name,
                          icon: Icons.location_city,
                          tools: toolsInObject,
                          onMove: (tool) => _showMoveDialog(context, tool),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLocationSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Tool> tools,
    required Function(Tool) onMove,
  }) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.blue),
            title: Text(title),
            subtitle: Text('${tools.length} инструментов'),
          ),
          Divider(),
          if (tools.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Нет инструментов',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...tools.map((tool) {
              return ListTile(
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
                            image: tool.displayImage!.startsWith('http')
                                ? NetworkImage(tool.displayImage!)
                                : FileImage(File(tool.displayImage!))
                                      as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.build, size: 20, color: Colors.grey),
                ),
                title: Text(tool.title),
                subtitle: Text(tool.brand),
                trailing: IconButton(
                  icon: Icon(Icons.move_to_inbox),
                  onPressed: () => onMove(tool),
                ),
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
            }),
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
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Переместить "${tool.title}"',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Garage option
              ListTile(
                leading: Icon(Icons.garage, color: Colors.blue),
                title: Text('Гараж'),
                trailing: tool.currentLocation == 'garage'
                    ? Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  if (tool.currentLocation != 'garage') {
                    await toolsProvider.moveTool(tool.id, 'garage', 'Гараж');
                  }
                },
              ),
              Divider(),

              // Objects options
              ...objectsProvider.objects.map((object) {
                return ListTile(
                  leading: Icon(Icons.location_city, color: Colors.orange),
                  title: Text(object.name),
                  trailing: tool.currentLocation == object.id
                      ? Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    if (tool.currentLocation != object.id) {
                      await toolsProvider.moveTool(
                        tool.id,
                        object.id,
                        object.name,
                      );
                    }
                  },
                );
              }),

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

// Favorites Screen
class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Избранное')),
      body: toolsProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : toolsProvider.favoriteTools.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 80, color: Colors.grey[300]),
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
              itemCount: toolsProvider.favoriteTools.length,
              itemBuilder: (context, index) {
                final tool = toolsProvider.favoriteTools[index];
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

// Profile Screen
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Профиль')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    SizedBox(height: 15),
                    Text(
                      authProvider.user?.email ?? 'Гость',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      authProvider.bypassAuth ? 'Демо режим' : 'Аккаунт',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Stats Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          icon: Icons.build,
                          label: 'Инструменты',
                          value: toolsProvider.tools.length.toString(),
                        ),
                        _buildStatCard(
                          icon: Icons.location_city,
                          label: 'Объекты',
                          value: objectsProvider.objects.length.toString(),
                        ),
                        _buildStatCard(
                          icon: Icons.star,
                          label: 'Избранное',
                          value: toolsProvider.favoriteTools.length.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Settings
            Text(
              'Настройки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Темная тема'),
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      themeProvider.setTheme(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                    secondary: Icon(Icons.dark_mode),
                  ),
                  ListTile(
                    leading: Icon(Icons.language),
                    title: Text('Язык'),
                    subtitle: Text(
                      themeProvider.locale.languageCode == 'en'
                          ? 'English'
                          : 'Русский',
                    ),
                    onTap: () {
                      themeProvider.toggleLocale();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.storage),
                    title: Text('Очистить кэш'),
                    subtitle: Text('Освободить место на устройстве'),
                    onTap: () {
                      _showClearCacheDialog(context);
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // About
            Text(
              'О приложении',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('Tooler'),
                subtitle: Text('Версия 1.0.0'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Tooler',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2024 Tooler App',
                    children: [
                      Text(
                        'Приложение для управления строительными инструментами',
                      ),
                    ],
                  );
                },
              ),
            ),

            SizedBox(height: 30),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AuthScreen()),
                  );
                },
                icon: Icon(Icons.logout),
                label: Text('Выйти'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Очистка кэша'),
        content: Text('Вы уверены, что хотите очистить кэш приложения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Hive.deleteBoxFromDisk(LocalDatabase.toolsBox);
                await Hive.deleteBoxFromDisk(LocalDatabase.objectsBox);
                await Hive.deleteBoxFromDisk(LocalDatabase.syncQueueBox);

                ErrorHandler.showSuccessDialog(context, 'Кэш успешно очищен');
              } catch (e) {
                ErrorHandler.showErrorDialog(
                  context,
                  'Ошибка при очистке кэша: ${e.toString()}',
                );
              }
            },
            child: Text('Очистить'),
          ),
        ],
      ),
    );
  }
}

// Search Screen
class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Tool> _filteredTools = [];
  List<ConstructionObject> _filteredObjects = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _filteredTools = Provider.of<ToolsProvider>(context, listen: false).tools;
    _filteredObjects = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    ).objects;
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );

    setState(() {
      if (query.isEmpty) {
        _filteredTools = toolsProvider.tools;
        _filteredObjects = objectsProvider.objects;
      } else {
        _filteredTools = toolsProvider.tools.where((tool) {
          return tool.title.toLowerCase().contains(query) ||
              tool.brand.toLowerCase().contains(query) ||
              tool.uniqueId.toLowerCase().contains(query) ||
              tool.description.toLowerCase().contains(query);
        }).toList();

        _filteredObjects = objectsProvider.objects.where((object) {
          return object.name.toLowerCase().contains(query) ||
              object.description.toLowerCase().contains(query);
        }).toList();
      }
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
            hintText: 'Поиск инструментов и объектов...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
            },
          ),
        ],
      ),
      body: _searchController.text.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text(
                    'Начните вводить для поиска',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                if (_filteredTools.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Инструменты (${_filteredTools.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ..._filteredTools.map((tool) {
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
                }),

                if (_filteredObjects.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Объекты (${_filteredObjects.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ..._filteredObjects.map((object) {
                  final toolCount = Provider.of<ToolsProvider>(
                    context,
                    listen: false,
                  ).tools.where((t) => t.currentLocation == object.id).length;

                  return SelectionObjectCard(
                    object: object,
                    toolCount: toolCount,
                    selectionMode: false,
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
                }),

                if (_filteredTools.isEmpty && _filteredObjects.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Ничего не найдено',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Попробуйте изменить запрос',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Search Delegate
class ToolSearchDelegate extends SearchDelegate<String> {
  final List<Tool> tools;

  ToolSearchDelegate(this.tools);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = tools.where((tool) {
      return tool.title.toLowerCase().contains(query.toLowerCase()) ||
          tool.brand.toLowerCase().contains(query.toLowerCase()) ||
          tool.uniqueId.toLowerCase().contains(query.toLowerCase()) ||
          tool.description.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final tool = results[index];
        return SelectionToolCard(
          tool: tool,
          selectionMode: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EnhancedToolDetailsScreen(tool: tool),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? []
        : tools.where((tool) {
            return tool.title.toLowerCase().contains(query.toLowerCase()) ||
                tool.brand.toLowerCase().contains(query.toLowerCase()) ||
                tool.uniqueId.toLowerCase().contains(query.toLowerCase()) ||
                tool.description.toLowerCase().contains(query.toLowerCase());
          }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final tool = suggestions[index];
        return SelectionToolCard(
          tool: tool,
          selectionMode: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EnhancedToolDetailsScreen(tool: tool),
              ),
            );
          },
        );
      },
    );
  }
}

// ========== ENHANCED TOOL DETAILS SCREEN ==========
class EnhancedToolDetailsScreen extends StatelessWidget {
  final Tool tool;

  const EnhancedToolDetailsScreen({Key? key, required this.tool})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'tool-${tool.id}',
                child: tool.displayImage != null
                    ? Image(
                        image: tool.displayImage!.startsWith('http')
                            ? NetworkImage(tool.displayImage!)
                            : FileImage(File(tool.displayImage!))
                                  as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.build,
                            size: 100,
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                      ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share),
                onPressed: () => _shareTool(context),
              ),
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
                            builder: (context) => AddEditToolScreen(tool: tool),
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
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
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

          // Tool Information
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Favorite
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tool.title,
                          style: TextStyle(
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
                            ),
                            onPressed: () {
                              toolsProvider.toggleFavorite(tool.id);
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  // Brand and ID
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
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
                      SizedBox(width: 10),
                      Icon(Icons.qr_code, size: 16, color: Colors.grey),
                      SizedBox(width: 5),
                      Text(tool.uniqueId, style: TextStyle(color: Colors.grey)),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Description
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
                          SizedBox(height: 10),
                          Text(
                            tool.description.isNotEmpty
                                ? tool.description
                                : 'Описание отсутствует',
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

                  SizedBox(height: 20),

                  // Details Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildDetailCard(
                        icon: Icons.location_on,
                        title: 'Местоположение',
                        value: tool.currentLocation == 'garage'
                            ? 'Гараж'
                            : 'На объекте',
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
                        icon: Icons.history,
                        title: 'История',
                        value: '${tool.locationHistory.length} записей',
                        color: Colors.purple,
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

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
                                Icon(Icons.history, color: Colors.purple),
                                SizedBox(width: 10),
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
                            SizedBox(height: 10),
                            ...tool.locationHistory.map((history) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.purple,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            history.locationName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            DateFormat(
                                              'dd.MM.yyyy HH:mm',
                                            ).format(history.date),
                                            style: TextStyle(
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

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      // Action Button
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Consumer<ToolsProvider>(
          builder: (context, toolsProvider, child) {
            return ElevatedButton.icon(
              onPressed: () => _showMoveDialog(context, tool),
              icon: Icon(Icons.move_to_inbox),
              label: Text('Переместить инструмент'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
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
                SizedBox(width: 8),
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
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
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

  void _shareTool(BuildContext context) async {
    // Implement sharing functionality
    ErrorHandler.showSuccessDialog(
      context,
      'Функция общего доступа скоро будет доступна',
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить "${tool.title}"? Это действие нельзя отменить.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
              await toolsProvider.deleteTool(tool.id);
              Navigator.pop(context);
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? selectedLocationId = tool.currentLocation;
        final objects = objectsProvider.objects;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Переместить инструмент',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.garage, color: Colors.blue),
                    title: Text('Гараж'),
                    trailing: selectedLocationId == 'garage'
                        ? Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedLocationId = 'garage';
                      });
                    },
                  ),
                  Divider(),
                  ...objects.map((object) {
                    return ListTile(
                      leading: Icon(Icons.location_city, color: Colors.orange),
                      title: Text(object.name),
                      subtitle: Text('${object.toolIds.length} инструментов'),
                      trailing: selectedLocationId == object.id
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedLocationId = object.id;
                        });
                      },
                    );
                  }),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Отмена'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
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

// ========== MULTI-SELECTION TOOL CARD ==========
class SelectionToolCard extends StatelessWidget {
  final Tool tool;
  final bool selectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SelectionToolCard({
    Key? key,
    required this.tool,
    this.selectionMode = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ToolsProvider>(
      builder: (context, toolsProvider, child) {
        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: InkWell(
            onTap: selectionMode
                ? () => toolsProvider.toggleToolSelection(tool.id)
                : onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: tool.isSelected
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  if (selectionMode)
                    Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tool.isSelected
                              ? Colors.blue
                              : Colors.grey[300],
                          border: Border.all(
                            color: tool.isSelected
                                ? Colors.blue
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: tool.isSelected
                            ? Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
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
                                  Icon(
                                    Icons.build,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!selectionMode && tool.isFavorite)
                              Icon(Icons.star, size: 16, color: Colors.amber),
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
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.blue,
                            ),
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
                  if (!selectionMode)
                    IconButton(
                      icon: Icon(
                        tool.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: tool.isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        toolsProvider.toggleFavorite(tool.id);
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
}

// ========== MULTI-SELECTION OBJECT CARD ==========
class SelectionObjectCard extends StatelessWidget {
  final ConstructionObject object;
  final int toolCount;
  final bool selectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SelectionObjectCard({
    Key? key,
    required this.object,
    required this.toolCount,
    this.selectionMode = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ObjectsProvider>(
      builder: (context, objectsProvider, child) {
        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: InkWell(
            onTap: selectionMode
                ? () => objectsProvider.toggleObjectSelection(object.id)
                : onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: object.isSelected
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  if (selectionMode)
                    Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: object.isSelected
                              ? Colors.blue
                              : Colors.grey[300],
                          border: Border.all(
                            color: object.isSelected
                                ? Colors.blue
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: object.isSelected
                            ? Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
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
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.location_city,
                                    size: 35,
                                    color: Colors.grey,
                                  ),
                            )
                          : Icon(
                              Icons.location_city,
                              size: 35,
                              color: Colors.grey,
                            ),
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
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
                                  Icon(
                                    Icons.build,
                                    size: 14,
                                    color: Colors.blue,
                                  ),
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
                            if (!selectionMode)
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
      },
    );
  }
}

// ========== MULTI-SELECTION ACTION BAR ==========
class MultiSelectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback? onDelete;
  final VoidCallback? onMove;
  final bool isToolSelection;

  const MultiSelectionAppBar({
    Key? key,
    required this.title,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onClearSelection,
    this.onDelete,
    this.onMove,
    this.isToolSelection = true,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(icon: Icon(Icons.close), onPressed: onClearSelection),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14)),
          Text(
            'Выбрано: $selectedCount',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      actions: [
        if (selectedCount > 0)
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.select_all),
                  title: Text('Выбрать все'),
                  onTap: () {
                    Navigator.pop(context);
                    onSelectAll();
                  },
                ),
              ),
              if (onMove != null)
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.move_to_inbox),
                    title: Text('Переместить выбранные'),
                    onTap: () {
                      Navigator.pop(context);
                      onMove!();
                    },
                  ),
                ),
              if (onDelete != null)
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text(
                      'Удалить выбранные',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onDelete!();
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// ========== ENHANCED GARAGE SCREEN WITH MULTI-SELECTION ==========
class EnhancedGarageScreen extends StatefulWidget {
  const EnhancedGarageScreen({Key? key}) : super(key: key);

  @override
  _EnhancedGarageScreenState createState() => _EnhancedGarageScreenState();
}

class _EnhancedGarageScreenState extends State<EnhancedGarageScreen> {
  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: toolsProvider.selectionMode
          ? MultiSelectionAppBar(
              title: 'Гараж',
              selectedCount: toolsProvider.selectedTools.length,
              onSelectAll: () => toolsProvider.selectAllTools(),
              onClearSelection: () => toolsProvider.toggleSelectionMode(),
              onDelete: () => _showMultiDeleteDialog(context),
              onMove: () => _showMultiMoveDialog(context),
              isToolSelection: true,
            )
          : AppBar(
              title: Text('Гараж'),
              actions: [
                if (toolsProvider.garageTools.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.checklist),
                    onPressed: () => toolsProvider.toggleSelectionMode(),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    final parts = value.split('_');
                    toolsProvider.setSort(parts[0], parts[1] == 'asc');
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'name_asc',
                      child: Text('По имени (А-Я)'),
                    ),
                    PopupMenuItem(
                      value: 'name_desc',
                      child: Text('По имени (Я-А)'),
                    ),
                    PopupMenuItem(
                      value: 'date_asc',
                      child: Text('По дате (старые)'),
                    ),
                    PopupMenuItem(
                      value: 'date_desc',
                      child: Text('По дате (новые)'),
                    ),
                    PopupMenuItem(
                      value: 'brand_asc',
                      child: Text('По бренду (А-Я)'),
                    ),
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
                    onLongPress: () {
                      if (!toolsProvider.selectionMode) {
                        toolsProvider.toggleSelectionMode();
                        toolsProvider.selectTool(tool.id);
                      }
                    },
                  );
                },
              ),
            ),
      floatingActionButton: !toolsProvider.selectionMode
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddEditToolScreen()),
                );
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  void _showMultiDeleteDialog(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final selectedCount = toolsProvider.selectedTools.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удаление инструментов'),
        content: Text(
          'Вы уверены, что хотите удалить выбранные $selectedCount инструментов? Это действие нельзя отменить.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await toolsProvider.deleteSelectedTools();
            },
            child: Text(
              'Удалить ($selectedCount)',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showMultiMoveDialog(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );
    final selectedCount = toolsProvider.selectedTools.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? selectedLocationId = 'garage';

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Переместить $selectedCount инструментов',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.garage, color: Colors.blue),
                    title: Text('Гараж'),
                    trailing: selectedLocationId == 'garage'
                        ? Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedLocationId = 'garage';
                      });
                    },
                  ),
                  Divider(),
                  ...objectsProvider.objects.map((object) {
                    return ListTile(
                      leading: Icon(Icons.location_city, color: Colors.orange),
                      title: Text(object.name),
                      subtitle: Text('${object.toolIds.length} инструментов'),
                      trailing: selectedLocationId == object.id
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedLocationId = object.id;
                        });
                      },
                    );
                  }),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Отмена'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedLocationId != null) {
                              String locationName = 'Гараж';
                              if (selectedLocationId != 'garage') {
                                final object = objectsProvider.objects
                                    .firstWhere(
                                      (o) => o.id == selectedLocationId,
                                      orElse: () => ConstructionObject(
                                        id: 'garage',
                                        name: 'Гараж',
                                        description: '',
                                      ),
                                    );
                                locationName = object.name;
                              }

                              await toolsProvider.moveSelectedTools(
                                selectedLocationId!,
                                locationName,
                              );
                              Navigator.pop(context);
                            }
                          },
                          child: Text('Переместить ($selectedCount)'),
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

// ========== ENHANCED OBJECTS LIST SCREEN WITH MULTI-SELECTION ==========
class EnhancedObjectsListScreen extends StatefulWidget {
  const EnhancedObjectsListScreen({Key? key}) : super(key: key);

  @override
  _EnhancedObjectsListScreenState createState() =>
      _EnhancedObjectsListScreenState();
}

class _EnhancedObjectsListScreenState extends State<EnhancedObjectsListScreen> {
  @override
  Widget build(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: objectsProvider.selectionMode
          ? MultiSelectionAppBar(
              title: 'Объекты',
              selectedCount: objectsProvider.selectedObjects.length,
              onSelectAll: () => objectsProvider.selectAllObjects(),
              onClearSelection: () => objectsProvider.toggleSelectionMode(),
              onDelete: () => _showMultiDeleteDialog(context),
              isToolSelection: false,
            )
          : AppBar(
              title: Text('Объекты'),
              actions: [
                if (objectsProvider.objects.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.checklist),
                    onPressed: () => objectsProvider.toggleSelectionMode(),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    final parts = value.split('_');
                    objectsProvider.setSort(parts[0], parts[1] == 'asc');
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'name_asc',
                      child: Text('По имени (А-Я)'),
                    ),
                    PopupMenuItem(
                      value: 'name_desc',
                      child: Text('По имени (Я-А)'),
                    ),
                    PopupMenuItem(
                      value: 'date_asc',
                      child: Text('По дате (старые)'),
                    ),
                    PopupMenuItem(
                      value: 'date_desc',
                      child: Text('По дате (новые)'),
                    ),
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

                  return SelectionObjectCard(
                    object: object,
                    toolCount: toolCount,
                    selectionMode: objectsProvider.selectionMode,
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
                    onLongPress: () {
                      if (!objectsProvider.selectionMode) {
                        objectsProvider.toggleSelectionMode();
                        objectsProvider.selectObject(object.id);
                      }
                    },
                  );
                },
              ),
            ),
      floatingActionButton: !objectsProvider.selectionMode
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditObjectScreen(),
                  ),
                );
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  void _showMultiDeleteDialog(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );
    final selectedCount = objectsProvider.selectedObjects.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удаление объектов'),
        content: Text(
          'Вы уверены, что хотите удалить выбранные $selectedCount объектов? Это действие нельзя отменить.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await objectsProvider.deleteSelectedObjects();
            },
            child: Text(
              'Удалить ($selectedCount)',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== UPDATED MAIN SCREEN ==========
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

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
    EnhancedGarageScreen(),
    ToolsListScreen(),
    EnhancedObjectsListScreen(),
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
  const MyApp({Key? key}) : super(key: key);

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

                    // Check if welcome screen should be shown
                    final seenWelcome = prefs.getBool('seen_welcome') ?? false;
                    if (!seenWelcome) {
                      return WelcomeScreen(
                        onContinue: () async {
                          await prefs.setBool('seen_welcome', true);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AuthScreen(),
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
