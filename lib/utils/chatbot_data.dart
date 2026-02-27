class ChatbotData {
  static const Map<int, String> questions = {
    1: "How to make a transaction?",
    2: "How to add a bank account?",
    3: "Plan my monthly budget",
    4: "How to check transaction history?",
    5: "How to change bank PIN?",
    6: "How to link multiple accounts?",
    7: "How to view insights?",
    8: "How to reset PIN?",
    9: "How to contact support?",
    10: "How to increase wallet security?",
  };

  static const Map<int, List<String>> answers = {
    1: [
      "To make a transaction:",
      "1. Go to the Home screen.",
      "2. Tap on 'To Contact' or use the 'Scanner'.",
      "3. Enter the amount and receiver's details.",
      "4. Confirm with your transaction PIN.",
    ],
    2: [
      "To add a bank account:",
      "1. Navigate to the Check Balance / Wallet screen.",
      "2. Select 'Add UPI Account'.",
      "3. Enter your bank name, account number, and IFSC code.",
      "4. Follow the prompts to verify your account.",
    ],
    3: [
      "To plan your budget:",
      "1. Tap the 'Expensya' tab in the navigation bar.",
      "2. Follow my prompts to enter your income and expenses.",
      "3. I will analyze your spending and provide a daily limit.",
    ],
    4: [
      "To check transaction history:",
      "1. Tap the 'History' icon in the bottom navigation.",
      "2. You can see a list of all your recent transactions.",
      "3. Tap on any transaction to see details or download a receipt.",
    ],
    5: [
      "To change your bank PIN:",
      "1. Go to the 'Profile' screen.",
      "2. Select 'Payment Settings' or 'Security'.",
      "3. Choose 'Change PIN' under the relevant bank account.",
      "4. Verify your current PIN and set a new one.",
    ],
    6: [
      "To link multiple accounts:",
      "1. Go to the 'Wallet' screen.",
      "2. Use the 'Add Account' button multiple times for each bank.",
      "3. Your linked accounts will appear in a list for easy switching.",
    ],
    7: [
      "To view insights:",
      "1. Tap the 'Insights' tab in the navigation bar.",
      "2. You'll see graphical representations of your spending.",
      "3. Use the 'Total' or 'Weekly' views to track trends.",
    ],
    8: [
      "To reset your app PIN:",
      "1. Go to the 'Profile' screen.",
      "2. Tap on 'App Settings' and then 'Security'.",
      "3. Select 'Reset App PIN'.",
      "4. Verify via your phone number or biometrics.",
    ],
    9: [
      "To contact support:",
      "1. Go to 'Profile'.",
      "2. Scroll down to 'Help & Support'.",
      "3. You can find our email, chat, and call options there.",
    ],
    10: [
      "To increase wallet security:",
      "1. Enable two-factor authentication in 'Security'.",
      "2. Set a strong, unique PIN.",
      "3. Regularly check your transaction history for anomalies.",
      "4. Use biometric login if your device supports it.",
    ],
  };

  static String? getAnswer(int option) {
    if (answers.containsKey(option)) {
      return answers[option]!.join("\n");
    }
    return null;
  }
}
