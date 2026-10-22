class DiaryEntry {
  final int id;
  final DateTime date;
  final String title;
  final String content;
  final List<String> emotionTypes;
  final String? imagePath;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.emotionTypes,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'content': content,
      'emotionTypes': emotionTypes.join(','),
      'imagePath': imagePath,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      title: map['title'],
      content: map['content'],
      emotionTypes: (map['emotionTypes'] as String).split(','),
      imagePath: map['imagePath'],
    );
  }
} 