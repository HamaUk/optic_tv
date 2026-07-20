import os
import re

lib_dir = 'lib'

# Patterns where we typically find const combined with AppTheme.primaryGold
# We want to remove 'const ' before these specific widgets if they contain AppTheme.primaryGold.
# Actually, since it's hard to match nested parentheses, we can just do a multi-pass approach or simpler replacements.

replacements = [
    (r'const\s+Icon\(([^)]*?)AppTheme\.primaryGold([^)]*?)\)', r'Icon(\1Theme.of(context).primaryColor\2)'),
    (r'const\s+TextStyle\(([^)]*?)AppTheme\.primaryGold([^)]*?)\)', r'TextStyle(\1Theme.of(context).primaryColor\2)'),
    (r'const\s+CircularProgressIndicator\(([^)]*?)AppTheme\.primaryGold([^)]*?)\)', r'CircularProgressIndicator(\1Theme.of(context).primaryColor\2)'),
    (r'const\s+BoxShadow\(([^)]*?)AppTheme\.primaryGold([^)]*?)\)', r'BoxShadow(\1Theme.of(context).primaryColor\2)'),
    (r'const\s+BorderSide\(([^)]*?)AppTheme\.primaryGold([^)]*?)\)', r'BorderSide(\1Theme.of(context).primaryColor\2)'),
    (r'const\s+Text\(([^)]*?)AppTheme\.primaryGold([^)]*?)\)', r'Text(\1Theme.of(context).primaryColor\2)'),
    # Also replace standard usages without const
    (r'AppTheme\.primaryGold', r'Theme.of(context).primaryColor'),
]

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Run replacements
            # Do the const ones first, multiple times to catch multiple args
            for _ in range(3):
                content = re.sub(r'const\s+Icon\(([^)]*?)AppTheme\.primaryGold([^)]*?)\)', r'Icon(\1Theme.of(context).primaryColor\2)', content)
                content = re.sub(r'const\s+TextStyle\(([^)]*?)AppTheme\.primaryGold([^)]*?)\)', r'TextStyle(\1Theme.of(context).primaryColor\2)', content)
                content = re.sub(r'const\s+CircularProgressIndicator\(([^)]*?)AppTheme\.primaryGold([^)]*?)\)', r'CircularProgressIndicator(\1Theme.of(context).primaryColor\2)', content)
                content = re.sub(r'const\s+BoxShadow\(([^)]*?)AppTheme\.primaryGold([^)]*?)\)', r'BoxShadow(\1Theme.of(context).primaryColor\2)', content)
                content = re.sub(r'const\s+BorderSide\(([^)]*?)AppTheme\.primaryGold([^)]*?)\)', r'BorderSide(\1Theme.of(context).primaryColor\2)', content)
                content = re.sub(r'const\s+Text\(([^)]*?)AppTheme\.primaryGold([^)]*?)\)', r'Text(\1Theme.of(context).primaryColor\2)', content)
            
            # Now replace any remaining AppTheme.primaryGold
            content = content.replace('AppTheme.primaryGold', 'Theme.of(context).primaryColor')
            
            if content != original_content:
                # Also import material if it's missing (though most ui files have it)
                if 'package:flutter/material.dart' not in content:
                    content = "import 'package:flutter/material.dart';\n" + content
                    
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Updated {filepath}")
