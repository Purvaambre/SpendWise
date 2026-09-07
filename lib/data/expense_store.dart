import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense.dart';

class ExpenseStore extends ChangeNotifier {
  final List<Expense> _expenses = [];

  double _monthlyBudget = 0;

  List<Expense> get expenses => List.unmodifiable(_expenses);

  double get totalSpent {
    return _expenses.fold(
      0,
      (sum, expense) => sum + expense.amount,
    );
  }

  double get monthlyBudget => _monthlyBudget;

  bool get hasBudget => _monthlyBudget > 0;

  double get remainingBudget {
    return _monthlyBudget - totalSpent;
  }

  Map<String, double> get categoryTotals {
    final totals = <String, double>{};

    for (final expense in _expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    return totals;
  }

  CollectionReference<Map<String, dynamic>>? get _expensesCollection {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses');
  }

  void setBudget(double budget) {
    _monthlyBudget = budget;
    notifyListeners();
  }

  Future<void> loadData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      // Load budget
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();

      if (data != null && data['monthlyBudget'] != null) {
        _monthlyBudget =
            (data['monthlyBudget'] as num).toDouble();
      }

      // Load expenses
      final snapshot = await _expensesCollection!
          .orderBy('date', descending: true)
          .get();

      _expenses.clear();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        _expenses.add(
          Expense(
            amount: (data['amount'] as num).toDouble(),
            description: data['description'] ?? '',
            category: data['category'] ?? 'Other',
            date: (data['date'] as Timestamp).toDate(),
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading SpendWise data: $e');
    }
  }

  Future<void> addExpense(Expense expense) async {
    final collection = _expensesCollection;

    if (collection == null) {
      debugPrint('No logged-in user. Expense not saved.');
      return;
    }

    try {
      await collection.add({
        'amount': expense.amount,
        'description': expense.description,
        'category': expense.category,
        'date': Timestamp.fromDate(expense.date),
      });

      _expenses.insert(0, expense);

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving expense: $e');
      rethrow;
    }
  }

  void removeExpense(Expense expense) {
    _expenses.remove(expense);
    notifyListeners();
  }
}

final expenseStore = ExpenseStore();
