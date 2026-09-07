import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense.dart';
import 'notification_store.dart';

class ExpenseStore extends ChangeNotifier {
  final List<Expense> _expenses = [];

  double _monthlyBudget = 0;

  List<Expense> get expenses => List.unmodifiable(_expenses);

  double get totalSpent {
    final now = DateTime.now();

    return _expenses
        .where(
          (expense) =>
              expense.date.year == now.year &&
              expense.date.month == now.month,
        )
        .fold(
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
    final now = DateTime.now();
    final totals = <String, double>{};

    for (final expense in _expenses) {
      if (expense.date.year == now.year &&
          expense.date.month == now.month) {
        totals[expense.category] =
            (totals[expense.category] ?? 0) + expense.amount;
      }
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
            id: doc.id,
            amount: (data['amount'] as num).toDouble(),
            description: data['description'] ?? '',
            category: data['category'] ?? 'Other',
            date: (data['date'] as Timestamp).toDate(),
          ),
        );
      }

      notifyListeners();

      notificationStore.checkBudgetNotifications();
      notificationStore.checkDailyReminder();
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
      final docRef = await collection.add({
        'amount': expense.amount,
        'description': expense.description,
        'category': expense.category,
        'date': Timestamp.fromDate(expense.date),
      });

      final savedExpense = Expense(
        id: docRef.id,
        amount: expense.amount,
        description: expense.description,
        category: expense.category,
        date: expense.date,
      );

      _expenses.insert(0, savedExpense);

      notifyListeners();

      notificationStore.checkBudgetNotifications();
    } catch (e) {
      debugPrint('Error saving expense: $e');
      rethrow;
    }
  }

  Future<void> removeExpense(Expense expense) async {
    final collection = _expensesCollection;

    if (collection == null) {
      debugPrint('No logged-in user. Expense not deleted.');
      return;
    }

    if (expense.id == null) {
      debugPrint('Expense has no Firestore ID.');
      return;
    }

    try {
      await collection.doc(expense.id).delete();

      _expenses.remove(expense);

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      rethrow;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    final collection = _expensesCollection;

    if (collection == null) {
      debugPrint('No logged-in user. Expense not updated.');
      return;
    }

    if (expense.id == null) {
      debugPrint('Expense has no Firestore ID.');
      return;
    }

    try {
      await collection.doc(expense.id).update({
        'amount': expense.amount,
        'description': expense.description,
        'category': expense.category,
        'date': Timestamp.fromDate(expense.date),
      });

      final index = _expenses.indexWhere(
        (e) => e.id == expense.id,
      );

      if (index != -1) {
        _expenses[index] = expense;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating expense: $e');
      rethrow;
    }
  }
}

final expenseStore = ExpenseStore();
