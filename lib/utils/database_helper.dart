import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vapornote.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        category TEXT,
        type INTEGER,
        checkItems TEXT,
        images TEXT,
        doodlePath TEXT,
        createdAt INTEGER,
        updatedAt INTEGER,
        isPinned INTEGER,
        colorIndex INTEGER
      )
    ''');
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final result = await db.query('notes', orderBy: 'isPinned DESC, updatedAt DESC');
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<Note?> getNoteById(String id) async {
    final db = await database;
    final result = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Note.fromMap(result.first);
  }

  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert('notes', note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updatedAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> getNotesByCategory(String category) async {
    final db = await database;
    if (category == '全部') {
      return getAllNotes();
    }
    final result = await db.query(
      'notes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT category FROM notes');
    return result.map((e) => e['category'] as String).toList();
  }
}
