import re
import codecs

file_path = r"c:\Users\vamsi\Downloads\Digital_wallet_app\lib\utils\localization_helper.dart"

with codecs.open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# We look for lines like `      'key': 'value',`
def replacer(match):
    key_part = match.group(1) # e.g. "      'bot_welcome': "
    val_part = match.group(2) # e.g. "Hi! I'm Expensya"
    
    # Check if there's an unescaped single quote inside val_part (a hint it might be broken)
    # Actually, we can just safely wrap ALL values in double quotes, 
    # but some values might already be properly formatted. 
    # The safest is to replace " 'value'," with ' "value",' 
    # However val_part is literally what is between the first single quote and the last single quote and comma.
    # Because of darts syntax, the broken lines have multiple single quotes. 
    # Let's just catch anything between `': '` and `',`
    
    escaped_val = val_part.replace('"', '\\"')
    return f"{key_part}\"{escaped_val}\","

new_content = re.sub(r"^(\s+'\w+':\s+)'(.*)',\s*$", replacer, content, flags=re.MULTILINE)

with codecs.open(file_path, "w", encoding="utf-8") as f:
    f.write(new_content)

print("Fixed quotes.")
