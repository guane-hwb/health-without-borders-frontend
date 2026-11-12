#!/usr/bin/env python3
import glob
import re
import sys

def check_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Patrón para aislar bloques test o testWidgets
    test_pattern = re.compile(r'(?:testWidgets|test)\s*\(\s*([\'"].*?[\'"])\s*,\s*(?:\([^\)]*\)\s*)?async?\s*\{', re.MULTILINE)
    
    no_assertion_count = 0
    only_take_exception_count = 0
    
    matches = list(test_pattern.finditer(content))
    for i, m in enumerate(matches):
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(content)
        body = content[start:end]
        
        has_expect = 'expect(' in body or 'expectLater(' in body or 'verify(' in body
        has_take_exception = 'takeException()' in body
        
        if not has_expect:
            no_assertion_count += 1
        else:
            # Comprobar si SOLO tiene takeException()
            expects = re.findall(r'expect\s*\(', body)
            if len(expects) == 1 and has_take_exception:
                only_take_exception_count += 1
                
    return no_assertion_count, only_take_exception_count

def main():
    test_files = glob.glob('test/**/*_test.dart', recursive=True)
    total_no_assert = 0
    total_only_take_exc = 0
    
    for f in test_files:
        no_a, only_te = check_file(f)
        total_no_assert += no_a
        total_only_take_exc += only_te
        if no_a > 0 or only_te > 0:
            print(f"{f}: sin expect/verify: {no_a}, solo takeException: {only_te}")
            
    print(f"\nTotal tests sin expect ni verify: {total_no_assert}")
    print(f"Total tests solo con takeException: {total_only_take_exc}")
    
    if total_no_assert > 0 or total_only_take_exc > 0:
        sys.exit(1)
    else:
        print("OK: Todos los tests contienen aserciones válidas.")

if __name__ == '__main__':
    main()