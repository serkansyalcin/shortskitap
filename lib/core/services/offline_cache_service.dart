import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/paragraph_model.dart';

class OfflineCacheService {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shortskitap.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_paragraphs (
            id INTEGER PRIMARY KEY,
            book_id INTEGER NOT NULL,
            content TEXT NOT NULL,
            sort_order INTEGER NOT NULL,
            word_count INTEGER,
            estimated_seconds INTEGER,
            type TEXT NOT NULL DEFAULT 'text',
            chapter_id INTEGER,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_progress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER NOT NULL,
            last_paragraph_order INTEGER NOT NULL,
            session_seconds INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_cached_book ON cached_paragraphs(book_id, sort_order)',
        );
      },
    );
  }

  Future<void> cacheParagraphs(
      int bookId, List<ParagraphModel> paragraphs) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final p in paragraphs) {
      batch.insert(
        'cached_paragraphs',
        {
          'id': p.id,
          'book_id': bookId,
          'content': p.content,
          'sort_order': p.sortOrder,
          'word_count': p.wordCount,
          'estimated_seconds': p.estimatedSeconds,
          'type': p.type.name,
          'chapter_id': p.chapterId,
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<ParagraphModel>> getCachedParagraphs(int bookId) async {
    final db = await database;
    final rows = await db.query(
      'cached_paragraphs',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'sort_order ASC',
    );

    return rows.map((row) {
      return ParagraphModel.fromJson({
        'id': row['id'],
        'book_id': row['book_id'],
        'content': row['content'],
        'sort_order': row['sort_order'],
        'word_count': row['word_count'],
        'estimated_seconds': row['estimated_seconds'],
        'type': row['type'],
        'chapter_id': row['chapter_id'],
      });
    }).toList();
  }

  Future<bool> hasCache(int bookId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM cached_paragraphs WHERE book_id = ?', [bookId]));
    return (count ?? 0) > 0;
  }

  Future<void> savePendingProgress(
      int bookId, int lastOrder, int sessionSeconds) async {
    final db = await database;
    await db.insert('pending_progress', {
      'book_id': bookId,
      'last_paragraph_order': lastOrder,
      'session_seconds': sessionSeconds,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingProgress() async {
    final db = await database;
    return db.query('pending_progress', orderBy: 'created_at ASC');
  }

  Future<void> clearPendingProgress() async {
    final db = await database;
    await db.delete('pending_progress');
  }
}
