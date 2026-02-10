// main.dart - Complete Tooler Construction Tool Management App
// ignore_for_file: empty_catches, avoid_print, library_private_types_in_public_api, deprecated_member_use, duplicate_ignore, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:tooler/firebase_options.dart';

// ========== FIREBASE INITIALIZATION ==========
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

// ========== DATA MODELS ==========
class Tool {
  String id;
  String title;
  String description;
  String brand;
  String uniqueId;
  String? imagePath;
  String currentObjectId;
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
    this.imagePath,
    required this.currentObjectId,
    List<LocationHistory>? locationHistory,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : locationHistory = locationHistory ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    brand: json['brand'],
    uniqueId: json['uniqueId'],
    imagePath: json['imagePath'],
    currentObjectId: json['currentObjectId'],
    locationHistory:
        (json['locationHistory'] as List?)
            ?.map((e) => LocationHistory.fromJson(e))
            .toList() ??
        [],
    isFavorite: json['isFavorite'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'brand': brand,
    'uniqueId': uniqueId,
    'imagePath': imagePath,
    'currentObjectId': currentObjectId,
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
    imagePath: imagePath,
    currentObjectId: currentObjectId,
    locationHistory: List.from(locationHistory),
    isFavorite: isFavorite,
  );
}

class LocationHistory {
  DateTime date;
  String objectId;
  String objectName;

  LocationHistory({
    required this.date,
    required this.objectId,
    required this.objectName,
  });

  factory LocationHistory.fromJson(Map<String, dynamic> json) =>
      LocationHistory(
        date: DateTime.parse(json['date']),
        objectId: json['objectId'],
        objectName: json['objectName'],
      );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'objectId': objectId,
    'objectName': objectName,
  };
}

class ConstructionObject {
  String id;
  String name;
  String description;
  String? imagePath;
  List<String> toolIds;
  DateTime createdAt;
  DateTime updatedAt;

