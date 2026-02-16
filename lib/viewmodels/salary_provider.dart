// ignore_for_file: unused_field

/// SalaryProvider - Provider for salaries, advances, penalties, attendance, daily reports

import 'package:flutter/material.dart';
import '../data/models/salary.dart';
import '../data/models/attendance.dart';
import '../data/repositories/local_database.dart';

class SalaryProvider with ChangeNotifier {
  List<SalaryEntry> _salaries = [];
  List<Advance> _advances = [];
  List<Penalty> _penalties = [];
  // NEW: Attendance and daily reports
  List<Attendance> _attendances = [];
  List<DailyWorkReport> _dailyReports = [];

  Future<void> loadData() async {
    await LocalDatabase.init();
    _salaries = LocalDatabase.salaries.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    _advances = LocalDatabase.advances.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    _penalties = LocalDatabase.penalties.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    _attendances = LocalDatabase.attendances.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    _dailyReports = LocalDatabase.dailyReports.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  List<SalaryEntry> getSalariesForWorker(String workerId, {DateTime? start, DateTime? end}) {
    var list = _salaries.where((s) => s.workerId == workerId).toList();
    if (start != null) list = list.where((s) => s.date.isAfter(start)).toList();
    if (end != null) list = list.where((s) => s.date.isBefore(end)).toList();
    return list;
  }

  List<Advance> getAdvancesForWorker(String workerId, {DateTime? start, DateTime? end}) {
    var list = _advances.where((a) => a.workerId == workerId).toList();
    if (start != null) list = list.where((a) => a.date.isAfter(start)).toList();
    if (end != null) list = list.where((a) => a.date.isBefore(end)).toList();
    return list;
  }

  List<Penalty> getPenaltiesForWorker(String workerId, {DateTime? start, DateTime? end}) {
    var list = _penalties.where((p) => p.workerId == workerId).toList();
    if (start != null) list = list.where((p) => p.date.isAfter(start)).toList();
    if (end != null) list = list.where((p) => p.date.isBefore(end)).toList();
    return list;
  }

  // NEW: Attendance methods
  List<Attendance> getAttendancesForWorker(String workerId, {DateTime? start, DateTime? end}) {
    var list = _attendances.where((a) => a.workerId == workerId).toList();
    if (start != null) list = list.where((a) => a.date.isAfter(start)).toList();
    if (end != null) list = list.where((a) => a.date.isBefore(end)).toList();
    return list;
  }

  List<Attendance> getAttendancesForObjectAndDate(String objectId, DateTime date) {
    // Not directly; need worker->object mapping. We'll handle in UI.
    return [];
  }

  Future<void> addAttendance(Attendance attendance) async {
    _attendances.add(attendance);
    await LocalDatabase.attendances.put(attendance.id, attendance);
    notifyListeners();
  }

  // Daily report methods
  Future<void> addDailyReport(DailyWorkReport report) async {
    _dailyReports.add(report);
    await LocalDatabase.dailyReports.put(report.id, report);
    notifyListeners();
  }

  Future<void> updateDailyReportStatus(String reportId, String status) async {
    final index = _dailyReports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _dailyReports[index] = DailyWorkReport(
        id: _dailyReports[index].id,
        objectId: _dailyReports[index].objectId,
        brigadierId: _dailyReports[index].brigadierId,
        date: _dailyReports[index].date,
        attendanceIds: _dailyReports[index].attendanceIds,
        status: status,
        submittedAt: _dailyReports[index].submittedAt,
      );
      await LocalDatabase.dailyReports.put(reportId, _dailyReports[index]);
      notifyListeners();
    }
  }

  List<DailyWorkReport> getPendingDailyReports() {
    return _dailyReports.where((r) => r.status == 'pending').toList();
  }

  Future<void> addSalary(SalaryEntry salary) async {
    _salaries.add(salary);
    await LocalDatabase.salaries.put(salary.id, salary);
    notifyListeners();
  }

  Future<void> addAdvance(Advance advance) async {
    _advances.add(advance);
    await LocalDatabase.advances.put(advance.id, advance);
    notifyListeners();
  }

  Future<void> addPenalty(Penalty penalty) async {
    _penalties.add(penalty);
    await LocalDatabase.penalties.put(penalty.id, penalty);
    notifyListeners();
  }

  Future<void> deleteSalary(String id) async {
    _salaries.removeWhere((s) => s.id == id);
    await LocalDatabase.salaries.delete(id);
    notifyListeners();
  }

  Future<void> deleteAdvance(String id) async {
    _advances.removeWhere((a) => a.id == id);
    await LocalDatabase.advances.delete(id);
    notifyListeners();
  }

  Future<void> deletePenalty(String id) async {
    _penalties.removeWhere((p) => p.id == id);
    await LocalDatabase.penalties.delete(id);
    notifyListeners();
  }
}
