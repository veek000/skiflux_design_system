import re

with open('ios/Runner/Info.plist', 'r', encoding='utf-8') as f:
    text = f.read()

if '<key>FlutterDeepLinkingEnabled</key>' not in text:
    text = text.replace('</dict>\n</plist>', '\t<key>FlutterDeepLinkingEnabled</key>\n\t<true/>\n</dict>\n</plist>')
    with open('ios/Runner/Info.plist', 'w', encoding='utf-8') as f:
        f.write(text)
