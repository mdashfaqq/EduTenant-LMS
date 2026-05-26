import '../database_helper.dart';
import '../models/attendance_model.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for Attendance operations with multi-tenant support
class AttendanceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Mark attendance
  Future<int> markAttendance(AttendanceModel attendance) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'attendance',
      attendance.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get attendance by class and institution
  Future<List<AttendanceModel>> getAttendanceByClass(
    String institutionCode,
    int classId,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance',
      where: 'institution_code = ? AND class_id = ?',
      whereArgs: [institutionCode, classId],
    );
    return List.generate(maps.length, (i) => AttendanceModel.fromMap(maps[i]));
  }

  /// Get attendance by student
  Future<List<AttendanceModel>> getAttendanceByStudent(
    String institutionCode,
    int studentId,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance',
      where: 'institution_code = ? AND student_id = ?',
      whereArgs: [institutionCode, studentId],
    );
    return List.generate(maps.length, (i) => AttendanceModel.fromMap(maps[i]));
  }

  /// Insert or update attendance record
  Future<int> saveAttendance(AttendanceModel attendance) async {
    final db = await _dbHelper.database;
    final attendanceWithSync = attendance.toMap();
    attendanceWithSync['last_sync'] = DateTime.now().toIso8601String();
    attendanceWithSync['sync_status'] = 1;
    return await db.insert(
      'attendance',
      attendanceWithSync,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update attendance record
  Future<int> updateAttendance(AttendanceModel attendance) async {
    final db = await _dbHelper.database;
    final attendanceWithSync = attendance.toMap();
    attendanceWithSync['last_sync'] = DateTime.now().toIso8601String();
    attendanceWithSync['sync_status'] = 0;
    return await db.update(
      'attendance',
      attendanceWithSync,
      where: 'institution_code = ? AND id = ?',
      whereArgs: [attendance.institutionCode, attendance.id],
    );
  }

  /// Delete attendance record
  Future<int> deleteAttendance(String institutionCode, int attendanceId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'attendance',
      where: 'institution_code = ? AND id = ?',
      whereArgs: [institutionCode, attendanceId],
    );
  }
}
