import 'package:hive/hive.dart';
import '../models/tool.dart';
import '../models/construction_object.dart';
import '../models/move_request.dart';
import '../models/notification.dart';
import '../models/worker.dart';
import '../models/salary.dart';
import '../models/attendance.dart';
import '../models/sync_item.dart';

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

class AttendanceAdapter extends TypeAdapter<Attendance> {
  @override
  final int typeId = 11;
  @override
  Attendance read(BinaryReader reader) => Attendance.fromJson(
      reader.readMap().map((key, value) => MapEntry(key.toString(), value)));
  @override
  void write(BinaryWriter writer, Attendance obj) => writer.writeMap(obj.toJson());
}

class DailyWorkReportAdapter extends TypeAdapter<DailyWorkReport> {
  @override
  final int typeId = 12;
  @override
  DailyWorkReport read(BinaryReader reader) => DailyWorkReport.fromJson(
      reader.readMap().map((key, value) => MapEntry(key.toString(), value)));
  @override
  void write(BinaryWriter writer, DailyWorkReport obj) =>
      writer.writeMap(obj.toJson());
}
