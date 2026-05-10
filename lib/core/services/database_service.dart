import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed local store.
/// All public methods are no-ops on web (kIsWeb) since sqflite is not
/// supported there — Firestore's own offline cache covers that platform.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;

  Future<Database?> get _database async {
    if (kIsWeb) return null;
    _db ??= await _init();
    return _db;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'tooler_local.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tools (
        id TEXT PRIMARY KEY,
        updated_at TEXT,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE objects (
        id TEXT PRIMARY KEY,
        updated_at TEXT,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE move_requests (
        id TEXT PRIMARY KEY,
        status TEXT,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE batch_move_requests (
        id TEXT PRIMARY KEY,
        status TEXT,
        data TEXT NOT NULL
      )
    ''');
  }

  // ── Tools ──────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTools() async {
    final db = await _database;
    if (db == null) return [];
    final rows = await db.query('tools');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> upsertTool(Map<String, dynamic> data) async {
    final db = await _database;
    if (db == null) return;
    await db.insert(
      'tools',
      {
        'id': data['id'],
        'updated_at': data['updatedAt'],
        'data': jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTool(String id) async {
    final db = await _database;
    if (db == null) return;
    await db.delete('tools', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceAllTools(List<Map<String, dynamic>> tools) async {
    final db = await _database;
    if (db == null) return;
    await db.transaction((txn) async {
      await txn.delete('tools');
      for (final t in tools) {
        await txn.insert(
          'tools',
          {
            'id': t['id'],
            'updated_at': t['updatedAt'],
            'data': jsonEncode(t),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ── Objects ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getObjects() async {
    final db = await _database;
    if (db == null) return [];
    final rows = await db.query('objects');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> upsertObject(Map<String, dynamic> data) async {
    final db = await _database;
    if (db == null) return;
    await db.insert(
      'objects',
      {
        'id': data['id'],
        'updated_at': data['updatedAt'],
        'data': jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteObject(String id) async {
    final db = await _database;
    if (db == null) return;
    await db.delete('objects', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceAllObjects(List<Map<String, dynamic>> objects) async {
    final db = await _database;
    if (db == null) return;
    await db.transaction((txn) async {
      await txn.delete('objects');
      for (final o in objects) {
        await txn.insert(
          'objects',
          {
            'id': o['id'],
            'updated_at': o['updatedAt'],
            'data': jsonEncode(o),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ── Move Requests ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMoveRequests() async {
    final db = await _database;
    if (db == null) return [];
    final rows = await db.query('move_requests');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> upsertMoveRequest(Map<String, dynamic> data) async {
    final db = await _database;
    if (db == null) return;
    await db.insert(
      'move_requests',
      {
        'id': data['id'],
        'status': data['status'],
        'data': jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMoveRequest(String id) async {
    final db = await _database;
    if (db == null) return;
    await db.delete('move_requests', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceAllMoveRequests(
      List<Map<String, dynamic>> requests) async {
    final db = await _database;
    if (db == null) return;
    await db.transaction((txn) async {
      await txn.delete('move_requests');
      for (final r in requests) {
        await txn.insert(
          'move_requests',
          {
            'id': r['id'],
            'status': r['status'],
            'data': jsonEncode(r),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ── Batch Move Requests ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBatchMoveRequests() async {
    final db = await _database;
    if (db == null) return [];
    final rows = await db.query('batch_move_requests');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> upsertBatchMoveRequest(Map<String, dynamic> data) async {
    final db = await _database;
    if (db == null) return;
    await db.insert(
      'batch_move_requests',
      {
        'id': data['id'],
        'status': data['status'],
        'data': jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBatchMoveRequest(String id) async {
    final db = await _database;
    if (db == null) return;
    await db.delete('batch_move_requests', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceAllBatchMoveRequests(
      List<Map<String, dynamic>> requests) async {
    final db = await _database;
    if (db == null) return;
    await db.transaction((txn) async {
      await txn.delete('batch_move_requests');
      for (final r in requests) {
        await txn.insert(
          'batch_move_requests',
          {
            'id': r['id'],
            'status': r['status'],
            'data': jsonEncode(r),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
