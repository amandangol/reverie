import 'package:flutter/foundation.dart';
import 'dart:convert';

@immutable
class JournalEntry {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final List<String> mediaIds;
  final String? mood;
  final List<String> tags;
  final DateTime? lastEdited;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.mediaIds,
    this.mood,
    this.tags = const [],
    this.lastEdited,
  });

  JournalEntry copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    List<String>? mediaIds,
    String? mood,
    List<String>? tags,
    DateTime? lastEdited,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      mediaIds: mediaIds ?? this.mediaIds,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      lastEdited: lastEdited ?? this.lastEdited,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.millisecondsSinceEpoch,
      'media_ids': jsonEncode(mediaIds),
      'mood': mood,
      'tags': jsonEncode(tags),
      'last_edited': lastEdited?.millisecondsSinceEpoch,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      mediaIds: (jsonDecode(json['media_ids'] as String) as List)
          .map((e) => e as String)
          .toList(),
      mood: json['mood'] as String?,
      tags: json['tags'] != null
          ? (jsonDecode(json['tags'] as String) as List)
              .map((e) => e as String)
              .toList()
          : [],
      lastEdited: json['last_edited'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_edited'] as int)
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
        other.date == date &&
        listEquals(other.mediaIds, mediaIds) &&
        other.mood == mood &&
        listEquals(other.tags, tags) &&
        other.lastEdited == lastEdited;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      content,
      date,
      Object.hashAll(mediaIds),
      mood,
      Object.hashAll(tags),
      lastEdited,
    );
  }
}
