import 'package:flutter/material.dart';


/// Model cho 1 danh mục (Ăn uống, Di chuyển, Lương, ...).
class CategoryModel {
  final int? id;
  final String name;
  final int iconCode; // IconData.codePoint, ví dụ Icons.restaurant.codePoint
  final int colorValue; // Color.value
  final String type; // 'expense' hoặc 'income'

  CategoryModel({
    this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.type,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code': iconCode,
      'color': colorValue,
      'type': type,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCode: map['icon_code'] as int,
      colorValue: map['color'] as int,
      type: map['type'] as String,
    );
  }
}
