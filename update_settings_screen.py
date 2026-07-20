import re

file_path = r'lib\ui\settings\settings_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'manual_sort_settings_page.dart' not in content:
    content = content.replace(
        "import 'pages/theme_settings_page.dart';",
        "import 'pages/theme_settings_page.dart';\nimport 'pages/manual_sort_settings_page.dart';"
    )

# Add to the first section
sort_item = '''CustomSettingsItem(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualSortSettingsPage())),
                      iconAsset: 'assets/images/flixy/ic_menu.png',
                      iconBgColor: Colors.deepOrangeAccent,
                      title: 'Manual Sort',
                      subtitle: 'Reorder channels and groups',
                    ),
                    '''

# Insert it before the Language item in the first section
if 'ManualSortSettingsPage' not in content:
    # Need to match the exact string or just insert after ThemeSettingsPage
    pattern = r'(CustomSettingsItem\(\s*onTap: \(\) => Navigator\.push\(context, MaterialPageRoute\(builder: \(\_\) => const ThemeSettingsPage\(\)\)\),.*?subtitle: s\.sectionInterfaceSub,\s*\),)'
    
    match = re.search(pattern, content, re.DOTALL)
    if match:
        content = content[:match.end()] + "\n                    " + sort_item + content[match.end():]
    else:
        print("Could not find insertion point!")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Updated settings_screen.dart')
