import 'package:flutter/foundation.dart';

/// Immutable model representing a row in the Supabase 'components' table
@immutable
class ComponentModel {
  final String id;
  final String name;
  final String category;
  final String description;

  const ComponentModel({
    required this.id,
    required this.name,
    required this.category,
    this.description = '',
  });

  factory ComponentModel.fromJson(Map<String, dynamic> json) {
    return ComponentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    if (description.isNotEmpty) 'description': description,
  };

  ComponentModel copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
  }) {
    return ComponentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ category.hashCode;

  @override
  String toString() => 'ComponentModel(id: $id, name: $name, category: $category)';
}
