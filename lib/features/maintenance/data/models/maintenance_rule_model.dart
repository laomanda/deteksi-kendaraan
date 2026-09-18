import 'package:flutter/foundation.dart';
import 'component_model.dart';

/// Immutable model representing a row in the Supabase 'maintenance_rules' table
@immutable
class MaintenanceRuleModel {
  final String id;
  final String profileId;
  final String componentId;
  final String description;
  final int intervalKm;
  final String priority;
  final ComponentModel? component;

  const MaintenanceRuleModel({
    required this.id,
    required this.profileId,
    required this.componentId,
    required this.description,
    required this.intervalKm,
    required this.priority,
    this.component,
  });

  factory MaintenanceRuleModel.fromJson(Map<String, dynamic> json) {
    ComponentModel? comp;
    if (json['components'] is Map<String, dynamic>) {
      comp = ComponentModel.fromJson(json['components'] as Map<String, dynamic>);
    }

    return MaintenanceRuleModel(
      id: json['id']?.toString() ?? '',
      profileId: json['profile_id']?.toString() ?? '',
      componentId: json['component_id']?.toString() ?? '',
      description: json['description']?.toString() ?? comp?.description ?? '',
      intervalKm: (json['interval_km'] as num?)?.toInt() ?? 0,
      priority: json['priority']?.toString() ?? 'medium',
      component: comp,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'profile_id': profileId,
    'component_id': componentId,
    'description': description,
    'interval_km': intervalKm,
    'priority': priority,
    if (component != null) 'components': component!.toJson(),
  };

  MaintenanceRuleModel copyWith({
    String? id,
    String? profileId,
    String? componentId,
    String? description,
    int? intervalKm,
    String? priority,
    ComponentModel? component,
  }) {
    return MaintenanceRuleModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      componentId: componentId ?? this.componentId,
      description: description ?? this.description,
      intervalKm: intervalKm ?? this.intervalKm,
      priority: priority ?? this.priority,
      component: component ?? this.component,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceRuleModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          profileId == profileId &&
          componentId == componentId &&
          intervalKm == intervalKm;

  @override
  int get hashCode =>
      id.hashCode ^ profileId.hashCode ^ componentId.hashCode ^ intervalKm.hashCode;

  @override
  String toString() =>
      'MaintenanceRuleModel(id: $id, profileId: $profileId, componentId: $componentId, intervalKm: $intervalKm)';
}
