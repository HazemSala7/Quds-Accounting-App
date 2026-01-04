class InvoiceItem {
  final String name;
  final String bonus;
  final double quantity;
  final double price;
  final double total;
  final double discount;

  InvoiceItem({
    required this.name,
    required this.bonus,
    required this.quantity,
    required this.price,
    required this.total,
    required this.discount,
  });
}
