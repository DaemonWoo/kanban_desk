class TreeRowDto {
  TreeRowDto({
    required this.id,
    required this.name,
    required this.parentId,
    required this.order,
    this.parentName,
  });

  final String id;
  final String name;
  final String parentId;
  final int order;
  final String? parentName;

  factory TreeRowDto.fromJson(Map<String, dynamic> json) {
    return TreeRowDto(
      id: json['indicator_to_mo_id'].toString(),
      name: (json['name'] ?? '').toString(),
      parentId: json['parent_id'].toString(),
      order: int.tryParse(json['order']?.toString() ?? '1') ?? 1,
      parentName: json['parent_name']?.toString(),
    );
  }
}
