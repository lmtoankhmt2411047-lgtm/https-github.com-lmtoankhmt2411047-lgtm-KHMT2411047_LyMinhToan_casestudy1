import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';

/// Lớp quản lý database SQLite cho toàn bộ app (singleton).
/// Gồm 2 bảng: categories (danh mục) và transactions (giao dịch).
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expense_manager.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    await _seedDefaultCategories(db);
  }

  /// Thêm sẵn vài danh mục mặc định khi tạo database lần đầu.
  Future<void> _seedDefaultCategories(Database db) async {
    final defaults = [
      CategoryModel(name: 'Ăn uống', iconCode: Icons.restaurant.codePoint, colorValue: 0xFFFF8A3D, type: 'expense'),
      CategoryModel(name: 'Di chuyển', iconCode: Icons.directions_car.codePoint, colorValue: 0xFF4C9AFF, type: 'expense'),
      CategoryModel(name: 'Mua sắm', iconCode: Icons.shopping_cart.codePoint, colorValue: 0xFF9C6BFF, type: 'expense'),
      CategoryModel(name: 'Hóa đơn', iconCode: Icons.receipt_long.codePoint, colorValue: 0xFF14B8A6, type: 'expense'),
      CategoryModel(name: 'Giáo dục', iconCode: Icons.school.codePoint, colorValue: 0xFF14B8A6, type: 'expense'),
      CategoryModel(name: 'Giải trí', iconCode: Icons.movie.codePoint, colorValue: 0xFF63E6BE, type: 'expense'),
      CategoryModel(name: 'Khác', iconCode: Icons.more_horiz.codePoint, colorValue: 0xFFADB5BD, type: 'expense'),
      CategoryModel(name: 'Lương', iconCode: Icons.savings.codePoint, colorValue: 0xFF4CAF50, type: 'income'),
      CategoryModel(name: 'Thu nhập khác', iconCode: Icons.attach_money.codePoint, colorValue: 0xFF4CAF50, type: 'income'),
    ];
    for (final c in defaults) {
      await db.insert('categories', c.toMap()..remove('id'));
    }
  }

  // ---------------- CATEGORY CRUD ----------------

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return db.insert('categories', category.toMap()..remove('id'));
  }

  Future<List<CategoryModel>> getCategories({String? type}) async {
    final db = await database;
    final maps = type == null
        ? await db.query('categories', orderBy: 'id')
        : await db.query('categories', where: 'type = ?', whereArgs: [type], orderBy: 'id');
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- TRANSACTION CRUD ----------------

  Future<int> insertTransaction(TransactionModel tx) async {
    final db = await database;
    return db.insert('transactions', tx.toMap()..remove('id'));
  }

  Future<int> updateTransaction(TransactionModel tx) async {
    final db = await database;
    return db.update(
      'transactions',
      tx.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Lấy toàn bộ giao dịch, mới nhất lên đầu.
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  /// Lấy N giao dịch gần đây nhất (dùng cho màn Dashboard).
  Future<List<TransactionModel>> getRecentTransactions({int limit = 5}) async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC', limit: limit);
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  /// Tổng thu nhập.
  Future<int> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'income'",
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Tổng chi tiêu.
  Future<int> getTotalExpense() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense'",
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Số dư hiện tại = tổng thu nhập - tổng chi tiêu.
  Future<int> getBalance() async {
    final income = await getTotalIncome();
    final expense = await getTotalExpense();
    return income - expense;
  }

  /// Đóng database khi không dùng nữa (ít khi cần gọi tay).
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
