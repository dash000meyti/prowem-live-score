class Team {
  const Team({required this.id, required this.name, required this.logoUrl});

  final int id;
  final String name;
  final String? logoUrl;

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
    );
  }
}
