#!/usr/bin/env python3

import os, sys, re, json, glob, xml.etree.ElementTree as ET

threshold = int(float(sys.argv[1])) if len(sys.argv) > 1 else 80

def py_coverage():
    if os.path.exists("coverage.xml"):
        tree = ET.parse("coverage.xml")
        root = tree.getroot()
        line_rate = float(root.attrib.get("line-rate", "0"))
        return int(round(line_rate * 100))
    return None

def dotnet_coverage():
    # look for coverage.cobertura.xml files produced by coverlet or ReportGenerator
    for path in glob.glob("**/*coverage.cobertura.xml", recursive=True):
        tree = ET.parse(path)
        root = tree.getroot()
        lines_valid = int(root.attrib.get("lines-valid", "0"))
        lines_covered = int(root.attrib.get("lines-covered", "0"))
        if lines_valid > 0:
            return int(round((lines_covered / lines_valid) * 100))
    return None

def fallback():
    # if no coverage files exist, treat as 0 to enforce policy
    return 0

score = py_coverage()
if score is None:
    score = dotnet_coverage()
if score is None:
    score = fallback()

print(f"Coverage: {score}% (threshold: {threshold}%)")
if score < threshold:
    print("::error::Coverage below threshold")
    sys.exit(1)
