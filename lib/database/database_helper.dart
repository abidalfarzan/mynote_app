import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'notes.db');

    print('📂 Database path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onOpen: (db) {
        print('📂 Database opened successfully');
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    print('🏗️ Creating new database table...');
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        image_path TEXT,
        label TEXT NOT NULL,
        color TEXT NOT NULL,
        link TEXT
      )
    ''');
    print('✅ Database table created successfully');
  }

  // Method untuk debugging database
  Future<void> printDatabaseInfo() async {
    try {
      final db = await database;
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM notes');
      final all = await db.query('notes');
      print('📊 Database Info:');
      print('   Total notes: ${count.first['count']}');
      print('   All notes: $all');
    } catch (e) {
      print('❌ Error getting database info: $e');
    }
  }

  // Method untuk reset database (gunakan hanya jika diperlukan)
  Future<void> resetDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'notes.db');
      await deleteDatabase(path);
      _database = null; // Reset instance
      print('🗑️ Database reset successfully');
    } catch (e) {
      print('❌ Error resetting database: $e');
    }
  }

  Future<int> insertNote(Note note) async {
    try {
      final db = await database;

      // Map yang sederhana dan jelas
      final Map<String, dynamic> noteMap = {
        'title': note.title,
        'description': note.description,
        'created_at': note.createdAt.millisecondsSinceEpoch,
        'updated_at': note.updatedAt.millisecondsSinceEpoch,
        'is_completed': note.isCompleted ? 1 : 0,
        'image_path': note.imagePath,
        'label': note.label,
        'color': note.color,
        'link': note.link,
      };

      print('💾 Inserting note with map: $noteMap');

      final result = await db.insert(
        'notes',
        noteMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Note inserted successfully with ID: $result');

      // Verifikasi penyimpanan
      final verifyCount =
          await db.rawQuery('SELECT COUNT(*) as count FROM notes');
      print(
          '📊 Total notes in database after insert: ${verifyCount.first['count']}');

      return result;
    } catch (e) {
      print('❌ Error inserting note: $e');
      rethrow;
    }
  }

  Future<List<Note>> getNotes() async {
    try {
      final db = await database;

      // Cek apakah tabel ada
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='notes'");
      print('📋 Notes table exists: ${tables.isNotEmpty}');

      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        orderBy: 'updated_at DESC',
      );

      print('📝 Retrieved ${maps.length} notes from database');

      // Debug: print structure of first note if exists
      if (maps.isNotEmpty) {
        print('First note structure: ${maps.first}');
      } else {
        print('⚠️ No notes found in database');
      }

      return List.generate(maps.length, (i) {
        try {
          return Note.fromMap(maps[i]);
        } catch (e) {
          print('❌ Error creating note from map ${maps[i]}: $e');
          rethrow;
        }
      });
    } catch (e) {
      print('❌ Error getting notes: $e');
      return [];
    }
  }

  Future<int> updateNote(Note note) async {
    try {
      final db = await database;

      final Map<String, dynamic> noteMap = {
        'title': note.title,
        'description': note.description,
        'updated_at': note.updatedAt.millisecondsSinceEpoch,
        'is_completed': note.isCompleted ? 1 : 0,
        'image_path': note.imagePath,
        'label': note.label,
        'color': note.color,
      };

      final result = await db.update(
        'notes',
        noteMap,
        where: 'id = ?',
        whereArgs: [note.id],
      );
      print('✅ Note updated: $result rows affected');
      return result;
    } catch (e) {
      print('❌ Error updating note: $e');
      rethrow;
    }
  }

  Future<int> deleteNote(int id) async {
    try {
      final db = await database;
      final result = await db.delete(
        'notes',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Note deleted: $result rows affected');
      return result;
    } catch (e) {
      print('❌ Error deleting note: $e');
      rethrow;
    }
  }
}
