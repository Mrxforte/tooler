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
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      // onOpen runs after the DB is fully opened. execute() works here for
      // PRAGMAs that don't return rows. journal_mode=WAL is intentionally
      // omitted — it returns a result row and crashes sqflite on Android.
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    try {
      await db.execute('PRAGMA synchronous=NORMAL');
      await db.execute('PRAGMA cache_size=-8000');
      await db.execute('PRAGMA temp_store=MEMORY');
    } catch (_) {}
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
    return _decodeRows(rows);
  }

  Future<void> upsertTool(Map<String, dynamic> data) async {
    final db = await _database;
    if (db == null) return;
    await db.insert(
      'tools',
      {'id': data['id'], 'updated_at': data['updatedAt'], 'data': jsonEncode(data)},
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
    final batch = db.batch();
    batch.delete('tools');
    for (final t in tools) {
      batch.insert(
        'tools',
        {'id': t['id'], 'updated_at': t['updatedAt'], 'data': jsonEncode(t)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ── Objects ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getObjects() async {
    final db = await _database;
    if (db == null) return [];
    final rows = await db.query('objects');
    return _decodeRows(rows);
  }

  Future<void> upsertObject(Map<String, dynamic> data) async {
    final db = await _database;
    if (db == null) return;
    await db.insert(
      'objects',
      {'id': data['id'], 'updated_at': data['updatedAt'], 'data': jsonEncode(data)},
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
    final batch = db.batch();
    batch.delete('objects');
    for (final o in objects) {
      batch.insert(
        'objects',
        {'id': o['id'], 'updated_at': o['updatedAt'], 'data': jsonEncode(o)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ── Move Requests ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMoveRequests() async {
    final db = await _database;
    if (db == null) return [];
    final rows = await db.query('move_requests');
    return _decodeRows(rows);
  }

  Future<void> upsertMoveRequest(Map<String, dynamic> data) async {
    final db = await _database;
    if (db == null) return;
    await db.insert(
      'move_requests',
      {'id': data['id'], 'status': data['status'], 'data': jsonEncode(data)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMoveRequest(String id) async {
    final db = await _database;
    if (db == null) return;
    await db.delete('move_requests', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceAllMoveRequests(List<Map<String, dynamic>> requests) async {
    final db = await _database;
    if (db == null) return;
    final batch = db.batch();
    batch.delete('move_requests');
    for (final r in requests) {
      batch.insert(
        'move_requests',
        {'id': r['id'], 'status': r['status'], 'data': jsonEncode(r)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ── Batch Move Requests ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBatchMoveRequests() async {
    final db = await _database;
    if (db == null) return [];
    final rows = await db.query('batch_move_requests');
    return _decodeRows(rows);
  }

  Future<void> upsertBatchMoveRequest(Map<String, dynamic> data) async {
    final db = await _database;
    if (db == null) return;
    await db.insert(
      'batch_move_requests',
      {'id': data['id'], 'status': data['status'], 'data': jsonEncode(data)},
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
    final batch = db.batch();
    batch.delete('batch_move_requests');
    for (final r in requests) {
      batch.insert(
        'batch_move_requests',
        {'id': r['id'], 'status': r['status'], 'data': jsonEncode(r)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _decodeRows(List<Map<String, dynamic>> rows) {
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      try {
        result.add(jsonDecode(row['data'] as String) as Map<String, dynamic>);
      } catch (_) {}
    }
    return result;
  }
}
