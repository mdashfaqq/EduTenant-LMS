import '../database_helper.dart';
import '../models/user_model.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for User operations with multi-tenant support
class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert or update user
  Future<int> saveUser(UserModel user) async {
    final db = await _dbHelper.database;
    final userWithSync = user.toMap();
    userWithSync['last_sync'] = DateTime.now().toIso8601String();
    userWithSync['sync_status'] = 1;
    return await db.insert(
      'users',
      userWithSync,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get users by institution code
  Future<List<UserModel>> getUsersByInstitution(String institutionCode) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'institution_code = ?',
      whereArgs: [institutionCode],
    );
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }

  /// Get users by role and institution
  Future<List<UserModel>> getUsersByRole(
    String institutionCode,
    String role,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'institution_code = ? AND role = ?',
      whereArgs: [institutionCode, role],
    );
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }

  /// Get user by ID and institution
  Future<UserModel?> getUserById(String institutionCode, int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'institution_code = ? AND id = ?',
      whereArgs: [institutionCode, userId],
    );

    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  /// Update user
  Future<int> updateUser(UserModel user) async {
    final db = await _dbHelper.database;
    final userWithSync = user.toMap();
    userWithSync['last_sync'] = DateTime.now().toIso8601String();
    userWithSync['sync_status'] = 0;
    return await db.update(
      'users',
      userWithSync,
      where: 'institution_code = ? AND id = ?',
      whereArgs: [user.institutionCode, user.id],
    );
  }

  /// Delete user
  Future<int> deleteUser(String institutionCode, int userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'users',
      where: 'institution_code = ? AND id = ?',
      whereArgs: [institutionCode, userId],
    );
  }

  /// Search users by name or email
  Future<List<UserModel>> searchUsers(
    String institutionCode,
    String query,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'institution_code = ? AND (name LIKE ? OR email LIKE ?)',
      whereArgs: [institutionCode, '%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }
}
