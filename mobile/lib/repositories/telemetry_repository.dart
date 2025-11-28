import '../database/database_helper.dart';
import '../models/telemetry.dart';
import '../core/constants/app_constants.dart';

class TelemetryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createTelemetry(Telemetry telemetry) async {
    final db = await _dbHelper.database;
    return await db.insert('telemetry', telemetry.toMap());
  }

  Future<List<Telemetry>> getMotorTelemetry(
    int motorId, {
    int limit = AppConstants.defaultTelemetryLimit,
    int hours = AppConstants.maxTelemetryHistoryHours,
  }) async {
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(hours: hours));

    final maps = await db.query(
      'telemetry',
      where: 'motor_id = ? AND created_at >= ?',
      whereArgs: [motorId, cutoffDate.toIso8601String()],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((map) => Telemetry.fromMap(map)).toList();
  }

  Future<Telemetry?> getLatestTelemetry(int motorId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'telemetry',
      where: 'motor_id = ?',
      whereArgs: [motorId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Telemetry.fromMap(maps.first);
  }

  Future<List<Telemetry>> getTelemetryBetween(
    int motorId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'telemetry',
      where: 'motor_id = ? AND created_at >= ? AND created_at <= ?',
      whereArgs: [
        motorId,
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => Telemetry.fromMap(map)).toList();
  }
}
