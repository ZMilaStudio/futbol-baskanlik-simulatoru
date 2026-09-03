class Club {
  const Club({
    required this.id,
    required this.name,
    required this.strength,
  });

  final String id;
  final String name;
  final double strength;

  Club copyWith({double? strength}) => Club(
        id: id,
        name: name,
        strength: strength ?? this.strength,
      );
}
