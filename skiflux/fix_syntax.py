import re

with open('lib/features/home/sheets/comments_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

duration_ms_func = '''
  int? _durationMsFromLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty || trimmed == '0:00') return null;
    final parts = trimmed.split(':');
    if (parts.length != 2) return null;
    final m = int.tryParse(parts[0]);
    final s = int.tryParse(parts[1]);
    if (m == null || s == null) return null;
    final ms = ((m * 60) + s) * 1000;
    return ms > 0 ? ms : null;
  }
'''

text = text.replace('  @override\n  Widget build(BuildContext context) {', duration_ms_func + '\n  @override\n  Widget build(BuildContext context) {')

with open('lib/features/home/sheets/comments_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(text)
