import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';


import '../models/errand.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String databaseName = 'unimove_db.sql';
  static const String seedAssetPath = 'assets/db/unimove_db.sql';

  Database? _database;

  Future<Database> get database async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final databasePath = p.join(await getDatabasesPath(), databaseName);
    final openedDatabase = await openDatabase(
      databasePath,
      version: 2,
      onCreate: _seedDatabase,
    );
    _database = openedDatabase;
    return openedDatabase;
  }

  Future<List<Errand>> getErrands() async {
    final db = await database;
    final rows = await db.query('errands', orderBy: 'created_at DESC');
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
  }) async {
    final db = await database;
    return db.insert('errands', {
      'title': title,
      'reward': reward,
      'description': description,
      'time_to_complete': timeToComplete,
      'status': 'Open',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  Future<int> insertUser(String name, String email, String password, String phone) async {
  final db = await database;

  return await db.insert(
    'user',
    {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    },
  );
}
Future<int> updateUser({
  required int id,
  required String name,
  required String email,
  required String phone,
  String? password,
}) async {
  final db = await database;

  final data = {
    'name': name,
    'email': email,
    'phone': phone,
  };

  if (password != null && password.isNotEmpty) {
    data['password'] = password;
  }

  return await db.update(
    'user',
    data,
    where: 'id = ?',
    whereArgs: [id],
  );
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
}
