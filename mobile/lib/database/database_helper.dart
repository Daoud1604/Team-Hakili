import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('motorguard_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Table users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Table motors
    await db.execute('''
      CREATE TABLE motors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        location TEXT,
        description TEXT,
        esp32_uid TEXT,
        is_running INTEGER NOT NULL DEFAULT 0,
        last_temperature REAL,
        last_vibration REAL,
        last_current REAL,
        last_speed_rpm REAL,
        last_battery_percent REAL,
        last_update TEXT
      )
    ''');

    // Table telemetry
    await db.execute('''
      CREATE TABLE telemetry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motor_id INTEGER NOT NULL,
        temperature REAL NOT NULL,
        vibration REAL NOT NULL,
        current REAL NOT NULL,
        speed_rpm REAL NOT NULL,
        is_running INTEGER NOT NULL,
        battery_percent REAL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (motor_id) REFERENCES motors (id)
      )
    ''');

    // Table maintenance_tasks
    await db.execute('''
      CREATE TABLE maintenance_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motor_id INTEGER NOT NULL,
        assigned_to_user_id INTEGER NOT NULL,
        created_by_user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        scheduled_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PLANNED',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (motor_id) REFERENCES motors (id),
        FOREIGN KEY (assigned_to_user_id) REFERENCES users (id),
        FOREIGN KEY (created_by_user_id) REFERENCES users (id)
      )
    ''');

    // Table maintenance_reports
    await db.execute('''
      CREATE TABLE maintenance_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL UNIQUE,
        summary TEXT NOT NULL,
        details TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (task_id) REFERENCES maintenance_tasks (id)
      )
    ''');

    // Table safety_configs
    await db.execute('''
      CREATE TABLE safety_configs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motor_id INTEGER NOT NULL UNIQUE,
        max_temperature REAL NOT NULL DEFAULT 80.0,
        max_vibration REAL NOT NULL DEFAULT 5.0,
        min_battery_percent REAL NOT NULL DEFAULT 20.0,
        emergency_stop_delay_seconds INTEGER NOT NULL DEFAULT 5,
        enable_sms_alerts INTEGER NOT NULL DEFAULT 0,
        sms_phone_number TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (motor_id) REFERENCES motors (id)
      )
    ''');

    // Table notifications
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motor_id INTEGER,
        user_id INTEGER,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (motor_id) REFERENCES motors (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Créer l'admin par défaut
    await db.insert('users', {
      'full_name': 'Administrateur',
      'email': 'admin@motorguard.local',
      'password': 'admin123', // En production, utiliser un hash
      'role': 'ADMIN',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
