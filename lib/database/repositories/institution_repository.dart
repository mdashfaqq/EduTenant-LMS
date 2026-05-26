import '../database_helper.dart';
import '../models/institution_model.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for Institution operations
class InstitutionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert or update institution
  Future<int> saveInstitution(InstitutionModel institution) async {
    final db = await _dbHelper.database;
    final institutionWithSync = institution.toMap();
    institutionWithSync['last_sync'] = DateTime.now().toIso8601String();
    institutionWithSync['sync_status'] = 1;
    return await db.insert(
      'institutions',
      institutionWithSync,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get institution by code
  Future<InstitutionModel?> getInstitutionByCode(String code) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'institutions',
      where: 'institution_code = ?',
      whereArgs: [code],
    );

    if (maps.isEmpty) return null;
    return InstitutionModel.fromMap(maps.first);
  }

  /// Get all institutions
  Future<List<InstitutionModel>> getAllInstitutions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('institutions');
    return List.generate(maps.length, (i) => InstitutionModel.fromMap(maps[i]));
  }

  /// Update institution
  Future<int> updateInstitution(InstitutionModel institution) async {
    final db = await _dbHelper.database;
    final institutionWithSync = institution.toMap();
    institutionWithSync['last_sync'] = DateTime.now().toIso8601String();
    institutionWithSync['sync_status'] = 0;
    return await db.update(
      'institutions',
      institutionWithSync,
      where: 'institution_code = ?',
      whereArgs: [institution.institutionCode],
    );
  }

  /// Delete institution
  Future<int> deleteInstitution(String code) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'institutions',
      where: 'institution_code = ?',
      whereArgs: [code],
    );
  }
}
