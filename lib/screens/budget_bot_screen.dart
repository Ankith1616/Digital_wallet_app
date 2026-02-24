import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import '../utils/budget_manager.dart';

class BudgetBotScreen extends StatefulWidget {
  const BudgetBotScreen({super.key});

  @override
  State<BudgetBotScreen> createState() => _BudgetBotScreenState();
}

enum BotState { salary, rent, bills, savings, finished }

class Message {
  final String text;
  final bool isBot;
  final Widget? customWidget;

  Message({required this.text, required this.isBot, this.customWidget});
}

class _BudgetBotScreenState extends State<BudgetBotScreen> {
  final List<Message> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  BotState _currentState = BotState.salary;
  bool _isTyping = false;

  // Captured Data
  double _salary = 0;
  double _rent = 0;
  double _bills = 0;
  double _savings = 0;

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      "Hi! I'm Expensya, your AI Budget Bot. Let's plan your month together. 🚀",
    );
    _addBotMessage(
      "First, what is your total monthly net salary (after taxes)?",
    );
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

    final val = double.tryParse(text) ?? 0;
    if (val <= 0 && _currentState != BotState.finished) {
      // Simple validation
      return;
    }

    setState(() {
      _messages.add(Message(text: "₹$text", isBot: false));
      _inputController.clear();
    });
    _scrollToBottom();

    _processNextState(val);
  }

  void _processNextState(double val) {
    switch (_currentState) {
      case BotState.salary:
        _salary = val;
        _currentState = BotState.rent;
        _addBotMessage(
          "Got it! ₹${_salary.toStringAsFixed(0)}. Now, how much do you pay for Rent or Home Loan monthly?",
        );
        break;
      case BotState.rent:
        _rent = val;
        _currentState = BotState.bills;
        _addBotMessage(
          "Noted. And your average monthly bills (Electricity, Water, Internet, etc.)?",
        );
        break;
      case BotState.bills:
        _bills = val;
        _currentState = BotState.savings;
        _addBotMessage(
          "Understood. Finally, what is your savings goal for this month? (Amount in ₹)",
        );
        break;
      case BotState.savings:
        _savings = val;
        _currentState = BotState.finished;
        _addBotMessage(
          "Perfect! I've analyzed your inputs. Here is your detailed monthly spending report:",
        );
        BudgetManager().updateBudget(
          salary: _salary,
          rent: _rent,
          bills: _bills,
          savingsGoal: _savings,
        );
        _showReport();
        break;
      case BotState.finished:
        _addBotMessage(
          "If you want to start over, just go back and return to this screen!",
        );
        break;
    }
  }

  void _showReport() async {
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final disposable = _salary - _rent - _bills - _savings;
    final daily = disposable / 30;

    setState(() {
      _isTyping = false;
      _messages.add(
        Message(
          text: "",
          isBot: true,
          customWidget: _buildReportCard(disposable, daily),
        ),
      );
    });
    _scrollToBottom();
  }

  Widget _buildReportCard(double disposable, double daily) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "MONTHLY BUDGET PLAN",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
          const Divider(height: 24),
          _reportItem(
            "Total Salary",
            "₹${_salary.toStringAsFixed(0)}",
            Colors.green,
          ),
          _reportItem(
            "Fixed Costs",
            "- ₹${(_rent + _bills).toStringAsFixed(0)}",
            Colors.red,
          ),
          _reportItem(
            "Savings Goal",
            "- ₹${_savings.toStringAsFixed(0)}",
            Colors.blue,
          ),
          const Divider(height: 24),
          Text(
            "Disposable Income",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
          Text(
            "₹${disposable.toStringAsFixed(0)}",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
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
                      Text(
                        "Daily Spending Limit",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "₹${daily.toStringAsFixed(0)} / day",
                        style: GoogleFonts.poppins(
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
          const SizedBox(height: 16),
          Text(
            "* Tip: Try to keep food and shopping under 40% of your disposable income (₹${(disposable * 0.4).toStringAsFixed(0)}).",
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Expensya",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
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
                if (msg.customWidget != null) return msg.customWidget!;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (msg.isBot)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, right: 8),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage: const AssetImage(
                            'assets/images/Expensya.png',
                          ),
                        ),
                      ),
                    Expanded(child: _buildChatBubble(msg)),
                  ],
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Message msg) {
    return Align(
      alignment: msg.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isBot
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isBot ? 0 : 18),
            bottomRight: Radius.circular(msg.isBot ? 18 : 0),
          ),
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.poppins(
            color: msg.isBot ? AppColors.primary : Colors.white,
            fontSize: 14,
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
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter amount...",
                hintStyle: GoogleFonts.poppins(fontSize: 14),
                prefixText: "₹ ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => _handleUserInput(),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: AppColors.primary,
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
