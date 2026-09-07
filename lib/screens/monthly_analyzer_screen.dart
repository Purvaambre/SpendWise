import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';

import '../data/expense_store.dart';
import '../models/expense.dart';
import '../utils/responsive.dart';

class MonthlyAnalyzerScreen extends StatefulWidget {
  const MonthlyAnalyzerScreen({super.key});

  @override
  State<MonthlyAnalyzerScreen> createState() =>
      _MonthlyAnalyzerScreenState();
}

class _MonthlyAnalyzerScreenState
    extends State<MonthlyAnalyzerScreen> {
  late DateTime selectedMonth;

  bool isGeneratingReview = false;
  String? aiReview;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    selectedMonth = DateTime(
      now.year,
      now.month - 1,
    );
  }

  List<Expense> get monthExpenses {
    return expenseStore.expenses.where((expense) {
      return expense.date.year == selectedMonth.year &&
          expense.date.month == selectedMonth.month;
    }).toList();
  }

  double get monthTotal {
    return monthExpenses.fold(
      0,
      (sum, expense) => sum + expense.amount,
    );
  }

  double get dailyAverage {
    if (monthExpenses.isEmpty) return 0;

    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    return monthTotal / daysInMonth;
  }

  int get transactionCount {
    return monthExpenses.length;
  }

  double get budgetUsedPercentage {
    final budget = expenseStore.monthlyBudget;

    if (budget <= 0) return 0;

    return (monthTotal / budget) * 100;
  }

  Expense? get highestExpense {
    if (monthExpenses.isEmpty) return null;

    return monthExpenses.reduce(
      (a, b) => a.amount > b.amount ? a : b,
    );
  }

  Map<String, double> get categoryTotals {
    final totals = <String, double>{};

    for (final expense in monthExpenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    return totals;
  }

  Map<int, double> get weeklyTotals {
    final totals = <int, double>{
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
    };

    for (final expense in monthExpenses) {
      final week = ((expense.date.day - 1) ~/ 7) + 1;

      totals[week] = (totals[week] ?? 0) + expense.amount;
    }

    return totals;
  }

  int get highestSpendingWeek {
    if (weeklyTotals.isEmpty) return 1;

    return weeklyTotals.entries
        .reduce(
          (a, b) => a.value > b.value ? a : b,
        )
        .key;
  }

  double _percentage(double amount) {
    if (monthTotal <= 0) return 0;

    return amount / monthTotal;
  }

  String get topCategory {
    if (categoryTotals.isEmpty) {
      return 'No spending yet';
    }

    return categoryTotals.entries
        .reduce(
          (a, b) => a.value > b.value ? a : b,
        )
        .key;
  }

  double get topCategoryPercentage {
    if (monthTotal <= 0 || categoryTotals.isEmpty) return 0;

    return categoryTotals[topCategory]! / monthTotal;
  }

  Future<void> generateAIReview() async {
    if (monthExpenses.isEmpty) {
      setState(() {
        aiReview =
            'There is not enough spending data to generate an AI review for this month.';
      });
      return;
    }

    setState(() {
      isGeneratingReview = true;
      aiReview = null;
    });

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.6-flash',
        systemInstruction: Content.system(
          '''
You are SpendWise AI Monthly Analyzer.

Analyze the user's previous month's spending.

Use ONLY the expense data provided.
Do not invent transactions or amounts.

Give a concise and useful financial review suitable for a college student.

Include:
1. Overall spending summary
2. Highest spending category
3. Important spending pattern
4. One or two practical suggestions

Use Indian Rupees (₹).
Do not provide investment, tax, loan, or professional financial advice.
''',
        ),
      );

      final transactions = monthExpenses.map((expense) {
        return '''
Date: ${expense.date.day}/${expense.date.month}/${expense.date.year}
Category: ${expense.category}
Description: ${expense.description}
Amount: ₹${expense.amount.toStringAsFixed(2)}
''';
      }).join('\n');

      final prompt = '''
Analyze my spending for ${_monthName(selectedMonth)}.

Total spent: ₹${monthTotal.toStringAsFixed(2)}
Highest spending category: $topCategory

Transactions:
$transactions

Give me my monthly spending review.

Format the response as clean plain text with these sections:

Overall Summary
Highest Spending Category
Spending Pattern
Practical Suggestions

Do not use Markdown symbols such as #, *, or bullet characters.
Keep the review concise and easy to read.
''';

      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      if (!mounted) return;

      setState(() {
        aiReview = response.text ??
            'Unable to generate a review right now.';
        isGeneratingReview = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('AI Monthly Review error: $e');

      if (!mounted) return;

      setState(() {
        aiReview =
            'Unable to generate your AI review right now. Please try again.';
        isGeneratingReview = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: expenseStore,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Monthly Analysis',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedMonth = DateTime(
                              selectedMonth.year,
                              selectedMonth.month - 1,
                            );
                          });
                        },
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),

                      Expanded(
                        child: Text(
                          _monthName(selectedMonth),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172033),
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          final now = DateTime.now();
                          final previousMonth = DateTime(
                            now.year,
                            now.month - 1,
                          );

                          if (selectedMonth.isBefore(previousMonth)) {
                            setState(() {
                              selectedMonth = DateTime(
                                selectedMonth.year,
                                selectedMonth.month + 1,
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Here is your spending analysis.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _summaryCard(),

                  const SizedBox(height: 24),

                  const Text(
                    'Quick Insights',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildQuickInsights(),

                  const SizedBox(height: 24),

                  const Text(
                    'Where Your Money Went',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (categoryTotals.isEmpty)
                    _emptyCard()
                  else
                    ...(() {
                      final entries = categoryTotals.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                      return entries.map(
                        (entry) => _categoryCard(
                          entry.key,
                          entry.value,
                        ),
                      );
                    })(),

                  if (highestExpense != null) ...[
                    const SizedBox(height: 24),

                    const Text(
                      'Biggest Expense',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE3E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Color(0xFF7C3AED),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  highestExpense!.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF172033),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  highestExpense!.category,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Text(
                            '₹${highestExpense!.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 28),

                  const Text(
                    'Weekly Spending',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 14),

                  ...weeklyTotals.entries.map(
                    (entry) => _weeklyCard(
                      entry.key,
                      entry.value,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.insights_rounded,
                          color: Color(0xFF7C3AED),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            'Week $highestSpendingWeek was your highest-spending week '
                            'last month.',
                            style: const TextStyle(
                              color: Color(0xFF4B3568),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildAIReviewSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Spent',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '₹${monthTotal.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  'Daily Average',
                  '₹${dailyAverage.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _summaryItem(
                  'Transactions',
                  '$transactionCount',
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            'Budget used: ${budgetUsedPercentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _categoryCard(String category, double amount) {
    final percentage =
        monthTotal > 0 ? (amount / monthTotal) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.category_outlined,
                color: Color(0xFF7C3AED),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  category,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          LinearProgressIndicator(
            value: percentage.toDouble(),
            minHeight: 7,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: const Color(0xFFEDE9FE),
            color: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _weeklyCard(int week, double amount) {
    final percentage = _percentage(amount);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  week == highestSpendingWeek
                      ? 'Week $week • Highest'
                      : 'Week $week',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172033),
                  ),
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          LinearProgressIndicator(
            value: percentage,
            minHeight: 7,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: const Color(0xFFEDE9FE),
            color: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'No expenses were recorded for this month. Start tracking your spending to see your monthly analysis here.',
        style: TextStyle(
          color: Colors.grey,
          height: 1.4,
        ),
      ),
    );
  }

  String _monthName(DateTime date) {
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

    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildQuickInsights() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _insightBox(
                icon: Icons.receipt_long,
                value: '$transactionCount',
                label: 'Transactions',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _insightBox(
                icon: Icons.currency_rupee,
                value: '₹${dailyAverage.toStringAsFixed(0)}',
                label: 'Daily Average',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _insightBox(
          icon: Icons.category_outlined,
          value: topCategory,
          label:
              'Highest Spending Category • ${(topCategoryPercentage * 100).toStringAsFixed(0)}% of spending',
        ),
      ],
    );
  }

  Widget _insightBox({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: const Color(0xFF6A4BBC),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Spending Review',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                isGeneratingReview ? null : generateAIReview,
            icon: isGeneratingReview
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              isGeneratingReview
                  ? 'Analyzing your spending...'
                  : 'Get AI Monthly Review',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A4BBC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        if (aiReview != null) ...[
          const SizedBox(height: 16),
          _aiReviewCard(),
        ],
      ],
    );
  }

  Widget _aiReviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF6A4BBC),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SpendWise AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Your personalized monthly spending insights',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            aiReview ?? '',
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF4A5568),
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
