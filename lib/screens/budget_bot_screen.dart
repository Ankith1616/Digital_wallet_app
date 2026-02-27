import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import '../utils/chatbot_data.dart';
import '../utils/localization_helper.dart';
import '../utils/transaction_manager.dart';
import '../utils/budget_manager.dart';

class ExpensyaChatbotScreen extends StatefulWidget {
  const ExpensyaChatbotScreen({super.key});

  @override
  State<ExpensyaChatbotScreen> createState() => _ExpensyaChatbotScreenState();
}

enum ChatFlow { menu, help, budgetSalary, budgetResult }

class Message {
  final String text;
  final bool isBot;
  final Widget? customWidget;
  final DateTime timestamp;

  Message({required this.text, required this.isBot, this.customWidget})
    : timestamp = DateTime.now();
}

class _ExpensyaChatbotScreenState extends State<ExpensyaChatbotScreen> {
  final List<Message> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  ChatFlow _currentFlow = ChatFlow.menu;

  @override
  void initState() {
    super.initState();
    _showWelcomeMessage();
  }

  void _showWelcomeMessage() async {
    _addBotMessage(
      "Hi! I'm Expensya, your personal financial assistant. How can I help you today? 🚀",
    );
    await Future.delayed(const Duration(milliseconds: 500));
    _showMenu();
  }

