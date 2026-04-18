/// Represents an extracted keyword tag.
class Tag {
  final int id;
  final String text;

  const Tag({required this.id, required this.text});

  factory Tag.fromMap(Map<String, dynamic> map) => Tag(
        id: map['id'] as int,
        text: map['text'] as String,
      );

  Map<String, dynamic> toMap() => {'id': id, 'text': text};
}
