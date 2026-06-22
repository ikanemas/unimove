import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_notification.dart';
import '../models/errand.dart';
import '../models/errand_offer.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String databaseName = 'unimove_db.sql';
  static const String seedAssetPath = 'assets/db/unimove.sql';

  Database? _database;
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<Database> get database async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final databasePath = p.join(await getDatabasesPath(), databaseName);
    final openedDatabase = await openDatabase(
      databasePath,
      version: 6,
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

  Future<List<Errand>> getOpenErrands() async {
    final db = await database;
    final rows = await db.query(
      'errands',
      where: 'status = ? AND runner_id IS NULL',
      whereArgs: ['Open'],
      orderBy: 'created_at DESC',
    );
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

  Future<List<Errand>> getAssignedErrands(String runnerId) async {
    final db = await database;
    final rows = await db.query(
      'errands',
      where: 'runner_id = ?',
      whereArgs: [runnerId],
      orderBy: 'accepted_at DESC, created_at DESC',
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

  // FIX 1: Added posterPhone parameter and saving it to local DB
  Future<int> insertErrand({
    required String title,
    required double reward,
    required String description,
    required String timeToComplete,
    String? posterId,
    String? posterName,
    String? posterPhone, 
  }) async {
    final db = await database;
    final id = await db.insert('errands', {
      'title': title,
      'reward': reward,
      'description': description,
      'time_to_complete': timeToComplete,
      'status': 'Open',
      'created_at': DateTime.now().toIso8601String(),
      'poster_id': posterId,
      'poster_name': posterName,
      'poster_phone': posterPhone, // Saved here
      'is_seed': 0,
    });
    changes.value++;
    return id;
  }

  Future<void> updateErrand({
    required int id,
    required String posterId,
    required String title,
    required double reward,
    required String description,
    required String timeToComplete,
    required String status,
  }) async {
    final db = await database;
    await db.update(
      'errands',
      {
        'title': title,
        'reward': reward,
        'description': description,
        'time_to_complete': timeToComplete,
        'status': status,
      },
      where: 'id = ? AND poster_id = ? AND is_seed = 0',
      whereArgs: [id, posterId],
    );
    changes.value++;
  }

  Future<void> updateErrandStatus({
    required int id,
    required String posterId,
    required String status,
  }) async {
    final db = await database;
    await db.update(
      'errands',
      {'status': status},
      where: 'id = ? AND poster_id = ? AND is_seed = 0',
      whereArgs: [id, posterId],
    );
    changes.value++;
  }

  // FIX 2: Added runnerPhone parameter and tracking transaction updates
  Future<bool> createOffer({
    required int errandId,
    required String runnerId,
    required String runnerName,
    required String message,
    required double proposedReward,
    required String estimatedTime,
    String? runnerPhone,
  }) async {
    final db = await database;
    final created = await db.transaction<bool>((transaction) async {
      final rows = await transaction.query(
        'errands',
        columns: ['title', 'poster_id'],
        where: 'id = ?',
        whereArgs: [errandId],
        limit: 1,
      );
      if (rows.isEmpty) return false;

      final errand = await transaction.query(
        'errands',
        columns: ['status', 'runner_id', 'poster_id'],
        where: 'id = ?',
        whereArgs: [errandId],
        limit: 1,
      );
      final row = errand.first;
      if (row['status'] != 'Open' ||
          row['runner_id'] != null ||
          row['poster_id'] == runnerId) {
        return false;
      }

      final existing = await transaction.query(
        'errand_offers',
        columns: ['id', 'status'],
        where: 'errand_id = ? AND runner_id = ?',
        whereArgs: [errandId, runnerId],
        limit: 1,
      );

      if (existing.isEmpty) {
        await transaction.insert('errand_offers', {
          'errand_id': errandId,
          'runner_id': runnerId,
          'runner_name': runnerName,
          'runner_phone': runnerPhone, // Inserted here
          'message': message,
          'proposed_reward': proposedReward,
          'estimated_time': estimatedTime,
          'status': 'Pending',
          'created_at': DateTime.now().toIso8601String(),
        });
      } else if (existing.first['status'] == 'Rejected' ||
          existing.first['status'] == 'Withdrawn') {
        await transaction.update(
          'errand_offers',
          {
            'runner_name': runnerName,
            'runner_phone': runnerPhone, // Updated here
            'message': message,
            'proposed_reward': proposedReward,
            'estimated_time': estimatedTime,
            'status': 'Pending',
            'created_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        return false;
      }

      final posterId = rows.first['poster_id'] as String?;
      if (posterId != null && posterId.isNotEmpty) {
        final errandTitle = rows.first['title'] as String;
        await transaction.insert('notifications', {
          'user_id': posterId,
          'errand_id': errandId,
          'title': 'New runner request',
          'message': '$runnerName wants to do "$errandTitle".',
          'is_read': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      return true;
    });

    if (created) changes.value++;
    return created;
  }

  Future<List<ErrandOffer>> getOffersForErrand(int errandId) async {
    final db = await database;
    final rows = await db.query(
      'errand_offers',
      where: 'errand_id = ?',
      whereArgs: [errandId],
      orderBy: '''
        CASE status
          WHEN 'Pending' THEN 0
          WHEN 'Accepted' THEN 1
          ELSE 2
        END,
        created_at DESC
      ''',
    );
    return rows.map(ErrandOffer.fromMap).toList();
  }

  // FIX 3: Updated SQL raw query to include errands.poster_phone in the JOIN select
  Future<List<ErrandOffer>> getOffersByRunner(String runnerId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
        SELECT errand_offers.*, errands.title AS errand_title, errands.poster_phone AS poster_phone
        FROM errand_offers
        INNER JOIN errands ON errands.id = errand_offers.errand_id
        WHERE errand_offers.runner_id = ?
        ORDER BY errand_offers.created_at DESC
      ''',
      [runnerId],
    );
    return rows.map(ErrandOffer.fromMap).toList();
  }

  Future<ErrandOffer?> getRunnerOffer({
    required int errandId,
    required String runnerId,
  }) async {
    final db = await database;
    final rows = await db.query(
      'errand_offers',
      where: 'errand_id = ? AND runner_id = ?',
      whereArgs: [errandId, runnerId],
      limit: 1,
    );
    return rows.isEmpty ? null : ErrandOffer.fromMap(rows.first);
  }

  // FIX 4: Copy the runner's phone number into the errands record table upon acceptance
  Future<bool> acceptOffer({
    required int offerId,
    required String posterId,
  }) async {
    final db = await database;
    final accepted = await db.transaction<bool>((transaction) async {
      final offers = await transaction.query(
        'errand_offers',
        where: 'id = ? AND status = ?',
        whereArgs: [offerId, 'Pending'],
        limit: 1,
      );
      if (offers.isEmpty) return false;

      final offer = offers.first;
      final errandId = offer['errand_id'] as int;
      final errands = await transaction.query(
        'errands',
        columns: ['title', 'poster_id', 'status', 'runner_id'],
        where: 'id = ?',
        whereArgs: [errandId],
        limit: 1,
      );
      if (errands.isEmpty) return false;

      final errand = errands.first;
      if (errand['poster_id'] != posterId ||
          errand['status'] != 'Open' ||
          errand['runner_id'] != null) {
        return false;
      }

      await transaction.update(
        'errands',
        {
          'runner_id': offer['runner_id'],
          'runner_name': offer['runner_name'],
          'runner_phone': offer['runner_phone'],
          'status': 'Closed',
          'accepted_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [errandId],
      );

      await transaction.update(
        'errand_offers',
        {'status': 'Accepted'},
        where: 'id = ?',
        whereArgs: [offerId],
      );
      await transaction.update(
        'errand_offers',
        {'status': 'Rejected'},
        where: 'errand_id = ? AND id != ? AND status = ?',
        whereArgs: [errandId, offerId, 'Pending'],
      );

      await transaction.insert('notifications', {
        'user_id': offer['runner_id'],
        'errand_id': errandId,
        'title': 'Request accepted',
        'message': 'Your request for "${errand['title']}" was accepted.',
        'is_read': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    });

    if (accepted) changes.value++;
    return accepted;
  }

  Future<bool> rejectOffer({
    required int offerId,
    required String posterId,
  }) async {
    final db = await database;
    final rejected = await db.transaction<bool>((transaction) async {
      final offers = await transaction.rawQuery(
        '''
          SELECT errand_offers.*, errands.title AS errand_title,
                 errands.poster_id AS poster_id
          FROM errand_offers
          INNER JOIN errands ON errands.id = errand_offers.errand_id
          WHERE errand_offers.id = ? AND errand_offers.status = ?
        ''',
        [offerId, 'Pending'],
      );
      if (offers.isEmpty || offers.first['poster_id'] != posterId) {
        return false;
      }

      final offer = offers.first;
      await transaction.update(
        'errand_offers',
        {'status': 'Rejected'},
        where: 'id = ?',
        whereArgs: [offerId],
      );
      await transaction.insert('notifications', {
        'user_id': offer['runner_id'],
        'errand_id': offer['errand_id'],
        'title': 'Request rejected',
        'message': 'Your request for "${offer['errand_title']}" was rejected.',
        'is_read': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    });

    if (rejected) changes.value++;
    return rejected;
  }

  Future<List<AppNotification>> getNotifications(String userId) async {
    final db = await database;
    final rows = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
        SELECT COUNT(*)
        FROM notifications
        WHERE user_id = ? AND is_read = 0
      ''',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markNotificationRead(int notificationId) async {
    final db = await database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
    changes.value++;
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final db = await database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ? AND is_read = 0',
      whereArgs: [userId],
    );
    changes.value++;
  }

  Future<void> updateAssignedErrandStatus({
    required int id,
    required String runnerId,
    required String status,
  }) async {
    final db = await database;
    await db.update(
      'errands',
      {'status': status},
      where: 'id = ? AND runner_id = ?',
      whereArgs: [id, runnerId],
    );
    changes.value++;
  }

  Future<void> deleteErrand({required int id, required String posterId}) async {
    final db = await database;
    await db.delete(
      'errands',
      where: 'id = ? AND poster_id = ? AND is_seed = 0',
      whereArgs: [id, posterId],
    );
    changes.value++;
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
    await _ensureRunnerColumns(db);
    await _ensureNotificationsTable(db);
    await _ensureOffersTable(db);
    await _markExistingSeedErrands(db);
  }

  Future<void> _ensureSeeded(Database db) async {
    if (!await _errandsTableExists(db)) {
      await _seedDatabase(db, 2);
      return;
    }

    await _ensureErrandSeedColumns(db);
    await _ensureRunnerColumns(db);
    await _ensureNotificationsTable(db);
    await _ensureOffersTable(db);
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

  // FIX 5: Added poster_phone and runner_phone checking setup to the migrations block
  Future<void> _ensureErrandSeedColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(errands)');
    final columnNames = columns.map((column) => column['name']).toSet();

    if (!columnNames.contains('poster_id')) {
      await db.execute('ALTER TABLE errands ADD COLUMN poster_id TEXT');
    }

    if (!columnNames.contains('poster_name')) {
      await db.execute('ALTER TABLE errands ADD COLUMN poster_name TEXT');
    }

    if (!columnNames.contains('poster_phone')) {
      await db.execute('ALTER TABLE errands ADD COLUMN poster_phone TEXT');
    }

    if (!columnNames.contains('runner_phone')) {
      await db.execute('ALTER TABLE errands ADD COLUMN runner_phone TEXT');
    }

    if (!columnNames.contains('is_seed')) {
      await db.execute(
        'ALTER TABLE errands ADD COLUMN is_seed INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  Future<void> _ensureRunnerColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(errands)');
    final columnNames = columns.map((column) => column['name']).toSet();

    if (!columnNames.contains('runner_id')) {
      await db.execute('ALTER TABLE errands ADD COLUMN runner_id TEXT');
    }
    if (!columnNames.contains('runner_name')) {
      await db.execute('ALTER TABLE errands ADD COLUMN runner_name TEXT');
    }
    if (!columnNames.contains('accepted_at')) {
      await db.execute('ALTER TABLE errands ADD COLUMN accepted_at TEXT');
    }
  }

  Future<void> _ensureNotificationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        errand_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (errand_id) REFERENCES errands(id) ON DELETE CASCADE
      )
    ''');
  }

  // FIX 6: Updated table setup to handle runner_phone fields safely
  Future<void> _ensureOffersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS errand_offers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        errand_id INTEGER NOT NULL,
        runner_id TEXT NOT NULL,
        runner_name TEXT NOT NULL,
        runner_phone TEXT,
        message TEXT NOT NULL,
        proposed_reward REAL NOT NULL,
        estimated_time TEXT NOT NULL,
        status TEXT NOT NULL CHECK (
          status IN ('Pending', 'Accepted', 'Rejected', 'Withdrawn')
        ) DEFAULT 'Pending',
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (errand_id, runner_id),
        FOREIGN KEY (errand_id) REFERENCES errands(id) ON DELETE CASCADE
      )
    ''');

    // Run dynamic structural alter check block in case table already exists on user's storage
    final columns = await db.rawQuery('PRAGMA table_info(errand_offers)');
    final columnNames = columns.map((column) => column['name']).toSet();
    if (columnNames.isNotEmpty && !columnNames.contains('runner_phone')) {
      await db.execute('ALTER TABLE errand_offers ADD COLUMN runner_phone TEXT');
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