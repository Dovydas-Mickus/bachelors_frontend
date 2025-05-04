// lib/core/models/team_overview.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class TeamOverview extends Equatable {
  final String teamId;
  final String teamName;
  final int projectCount;
  final int openTasksCount;
  final int completedTasksCount;
  final Duration avgCompletionTime;

  const TeamOverview({
    required this.teamId,
    required this.teamName,
    required this.projectCount,
    required this.openTasksCount,
    required this.completedTasksCount,
    required this.avgCompletionTime,
  });

  factory TeamOverview.fromJson(Map<String, dynamic> json) {
    debugPrint('--- [TeamOverview.fromJson] Start parsing overview ---');

    // ID & Name (support both camelCase and snake_case)
    final id = json['teamId'] ??
        json['team_id'] ??
        (throw FormatException(
            'Missing teamId/team_id in TeamOverview JSON: $json'));
    final name = json['teamName'] ??
        json['team_name'] ??
        (throw FormatException(
            'Missing teamName/team_name in TeamOverview JSON: $json'));

    // Helper to parse ints
    int _parseInt(dynamic value, String field) {
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      debugPrint(
          '   [TeamOverview.fromJson] ⚠️ Unable to parse `$field` from $value; defaulting to 0');
      return 0;
    }

    // Project count
    final projectCount = _parseInt(
      json['projectCount'] ?? json['project_count'],
      'projectCount',
    );

    // Open tasks count
    final openTasksCount = _parseInt(
      json['openTasksCount'] ?? json['open_tasks_count'],
      'openTasksCount',
    );

    // Completed tasks count
    final completedTasksCount = _parseInt(
      json['completedTasksCount'] ?? json['completed_tasks_count'],
      'completedTasksCount',
    );

    // Average completion time (in minutes)
    Duration _parseDuration(dynamic value, String field) {
      if (value is num) {
        return Duration(minutes: value.toInt());
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return Duration(minutes: parsed);
      }
      debugPrint(
          '   [TeamOverview.fromJson] ⚠️ Unable to parse `$field` from $value; defaulting to 0m');
      return Duration.zero;
    }

    final avgCompletionTime = _parseDuration(
      json['avgCompletionTimeMinutes'] ??
          json['avg_completion_time_minutes'],
      'avgCompletionTimeMinutes',
    );

    debugPrint(
      '--- [TeamOverview.fromJson] Parsed overview for team $id: '
          'projects=$projectCount, openTasks=$openTasksCount, '
          'completed=$completedTasksCount, avgTime=${avgCompletionTime.inMinutes}m ---',
    );

    return TeamOverview(
      teamId: id as String,
      teamName: name as String,
      projectCount: projectCount,
      openTasksCount: openTasksCount,
      completedTasksCount: completedTasksCount,
      avgCompletionTime: avgCompletionTime,
    );
  }

  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'team_name': teamName,
    'projectCount': projectCount,
    'openTasksCount': openTasksCount,
    'completedTasksCount': completedTasksCount,
    'avgCompletionTimeMinutes': avgCompletionTime.inMinutes,
  };

  @override
  List<Object> get props => [
    teamId,
    teamName,
    projectCount,
    openTasksCount,
    completedTasksCount,
    avgCompletionTime,
  ];
}
