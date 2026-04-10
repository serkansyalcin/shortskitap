import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../platform/offline_audio_storage.dart';
import '../models/book_model.dart';
import '../models/paragraph_model.dart';

class OfflineCacheService {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = kIsWeb
        ? 'kitaplig.db'
        : join(await getDatabasesPath(), 'kitaplig.db');

    return openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE cached_books (
              id INTEGER PRIMARY KEY,
              slug TEXT NOT NULL,
              title TEXT NOT NULL,
              cover_image_url TEXT,
              description TEXT,
              language TEXT NOT NULL DEFAULT 'tr',
              is_premium INTEGER NOT NULL DEFAULT 0,
              is_kids INTEGER NOT NULL DEFAULT 0,
              total_paragraphs INTEGER NOT NULL DEFAULT 0,
              estimated_read_minutes INTEGER,
              view_count INTEGER NOT NULL DEFAULT 0,
              author_json TEXT,
              category_json TEXT,
              cached_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_cached_books_cached_at ON cached_books(cached_at DESC)',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE cached_paragraphs ADD COLUMN audio_url TEXT',
          );
          await db.execute(
            'ALTER TABLE cached_paragraphs ADD COLUMN audio_provider TEXT',
          );
          await db.execute(
            'ALTER TABLE cached_paragraphs ADD COLUMN audio_status TEXT',
          );
          await db.execute(
            'ALTER TABLE cached_paragraphs ADD COLUMN audio_duration_seconds INTEGER',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE cached_paragraphs ADD COLUMN audio_local_path TEXT',
          );
        }
        if (oldVersion < 5) {
          // Eski sürümlerde okuma sırasında oluşan metadata senkronu cached_books'a
          // yazılıyordu; kitaplar yanlışlıkla "indirilmiş" görünüyordu. İndirilenler
          // listesi satırlarını sıfırla (paragraf önbelleği cached_paragraphs kalır).
          await db.delete('cached_books');
        }
      },
    );
  }

  static Future<void> _createTables(Database db) async {
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
        audio_url TEXT,
        audio_local_path TEXT,
        audio_provider TEXT,
        audio_status TEXT,
        audio_duration_seconds INTEGER,
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
    await db.execute('''
      CREATE TABLE cached_books (
        id INTEGER PRIMARY KEY,
        slug TEXT NOT NULL,
        title TEXT NOT NULL,
        cover_image_url TEXT,
        description TEXT,
        language TEXT NOT NULL DEFAULT 'tr',
        is_premium INTEGER NOT NULL DEFAULT 0,
        is_kids INTEGER NOT NULL DEFAULT 0,
        total_paragraphs INTEGER NOT NULL DEFAULT 0,
        estimated_read_minutes INTEGER,
        view_count INTEGER NOT NULL DEFAULT 0,
        author_json TEXT,
        category_json TEXT,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_cached_book ON cached_paragraphs(book_id, sort_order)',
    );
    await db.execute(
      'CREATE INDEX idx_cached_books_cached_at ON cached_books(cached_at DESC)',
    );
  }

  Future<void> cacheBook(BookModel book) async {
    final db = await database;
    await db.insert('cached_books', {
      'id': book.id,
      'slug': book.slug,
      'title': book.title,
      'cover_image_url': book.coverImageUrl,
      'description': book.description,
      'language': book.language,
      'is_premium': book.isPremium ? 1 : 0,
      'is_kids': book.isKids ? 1 : 0,
      'total_paragraphs': book.totalParagraphs,
      'estimated_read_minutes': book.estimatedReadMinutes,
      'view_count': book.viewCount,
      'author_json': book.author == null
          ? null
          : jsonEncode(book.author!.toJson()),
      'category_json': book.category == null
          ? null
          : jsonEncode(book.category!.toJson()),
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Okuyucu gibi ekranlarda [BookModel] yokken; yalnızca İndirilenler satırı için minimal kayıt.
  Future<void> cacheBookPlaceholder(int bookId, {String? title}) async {
    final db = await database;
    final safeTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : 'Kitap';
    await db.insert('cached_books', {
      'id': bookId,
      'slug': 'id-$bookId',
      'title': safeTitle,
      'cover_image_url': null,
      'description': null,
      'language': 'tr',
      'is_premium': 0,
      'is_kids': 0,
      'total_paragraphs': 0,
      'estimated_read_minutes': null,
      'view_count': 0,
      'author_json': null,
      'category_json': null,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BookModel>> getCachedBooks() async {
    final db = await database;
    final rows = await db.query('cached_books', orderBy: 'cached_at DESC');

    return rows
        .map(
          (row) => BookModel.fromJson({
            'id': row['id'],
            'title': row['title'],
            'slug': row['slug'],
            'author': _decodeJsonMap(row['author_json'] as String?),
            'category': _decodeJsonMap(row['category_json'] as String?),
            'cover_image_url': row['cover_image_url'],
            'description': row['description'],
            'language': row['language'],
            'tags': const <String>[],
            'is_published': true,
            'is_featured': false,
            'is_premium': row['is_premium'] == 1,
            'is_kids': row['is_kids'] == 1,
            'total_paragraphs': row['total_paragraphs'],
            'estimated_read_minutes': row['estimated_read_minutes'],
            'view_count': row['view_count'],
          }),
        )
        .toList();
  }

  Future<List<ParagraphModel>> cacheParagraphs(
    int bookId,
    List<ParagraphModel> paragraphs, {
    bool downloadAudioFiles = false,
  }) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    final localAudioPaths = await _getLocalAudioPathMap(db, bookId);
    final cachedParagraphs = <ParagraphModel>[];

    for (final p in paragraphs) {
      var localAudioPath = localAudioPaths[p.id];
      if (localAudioPath != null &&
          localAudioPath.isNotEmpty &&
          !await localAudioFileExists(localAudioPath)) {
        localAudioPath = null;
      }

      if (downloadAudioFiles && p.audioUrl != null && p.audioUrl!.isNotEmpty) {
        localAudioPath = await cacheAudioFile(
          bookId: bookId,
          paragraphId: p.id,
          audioUrl: p.audioUrl!,
          currentLocalPath: localAudioPath,
        );
      }

      batch.insert('cached_paragraphs', {
        'id': p.id,
        'book_id': bookId,
        'content': p.content,
        'sort_order': p.sortOrder,
        'word_count': p.wordCount,
        'estimated_seconds': p.estimatedSeconds,
        'type': p.type.name,
        'chapter_id': p.chapterId,
        'audio_url': p.audioUrl,
        'audio_local_path': localAudioPath,
        'audio_provider': p.audioProvider,
        'audio_status': p.audioStatus,
        'audio_duration_seconds': p.audioDurationSeconds,
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      cachedParagraphs.add(p.copyWith(localAudioPath: localAudioPath));
    }

    await batch.commit(noResult: true);
    return cachedParagraphs;
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
        'audio_url': row['audio_url'],
        'audio_local_path': row['audio_local_path'],
        'audio_provider': row['audio_provider'],
        'audio_status': row['audio_status'],
        'audio_duration_seconds': row['audio_duration_seconds'],
      });
    }).toList();
  }

  Future<bool> hasCache(int bookId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM cached_paragraphs WHERE book_id = ?',
        [bookId],
      ),
    );
    return (count ?? 0) > 0;
  }

  Future<bool> hasCachedBookRecord(int bookId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cached_books WHERE id = ?', [
        bookId,
      ]),
    );
    return (count ?? 0) > 0;
  }

  Future<void> removeCachedBook(int bookId) async {
    final db = await database;
    final batch = db.batch();
    batch.delete(
      'cached_paragraphs',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
    batch.delete('cached_books', where: 'id = ?', whereArgs: [bookId]);
    await batch.commit(noResult: true);
    await deleteBookAudioCache(bookId);
  }

  Future<void> savePendingProgress(
    int bookId,
    int lastOrder,
    int sessionSeconds,
  ) async {
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

  Map<String, dynamic>? _decodeJsonMap(String? source) {
    if (source == null || source.isEmpty) return null;
    return jsonDecode(source) as Map<String, dynamic>;
  }

  Future<Map<int, String>> _getLocalAudioPathMap(
    Database db,
    int bookId,
  ) async {
    final rows = await db.query(
      'cached_paragraphs',
      columns: ['id', 'audio_local_path'],
      where: 'book_id = ?',
      whereArgs: [bookId],
    );

    final paths = <int, String>{};
    for (final row in rows) {
      final paragraphId = row['id'];
      final localPath = row['audio_local_path'];
      if (paragraphId is int && localPath is String && localPath.isNotEmpty) {
        paths[paragraphId] = localPath;
      }
    }
    return paths;
  }
}
