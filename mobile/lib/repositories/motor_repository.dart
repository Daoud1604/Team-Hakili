import '../database/database_helper.dart';
import '../models/motor.dart';

class MotorRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createMotor(Motor motor) async {
    final db = await _dbHelper.database;
    return await db.insert('motors', motor.toMap());
  }

  Future<List<Motor>> getAllMotors() async {
    final db = await _dbHelper.database;
    final maps = await db.query('motors', orderBy: 'name ASC');
    return maps.map((map) => Motor.fromMap(map)).toList();
  }

  Future<Motor?> getMotorById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'motors',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Motor.fromMap(maps.first);
  }

  Future<Motor?> getMotorByCode(String code) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'motors',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Motor.fromMap(maps.first);
  }

  Future<int> updateMotor(Motor motor) async {
    final db = await _dbHelper.database;
    return await db.update(
      'motors',
      motor.toMap(),
      where: 'id = ?',
      whereArgs: [motor.id],
    );
  }

  Future<int> deleteMotor(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('motors', where: 'id = ?', whereArgs: [id]);
  }
}
