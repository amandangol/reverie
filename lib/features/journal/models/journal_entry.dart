import 'package:flutter/foundation.dart';
import 'dart:convert';

@immutable
class JournalEntry {
  final String id;
  final String title;
  final String content;
  final List<String> mediaIds;
  final String? mood;
  final List<String> tags;
  final DateTime date;
  final DateTime? lastEdited;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.mediaIds,
    this.mood,
    required this.tags,
    required this.date,
    this.lastEdited,
  });

  JournalEntry copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? mediaIds,
    String? mood,
    List<String>? tags,
    DateTime? date,
    DateTime? lastEdited,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      mediaIds: mediaIds ?? this.mediaIds,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      date: date ?? this.date,
      lastEdited: lastEdited ?? this.lastEdited,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'mediaIds': mediaIds,
      'mood': mood,
      'tags': tags,
      'date': date.toIso8601String(),
      'lastEdited': lastEdited?.toIso8601String(),
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      mediaIds: List<String>.from(json['mediaIds'] as List),
      mood: json['mood'] as String?,
      tags: List<String>.from(json['tags'] as List),
      date: DateTime.parse(json['date'] as String),
      lastEdited: json['lastEdited'] != null
          ? DateTime.parse(json['lastEdited'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntry &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        listEquals(other.mediaIds, mediaIds) &&
        other.mood == mood &&
        listEquals(other.tags, tags) &&
        other.date == date &&
        other.lastEdited == lastEdited;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      content,
      Object.hashAll(mediaIds),
      mood,
      Object.hashAll(tags),
      date,
      lastEdited,
    );
  }
}