  void _showMenu() {
    _currentFlow = ChatFlow.menu;
    _addBotMessage(
      "Please select an option by tapping it or entering the number below:",
    );

    final menuWidget = Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: ChatbotData.questions.entries.map((entry) {
          return InkWell(
            onTap: () => _handleSelection(entry.key),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${entry.key}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    setState(() {
      _messages.add(Message(text: "", isBot: true, customWidget: menuWidget));
    });
    _scrollToBottom();
  }

  void _addBotMessage(String text) async {
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(Message(text: text, isBot: true));
    });
    _scrollToBottom();
  }

  void _addCustomerMessage(String text) {
    setState(() {
      _messages.add(Message(text: text, isBot: false));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleUserInput() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _addCustomerMessage(text);
    _inputController.clear();

    if (_currentFlow == ChatFlow.budgetSalary) {
      final salary = double.tryParse(text);
      if (salary != null && salary > 0) {
        _processBudgetPlan(salary);
      } else {
        _addBotMessage("Please enter a valid salary amount (e.g., 50000).");
      }
      return;
    }

    final option = int.tryParse(text);
    if (option != null && ChatbotData.questions.containsKey(option)) {
      _handleSelection(option);
    } else {
      _addBotMessage(
        "I'm sorry, I didn't recognize that option. Please enter a number from 1 to 10.",
      );
    }
  }

  void _handleSelection(int option) {
    if (option != 3) {
      // General help option
      _addCustomerMessage(ChatbotData.questions[option]!);
      _processHelpResponse(option);
    } else {
      // Specialized Budget Planning flow
      _currentFlow = ChatFlow.budgetSalary;
      _addBotMessage("Let's plan your budget! 📊");
      _addBotMessage(
        "First, what is your total monthly net salary (after taxes)?",
      );
    }
  }

  void _processHelpResponse(int option) async {
    _currentFlow = ChatFlow.help;
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final answer = ChatbotData.getAnswer(option);
    setState(() {
      _isTyping = false;
      _messages.add(
        Message(text: answer ?? "Something went wrong.", isBot: true),
      );
    });

    await Future.delayed(const Duration(milliseconds: 500));
    _addBotMessage(
      "Do you need more help? (Enter another option number or scroll up to see the menu)",
    );
    _currentFlow = ChatFlow.menu;
    _scrollToBottom();
  }

  void _processBudgetPlan(double salary) async {
    _currentFlow = ChatFlow.budgetResult;
    _addBotMessage(
      "Analyzing your spending habits from the previous month... 🔍",
    );

    // Get last month's date range
    final now = DateTime.now();
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayLastMonth = DateTime(now.year, now.month, 0);

    int lastMonth = firstDayLastMonth.month;
    int lastYear = firstDayLastMonth.year;

    // Fetch actual historical expenses
    final historicalExpense = TransactionManager().getMonthlyExpense(
      lastMonth,
      lastYear,
    );
    final categorySpending = TransactionManager().getCategorySpending(
      firstDayLastMonth,
      lastDayLastMonth,
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final hasData = historicalExpense > 0;
    final displayExpense = hasData
        ? historicalExpense
        : 5300.0; // Assumed total if no data

    final disposable = salary - displayExpense;
    final dailyLimit = disposable > 0 ? disposable / 30 : 0.0;

    if (hasData) {
      _addBotMessage(
        "Based on your salary of ₹${salary.toStringAsFixed(0)} and last month's expenses (₹${historicalExpense.toStringAsFixed(0)}), here is your suggested plan:",
      );
    } else {
      _addBotMessage(
        "Last month's expenses were not found or not tracked. Assuming the following estimated expenses for your profile:",
      );
    }

    final reportWidget = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "INTELLIGENT BUDGET PLAN",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
              if (!hasData)
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
            ],
          ),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "Assuming default estimated values",
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const Divider(height: 24),
          _reportItem(
            "Monthly Salary",
            "₹${salary.toStringAsFixed(0)}",
            Colors.green,
          ),
          _reportItem(
            hasData ? "Total Spent" : "Estimated Spent",
            "₹${displayExpense.toStringAsFixed(0)}",
            Colors.red,
          ),

          const SizedBox(height: 12),
          Text(
            "Category breakdown:",
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (hasData)
            ...categorySpending.entries.map(
              (e) => _reportItem(
                e.key.name.toUpperCase(),
                "₹${e.value.toStringAsFixed(0)}",
                Colors.grey[700]!,
              ),
            )
          else ...[
            _reportItem("BILLS", "₹5000", Colors.grey[700]!),
            _reportItem("RECHARGE", "₹300", Colors.grey[700]!),
          ],

          const Divider(height: 24),
          Text(
            disposable > 0 ? "Projected Savings" : "Budget Overrun",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
          Text(
            "₹${disposable.abs().toStringAsFixed(0)}",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: disposable > 0 ? AppColors.primary : Colors.red,
            ),
          ),
          if (disposable > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Suggested Daily Limit",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          "₹${dailyLimit.toStringAsFixed(0)} / day",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                "Warning: Your spending exceeds your salary. Consider reducing non-essential expenses.",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );

    setState(() {
      _messages.add(Message(text: "", isBot: true, customWidget: reportWidget));
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    _addBotMessage(
      "I've also updated your active budget settings. Do you need more help?",
    );

    // Actually update the app's budget state if needed
    BudgetManager().updateBudget(
      salary: salary,
      rent: 0,
      bills: historicalExpense,
      savingsGoal: disposable > 0
          ? disposable * 0.2
          : 0, // Suggest 20% savings if positive
    );

    _currentFlow = ChatFlow.menu;
    _scrollToBottom();
  }

  Widget _reportItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          L10n.s('chatbot'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                if (msg.customWidget != null) {
                  return Column(
                    children: [
                      if (msg.text.isNotEmpty) _buildChatBubble(msg),
                      msg.customWidget!,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: msg.isBot
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                  children: [
                    if (msg.isBot)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, right: 8),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.smart_toy_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    Flexible(child: _buildChatBubble(msg)),
                    if (!msg.isBot)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6, left: 8),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey,
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Message msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: msg.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isBot
              ? (isDark ? Colors.grey[800] : Colors.grey[200])
              : AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isBot ? 0 : 18),
            bottomRight: Radius.circular(msg.isBot ? 18 : 0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.poppins(
            color: msg.isBot
                ? (isDark ? Colors.white : Colors.black87)
                : Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: "Type a number or message...",
                hintStyle: GoogleFonts.poppins(fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _handleUserInput(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: _handleUserInput,
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
