
import json

def compare_arb(file1, file2):
    with open(file1, 'r') as f1, open(file2, 'r') as f2:
        en = json.load(f1)
        vi = json.load(f2)
    
    missing_in_vi = [key for key in en if key not in vi]
    return missing_in_vi

missing = compare_arb('/Users/duylong/Code/Flutter/icegate/lib/l10n/app_en.arb', '/Users/duylong/Code/Flutter/icegate/lib/l10n/app_vi.arb')
print(f"Missing keys in Vietnamese: {len(missing)}")
for key in missing[:20]:
    print(key)
if len(missing) > 20:
    print("...")
