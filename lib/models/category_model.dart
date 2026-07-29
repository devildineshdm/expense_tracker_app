import 'package:flutter/material.dart';

// Ha model ek category cha - navasakat icon ani color pan store karto
class CategoryModel {
  final String id;
  final String name;
  final String type; // 'income' ki 'expense'
  final int iconCodePoint; // Material icon cha code (IconOptions madhun nivadlela)
  final int colorValue; // Color cha ARGB value

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCodePoint,
    required this.colorValue,
  });

  IconData get icon =>
      IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      iconCodePoint: map['iconCodePoint'],
      colorValue: map['colorValue'],
    );
  }

  CategoryModel copyWith({
    String? name,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      type: type,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
