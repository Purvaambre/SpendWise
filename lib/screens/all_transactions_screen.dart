import 'package:flutter/material.dart';
import '../data/expense_store.dart';
import '../widgets/transaction_actions_sheet.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() =>
      _AllTransactionsScreenState();
}

class _AllTransactionsScreenState
    extends State<AllTransactionsScreen> {
  String selectedCategory = 'All Categories';

  final List<String> categories = [
    'All Categories',
    'Food & Dining',
    'Shopping',
    'Transport',
    'Entertainment',
    'Education',
    'Bills & Utilities',
    'Healthcare',
    'Other',
  ];

  String _monthName(int month) {
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: expenseStore,
      builder: (context, _) {
        final filteredExpenses = expenseStore.expenses
            .where(
              (expense) =>
                  selectedCategory == 'All Categories' ||
                  expense.category == selectedCategory,
            )
            .toList();

        // Newest transactions first.
        filteredExpenses.sort(
          (a, b) => b.date.compareTo(a.date),
        );

        // Group transactions by year + month.
        final Map<String, List<dynamic>> groupedExpenses = {};

        for (final expense in filteredExpenses) {
          final key = '${expense.date.year}-${expense.date.month}';

          groupedExpenses.putIfAbsent(key, () => []);
          groupedExpenses[key]!.add(expense);
        }

        return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF172033),
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'All Transactions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
      ),

      body: Column(
        children: [
          // ==========================================================
          // CATEGORY FILTER
          // ==========================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              14,
            ),
            color: Colors.white,

            child: DropdownButtonFormField<String>(
              initialValue: selectedCategory,

              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(
                  Icons.filter_list_rounded,
                  color: Color(0xFF7C3AED),
                ),
                filled: true,
                fillColor: const Color(0xFFF7F9FC),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),

              items: categories.map(
                (category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                },
              ).toList(),

              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedCategory = value;
                });
              },
            ),
          ),

          // ==========================================================
          // TRANSACTIONS
          // ==========================================================

          Expanded(
            child: filteredExpenses.isEmpty
                ? const Center(
                    child: Text(
                      'No transactions found.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      for (final entry
                          in groupedExpenses.entries) ...[
                        _monthHeader(entry.value.first.date),

                        const SizedBox(height: 10),

                        ...entry.value.map(
                          (expense) =>
                              _transactionCard(expense),
                        ),

                        const SizedBox(height: 18),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  },
);
}

  // ==============================================================
  // MONTH HEADER
  // ==============================================================

  Widget _monthHeader(DateTime date) {
    return Text(
      '${_monthName(date.month).toUpperCase()} ${date.year}',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF172033),
        letterSpacing: 0.5,
      ),
    );
  }

  // ==============================================================
  // TRANSACTION CARD
  // ==============================================================

  Widget _transactionCard(dynamic expense) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        TransactionActionsSheet.show(
          context,
          expense,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFECEFF4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF7C3AED),
                size: 22,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          expense.category,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      Text(
                        '${expense.date.day} '
                        '${_monthName(expense.date.month).substring(0, 3)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Text(
              '₹${expense.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),

            const SizedBox(width: 4),

            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

}
