import re

with open('lib/features/home/data/episodes_repository.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('creatorAvatarUrl = _stringOrNull(c[\'avatar_url\']);', 'creatorAvatarUrl = _stringOrNull(c[\'avatarUrl\']) ?? _stringOrNull(c[\'avatar_url\']);')

with open('lib/features/home/data/episodes_repository.dart', 'w', encoding='utf-8') as f:
    f.write(text)
