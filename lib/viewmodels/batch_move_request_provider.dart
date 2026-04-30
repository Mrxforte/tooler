// ignore_for_file: unused_field

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/models/move_request.dart';
import '../core/utils/id_generator.dart';

class BatchMoveRequestProvider with ChangeNotifier {
  final List<BatchMoveRequest> _requests = [];
  bool _isLoading = false;

  List<BatchMoveRequest> get requests => List.unmodifiable(_requests);
  List<BatchMoveRequest> get pendingRequests =>
      _requests.where((r) => r.status == 'pending').toList();
  bool get isLoading => _isLoading;

  static const _collection = 'batch_move_requests';

  Future<void> loadRequests({String? userId}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      Query query = FirebaseFirestore.instance
          .collection(_collection)
          .orderBy('timestamp', descending: true);
      if (userId != null) {
        query = query.where('requestedBy', isEqualTo: userId);
      }
      final snapshot =
          await query.get().timeout(const Duration(seconds: 15));
      _requests.clear();
      for (final doc in snapshot.docs) {
        try {
          _requests.add(
              BatchMoveRequest.fromJson(doc.data() as Map<String, dynamic>));
        } catch (_) {}
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createRequest({
    required List<String> toolIds,
    required String fromLocationId,
    required String fromLocationName,
    required String toLocationId,
    required String toLocationName,
    required String requestedBy,
  }) async {
    final request = BatchMoveRequest(
      id: IdGenerator.generateBatchRequestId(),
      toolIds: toolIds,
      fromLocationId: fromLocationId,
      fromLocationName: fromLocationName,
      toLocationId: toLocationId,
      toLocationName: toLocationName,
      requestedBy: requestedBy,
      status: 'pending',
    );
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(request.id)
        .set(request.toJson(), SetOptions(merge: true))
        .timeout(const Duration(seconds: 15));
    _requests.insert(0, request);
    notifyListeners();
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(requestId)
        .update({'status': status}).timeout(const Duration(seconds: 15));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final r = _requests[index];
      _requests[index] = BatchMoveRequest(
        id: r.id,
        toolIds: r.toolIds,
        fromLocationId: r.fromLocationId,
        fromLocationName: r.fromLocationName,
        toLocationId: r.toLocationId,
        toLocationName: r.toLocationName,
        requestedBy: r.requestedBy,
        status: status,
        timestamp: r.timestamp,
      );
      notifyListeners();
    }
  }

  Future<void> deleteRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(requestId)
        .delete()
        .timeout(const Duration(seconds: 15));
    _requests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }
}
