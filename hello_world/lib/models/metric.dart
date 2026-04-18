/// Represents a trackable metric category (e.g., Air, Earth, Wind, Fire).
class Metric {
  final int id;
  final String key;
  final String name;
  final int iconIndex;

  const Metric({
    required this.id,
    required this.key,
    required this.name,
    required this.iconIndex,
  });

  factory Metric.fromMap(Map<String, dynamic> map) => Metric(
        id: map['id'] as int,
        key: map['key'] as String,
        name: map['name'] as String,
        iconIndex: map['icon_index'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'key': key,
        'name': name,
        'icon_index': iconIndex,
      };
}
