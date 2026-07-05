import re

file_path = 'lib/services/pocketbase_database_mock.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _notify to PocketBaseDatabase
notify_method = '''
  Future<void> _notify(String targetPath) async {
    final controller = _streamCache[targetPath];
    if (controller != null && !controller.isClosed) {
      final snap = await ref(targetPath).get();
      controller.add(DatabaseEvent(snap));
    }
  }
}'''
content = content.replace('\n}\n', '\n' + notify_method + '\n', 1)

# 2. Add await _notify(path) to set()
set_regex = re.compile(r'(Future<void> set\(dynamic value\) async \{.*?^\s*\}\n  \}\n)', re.MULTILINE | re.DOTALL)
content = set_regex.sub(lambda m: m.group(1)[:-3] + '  await _notify(path);\n  }\n', content)

# 3. Add await _notify(path) to update()
update_regex = re.compile(r'(Future<void> update\(Map<String, dynamic> value\) async \{.*?^\s*\}\n  \}\n)', re.MULTILINE | re.DOTALL)
content = update_regex.sub(lambda m: m.group(1)[:-3] + '  await _notify(path);\n  }\n', content)

# 4. Modify the catch block in update() to provide default text and throw e1 instead of creating random
old_catch = '''      } catch (_) {
        try {
          await pb.collection(col).create(body: {'id': id, ...value});
        } catch (_) {
          await pb.collection(col).create(body: value).catchError((_) {});
        }
      }'''

new_catch = '''      } catch (e1) {
        try {
          await pb.collection(col).create(body: {'id': id, 'text': 'Welcome', ...value});
        } catch (e2) {
          throw e1;
        }
      }'''
content = content.replace(old_catch, new_catch)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched successfully.')
