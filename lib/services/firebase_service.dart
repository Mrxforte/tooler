import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tool_object.dart';
import '../models/tool.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Objects Collection
  CollectionReference get _objectsCollection =>
      _firestore.collection('objects');
  CollectionReference get _toolsCollection => _firestore.collection('tools');

  // CRUD for Objects
  Future<String> createObject(ToolObject object) async {
    final doc = await _objectsCollection.add(object.toMap());
    return doc.id;
  }

  Stream<List<ToolObject>> getObjects() {
    return _objectsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ToolObject.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  Future<void> updateObject(ToolObject object) async {
    await _objectsCollection.doc(object.id).update(object.toMap());
  }

  Future<void> deleteObject(String objectId) async {
    // Delete all tools in this object first
    final tools = await _toolsCollection
        .where('objectId', isEqualTo: objectId)
        .get();
    for (var doc in tools.docs) {
      await doc.reference.delete();
    }
    await _objectsCollection.doc(objectId).delete();
  }

  // CRUD for Tools
  Future<String> createTool(Tool tool) async {
    final doc = await _toolsCollection.add(tool.toMap());
    return doc.id;
  }

  Stream<List<Tool>> getToolsByObject(String objectId) {
    return _toolsCollection
        .where('objectId', isEqualTo: objectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Tool.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  Future<void> updateTool(Tool tool) async {
    await _toolsCollection.doc(tool.id).update(tool.toMap());
  }

  Future<void> deleteTool(String toolId) async {
    await _toolsCollection.doc(toolId).delete();
  }

  Future<void> moveTool(String toolId, String newObjectId) async {
    await _toolsCollection.doc(toolId).update({'objectId': newObjectId});
  }
}
