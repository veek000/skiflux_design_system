# -*- coding: utf-8 -*-
import re

with open('lib/features/home/data/comments_store.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Chunk 1
text = re.sub(
    r'(final Map<int, String> _localAudioById = <int, String>\{\};)\s*(/// Path of a voice note.*?)\s*(String\? _pendingLocalAudio;)',
    r'\1\n  final Map<int, String> _localDurationById = <int, String>{};\n\n  \2\n  \3\n  String? _pendingLocalDuration;',
    text,
    flags=re.DOTALL
)

text = re.sub(
    r'(_pendingLocalAudio = null;)(\s*\})',
    r'\1\n    _pendingLocalDuration = null;\2',
    text,
    flags=re.DOTALL,
    count=1
)

# Chunk 2
text = re.sub(
    r'(for \(final c in state\.comments\) \{.*?final id = c\.id;\s*final path = c\.audioPath;)\s*(if \(id != null && path != null && path\.isNotEmpty\) \{.*?_localAudioById\[id\] = path;\s*\})\s*\}',
    r'\1\n      final duration = c.durationLabel;\n      \2\n        if (duration != "0:00") _localDurationById[id] = duration;\n      }\n    }',
    text,
    flags=re.DOTALL
)

text = re.sub(
    r'(final pendingPath = _pendingLocalAudio;)(\s*await _load\(\);)',
    r'\1\n    final pendingDuration = _pendingLocalDuration;\2',
    text,
    flags=re.DOTALL
)

text = re.sub(
    r'(if \(pendingPath != null && pendingPath\.isNotEmpty\) \{.*?)(\_localAudioById\.putIfAbsent\(id, \(\) => pendingPath\);)(\s*\})(\s*if \(newIds\.isNotEmpty\) _pendingLocalAudio = null;)',
    r'\1\2\n        if (pendingDuration != null) {\n          _localDurationById.putIfAbsent(id, () => pendingDuration);\n        }\3\n      if (newIds.isNotEmpty) {\n        _pendingLocalAudio = null;\n        _pendingLocalDuration = null;\n      }',
    text,
    flags=re.DOTALL
)

text = re.sub(
    r'(audioPath: pendingPath,)(\s*timeLabel: \'now\',)',
    r'\1\n          durationLabel: pendingDuration ?? "0:00",\2',
    text,
    flags=re.DOTALL
)

# Chunk 3
text = re.sub(
    r'(final pending = _pendingLocalAudio;)(\s*final out = <CommentItem>\[\];\s*for \(final c in comments\) \{)\s*(var path = c\.id != null \? _localAudioById\[c\.id!\] : null;)\s*(if \(path == null &&.*?c\.id != null &&.*?claimPendingFor\.contains\(c\.id\)\) \{.*?path = pending;.*?_localAudioById\[c\.id!\] = pending;\s*\})\s*(if \(path == null || path\.isEmpty\) \{.*?out\.add\(c\);.*?continue;\s*\})\s*(if \(c\.body == SkifluxCommentBody\.voicenote && c\.audioPath == path\) \{.*?out\.add\(c\);.*?continue;\s*\})\s*(out\.add\(\s*c\.copyWith\(\s*body: SkifluxCommentBody\.voicenote,\s*audioPath: path,\s*\),\s*\);)',
    r'\1\n    final pendingDuration = _pendingLocalDuration;\2\n      \3\n      var duration = c.id != null ? _localDurationById[c.id!] : null;\n      if (path == null && pending != null && c.id != null && claimPendingFor.contains(c.id)) {\n        path = pending;\n        duration = pendingDuration;\n        _localAudioById[c.id!] = pending;\n        if (pendingDuration != null) {\n          _localDurationById[c.id!] = pendingDuration;\n        }\n      }\n      \5\n      if (c.body == SkifluxCommentBody.voicenote && c.audioPath == path && (duration == null || c.durationLabel == duration)) {\n        out.add(c);\n        continue;\n      }\n      out.add(\n        c.copyWith(\n          body: SkifluxCommentBody.voicenote,\n          audioPath: path,\n          durationLabel: duration ?? c.durationLabel,\n        ),\n      );',
    text,
    flags=re.DOTALL
)

# Chunk 4 (addVoiceNote)
text = re.sub(
    r'(_pendingLocalAudio = path;)(\s*state = state\.copyWith\()',
    r'\1\n      _pendingLocalDuration = durationLabel;\2',
    text,
    flags=re.DOTALL
)

text = re.sub(
    r'(_localAudioById\[id\] = path;)(\s*_pendingLocalAudio = null;)',
    r'\1\n            _localDurationById[id] = durationLabel;\2\n            _pendingLocalDuration = null;',
    text,
    flags=re.DOTALL
)

text = re.sub(
    r'(_pendingLocalAudio = null;)(\s*if \(ref\.mounted\) \{)',
    r'\1\n        _pendingLocalDuration = null;\2',
    text,
    flags=re.DOTALL
)


with open('lib/features/home/data/comments_store.dart', 'w', encoding='utf-8') as f:
    f.write(text)
