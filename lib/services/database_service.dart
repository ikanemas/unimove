import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/errand.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String databaseName = 'unimove_db.sql';
  static const String seedAssetPath = 'assets/db/unimove.sql';

  Database? _database;

  Future<Database> get database async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final databasePath = p.join(await getDatabasesPath(), databaseName);
    final openedDatabase = await openDatabase(
      databasePath,
      version: 3,
      onCreate: _seedDatabase,
      onUpgrade: _upgradeDatabase,
      onOpen: _ensureSeeded,
    );
    _database = openedDatabase;
    return openedDatabase;
  }

  Future<List<Errand>> getErrands() async {
    final db = await database;
    final rows = await db.query('errands', orderBy: 'created_at DESC');
    return rows.map(Errand.fromMap).toList();
  }

  Future<List<Errand>> getUserPostedErrands(String userId) async {
    final db = await database;
    final rows = await db.query(
      'errands',
      where: 'is_seed = 0 AND poster_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Errand.fromMap).toList();
  }

  Future<Errand?> getErrand(int id) async {
    final db = await database;
    final rows = await db.query(
      'errands',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Errand.fromMap(rows.first);
  }

  Future<int> insertErrand({
    required String title,
    required double reward,
    required String description,
    required String timeToComplete,
    String? posterId,
    String? posterName,
  }) async {
    final db = await database;
    return db.insert('errands', {
      'title': title,
      'reward': reward,
      'description': description,
      'time_to_complete': timeToComplete,
      'status': 'Open',
      'created_at': DateTime.now().toIso8601String(),
      'poster_id': posterId,
      'poster_name': posterName,
      'is_seed': 0,
    });
  }

  Future<int> insertUser(
    String name,
    String email,
    String password,
    String phone,
    String role,
  ) async {
    final db = await database;

    return await db.insert('user', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
    });
  }

  Future<int> updateUser({
    required int id,
    required String name,
    required String email,
    required String phone,
    String? password,
  }) async {
    final db = await database;

    final data = <String, Object?>{
      'name': name,
      'email': email,
      'phone': phone,
    };

    if (password != null && password.isNotEmpty) {
      data['password'] = password;
    }

    return await db.update('user', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, Object?>?> getUser() async {
    final db = await database;

    final result = await db.query('user', limit: 1);

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> _seedDatabase(Database db, int version) async {
    final seedSql = await rootBundle.loadString(seedAssetPath);
    final statements = seedSql
        .split(';')
        .map((statement) => statement.trim())
        .where((statement) => statement.isNotEmpty);

    for (final statement in statements) {
      await db.execute(statement);
    }
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (!await _errandsTableExists(db)) {
      await _seedDatabase(db, newVersion);
      return;
    }

    await _ensureErrandSeedColumns(db);
    await _markExistingSeedErrands(db);
  }

  Future<void> _ensureSeeded(Database db) async {
    if (!await _errandsTableExists(db)) {
      await _seedDatabase(db, 2);
      return;
    }

    await _ensureErrandSeedColumns(db);
    await _markExistingSeedErrands(db);

    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM errands WHERE is_seed = 1'),
    );

    if (count == 0) {
      await _seedDatabase(db, 2);
    }
  }

  Future<bool> _errandsTableExists(Database db) async {
    final tableRows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      ['errands'],
    );

    return tableRows.isNotEmpty;
  }

  Future<void> _ensureErrandSeedColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(errands)');
    final columnNames = columns.map((column) => column['name']).toSet();

    if (!columnNames.contains('poster_id')) {
      await db.execute('ALTER TABLE errands ADD COLUMN poster_id TEXT');
    }

    if (!columnNames.contains('poster_name')) {
      await db.execute('ALTER TABLE errands ADD COLUMN poster_name TEXT');
    }

    if (!columnNames.contains('is_seed')) {
      await db.execute(
        'ALTER TABLE errands ADD COLUMN is_seed INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  Future<void> _markExistingSeedErrands(Database db) async {
    await db.update(
      'errands',
      {'poster_id': null, 'poster_name': 'UniMove', 'is_seed': 1},
      where: '''
        title IN (?, ?, ?, ?)
        AND created_at IN (?, ?, ?, ?)
      ''',
      whereArgs: const [
        'Simpan barang waktu cuti sem',
        'Photostate slip exam',
        'Beli Abuya COD KHAR 4182',
        'Pinjam raket',
        '2026-06-12T09:00:00.000',
        '2026-06-12T10:30:00.000',
        '2026-06-12T11:15:00.000',
        '2026-06-11T16:45:00.000',
      ],
    );
  }
}
