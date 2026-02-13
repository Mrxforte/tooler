import 'package:hive_flutter/hive_flutter.dart';
import '../models/tool.dart';
import '../models/location_history.dart';
import '../models/construction_object.dart';
import '../models/sync_item.dart';

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
