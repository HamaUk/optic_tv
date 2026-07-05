import re

file_path = 'lib/services/pocketbase_database_mock.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add _notify to PocketBaseDatabase
notify_method = '''
  Future<void> _notify(String targetPath) async {
    final controller = DatabaseReference._streamCache[targetPath];
    if (controller != null && !controller.isClosed) {
      final snap = await ref(targetPath).get();
      controller.add(DatabaseEvent(snap));
    }
  }
}'''
content = content.replace('\n}\n\nclass DataSnapshot', '\n' + notify_method + '\n\nclass DataSnapshot')

# Add await PocketBaseDatabase.instance._notify(path); to set()
content = content.replace('''      }
    }
  }

  Future<void> update''', '''      }
    }
    await PocketBaseDatabase.instance._notify(path);
  }

  Future<void> update''')

# Add await PocketBaseDatabase.instance._notify(path); to update()
content = content.replace('''      }
    }
  }

  Future<void> remove''', '''      }
    }
    await PocketBaseDatabase.instance._notify(path);
  }

  Future<void> remove''')

# Make _streamCache visible to PocketBaseDatabase
content = content.replace('static final Map<String, BehaviorSubject<DatabaseEvent>> _streamCache = {};', 'static final Map<String, BehaviorSubject<DatabaseEvent>> _streamCache = {};')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched correctly.')
