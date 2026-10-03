import 'package:flutter_test/flutter_test.dart';
import 'package:hazy_mobile/core/db/local_database.dart';
import 'package:hazy_mobile/models/saved_url.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

SavedUrl _item(String id, DateTime createdAt, {String? title}) {
  return SavedUrl.fromJson({
    'id': id,
    'url': 'https://example.com/$id',
    'domain': 'example.com',
    'title': title,
    'description': null,
    'faviconUrl': null,
    'ogImageUrl': null,
    'summary': null,
    'tags': ['a', 'b'],
    'contentLanguage': 'en',
    'estimatedReadMinutes': 3,
    'fetchStatus': 'success',
    'fetchError': null,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': createdAt.toIso8601String(),
    'readLaterStatus': 'inbox',
  });
}

void main() {
  late LocalDatabase db;

  setUp(() {
    sqfliteFfiInit();
    db = LocalDatabase(
      open: () => databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: LocalDatabase.createSchema,
        ),
      ),
    );
  });

  tearDown(() => db.close());

  final older = _item('1', DateTime.utc(2026, 1, 1), title: 'Older');
  final newer = _item('2', DateTime.utc(2026, 2, 1), title: 'Newer');

  test('round-trips a SavedUrl and orders by sort', () async {
    await db.upsertSavedUrl('u1', older);
    await db.upsertSavedUrl('u1', newer);

    final newest = await db.savedUrls('u1');
    expect(newest.map((i) => i.id), ['2', '1']);
    expect(newest.first.toJson(), newer.toJson());

    final oldest = await db.savedUrls('u1', sort: 'oldest');
    expect(oldest.map((i) => i.id), ['1', '2']);
  });

  test('upsert replaces an existing row instead of duplicating it', () async {
    await db.upsertSavedUrl('u1', older);
    await db.upsertSavedUrl('u1', older.copyWith(title: 'Edited'));

    final items = await db.savedUrls('u1');
    expect(items, hasLength(1));
    expect(items.single.title, 'Edited');
  });

  test('replaceSavedUrls drops rows missing from the server', () async {
    await db.upsertSavedUrl('u1', older);
    await db.replaceSavedUrls('u1', [newer]);

    expect((await db.savedUrls('u1')).map((i) => i.id), ['2']);
  });

  test('rows are scoped per user', () async {
    await db.upsertSavedUrl('u1', older);
    await db.upsertSavedUrl('u2', newer);
    await db.replaceSavedUrls('u1', []);
    await db.deleteSavedUrl('u1', '2');

    expect(await db.savedUrls('u1'), isEmpty);
    expect((await db.savedUrls('u2')).map((i) => i.id), ['2']);
  });
}
