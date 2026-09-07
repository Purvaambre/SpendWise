import 'package:flutter/material.dart';
import '../data/expense_store.dart';
import '../models/expense.dart';

class TransactionActionsSheet {
  static void show(
    BuildContext context,
    Expense expense,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9DDE5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              // Transaction information
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFF7C3AED),
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172033),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          '₹${expense.amount.toStringAsFixed(0)} • '
                          '${expense.category}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Edit
              _actionTile(
                icon: Icons.edit_outlined,
                iconColor: const Color(0xFF7C3AED),
                backgroundColor: const Color(0xFFF3E8FF),
                title: 'Edit transaction',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showEditSheet(context, expense);
                },
              ),

              const SizedBox(height: 10),

              // Delete
              _actionTile(
                icon: Icons.delete_outline,
                iconColor: Colors.red,
                backgroundColor: const Color(0xFFFFE7E7),
                title: 'Delete transaction',
                titleColor: Colors.red,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showDeleteSheet(context, expense);
                },
              ),

              const SizedBox(height: 10),

              // Cancel
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 21,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? const Color(0xFF172033),
                ),
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: titleColor ?? Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  static void _showEditSheet(
    BuildContext context,
    Expense expense,
  ) {
    final amountController = TextEditingController(
      text: expense.amount.toString(),
    );

    final descriptionController = TextEditingController(
      text: expense.description,
    );

    String selectedCategory = expense.category;
    DateTime selectedDate = expense.date;

    const categories = [
      'Food & Dining',
      'Shopping',
      'Transport',
      'Entertainment',
      'Education',
      'Bills & Utilities',
      'Healthcare',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9DDE5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Edit Transaction',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Update your expense details',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _fieldLabel('Amount'),

                    const SizedBox(height: 7),

                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration(
                        prefixText: '₹ ',
                      ),
                    ),

                    const SizedBox(height: 18),

                    _fieldLabel('Description'),

                    const SizedBox(height: 7),

                    TextField(
                      controller: descriptionController,
                      decoration: _inputDecoration(),
                    ),

                    const SizedBox(height: 18),

                    _fieldLabel('Category'),

                    const SizedBox(height: 7),

                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: _inputDecoration(),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 18),

                    _fieldLabel('Date'),

                    const SizedBox(height: 7),

                    InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () async {
                        final pickedDate =
                            await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );

                        if (pickedDate != null) {
                          setSheetState(() {
                            selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              selectedDate.hour,
                              selectedDate.minute,
                            );
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFE5E9F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: Color(0xFF7C3AED),
                            ),

                            const SizedBox(width: 12),

                            Text(
                              '${selectedDate.day} '
                              '${_monthName(selectedDate.month)} '
                              '${selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF172033),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          final amount = double.tryParse(
                            amountController.text.trim(),
                          );

                          if (amount == null || amount <= 0) {
                            _showMessage(
                              context,
                              'Please enter a valid amount.',
                            );
                            return;
                          }

                          final description =
                              descriptionController.text.trim();

                          if (description.isEmpty) {
                            _showMessage(
                              context,
                              'Please enter a description.',
                            );
                            return;
                          }

                          final updatedExpense = Expense(
                            id: expense.id,
                            amount: amount,
                            description: description,
                            category: selectedCategory,
                            date: selectedDate,
                          );

                          try {
                            await expenseStore.updateExpense(
                              updatedExpense,
                            );

                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);

                              _showMessage(
                                context,
                                'Expense updated successfully.',
                              );
                            }
                          } catch (e) {
                            if (sheetContext.mounted) {
                              _showMessage(
                                context,
                                'Could not update expense.',
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void _showDeleteSheet(
    BuildContext context,
    Expense expense,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7E7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 27,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Delete transaction?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),

              const SizedBox(height: 7),

              Text(
                'Are you sure you want to delete '
                '₹${expense.amount.toStringAsFixed(0)}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(0xFF172033),
                        side: const BorderSide(
                          color: Color(0xFFE1E5EB),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await expenseStore.removeExpense(
                            expense,
                          );

                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);

                            _showMessage(
                              context,
                              'Expense deleted successfully.',
                            );
                          }
                        } catch (e) {
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);

                            _showMessage(
                              context,
                              'Could not delete expense.',
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static InputDecoration _inputDecoration({
    String? prefixText,
  }) {
    return InputDecoration(
      prefixText: prefixText,
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE5E9F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE5E9F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF7C3AED),
          width: 1.5,
        ),
      ),
    );
  }

  static Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF172033),
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  static void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
