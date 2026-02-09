import 'package:flutter/material.dart';
import '../models/tool_object.dart';
import '../services/firebase_service.dart';

class ObjectProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<ToolObject> _objects = [];

  List<ToolObject> get objects => _objects;

  void listenToObjects() {
    _firebaseService.getObjects().listen((objects) {
      _objects = objects;
      notifyListeners();
    });
  }

  Future<void> addObject(String name, String description) async {
    final object = ToolObject(
      id: '',
      name: name,
      description: description,
      createdAt: DateTime.now(),
    );
    await _firebaseService.createObject(object);
  }

  Future<void> updateObject(ToolObject object) async {
    await _firebaseService.updateObject(object);
  }

  Future<void> deleteObject(String objectId) async {
    await _firebaseService.deleteObject(objectId);
  }
}
