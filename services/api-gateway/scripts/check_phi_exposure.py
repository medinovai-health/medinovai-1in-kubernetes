#!/usr/bin/env python3
"""Check for potential PHI exposure in code."""

import re
import sys
from pathlib import Path

# Common PHI patterns to detect
PHI_PATTERNS = [
    r'\b\d{3}-\d{2}-\d{4}\b',  # SSN
    r'\b[A-Z][a-z]+\s+[A-Z][a-z]+\b',  # Names (simplified)
    r'\b\d{10,}\b',  # Long numbers (MRN, etc)
    r'\b\d{1,2}/\d{1,2}/\d{4}\b',  # Dates
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',  # Email
]

# Allowed patterns (not PHI)
ALLOWED_PATTERNS = [
    r'test',
    r'example',
    r'demo',
    r'sample',
    r'mock',
]

def check_file(filepath: Path) -> list:
    """Check a single file for PHI exposure."""
    violations = []
    
    try:
        content = filepath.read_text()
        
        for line_num, line in enumerate(content.splitlines(), 1):
            # Skip comments and test data
            if any(pattern in line.lower() for pattern in ALLOWED_PATTERNS):
                continue
                
            for pattern in PHI_PATTERNS:
                if re.search(pattern, line):
                    violations.append(f"{filepath}:{line_num}: Potential PHI found")
                    break
    
    except Exception as e:
        print(f"Error checking {filepath}: {e}")
    
    return violations

def main():
    """Check all Python files for PHI exposure."""
    violations = []
    
    for py_file in Path(".").rglob("*.py"):
        if "test" in str(py_file) or "__pycache__" in str(py_file):
            continue
            
        violations.extend(check_file(py_file))
    
    if violations:
        print("❌ PHI exposure detected:")
        for violation in violations:
            print(f"  {violation}")
        sys.exit(1)
    else:
        print("✅ No PHI exposure detected")
        sys.exit(0)

if __name__ == "__main__":
    main()
