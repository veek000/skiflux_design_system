import re

with open('lib/features/tasks/submission_task_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('''        String? link;
        if (_method == 0) {
          link = _linkController.text.trim();
          final uri = Uri.tryParse(link);
          final valid =
              uri != null &&
              (uri.scheme == 'http' || uri.scheme == 'https') &&
              uri.host.isNotEmpty;
          if (!valid) {
            throw const SkifluxFailure(SkifluxErrorKind.taskSubmission);
          }
        }''', '''        String? link;
        if (_method == 0) {
          link = _linkController.text.trim();
          if (not link.lower().startswith('http://') and not link.lower().startswith('https://')):
              # Note: this is dart code, I shouldn't use Python syntax in Dart code!
              pass''')

text = text.replace('''        String? link;
        if (_method == 0) {
          link = _linkController.text.trim();
          final uri = Uri.tryParse(link);
          final valid =
              uri != null &&
              (uri.scheme == 'http' || uri.scheme == 'https') &&
              uri.host.isNotEmpty;
          if (!valid) {
            throw const SkifluxFailure(SkifluxErrorKind.taskSubmission);
          }
        }''', '''        String? link;
        if (_method == 0) {
          link = _linkController.text.trim();
          if (!link.toLowerCase().startsWith('http://') && !link.toLowerCase().startsWith('https://')) {
            link = 'https://\';
          }
          final uri = Uri.tryParse(link);
          final valid =
              uri != null &&
              (uri.scheme == 'http' || uri.scheme == 'https') &&
              uri.host.isNotEmpty;
          if (!valid) {
            throw const SkifluxFailure(SkifluxErrorKind.taskSubmission);
          }
        }''')

with open('lib/features/tasks/submission_task_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
