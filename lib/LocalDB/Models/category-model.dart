class Category {
  int? id; // If you need an ID for local storage
  String name;
  int companyId;
  int salesmanId;

  Category({
    this.id,
    required this.name,
    required this.companyId,
    required this.salesmanId,
  });

  // Convert a Category object into a Map object for storing in the database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company_id': companyId,
      'salesman_id': salesmanId,
    };
  }

  // Create a Category object from a Map object
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      companyId: json['company_id'] ?? 0,
      salesmanId: json['salesman_id'] ?? 0,
    );
  }
}
