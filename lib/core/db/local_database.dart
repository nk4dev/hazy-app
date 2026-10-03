import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/saved_url.dart';

/// On-device SQLite mirror of the signed-in user's saved items, so Library
/// renders instantly (and offline) from the last sync.
///
/// This is a cache of `GET /items`, never a second source of truth: every
/// write here follows a successful API call, and a sync replaces the
/// user's rows wholesale with what the server returned. Rows are scoped by
/// Clerk user id so switching accounts on one device never mixes libraries.
class LocalDatabase {
  LocalDatabase({Future<Database> Function()? open}) : _open = open ?? _openDefault;

  final Future<Database> Function() _open;
  Future<Database>? _db;

  static const _table = 'saved_urls';

  static Future<Database> _openDefault() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'hazy.db'),
      version: 1,
      onCreate: createSchema,
    );
  }

  static Future<void> createSchema(Database db, int version) async {
    // `json` holds the full SavedUrlDTO as returned by the API; the other
    // columns exist only for keying and ordering.
    await db.execute('''
      CREATE TABLE $_table (
        user_id TEXT NOT NULL,
        id TEXT NOT NULL,
        url TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        json TEXT NOT NULL,
        PRIMARY KEY (user_id, id)
      )
    ''');
    await db.execute(
      'CREATE INDEX saved_urls_user_created ON $_table (user_id, created_at)',
    );
  }

  Future<Database> get _database => _db ??= _open();

  Map<String, Object?> _row(String userId, SavedUrl item) => {
        'user_id': userId,
        'id': item.id,
        'url': item.url,
        'created_at': item.createdAt.millisecondsSinceEpoch,
        'json': jsonEncode(item.toJson()),
      };

  /// [sort] is `"newest"` or `"oldest"`, matching `GET /items?sort=`.
  Future<List<SavedUrl>> savedUrls(String userId, {String sort = 'newest'}) async {
    final db = await _database;
    final direction = sort == 'oldest' ? 'ASC' : 'DESC';
    final rows = await db.query(
      _table,
      columns: ['json'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at $direction, id $direction',
    );
    return rows
        .map(
          (r) => SavedUrl.fromJson(
            jsonDecode(r['json'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> upsertSavedUrl(String userId, SavedUrl item) async {
    final db = await _database;
    await db.insert(
      _table,
      _row(userId, item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSavedUrl(String userId, String id) async {
    final db = await _database;
    await db.delete(
      _table,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }

  /// Replaces every row for [userId] with [items] in one transaction, so a
  /// sync also drops items deleted from another device.
  Future<void> replaceSavedUrls(String userId, List<SavedUrl> items) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete(_table, where: 'user_id = ?', whereArgs: [userId]);
      final batch = txn.batch();
      for (final item in items) {
        batch.insert(
          _table,
          _row(userId, item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) await (await db).close();
  }
}
