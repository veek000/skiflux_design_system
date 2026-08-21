import re

with open('lib/features/profile/data/library_episode.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('avatarUrl = _string(c[\'avatar_url\']);', 'avatarUrl = _string(c[\'avatarUrl\']) ?? _string(c[\'avatar_url\']);')

with open('lib/features/profile/data/library_episode.dart', 'w', encoding='utf-8') as f:
    f.write(text)
