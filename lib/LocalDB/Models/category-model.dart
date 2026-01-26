class Category {
  final String id; // make it non-null and always string
  final String name;
  final int companyId;
  final int salesmanId;

  Category({
    required this.id,
    required this.name,
    required this.companyId,
    required this.salesmanId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id, // ALWAYS STRING
      'name': name,
      'company_id': companyId,
      'salesman_id': salesmanId,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];

    return Category(
      id: rawId == null ? '0' : rawId.toString(), // ALWAYS STRING
      name: (json['name'] ?? '').toString(),
      companyId: int.tryParse((json['company_id'] ?? 0).toString()) ?? 0,
      salesmanId: int.tryParse((json['salesman_id'] ?? 0).toString()) ?? 0,
    );
  }

  @override
  String toString() {
    return 'Category{id: "$id", name: "$name", company_id: $companyId, salesman_id: $salesmanId}';
  }
}
