import os
import re

file_path = r"c:\Users\vamsi\Downloads\Digital_wallet_app\lib\utils\localization_helper.dart"

new_keys = {
    'en': {
        'no_recent_transactions': 'No recent transactions',
        'no_contacts_found': 'No contacts found',
        'permission_required': 'Permission required',
        'recharge': 'Recharge',
        'electricity': 'Electricity',
        'water': 'Water',
        'dth': 'DTH',
        'fastag': 'FASTag',
        'broadband': 'Broadband',
        'gas': 'Gas',
        'all_filter': 'All',
        'received': 'Received',
        'sent': 'Sent',
        'bills': 'Bills',
        'generate_statement': 'Generate Statement',
        'select_duration_report': 'Select the duration for your transaction report',
        'download_statement': 'Download Statement',
        'download': 'Download',
        'track_spending': 'Track your spending & earnings',
        'search_transactions': 'Search transactions...',
        'no_transactions_found': 'No transactions found',
        'try_adjusting_filters': 'Try adjusting your filters',
        'no_qr_found': 'No QR code found in image',
        'qr_detected': 'QR Code Detected!',
        'paying_to': 'Paying to',
        'enter_amount': 'Enter amount',
        'enter_valid_amount': 'Please enter a valid amount',
        'paid_to': 'Paid to',
        'rewards_applied': 'Rewards Applied',
        'upi_payment': 'UPI Payment',
        'pay_now': 'Pay Now',
        'scan_again': 'Scan Again',
        'payment_successful': 'Payment Successful!',
        'transaction_completed': 'Your transaction has been completed.',
        'scan_any_qr': 'Scan any QR code',
        'point_camera_qr': 'Point camera at a QR code',
        'pay_contacts': 'Pay Contacts',
        'pay_phone_number': 'Pay Phone Number',
        'self_transfer': 'Self Transfer',
        'bank_transfer': 'Bank Transfer',
        'bot_welcome': "Hi! I'm Expensya, your personal financial assistant. How can I help you today? 🚀",
        'bot_select_option': 'Please select an option by tapping it or entering the number below:',
        'bot_valid_salary': 'Please enter a valid salary amount (e.g., 50000).',
        'bot_unrecognized_option': "I'm sorry, I didn't recognize that option. Please enter a number from 1 to 10.",
        'bot_plan_budget': "Let's plan your budget! 📊",
        'bot_ask_salary': 'First, what is your total monthly net salary (after taxes)?',
        'something_went_wrong': 'Something went wrong.',
        'bot_need_more_help': 'Do you need more help? (Enter another option number or scroll up to see the menu)',
        'bot_analyzing': 'Analyzing your spending habits from the previous month... 🔍',
        'bot_suggested_plan': 'Based on your salary of {salary} and last month\'s expenses ({expenses}), here is your suggested plan:',
        'bot_no_expenses_found': 'Last month\'s expenses were not found or not tracked. Assuming the following estimated expenses for your profile:',
        'intelligent_budget_plan': 'INTELLIGENT BUDGET PLAN',
        'assuming_default_values': 'Assuming default estimated values',
        'monthly_salary': 'Monthly Salary',
        'total_spent': 'Total Spent',
        'estimated_spent': 'Estimated Spent',
        'category_breakdown': 'Category breakdown:',
        'bills_upper': 'BILLS',
        'recharge_upper': 'RECHARGE',
        'projected_savings': 'Projected Savings',
        'budget_overrun': 'Budget Overrun',
        'suggested_daily_limit': 'Suggested Daily Limit',
        'day': 'day',
        'warning_overrun': 'Warning: Your spending exceeds your salary. Consider reducing non-essential expenses.',
        'bot_updated_budget': "I've also updated your active budget settings. Do you need more help?",
        'type_message': 'Type a number or message...',

        'faq_1_q': 'How to make a transaction?',
        'faq_2_q': 'How to add a bank account?',
        'faq_3_q': 'Plan my monthly budget',
        'faq_4_q': 'How to check transaction history?',
        'faq_5_q': 'How to change bank PIN?',
        'faq_6_q': 'How to link multiple accounts?',
        'faq_7_q': 'How to view insights?',
        'faq_8_q': 'How to reset PIN?',
        'faq_9_q': 'How to contact support?',
        'faq_10_q': 'How to increase wallet security?',

        'faq_1_a1': "To make a transaction:",
        'faq_1_a2': "1. Go to the Home screen.",
        'faq_1_a3': "2. Tap on 'To Contact' or use the 'Scanner'.",
        'faq_1_a4': "3. Enter the amount and receiver's details.",
        'faq_1_a5': "4. Confirm with your transaction PIN.",
        
        'faq_2_a1': "To add a bank account:",
        'faq_2_a2': "1. Navigate to the Check Balance / Wallet screen.",
        'faq_2_a3': "2. Select 'Add UPI Account'.",
        'faq_2_a4': "3. Enter your bank name, account number, and IFSC code.",
        'faq_2_a5': "4. Follow the prompts to verify your account.",

        'faq_3_a1': "To plan your budget:",
        'faq_3_a2': "1. Tap the 'Expensya' tab in the navigation bar.",
        'faq_3_a3': "2. Follow my prompts to enter your income and expenses.",
        'faq_3_a4': "3. I will analyze your spending and provide a daily limit.",

        'faq_4_a1': "To check transaction history:",
        'faq_4_a2': "1. Tap the 'History' icon in the bottom navigation.",
        'faq_4_a3': "2. You can see a list of all your recent transactions.",
        'faq_4_a4': "3. Tap on any transaction to see details or download a receipt.",

        'faq_5_a1': "To change your bank PIN:",
        'faq_5_a2': "1. Go to the 'Profile' screen.",
        'faq_5_a3': "2. Select 'Payment Settings' or 'Security'.",
        'faq_5_a4': "3. Choose 'Change PIN' under the relevant bank account.",
        'faq_5_a5': "4. Verify your current PIN and set a new one.",

        'faq_6_a1': "To link multiple accounts:",
        'faq_6_a2': "1. Go to the 'Wallet' screen.",
        'faq_6_a3': "2. Use the 'Add Account' button multiple times for each bank.",
        'faq_6_a4': "3. Your linked accounts will appear in a list for easy switching.",

        'faq_7_a1': "To view insights:",
        'faq_7_a2': "1. Tap the 'Insights' tab in the navigation bar.",
        'faq_7_a3': "2. You'll see graphical representations of your spending.",
        'faq_7_a4': "3. Use the 'Total' or 'Weekly' views to track trends.",

        'faq_8_a1': "To reset your app PIN:",
        'faq_8_a2': "1. Go to the 'Profile' screen.",
        'faq_8_a3': "2. Tap on 'App Settings' and then 'Security'.",
        'faq_8_a4': "3. Select 'Reset App PIN'.",
        'faq_8_a5': "4. Verify via your phone number or biometrics.",

        'faq_9_a1': "To contact support:",
        'faq_9_a2': "1. Go to 'Profile'.",
        'faq_9_a3': "2. Scroll down to 'Help & Support'.",
        'faq_9_a4': "3. You can find our email, chat, and call options there.",

        'faq_10_a1': "To increase wallet security:",
        'faq_10_a2': "1. Enable two-factor authentication in 'Security'.",
        'faq_10_a3': "2. Set a strong, unique PIN.",
        'faq_10_a4': "3. Regularly check your transaction history for anomalies.",
        'faq_10_a5': "4. Use biometric login if your device supports it.",

        'login_to_see_banks': 'Please login to see bank accounts',
        'no_banks_linked': 'No bank accounts linked',
        'savings': 'Savings',
        'primary': 'Primary',
        'set_as_primary': 'Set as Primary Account',
        'primary_account_updated': 'Primary account updated successfully.',
        'change_pin': 'Change PIN',
        'delete_account': 'Delete Account',
        'remove_account': 'Remove Account?',
        'sure_remove_part1': 'Are you sure you want to remove',
        'ending_in': 'ending in',
        'need_pin_to_confirm': 'You will need your PIN to confirm.',
        'cancel': 'Cancel',
        'remove': 'Remove',
        'bank_removed_successfully': 'Bank account removed successfully.',
        'link_new_bank': 'Link New Bank Account',
        'bank_name': 'Bank Name',
        'account_number': 'Account Number',
        'ifsc_code': 'IFSC Code',
        'bank_linked_successfully': 'Bank account and PIN linked successfully!',
        'link_account': 'Link Account',
        'bank_pin_updated': 'Bank PIN updated successfully!'
    },
    'hi': {
        'no_recent_transactions': 'कोई हालिया लेनदेन नहीं',
        'no_contacts_found': 'कोई संपर्क नहीं मिला',
        'permission_required': 'अनुमति आवश्यक है',
        'recharge': 'रिचार्ज',
        'electricity': 'बिजली',
        'water': 'पानी',
        'dth': 'DTH',
        'fastag': 'FASTag',
        'broadband': 'ब्रॉडबैंड',
        'gas': 'गैस',
        'all_filter': 'सभी',
        'received': 'प्राप्त',
        'sent': 'भेजा गया',
        'bills': 'बिल',
        'generate_statement': 'स्टेटमेंट जनरेट करें',
        'select_duration_report': 'लेनदेन रिपोर्ट की अवधि चुनें',
        'download_statement': 'स्टेटमेंट डाउनलोड करें',
        'download': 'डाउनलोड करें',
        'track_spending': 'अपने खर्च और आय पर नज़र रखें',
        'search_transactions': 'लेनदेन खोजें...',
        'no_transactions_found': 'कोई लेनदेन नहीं मिला',
        'try_adjusting_filters': 'फ़िल्टर बदलने का प्रयास करें',
        'no_qr_found': 'छवि में कोई QR कोड नहीं मिला',
        'qr_detected': 'QR कोड मिल गया!',
        'paying_to': 'भुगतान कर रहे हैं',
        'enter_amount': 'राशि दर्ज करें',
        'enter_valid_amount': 'कृपया एक वैध राशि दर्ज करें',
        'paid_to': 'का भुगतान किया',
        'rewards_applied': 'पुरस्कार लागू',
        'upi_payment': 'UPI भुगतान',
        'pay_now': 'अभी भुगतना करें',
        'scan_again': 'फिर से स्कैन करें',
        'payment_successful': 'भुगतान सफल!',
        'transaction_completed': 'आपका लेनदेन पूरा हो गया है।',
        'scan_any_qr': 'कोई भी QR कोड स्कैन करें',
        'point_camera_qr': 'QR कोड पर कैमरा इंगित करें',
        'pay_contacts': 'संपर्कों को भुगतान',
        'pay_phone_number': 'फ़ोन नंबर पर भुगतान',
        'self_transfer': 'स्वयं को स्थानांतरण',
        'bank_transfer': 'बैंक स्थानांतरण',
        'bot_welcome': "नमस्ते! मैं Expensya हूँ, आपका वित्तीय सहायक। मैं आज आपकी कैसे मदद कर सकता हूँ? 🚀",
        'bot_select_option': 'कृपया नीचे दिए गए नंबर को दर्ज करें या किसी विकल्प पर टैप करें:',
        'bot_valid_salary': 'कृपया एक वैध वेतन राशि दर्ज करें (जैसे, 50000)।',
        'bot_unrecognized_option': "क्षमा करें, मैंने उस विकल्प को नहीं पहचाना। कृपया 1 से 10 के बीच एक संख्या दर्ज करें।",
        'bot_plan_budget': "चलो अपना बजट बनाएँ! 📊",
        'bot_ask_salary': 'सबसे पहले, आपका कुल मासिक शुद्ध वेतन (कर कटौती के बाद) क्या है?',
        'something_went_wrong': 'कुछ गलत हो गया।',
        'bot_need_more_help': 'क्या आपको और मदद की ज़रूरत है? (अन्य विकल्प नंबर दर्ज करें या मेनू જોવાके लिए ऊपर स्क्रॉल करें)',
        'bot_analyzing': 'पिछले महीने के आपके खर्च करने की आदतों का विश्लेषण किया जा रहा है... 🔍',
        'bot_suggested_plan': '₹{salary} के वेतन और पिछले महीने के खर्चों (₹{expenses}) के आधार पर, यह आपकी सुझाई गई योजना है:',
        'bot_no_expenses_found': 'पिछले महीने के खर्च नहीं मिले। आपकी પ્રોफ़ाइल के लिए अनुमानित खर्च नीचे दिए गए हैं:',
        'intelligent_budget_plan': 'बुद्धिमान बजट योजना',
        'assuming_default_values': 'डिफ़ॉल्ट अनुमानित मानों को मान लेना',
        'monthly_salary': 'मासिक वेतन',
        'total_spent': 'कुल खर्च',
        'estimated_spent': 'अनुमानित खर्च',
        'category_breakdown': 'श्रेणीवार विवरण:',
        'bills_upper': 'बिल',
        'recharge_upper': 'रिचार्ज',
        'projected_savings': 'अनुमानित बचत',
        'budget_overrun': 'बजट अधिक होना',
        'suggested_daily_limit': 'सुझाई गई दैनिक सीमा',
        'day': 'दिन',
        'warning_overrun': 'चेतावनी: आपका खर्च आपके वेतन से अधिक है। खर्च को कम करने पर विचार करें।',
        'bot_updated_budget': "मैंने आपकी सक्रिय बजट सेटिंग्स अपडेट कर दी हैं। क्या आपको और मदद चाहिए?",
        'type_message': 'कोई नंबर या संदेश टाइप करें...',

        'faq_1_q': "लेनदेन कैसे करें?",
        'faq_2_q': "बैंक खाता कैसे जोड़ें?",
        'faq_3_q': "मेरा मासिक बजट योजना बनाएँ",
        'faq_4_q': "लेनदेन का इतिहास कैसे जांचें?",
        'faq_5_q': "बैंक पिन कैसे बदलें?",
        'faq_6_q': "कई खातों को कैसे लिंक करें?",
        'faq_7_q': "इंसाइड्स कैसे देखें?",
        'faq_8_q': "पिन कैसे रीसेट करें?",
        'faq_9_q': "समर्थन टीम से कैसे संपर्क करें?",
        'faq_10_q': "वॉलेट की सुरक्षा कैसे बढ़ाएं?",

        'faq_1_a1': "लेनदेन करने के लिए:",
        'faq_1_a2': "1. होम स्क्रीन पर जाएं।",
        'faq_1_a3': "2. 'संपर्क करने के लिए' टैप करें या 'स्कैनर' का उपयोग करें।",
        'faq_1_a4': "3. राशि और प्राप्तकर्ता का विवरण दर्ज करें।",
        'faq_1_a5': "4. अपने लेनदेन पिन की पुष्टि करें।",
        
        'faq_2_a1': "बैंक खाता जोड़ने के लिए:",
        'faq_2_a2': "1. बैलेंस चेक / वॉलेट स्क्रीन पर नेविगेट करें।",
        'faq_2_a3': "2. 'UPI खाता जोड़ें' चुनें।",
        'faq_2_a4': "3. अपना बैंक का नाम, खाता संख्या और IFSC कोड दर्ज करें।",
        'faq_2_a5': "4. अपने खाते को सत्यापित करने के लिए संकेतों का पालन करें।",

        'faq_3_a1': "अपना बजट योजना बनाने के लिए:",
        'faq_3_a2': "1. नेविगेशन बार में 'Expensya' टैब टैप करें।",
        'faq_3_a3': "2. अपनी आय और खर्चों को दर्ज करने के लिए मेरे संकेतों का पालन करें।",
        'faq_3_a4': "3. मैं आपके खर्च का विश्लेषण करूँगा और दैनिक सीमा प्रदान करूँगा।",

        'faq_4_a1': "लेनदेन का इतिहास जांचने के लिए:",
        'faq_4_a2': "1. निचले नेविगेशन में 'इतिहास' आइकन पर टैप करें।",
        'faq_4_a3': "2. आप अपने सभी हाल के लेनदेन की सूची देख सकते हैं।",
        'faq_4_a4': "3. विवरण देखने या रसीद डाउनलोड करने के लिए किसी भी लेनदेन पर टैप करें।",

        'faq_5_a1': "अपना बैंक पिन बदलने के लिए:",
        'faq_5_a2': "1. 'प्रोफ़ाइल' स्क्रीन पर जाएं।",
        'faq_5_a3': "2. 'भुगतान सेटिंग्स' या 'सुरक्षा' चुनें।",
        'faq_5_a4': "3. संबंधित बैंक खाते के तहत 'पिन बदलें' चुनें।",
        'faq_5_a5': "4. अपना वर्तमान पिन सत्यापित करें और एक नया सेट करें।",

        'faq_6_a1': "कई खातों को लिंक करने के लिए:",
        'faq_6_a2': "1. 'वॉलेट' स्क्रीन पर जाएं।",
        'faq_6_a3': "2. प्रत्येक बैंक के लिए कई बार 'खाता जोड़ें' बटन का उपयोग करें।",
        'faq_6_a4': "3. आपके लिंक किए गए खाते आसान स्विचिंग के लिए एक सूची में दिखाई देंगे।",

        'faq_7_a1': "इंसाइड्स देखने के लिए:",
        'faq_7_a2': "1. नेविगेशन बार में 'इंसाइड्स' टैब टैप करें।",
        'faq_7_a3': "2. आपको अपने खर्च के ग्राफ मिल जाएंगे।",
        'faq_7_a4': "3. रुझानों को ट्रैक करने के लिए 'कुल' या 'साप्ताहिक' दृश्यों का उपयोग करें।",

        'faq_8_a1': "अपना ऐप पिन रीसेट करने के लिए:",
        'faq_8_a2': "1. 'प्रोफ़ाइल' स्क्रीन पर जाएं।",
        'faq_8_a3': "2. 'ऐप सेटिंग्स' और फिर 'सुरक्षा' पर टैप करें।",
        'faq_8_a4': "3. 'ऐप पिन रीसेट करें' चुनें।",
        'faq_8_a5': "4. अपने फोन नंबर या बायोमेट्रिक्स के माध्यम से सत्यापित करें।",

        'faq_9_a1': "स्मर्थन के लिए संपर्क करने हेतु:",
        'faq_9_a2': "1. 'प्रोफ़ाइल' पर जाएं।",
        'faq_9_a3': "2. 'सहायता और समर्थन' तक नीचे स्क्रॉल करें।",
        'faq_9_a4': "3. आप वहां हमारे ईमेल, चैट और कॉल विकल्प पा सकते हैं।",

        'faq_10_a1': "वॉलेट की सुरक्षा बढ़ाने के लिए:",
        'faq_10_a2': "1. 'सुरक्षा' में दो-कारक प्रमाणीकरण सक्षम करें।",
        'faq_10_a3': "2. एक मजबूत, अनोखा पिन सेट करें।",
        'faq_10_a4': "3. विसंगतियों के लिए नियमित रूप से अपने लेनदेन इतिहास की जांच करें।",
        'faq_10_a5': "4. यदि आपका डिवाइस इसका समर्थन करता है तो बायोमेट्रिक लॉगिन का उपयोग करें।",

        'login_to_see_banks': 'बैंक खातों को देखने के लिए कृपया लॉगिन करें',
        'no_banks_linked': 'कोई बैंक खाता लिंक नहीं है',
        'savings': 'बचत',
        'primary': 'प्राथमिक',
        'set_as_primary': 'प्राथमिक खाते के रूप में सेट करें',
        'primary_account_updated': 'प्राथमिक खाता सफलतापूर्वक अपडेट किया गया।',
        'change_pin': 'पिन बदलें',
        'delete_account': 'खाता हटाएं',
        'remove_account': 'खाता हटाएं?',
        'sure_remove_part1': 'क्या आप वाकई',
        'ending_in': 'में समाप्त होने वाले',
        'need_pin_to_confirm': 'को हटाना चाहते हैं? पुष्टि करने के लिए पिन आवश्यकता होगी।',
        'cancel': 'रद्द करें',
        'remove': 'हटाएं',
        'bank_removed_successfully': 'बैंक खाता सफलतापूर्वक हटा दिया गया।',
        'link_new_bank': 'नया बैंक खाता लिंक करें',
        'bank_name': 'बैंक का नाम',
        'account_number': 'खाता संख्या',
        'ifsc_code': 'IFSC कोड',
        'bank_linked_successfully': 'बैंक खाता और पिन सफलतापूर्वक लिंक किए गए!',
        'link_account': 'खाता लिंक करें',
        'bank_pin_updated': 'बैंक पिन सफलतापूर्वक अपडेट किया गया!'
    },
    'te': {},
    'ta': {},
    'kn': {}
}

import codecs

for lang in ['te', 'ta', 'kn']:
    new_keys[lang] = new_keys['en'].copy()

with codecs.open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

for lang, keys_dict in new_keys.items():
    lang_block_regex = re.compile(rf"('{lang}':\s*{{)([\s\S]*?)(}})", re.MULTILINE)
    
    match = lang_block_regex.search(content)
    if match:
        existing_block = match.group(2)
        new_entries = []
        for k, v in keys_dict.items():
            if f"'{k}':" not in existing_block:
                escaped_val = str(v).replace("'", "\'")
                new_entries.append(f"      '{k}': '{escaped_val}',")
        
        if new_entries:
            updated_block = existing_block.rstrip()
            if not updated_block.endswith(","):
                updated_block += ",\n"
            else:
                updated_block += "\n"
            updated_block += "\n".join(new_entries) + "\n    "
            
            content = content[:match.start(2)] + updated_block + content[match.end(2):]

with codecs.open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done patching L10n")
