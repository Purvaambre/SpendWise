class Expense {
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final String? id;

  Expense({
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    this.id,
  });
}
