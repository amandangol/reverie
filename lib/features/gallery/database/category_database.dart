import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class CategoryDatabase {
  static final CategoryDatabase instance = CategoryDatabase._init();
  static Database? _database;

  CategoryDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('media_categories.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE image_labels (
        asset_id TEXT PRIMARY KEY,
        labels TEXT,
        created_at INTEGER,
        processed INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE image_categories (
        category TEXT,
        asset_id TEXT,
        PRIMARY KEY (category, asset_id)
      )
    ''');
  }

  Future<void> saveLabels(String assetId, List<ImageLabel> labels) async {
    final db = await database;
    final labelsJson = json.encode(
      labels
          .map((label) => {
                'label': label.label,
                'confidence': label.confidence,
              })
          .toList(),
    );

    await db.insert(
      'image_labels',
      {
        'asset_id': assetId,
        'labels': labelsJson,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'processed': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ImageLabel>> getLabels(String assetId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'image_labels',
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );

    if (maps.isEmpty) return [];

    final labelsJson = json.decode(maps.first['labels'] as String) as List;
    return labelsJson
        .map((e) => ImageLabel(
              label: e['label'] as String,
              confidence: e['confidence'] as double,
              index: 0,
            ))
        .toList();
  }

  Future<void> saveCategory(String category, String assetId) async {
    final db = await database;
    await db.insert(
      'image_categories',
      {
        'category': category,
        'asset_id': assetId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getCategoriesForAsset(String assetId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'image_categories',
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );

    return maps.map((map) => map['category'] as String).toList();
  }

  Future<List<String>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'image_categories',
      distinct: true,
      columns: ['category'],
    );

    return maps.map((map) => map['category'] as String).toList();
  }

  Future<List<String>> getUnprocessedAssets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'image_labels',
      where: 'processed = ?',
      whereArgs: [0],
    );

    return maps.map((map) => map['asset_id'] as String).toList();
  }

  Future<void> markAssetAsProcessed(String assetId) async {
    final db = await database;
    await db.update(
      'image_labels',
      {'processed': 1},
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('image_labels');
    await db.delete('image_categories');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
