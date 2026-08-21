import re

with open('lib/features/home/data/comments_store.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('''    for (final c in state.comments) {
      final id = c.id;
      final path = c.audioPath;
      final duration = c.durationLabel;
      if (id != null && path != null && path.isNotEmpty) {
        _localAudioById[id] = path;
      }
        if (duration != "0:00") _localDurationById[id] = duration;
      }
    }''', '''    for (final c in state.comments) {
      final id = c.id;
      final path = c.audioPath;
      final duration = c.durationLabel;
      if (id != null && path != null && path.isNotEmpty) {
        _localAudioById[id] = path;
        if (duration != "0:00") _localDurationById[id] = duration;
      }
    }''')

text = text.replace('''      if (newIds.isNotEmpty) {
        _pendingLocalAudio = null;
        _pendingLocalDuration = null;
      }
    _pendingLocalDuration = null;
    }''', '''      if (newIds.isNotEmpty) {
        _pendingLocalAudio = null;
        _pendingLocalDuration = null;
      }
    }''')

with open('lib/features/home/data/comments_store.dart', 'w', encoding='utf-8') as f:
    f.write(text)
