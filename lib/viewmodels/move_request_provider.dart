/// MoveRequestProvider - Extract from main.dart lines 2131-2173
/// Provider for single tool move requests

import 'package:flutter/material.dart';

class MoveRequestProvider with ChangeNotifier {
  // TODO: Extract full implementation from main.dart lines 2131-2173
  
  List<dynamic> _requests = [];

  List<dynamic> get pendingRequests => [];

  Future<void> loadRequests() async {
    throw UnimplementedError('Extract from main.dart lines 2131-2173');
  }

  Future<void> createRequest(dynamic request) async {
    throw UnimplementedError();
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    throw UnimplementedError();
  }
}
