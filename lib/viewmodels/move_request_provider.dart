// ignore_for_file: unused_field

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/models/move_request.dart';
import '../core/utils/id_generator.dart';
import '../core/services/database_service.dart';

class MoveRequestProvider with ChangeNotifier {
  final List<MoveRequest> _requests = [];
  bool _isLoading = false;

  List<MoveRequest> get requests => List.unmodifiable(_requests);
  List<MoveRequest> get pendingRequests =>
      _requests.where((r) => r.status == 'pending').toList();
  bool get isLoading => _isLoading;

  static const _collection = 'move_requests';

  Future<void> loadRequests({String? userId}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Show SQLite data immediately (works offline)
      final localRows = await DatabaseService.instance.getMoveRequests();
      if (localRows.isNotEmpty) {
        var filtered = List<Map<String, dynamic>>.from(localRows);
        if (userId != null) {
          filtered = filtered
              .where((r) => r['requestedBy'] == userId)
              .toList();
        }
        filtered.sort((a, b) {
          final at =
              DateTime.tryParse(a['timestamp'] as String? ?? '') ?? DateTime(0);
          final bt =
              DateTime.tryParse(b['timestamp'] as String? ?? '') ?? DateTime(0);
          return bt.compareTo(at);
        });
        _requests.clear();
        for (final row in filtered) {
          try { _requests.add(MoveRequest.fromJson(row)); } catch (_) {}
        }
        _isLoading = false;
        notifyListeners();
      }

      // 2. Sync from Firestore (updates SQLite + in-memory)
      Query query = FirebaseFirestore.instance
          .collection(_collection)
          .orderBy('timestamp', descending: true);
      if (userId != null) {
        query = query.where('requestedBy', isEqualTo: userId);
      }
      final snapshot = await query.get();
      final allData = snapshot.docs
          .map((d) => d.data() as Map<String, dynamic>)
          .toList();
      await DatabaseService.instance.replaceAllMoveRequests(allData);
      _requests.clear();
      for (final doc in snapshot.docs) {
        try {
          _requests.add(MoveRequest.fromJson(doc.data() as Map<String, dynamic>));
        } catch (_) {}
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createRequest({
    required String toolId,
    required String fromLocationId,
    required String fromLocationName,
    required String toLocationId,
    required String toLocationName,
    required String requestedBy,
  }) async {
    final request = MoveRequest(
      id: IdGenerator.generateRequestId(),
      toolId: toolId,
      fromLocationId: fromLocationId,
      fromLocationName: fromLocationName,
      toLocationId: toLocationId,
      toLocationName: toLocationName,
      requestedBy: requestedBy,
      status: 'pending',
    );
    // Write to SQLite first
    await DatabaseService.instance.upsertMoveRequest(request.toJson());
    // Write to Firestore (queued offline, auto-syncs when online)
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(request.id)
        .set(request.toJson(), SetOptions(merge: true));
    _requests.insert(0, request);
    notifyListeners();
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(requestId)
        .update({'status': status});
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final r = _requests[index];
      _requests[index] = MoveRequest(
        id: r.id,
        toolId: r.toolId,
        fromLocationId: r.fromLocationId,
        fromLocationName: r.fromLocationName,
        toLocationId: r.toLocationId,
        toLocationName: r.toLocationName,
        requestedBy: r.requestedBy,
        status: status,
        timestamp: r.timestamp,
      );
      // Update SQLite
      await DatabaseService.instance.upsertMoveRequest(_requests[index].toJson());
      notifyListeners();
    }
  }

  Future<void> deleteRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(requestId)
        .delete();
    await DatabaseService.instance.deleteMoveRequest(requestId);
    _requests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }
}
