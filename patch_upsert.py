import re
file_path = 'lib/services/pocketbase_database_mock.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

upsert = '''      try {
        await pb.collection(col).update(id, body: value);
      } catch (_) {
        await pb.collection(col).create(body: {'id': id, 'text': 'Welcome to Optic TV', ...value});
      }'''

content = content.replace('await pb.collection(col).update(id, body: value);', upsert, 1)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
