import '../database_helper.dart';
import '../models/course_model.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for Course operations with multi-tenant support
class CourseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert or update course
  Future<int> saveCourse(CourseModel course) async {
    final db = await _dbHelper.database;
    final courseWithSync = course.toMap();
    courseWithSync['last_sync'] = DateTime.now().toIso8601String();
    courseWithSync['sync_status'] = 1;
    return await db.insert(
      'courses',
      courseWithSync,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get courses by institution code
  Future<List<CourseModel>> getCoursesByInstitution(
    String institutionCode,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      where: 'institution_code = ?',
      whereArgs: [institutionCode],
    );
    return List.generate(maps.length, (i) => CourseModel.fromMap(maps[i]));
  }

  /// Get course by ID and institution
  Future<CourseModel?> getCourseById(
    String institutionCode,
    int courseId,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      where: 'institution_code = ? AND id = ?',
      whereArgs: [institutionCode, courseId],
    );

    if (maps.isEmpty) return null;
    return CourseModel.fromMap(maps.first);
  }

  /// Get courses by instructor
  Future<List<CourseModel>> getCoursesByInstructor(
    String institutionCode,
    int instructorId,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      where: 'institution_code = ? AND instructor_id = ?',
      whereArgs: [institutionCode, instructorId],
    );
    return List.generate(maps.length, (i) => CourseModel.fromMap(maps[i]));
  }

  /// Update course
  Future<int> updateCourse(CourseModel course) async {
    final db = await _dbHelper.database;
    final courseWithSync = course.toMap();
    courseWithSync['last_sync'] = DateTime.now().toIso8601String();
    courseWithSync['sync_status'] = 0;
    return await db.update(
      'courses',
      courseWithSync,
      where: 'institution_code = ? AND id = ?',
      whereArgs: [course.institutionCode, course.id],
    );
  }

  /// Delete course
  Future<int> deleteCourse(String institutionCode, int courseId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'courses',
      where: 'institution_code = ? AND id = ?',
      whereArgs: [institutionCode, courseId],
    );
  }
}
