import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/brigadier_request_model.dart';

class BrigadierRequestProvider with ChangeNotifier {
  final List<BrigadierRequest> _requests = [];
  bool _isLoading = false;

  List<BrigadierRequest> get requests => List.unmodifiable(_requests);
  List<BrigadierRequest> get pendingRequests =>
      _requests.where((r) => r.status == RequestStatus.pending).toList();
  List<BrigadierRequest> get approvedRequests =>
      _requests.where((r) => r.status == RequestStatus.approved).toList();
  List<BrigadierRequest> get rejectedRequests =>
      _requests.where((r) => r.status == RequestStatus.rejected).toList();
  bool get isLoading => _isLoading;

  Future<void> loadRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('brigadier_requests')
          .orderBy('createdAt', descending: true)
          .get();
      _requests.clear();
      for (final doc in snapshot.docs) {
        _requests.add(BrigadierRequest.fromJson({
          'id': doc.id,
          ...doc.data(),
        }));
      }
    } catch (e) {
      // Silent error handling
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createRequest({
    required String brigadierId,
    required String objectId,
    required RequestType type,
    required Map<String, dynamic> data,
    String? reason,
  }) async {
    try {
      final docRef =
          await FirebaseFirestore.instance.collection('brigadier_requests').add({
        'brigadierId': brigadierId,
        'objectId': objectId,
        'type': type.toString().split('.').last,
        'status': RequestStatus.pending.toString().split('.').last,
        'createdAt': DateTime.now().toIso8601String(),
        'data': data,
        'reason': reason,
      });

      _requests.insert(
        0,
        BrigadierRequest(
          id: docRef.id,
          brigadierId: brigadierId,
          objectId: objectId,
          type: type,
          status: RequestStatus.pending,
          createdAt: DateTime.now(),
          data: data,
          reason: reason,
        ),
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveRequest({
    required String requestId,
    required String adminId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('brigadier_requests')
          .doc(requestId)
          .update({
        'status': RequestStatus.approved.toString().split('.').last,
        'resolvedAt': DateTime.now().toIso8601String(),
        'resolvedBy': adminId,
      });

      final index = _requests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        final request = _requests[index];
        _requests[index] = BrigadierRequest(
          id: request.id,
          brigadierId: request.brigadierId,
          objectId: request.objectId,
          type: request.type,
          status: RequestStatus.approved,
          createdAt: request.createdAt,
          resolvedAt: DateTime.now(),
          resolvedBy: adminId,
          data: request.data,
          reason: request.reason,
        );
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectRequest({
    required String requestId,
    required String adminId,
    required String rejectionReason,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('brigadier_requests')
          .doc(requestId)
          .update({
        'status': RequestStatus.rejected.toString().split('.').last,
        'resolvedAt': DateTime.now().toIso8601String(),
        'resolvedBy': adminId,
        'rejectionReason': rejectionReason,
      });

      final index = _requests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        final request = _requests[index];
        _requests[index] = BrigadierRequest(
          id: request.id,
          brigadierId: request.brigadierId,
          objectId: request.objectId,
          type: request.type,
          status: RequestStatus.rejected,
          createdAt: request.createdAt,
          resolvedAt: DateTime.now(),
          resolvedBy: adminId,
          data: request.data,
          reason: request.reason,
          rejectionReason: rejectionReason,
        );
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  BrigadierRequest? getRequest(String requestId) {
    try {
      return _requests.firstWhere((r) => r.id == requestId);
    } catch (e) {
      return null;
    }
  }

  List<BrigadierRequest> getRequestsByBrigadier(String brigadierId) {
    return _requests.where((r) => r.brigadierId == brigadierId).toList();
  }

  List<BrigadierRequest> getRequestsByObject(String objectId) {
    return _requests.where((r) => r.objectId == objectId).toList();
  }
}
