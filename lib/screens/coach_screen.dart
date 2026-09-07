import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';

import '../data/expense_store.dart';
import '../utils/responsive.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class _CoachScreenState extends State<CoachScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late final GenerativeModel _model;
  late final ChatSession _chat;

  final List<_ChatMessage> messages = [];

  bool thinking = false;

  @override
  void initState() {
    super.initState();

    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.6-flash',
      systemInstruction: Content.system(
        '''
You are SpendWise AI Coach, a friendly personal finance assistant for students.

Your job is to help the user understand their spending, budget, and saving habits.

IMPORTANT RULES:

1. Only use financial information provided by the SpendWise app.
2. Never invent transactions, amounts, categories, dates, or balances.
3. If information is not available, clearly say that it is not available.
4. Give practical and simple advice suitable for a student.
5. Keep answers concise and conversational.
6. Always use Indian Rupees (₹) when discussing money.
7. Perform calculations accurately using the provided numbers.
8. Never claim access to the user's bank account or live financial information.
9. Do not make up spending categories or transactions.
10. You can help with budgeting, affordability, spending habits, and saving.
11. Do not provide professional investment, tax, loan, or financial advice.
12. Talk naturally like a helpful personal money coach.
13. When asked about a month, use the actual transaction dates to determine the correct month.
14. When asked about categories, calculate totals from the provided transactions.
15. When comparing months, calculate each month's total using only transactions from that month.

The user may ask follow-up questions. Remember the conversation context and answer naturally.
        ''',
      ),
    );

    _chat = _model.startChat();
  }

  Future<void> askCoach() async {
    final question = controller.text.trim();

    if (question.isEmpty || thinking) {
      return;
    }

    final userMessage = question;

    controller.clear();

    setState(() {
      messages.add(
        _ChatMessage(
          text: userMessage,
          isUser: true,
        ),
      );

      thinking = true;
    });

    _scrollToBottom();

    try {
      // Load the latest budget and transactions from Firestore.
      await expenseStore.loadData();

      final budget = expenseStore.monthlyBudget;

      // Get ALL transactions, including previous months.
      final transactions = [...expenseStore.expenses];

      // Sort newest first.
      transactions.sort(
        (a, b) => b.date.compareTo(a.date),
      );

      final now = DateTime.now();

      // Calculate current month's expenses only.
      final currentMonthExpenses = transactions.where((expense) {
        return expense.date.year == now.year &&
            expense.date.month == now.month;
      }).toList();

      final currentMonthSpent = currentMonthExpenses.fold<double>(
        0,
        (sum, expense) => sum + expense.amount,
      );

      final remaining = budget - currentMonthSpent;

      // Prepare complete transaction history for Gemini.
      final transactionHistory = transactions.isEmpty
          ? 'No transactions have been recorded yet.'
          : transactions.map((expense) {
              final date =
                  '${expense.date.day.toString().padLeft(2, '0')}/'
                  '${expense.date.month.toString().padLeft(2, '0')}/'
                  '${expense.date.year}';

              return '- $date | '
                  '${expense.category} | '
                  '${expense.description} | '
                  '₹${expense.amount.toStringAsFixed(0)}';
            }).join('\n');

      final prompt = '''
CURRENT SPENDWISE FINANCIAL DATA

Current date:
${now.day}/${now.month}/${now.year}

Monthly budget:
₹${budget.toStringAsFixed(0)}

Current month spending:
₹${currentMonthSpent.toStringAsFixed(0)}

Current month remaining budget:
₹${remaining.toStringAsFixed(0)}

ALL RECORDED TRANSACTIONS:
$transactionHistory

USER'S MESSAGE:
"$userMessage"

ANSWER THE USER USING ONLY THE DATA ABOVE.

IMPORTANT:

- The transaction list contains transactions from multiple months.
- Use the transaction DATE to determine which month an expense belongs to.
- If the user says "last month", calculate the calendar month immediately before the current month.
- If the user asks about a specific month, use only transactions from that month.
- If the user asks "where am I spending too much?", group transactions by category and calculate category totals.
- If the user asks "what do I spend most on?", compare category totals.
- If the user asks for a month-to-month comparison, calculate each month's total separately.
- If the user asks about the current month, use only transactions from the current month.
- Never count an expense from another month as part of the current month.
- Never invent missing transactions or financial information.
- If there are no transactions for the requested period, clearly say so.
- Perform all calculations accurately.
- Always use Indian Rupees (₹).
- Keep the response concise, natural, and helpful.
''';

      final result = await _chat.sendMessage(
        Content.text(prompt),
      );

      final answer = result.text?.trim();

      if (!mounted) return;

      setState(() {
        thinking = false;

        messages.add(
          _ChatMessage(
            text: answer == null || answer.isEmpty
                ? 'I could not generate a response right now. Please try again.'
                : answer,
            isUser: false,
          ),
        );
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('================ GEMINI ERROR ================');
      debugPrint(e.toString());
      debugPrint('================================================');

      if (!mounted) return;

      setState(() {
        thinking = false;

        messages.add(
          const _ChatMessage(
            text:
                'I’m having trouble connecting to Gemini right now. '
                'Please try again in a moment.',
            isUser: false,
          ),
        );
      });

      _scrollToBottom();
    }
  }

  void useSuggestion(String text) {
    controller.text = text;
    askCoach();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AI Coach',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  Responsive.horizontalPadding(context), 
                  8, 
                  Responsive.horizontalPadding(context), 
                  16,
                ),
                children: [
                  const Text(
                    'Your personal money coach ✨',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Ask questions about your spending and budget.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Suggestions
                  if (messages.isEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _suggestion(
                          'How am I doing?',
                          () => useSuggestion(
                            'How am I doing this month?',
                          ),
                        ),
                        _suggestion(
                          'Can I afford ₹2,000?',
                          () => useSuggestion(
                            'Can I afford ₹2,000?',
                          ),
                        ),
                        _suggestion(
                          'Give me a saving tip',
                          () => useSuggestion(
                            'Give me a saving tip',
                          ),
                        ),
                      ],
                    ),

                  if (messages.isEmpty)
                    const SizedBox(height: 20),

                  // Chat messages
                  ...messages.map(
                    (message) => _messageBubble(message),
                  ),

                  // Typing indicator
                  if (thinking) _typingIndicator(),

                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Message input
            Container(
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context),
                10,
                Responsive.horizontalPadding(context),
                12,
              ),
              color: const Color(0xFFF7F9FC),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => askCoach(),
                      decoration: InputDecoration(
                        hintText: 'Ask SpendWise...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  SizedBox(
                    height: 54,
                    width: 54,
                    child: ElevatedButton(
                      onPressed: thinking ? null : askCoach,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFFBFA7F7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: thinking
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(_ChatMessage message) {
    if (message.isUser) {
      // USER MESSAGE — RIGHT SIDE
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 300,
          ),
          margin: const EdgeInsets.only(
            bottom: 12,
            left: 50,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF7C3AED),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    // GEMINI MESSAGE — LEFT SIDE
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 320,
        ),
        margin: const EdgeInsets.only(
          bottom: 12,
          right: 35,
        ),
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(5),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Color(0xFF7C3AED),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
          right: 100,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(5),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Color(0xFF7C3AED),
              ),
            ),

            const SizedBox(width: 10),

            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestion(
    String text,
    VoidCallback onTap,
  ) {
    return ActionChip(
      label: Text(text),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: const BorderSide(
        color: Color(0xFFE3D7F5),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}