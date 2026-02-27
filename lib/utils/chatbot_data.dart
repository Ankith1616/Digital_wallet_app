import '../utils/localization_helper.dart';

class ChatbotData {
  static Map<int, String> get questions => {
    1: L10n.s("faq_1_q"),
    2: L10n.s("faq_2_q"),
    3: L10n.s("faq_3_q"),
    4: L10n.s("faq_4_q"),
    5: L10n.s("faq_5_q"),
    6: L10n.s("faq_6_q"),
    7: L10n.s("faq_7_q"),
    8: L10n.s("faq_8_q"),
    9: L10n.s("faq_9_q"),
    10: L10n.s("faq_10_q"),
  };

  static Map<int, List<String>> get answers => {
    1: [
      L10n.s("faq_1_a1"),
      L10n.s("faq_1_a2"),
      L10n.s("faq_1_a3"),
      L10n.s("faq_1_a4"),
      L10n.s("faq_1_a5"),
    ],
    2: [
      L10n.s("faq_2_a1"),
      L10n.s("faq_2_a2"),
      L10n.s("faq_2_a3"),
      L10n.s("faq_2_a4"),
      L10n.s("faq_2_a5"),
    ],
    3: [
      L10n.s("faq_3_a1"),
      L10n.s("faq_3_a2"),
      L10n.s("faq_3_a3"),
      L10n.s("faq_3_a4"),
    ],
    4: [
      L10n.s("faq_4_a1"),
      L10n.s("faq_4_a2"),
      L10n.s("faq_4_a3"),
      L10n.s("faq_4_a4"),
    ],
    5: [
      L10n.s("faq_5_a1"),
      L10n.s("faq_5_a2"),
      L10n.s("faq_5_a3"),
      L10n.s("faq_5_a4"),
      L10n.s("faq_5_a5"),
    ],
    6: [
      L10n.s("faq_6_a1"),
      L10n.s("faq_6_a2"),
      L10n.s("faq_6_a3"),
      L10n.s("faq_6_a4"),
    ],
    7: [
      L10n.s("faq_7_a1"),
      L10n.s("faq_7_a2"),
      L10n.s("faq_7_a3"),
      L10n.s("faq_7_a4"),
    ],
    8: [
      L10n.s("faq_8_a1"),
      L10n.s("faq_8_a2"),
      L10n.s("faq_8_a3"),
      L10n.s("faq_8_a4"),
      L10n.s("faq_8_a5"),
    ],
    9: [
      L10n.s("faq_9_a1"),
      L10n.s("faq_9_a2"),
      L10n.s("faq_9_a3"),
      L10n.s("faq_9_a4"),
    ],
    10: [
      L10n.s("faq_10_a1"),
      L10n.s("faq_10_a2"),
      L10n.s("faq_10_a3"),
      L10n.s("faq_10_a4"),
      L10n.s("faq_10_a5"),
    ],
  };

  static String? getAnswer(int option) {
    if (answers.containsKey(option)) {
      return answers[option]!.join("\n");
    }
    return null;
  }
}
