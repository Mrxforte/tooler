import 'package:flutter/material.dart';
import '../models/tool.dart';
import '../services/firebase_service.dart';

class ToolProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final _toolsByObject = <String, List<Tool>>{};

  List<Tool> getToolsForObject(String objectId) {
    return _toolsByObject[objectId] ?? [];
  }

  void listenToTools(String objectId) {
    _firebaseService.getToolsByObject(objectId).listen((tools) {
      _toolsByObject[objectId] = tools;
      notifyListeners();
    });
  }

  Future<void> addTool(
    String objectId,
    String name,
    String description,
    int quantity,
  ) async {
    final tool = Tool(
      id: '',
      objectId: objectId,
      name: name,
      description: description,
      quantity: quantity,
      createdAt: DateTime.now(),
    );
    await _firebaseService.createTool(tool);
  }

  Future<void> updateTool(Tool tool) async {
    await _firebaseService.updateTool(tool);
  }

  Future<void> deleteTool(String toolId) async {
    await _firebaseService.deleteTool(toolId);
  }

  Future<void> moveTool(String toolId, String newObjectId) async {
    await _firebaseService.moveTool(toolId, newObjectId);
  }
}
