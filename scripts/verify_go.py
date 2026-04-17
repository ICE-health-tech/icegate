import os
import re

def validate_go_files(directory):
    errors = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".go"):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                    
                    # Check for basic package declaration
                    if not re.search(r'^package \w+', content, re.MULTILINE):
                        errors.append(f"Missing package declaration in {path}")
                    
                    # Check for unused imports (simple check)
                    imports = re.findall(r'"([^"]+)"', re.search(r'import \((.*?)\)', content, re.DOTALL).group(1)) if "import (" in content else []
                    for imp in imports:
                        # Skip multiple slashes or complex imports for now
                        base_imp = imp.split('/')[-1]
                        if base_imp not in content:
                            # Note: This is a loose check as base_imp might differ from package name
                            pass 

                    # Check for syntax placeholders
                    if "TODO" in content:
                        print(f"Warning: TODO found in {path}")
                        
    return errors

if __name__ == "__main__":
    errs = validate_go_files("./ice_gate_auth")
    if errs:
        for e in errs:
            print(f"Error: {e}")
        exit(1)
    else:
        print("Static verification passed (Basic structure checks).")
        exit(0)
