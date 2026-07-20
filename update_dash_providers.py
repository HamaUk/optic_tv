import re

file_path = r'lib\ui\dashboard\dashboard_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

if 'local_sort_provider.dart' not in content:
    content = content.replace(
        "import '../../providers/channel_library_provider.dart';",
        "import '../../providers/channel_library_provider.dart';\nimport '../../providers/local_sort_provider.dart';"
    )

content = content.replace('ref.watch(channelsProvider)', 'ref.watch(sortedChannelsProvider)')
content = content.replace('ref.watch(groupsProvider)', 'ref.watch(sortedGroupsProvider)')
content = content.replace('ref.read(channelsProvider)', 'ref.read(sortedChannelsProvider)')
# Do NOT replace ref.invalidate(channelsProvider) or ref.invalidate(groupsProvider)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Replaced providers in dashboard_screen.dart')