  ConstructionObject({
    required this.id,
    required this.name,
    required this.description,
    this.imagePath,
    List<String>? toolIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : toolIds = toolIds ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ConstructionObject.fromJson(Map<String, dynamic> json) =>
      ConstructionObject(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        imagePath: json['imagePath'],
        toolIds: List<String>.from(json['toolIds'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imagePath': imagePath,
    'toolIds': toolIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

// ========== LOCAL DATABASE (HIVE) ==========
class LocalDatabase {
  static const String toolsBox = 'tools';
  static const String objectsBox = 'objects';
  static const String syncQueueBox = 'sync_queue';

  static Future<void> init() async {
    await Hive.openBox<Tool>(toolsBox);
    await Hive.openBox<ConstructionObject>(objectsBox);
    await Hive.openBox<SyncItem>(syncQueueBox);
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

// ========== STATE MANAGEMENT PROVIDERS ==========
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}

class ToolsProvider with ChangeNotifier {
  final List<Tool> _tools = [];
  List<Tool> get tools => _tools;
  List<Tool> get favoriteTools => _tools.where((t) => t.isFavorite).toList();

  Future<void> loadTools() async {
    // Load from local DB
    _tools.clear();
    _tools.addAll(LocalDatabase.tools.values);

    // Try to sync with Firebase if online
    await _syncWithFirebase();

    notifyListeners();
  }

  Future<void> addTool(Tool tool) async {
    _tools.add(tool);
    await LocalDatabase.tools.put(tool.id, tool);

    // Add to sync queue
    await _addToSyncQueue(
      action: 'create',
      collection: 'tools',
      data: tool.toJson(),
    );

    notifyListeners();
  }

  Future<void> updateTool(Tool tool) async {
    final index = _tools.indexWhere((t) => t.id == tool.id);
    if (index != -1) {
      _tools[index] = tool;
      await LocalDatabase.tools.put(tool.id, tool);

      await _addToSyncQueue(
        action: 'update',
        collection: 'tools',
        data: tool.toJson(),
      );

      notifyListeners();
    }
  }

  Future<void> deleteTool(String toolId) async {
    _tools.removeWhere((t) => t.id == toolId);
    await LocalDatabase.tools.delete(toolId);

    await _addToSyncQueue(
      action: 'delete',
      collection: 'tools',
      data: {'id': toolId},
    );

    notifyListeners();
  }

  Future<void> duplicateTool(Tool original) async {
    final newTool = original.duplicate();
    await addTool(newTool);
  }

  Future<void> moveTool(
    String toolId,
    String newObjectId,
    String newObjectName,
  ) async {
    final tool = _tools.firstWhere((t) => t.id == toolId);
    tool.locationHistory.add(
      LocationHistory(
        date: DateTime.now(),
        objectId: tool.currentObjectId,
        objectName: 'Previous Location',
      ),
    );
    tool.currentObjectId = newObjectId;
    tool.updatedAt = DateTime.now();

    await updateTool(tool);
  }

  Future<void> toggleFavorite(String toolId) async {
    final tool = _tools.firstWhere((t) => t.id == toolId);
    tool.isFavorite = !tool.isFavorite;
    await updateTool(tool);
  }

  Future<void> _addToSyncQueue({
    required String action,
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final syncItem = SyncItem(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      action: action,
      collection: collection,
      data: data,
    );
    await LocalDatabase.syncQueue.put(syncItem.id, syncItem);
  }

  Future<void> _syncWithFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final syncItems = LocalDatabase.syncQueue.values.toList();

      for (final item in syncItems) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection(item.collection)
            .doc(item.data['id']);

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
    } catch (e) {}
  }
}

class ObjectsProvider with ChangeNotifier {
  final List<ConstructionObject> _objects = [];
  List<ConstructionObject> get objects => _objects;

  Future<void> loadObjects() async {
    _objects.clear();
    _objects.addAll(LocalDatabase.objects.values);
    notifyListeners();
  }

  Future<void> addObject(ConstructionObject obj) async {
    _objects.add(obj);
    await LocalDatabase.objects.put(obj.id, obj);

    await _addToSyncQueue(
      action: 'create',
      collection: 'objects',
      data: obj.toJson(),
    );

    notifyListeners();
  }

  Future<void> updateObject(ConstructionObject obj) async {
    final index = _objects.indexWhere((o) => o.id == obj.id);
    if (index != -1) {
      _objects[index] = obj;
      await LocalDatabase.objects.put(obj.id, obj);

      await _addToSyncQueue(
        action: 'update',
        collection: 'objects',
        data: obj.toJson(),
      );

      notifyListeners();
    }
  }

  Future<void> deleteObject(String objectId) async {
    _objects.removeWhere((o) => o.id == objectId);
    await LocalDatabase.objects.delete(objectId);

    await _addToSyncQueue(
      action: 'delete',
      collection: 'objects',
      data: {'id': objectId},
    );

    notifyListeners();
  }

  Future<void> addToolsToObject(String objectId, List<String> toolIds) async {
    final object = _objects.firstWhere((o) => o.id == objectId);
    object.toolIds.addAll(toolIds);
    object.toolIds = object.toolIds.toSet().toList(); // Remove duplicates
    await updateObject(object);
  }

  Future<void> removeToolsFromObject(
    String objectId,
    List<String> toolIds,
  ) async {
    final object = _objects.firstWhere((o) => o.id == objectId);
    object.toolIds.removeWhere((id) => toolIds.contains(id));
    await updateObject(object);
  }

  Future<void> _addToSyncQueue({
    required String action,
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final syncItem = SyncItem(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      action: action,
      collection: collection,
      data: data,
    );
    await LocalDatabase.syncQueue.put(syncItem.id, syncItem);
  }
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}

// ========== PDF EXPORT SERVICE ==========
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
                  'Tool Inventory Report',
                  style: pw.TextStyle(fontSize: 24),
                ),
              ),
              pw.SizedBox(height: 20),
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  ['ID', 'Tool Name', 'Brand', 'Current Location', 'Status'],
                  ...tools.map(
                    (tool) => [
                      tool.uniqueId,
                      tool.title,
                      tool.brand,
                      tool.currentObjectId,
                      tool.isFavorite ? 'Favorite' : 'Available',
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
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

// ========== WIDGETS ==========
class ToolCard extends StatelessWidget {
  final Tool tool;
  final VoidCallback? onTap;
  final bool isDraggable;
  final VoidCallback? onFavoriteToggle;

  const ToolCard({
    super.key,
    required this.tool,
    this.onTap,
    this.isDraggable = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
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
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      tool.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: tool.isFavorite ? Colors.red : null,
                    ),
                    onPressed: onFavoriteToggle,
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(tool.brand, style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: 4),
              Text(
                'ID: ${tool.uniqueId}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
  final bool isDropTarget;

  const ObjectCard({
    super.key,
    required this.object,
    required this.toolCount,
    this.onTap,
    this.isDropTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: isDropTarget ? Colors.blue[50] : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                object.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                object.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.build, size: 16),
                  SizedBox(width: 4),
                  Text('Tools: $toolCount'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DragDropToolMovement extends StatefulWidget {
  final List<Tool> tools;
  final List<ConstructionObject> objects;
  final Function(String, String) onToolMoved;

  const DragDropToolMovement({
    super.key,
    required this.tools,
    required this.objects,
    required this.onToolMoved,
  });

  @override
  _DragDropToolMovementState createState() => _DragDropToolMovementState();
}

class _DragDropToolMovementState extends State<DragDropToolMovement> {
  String? _hoveredObjectId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tools Grid
        Expanded(
          flex: 2,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemCount: widget.tools.length,
            itemBuilder: (context, index) {
              final tool = widget.tools[index];
              return Draggable<String>(
                data: tool.id,
                feedback: Material(
                  elevation: 4,
                  child: Container(
                    width: 150,
                    height: 100,
                    color: Colors.white,
                    child: Center(child: Text(tool.title)),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.5,
                  child: ToolCard(tool: tool),
                ),
                onDragStarted: () {
                  setState(() {});
                },
                onDragEnd: (details) {
                  setState(() {
                    _hoveredObjectId = null;
                  });
                },
                child: ToolCard(tool: tool),
              );
            },
          ),
        ),

        SizedBox(height: 20),

        // Objects Grid (Drop Targets)
        Expanded(
          flex: 3,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemCount: widget.objects.length,
            itemBuilder: (context, index) {
              final object = widget.objects[index];
              final toolCount = widget.tools
                  .where((t) => t.currentObjectId == object.id)
                  .length;

              return DragTarget<String>(
                builder: (context, candidateData, rejectedData) {
                  return ObjectCard(
                    object: object,
                    toolCount: toolCount,
                    isDropTarget: _hoveredObjectId == object.id,
                  );
                },
                onWillAccept: (data) => true,
                onAccept: (toolId) {
                  widget.onToolMoved(toolId, object.id);
                },
                onLeave: (data) {
                  setState(() {
                    _hoveredObjectId = null;
                  });
                },
                onMove: (details) {
                  setState(() {
                    _hoveredObjectId = object.id;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ========== SCREENS ==========
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Welcome to Tooler',
      'description': 'Manage your construction tools efficiently',
      'image': Icons.build_circle,
    },
    {
      'title': 'Track Tools',
      'description': 'Move tools between construction objects',
      'image': Icons.move_to_inbox,
    },
    {
      'title': 'Work Offline',
      'description': 'Sync data when internet is available',
      'image': Icons.cloud_off,
    },
    {
      'title': 'Export & Share',
      'description': 'Create PDF reports and share inventory',
      'image': Icons.share,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
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
                      Icon(
                        _pages[index]['image'],
                        size: 100,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(height: 40),
                      Text(
                        _pages[index]['title'],
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        _pages[index]['description'],
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
              _pages.length,
              (index) => Container(
                margin: EdgeInsets.all(4),
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
                    child: Text('Back'),
                  ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AuthScreen()),
                      );
                    } else {
                      _controller.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  ),
                ),
              ],
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  'Construction Tool Management',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _authenticate,
                      child: Text(_isLogin ? 'Sign In' : 'Sign Up'),
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
                        ? 'Don\'t have an account? Sign Up'
                        : 'Already have an account? Sign In',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLogin
                ? 'Sign in failed. Check your credentials.'
                : 'Sign up failed. Try again.',
          ),
        ),
      );
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    ToolsListScreen(),
    ObjectsListScreen(),
    MoveToolsScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tooler'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // TODarch
            },
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PDFPreviewScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // TOD
              },
              child: Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Tools'),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city),
            label: 'Objects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.move_to_inbox),
            label: 'Move',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
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
      body: toolsProvider.tools.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text(
                    'No tools yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Add your first tool to get started',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: toolsProvider.tools.length,
              itemBuilder: (context, index) {
                final tool = toolsProvider.tools[index];
                return ToolCard(
                  tool: tool,
                  onTap: () {
                    // TODtool detail
                  },
                  onFavoriteToggle: () {
                    toolsProvider.toggleFavorite(tool.id);
                  },
                );
              },
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
      body: objectsProvider.objects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_city, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text(
                    'No construction objects',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Add your first construction site',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: objectsProvider.objects.length,
              itemBuilder: (context, index) {
                final object = objectsProvider.objects[index];
                final toolCount = toolsProvider.tools
                    .where((t) => t.currentObjectId == object.id)
                    .length;

                return ObjectCard(
                  object: object,
                  toolCount: toolCount,
                  onTap: () {
                    // TODobject detail
                  },
                );
              },
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
      appBar: AppBar(title: Text('Move Tools')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DragDropToolMovement(
          tools: toolsProvider.tools,
          objects: objectsProvider.objects,
          onToolMoved: (toolId, objectId) async {
            final object = objectsProvider.objects.firstWhere(
              (o) => o.id == objectId,
            );

            await toolsProvider.moveTool(toolId, objectId, object.name);

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Tool moved successfully')));
          },
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Favorite Tools')),
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
                    'No favorite tools',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Mark tools as favorites to see them here',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: toolsProvider.favoriteTools.length,
              itemBuilder: (context, index) {
                final tool = toolsProvider.favoriteTools[index];
                return ToolCard(
                  tool: tool,
                  onFavoriteToggle: () {
                    toolsProvider.toggleFavorite(tool.id);
                  },
                );
              },
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
      appBar: AppBar(title: Text('Profile')),
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(authProvider.user?.email ?? 'Guest'),
            accountEmail: Text('Construction Manager'),
            currentAccountPicture: CircleAvatar(child: Icon(Icons.person)),
          ),
          SwitchListTile(
            title: Text('Dark Mode'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.setTheme(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Export to PDF'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PDFPreviewScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.screenshot),
            title: Text('Take Screenshot'),
            onTap: () async {
              final image = await ScreenshotService.capture();
              if (image != null) {
                // TODe screenshot
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Screenshot saved')));
              }
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign Out'),
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

class PDFPreviewScreen extends StatelessWidget {
  const PDFPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Preview'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () async {
              await PDFExportService.generateInventoryPDF(toolsProvider.tools);
              // TODare functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              final pdfBytes = await PDFExportService.generateInventoryPDF(
                toolsProvider.tools,
              );
              await Printing.layoutPdf(onLayout: (format) => pdfBytes);
            },
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: PDFExportService.generateInventoryPDF(toolsProvider.tools),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error generating PDF'));
          }

          return PdfPreview(build: (format) => snapshot.data!);
        },
      ),
    );
  }
}

// ========== MAIN APP WIDGET ==========
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ToolsProvider()),
        ChangeNotifierProvider(create: (_) => ObjectsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Tooler',
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeProvider.themeMode,
            home: FutureBuilder(
              future: LocalDatabase.init(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                return Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.user == null) {
                      return OnboardingScreen();
                    }

                    return MainScreen();
                  },
                );
              },
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
