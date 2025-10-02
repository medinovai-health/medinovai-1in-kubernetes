#!/usr/bin/env python3
"""
Analyze Ollama validation results and aggregate scores
Target: 10/10 from each model (50/50 total)
"""

import os
import re
import json
from pathlib import Path
from datetime import datetime

RESULTS_DIR = Path(__file__).parent / "results"
OUTPUT_DIR = Path(__file__).parent / "reports"

def parse_result_file(filepath):
    """Parse a single result file and extract scores"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        result = {
            'filename': filepath.name,
            'model': filepath.name.split('-')[1] if '-' in filepath.name else 'unknown',
            'iteration': int(filepath.name.split('-')[0].replace('iter', '')) if 'iter' in filepath.name else 0,
            'overall_score': 0,
            'architecture': 0,
            'code_quality': 0,
            'healthcare': 0,
            'coverage': 0,
            'production': 0,
            'strengths': [],
            'improvements': [],
            'critical_issues': [],
            'recommendation': 'UNKNOWN',
            'raw_content': content
        }
        
        # Extract overall score
        overall_match = re.search(r'OVERALL SCORE:\s*(\d+(?:\.\d+)?)\s*/\s*10', content, re.IGNORECASE)
        if overall_match:
            result['overall_score'] = float(overall_match.group(1))
        
        # Extract individual scores
        arch_match = re.search(r'Architecture.*?:\s*(\d+(?:\.\d+)?)\s*/\s*2', content, re.IGNORECASE)
        if arch_match:
            result['architecture'] = float(arch_match.group(1))
        
        code_match = re.search(r'Code Quality.*?:\s*(\d+(?:\.\d+)?)\s*/\s*2', content, re.IGNORECASE)
        if code_match:
            result['code_quality'] = float(code_match.group(1))
        
        health_match = re.search(r'Healthcare Compliance.*?:\s*(\d+(?:\.\d+)?)\s*/\s*2', content, re.IGNORECASE)
        if health_match:
            result['healthcare'] = float(health_match.group(1))
        
        cov_match = re.search(r'Test Coverage.*?:\s*(\d+(?:\.\d+)?)\s*/\s*2', content, re.IGNORECASE)
        if cov_match:
            result['coverage'] = float(cov_match.group(1))
        
        prod_match = re.search(r'Production Readiness.*?:\s*(\d+(?:\.\d+)?)\s*/\s*2', content, re.IGNORECASE)
        if prod_match:
            result['production'] = float(prod_match.group(1))
        
        # Extract strengths
        strengths_section = re.search(r'TOP \d+ STRENGTHS:(.*?)(?:TOP \d+ IMPROVEMENTS|CRITICAL ISSUES|RECOMMENDATION|$)', content, re.DOTALL | re.IGNORECASE)
        if strengths_section:
            strengths_text = strengths_section.group(1)
            strengths = re.findall(r'\d+\.\s*(.+?)(?:\n|$)', strengths_text)
            result['strengths'] = [s.strip() for s in strengths if s.strip()]
        
        # Extract improvements
        improvements_section = re.search(r'TOP \d+ IMPROVEMENTS.*?:(.*?)(?:CRITICAL ISSUES|RECOMMENDATION|$)', content, re.DOTALL | re.IGNORECASE)
        if improvements_section:
            improvements_text = improvements_section.group(1)
            improvements = re.findall(r'\d+\.\s*(.+?)(?:\n|$)', improvements_text)
            result['improvements'] = [i.strip() for i in improvements if i.strip()]
        
        # Extract recommendation
        rec_match = re.search(r'RECOMMENDATION:\s*(\w+)', content, re.IGNORECASE)
        if rec_match:
            result['recommendation'] = rec_match.group(1).upper()
        
        return result
        
    except Exception as e:
        print(f"Error parsing {filepath}: {e}")
        return None

def aggregate_results(results):
    """Aggregate results across all models and iterations"""
    models = {}
    
    for result in results:
        model = result['model']
        if model not in models:
            models[model] = {
                'iterations': [],
                'avg_overall': 0,
                'avg_architecture': 0,
                'avg_code_quality': 0,
                'avg_healthcare': 0,
                'avg_coverage': 0,
                'avg_production': 0,
                'all_strengths': [],
                'all_improvements': [],
                'recommendations': []
            }
        
        models[model]['iterations'].append(result)
        models[model]['all_strengths'].extend(result['strengths'])
        models[model]['all_improvements'].extend(result['improvements'])
        models[model]['recommendations'].append(result['recommendation'])
    
    # Calculate averages
    for model, data in models.items():
        n = len(data['iterations'])
        if n > 0:
            data['avg_overall'] = sum(r['overall_score'] for r in data['iterations']) / n
            data['avg_architecture'] = sum(r['architecture'] for r in data['iterations']) / n
            data['avg_code_quality'] = sum(r['code_quality'] for r in data['iterations']) / n
            data['avg_healthcare'] = sum(r['healthcare'] for r in data['iterations']) / n
            data['avg_coverage'] = sum(r['coverage'] for r in data['iterations']) / n
            data['avg_production'] = sum(r['production'] for r in data['iterations']) / n
    
    return models

def generate_report(models):
    """Generate comprehensive report"""
    OUTPUT_DIR.mkdir(exist_ok=True)
    
    report_file = OUTPUT_DIR / f"validation-report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    
    with open(report_file, 'w') as f:
        f.write("# Ollama 5-Model Validation Report\n\n")
        f.write(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write("---\n\n")
        
        # Overall summary
        f.write("## 📊 Overall Summary\n\n")
        
        total_avg = sum(data['avg_overall'] for data in models.values()) / len(models)
        total_possible = 10 * len(models)
        total_achieved = sum(data['avg_overall'] for data in models.values())
        
        f.write(f"**Target Score:** {total_possible}/50 (10/10 per model)\n")
        f.write(f"**Achieved Score:** {total_achieved:.1f}/50\n")
        f.write(f"**Average Score:** {total_avg:.2f}/10\n\n")
        
        if total_avg >= 9.5:
            f.write("**Status:** ✅ EXCEEDS TARGET\n\n")
        elif total_avg >= 9.0:
            f.write("**Status:** ✅ MEETS TARGET\n\n")
        elif total_avg >= 8.0:
            f.write("**Status:** ⚠️  NEAR TARGET - Minor improvements needed\n\n")
        else:
            f.write("**Status:** ❌ BELOW TARGET - Significant improvements needed\n\n")
        
        # Model-by-model breakdown
        f.write("## 🤖 Model-by-Model Breakdown\n\n")
        
        for model, data in sorted(models.items(), key=lambda x: x[1]['avg_overall'], reverse=True):
            f.write(f"### {model}\n\n")
            f.write(f"**Average Overall Score:** {data['avg_overall']:.2f}/10\n\n")
            f.write("**Category Scores:**\n")
            f.write(f"- Architecture: {data['avg_architecture']:.2f}/2\n")
            f.write(f"- Code Quality: {data['avg_code_quality']:.2f}/2\n")
            f.write(f"- Healthcare Compliance: {data['avg_healthcare']:.2f}/2\n")
            f.write(f"- Test Coverage: {data['avg_coverage']:.2f}/2\n")
            f.write(f"- Production Readiness: {data['avg_production']:.2f}/2\n\n")
            
            f.write(f"**Iterations:** {len(data['iterations'])}\n")
            iteration_scores = [r['overall_score'] for r in data['iterations']]
            f.write(f"**Scores:** {', '.join(f'{s:.1f}' for s in iteration_scores)}\n\n")
            
            # Recommendations
            approve_count = data['recommendations'].count('APPROVE')
            revision_count = data['recommendations'].count('NEEDS REVISION')
            reject_count = data['recommendations'].count('REJECT')
            
            f.write(f"**Recommendations:** ")
            if approve_count > 0:
                f.write(f"{approve_count} APPROVE ")
            if revision_count > 0:
                f.write(f"{revision_count} NEEDS REVISION ")
            if reject_count > 0:
                f.write(f"{reject_count} REJECT")
            f.write("\n\n---\n\n")
        
        # Aggregated strengths
        f.write("## 💪 Top Strengths (Across All Models)\n\n")
        all_strengths = []
        for data in models.values():
            all_strengths.extend(data['all_strengths'])
        
        # Count frequency
        strength_counts = {}
        for strength in all_strengths:
            key = strength[:50]  # First 50 chars as key
            strength_counts[key] = strength_counts.get(key, 0) + 1
        
        top_strengths = sorted(strength_counts.items(), key=lambda x: x[1], reverse=True)[:10]
        for i, (strength, count) in enumerate(top_strengths, 1):
            f.write(f"{i}. {strength}... (mentioned {count} times)\n")
        
        f.write("\n")
        
        # Aggregated improvements
        f.write("## 🔧 Top Improvements Needed (Across All Models)\n\n")
        all_improvements = []
        for data in models.values():
            all_improvements.extend(data['all_improvements'])
        
        # Count frequency
        improvement_counts = {}
        for improvement in all_improvements:
            key = improvement[:50]
            improvement_counts[key] = improvement_counts.get(key, 0) + 1
        
        top_improvements = sorted(improvement_counts.items(), key=lambda x: x[1], reverse=True)[:10]
        for i, (improvement, count) in enumerate(top_improvements, 1):
            f.write(f"{i}. {improvement}... (mentioned {count} times)\n")
        
        f.write("\n---\n\n")
        
        # Recommendations
        f.write("## 🎯 Recommendations\n\n")
        
        if total_avg >= 9.0:
            f.write("✅ **Test suite APPROVED for production use**\n\n")
            f.write("The test suite meets the high-quality standards required for a healthcare infrastructure platform.\n\n")
        elif total_avg >= 8.0:
            f.write("⚠️  **Test suite CONDITIONALLY APPROVED**\n\n")
            f.write("Address the top 5 improvements listed above before production deployment.\n\n")
        else:
            f.write("❌ **Test suite NEEDS REVISION**\n\n")
            f.write("Significant improvements required. Focus on:\n")
            for i, (improvement, _) in enumerate(top_improvements[:5], 1):
                f.write(f"{i}. {improvement}\n")
            f.write("\n")
        
        f.write("---\n\n")
        f.write("## 📋 Next Steps\n\n")
        
        if total_avg >= 9.0:
            f.write("1. ✅ Proceed with CI/CD integration\n")
            f.write("2. ✅ Deploy to staging environment\n")
            f.write("3. ✅ Execute full test suite\n")
            f.write("4. ✅ Production deployment ready\n")
        else:
            f.write("1. Address top improvements\n")
            f.write("2. Re-run validation\n")
            f.write("3. Achieve 9.0+ average score\n")
            f.write("4. Proceed with deployment\n")
    
    print(f"\n✅ Report generated: {report_file}\n")
    
    # Also print to console
    with open(report_file, 'r') as f:
        print(f.read())
    
    return report_file

def main():
    print("🔍 Analyzing validation results...\n")
    
    if not RESULTS_DIR.exists():
        print(f"❌ Results directory not found: {RESULTS_DIR}")
        return
    
    # Find all result files
    result_files = list(RESULTS_DIR.glob("*.txt"))
    
    if not result_files:
        print(f"❌ No result files found in {RESULTS_DIR}")
        return
    
    print(f"📄 Found {len(result_files)} result files\n")
    
    # Parse all results
    results = []
    for filepath in result_files:
        print(f"Parsing: {filepath.name}")
        result = parse_result_file(filepath)
        if result:
            results.append(result)
    
    print(f"\n✅ Parsed {len(results)} results successfully\n")
    
    # Aggregate
    models = aggregate_results(results)
    
    # Generate report
    report_file = generate_report(models)
    
    # Save JSON for programmatic access
    json_file = OUTPUT_DIR / f"validation-data-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
    with open(json_file, 'w') as f:
        json.dump({
            'timestamp': datetime.now().isoformat(),
            'models': {k: {
                'avg_overall': v['avg_overall'],
                'avg_architecture': v['avg_architecture'],
                'avg_code_quality': v['avg_code_quality'],
                'avg_healthcare': v['avg_healthcare'],
                'avg_coverage': v['avg_coverage'],
                'avg_production': v['avg_production'],
                'recommendations': v['recommendations']
            } for k, v in models.items()},
            'total_average': sum(data['avg_overall'] for data in models.values()) / len(models)
        }, f, indent=2)
    
    print(f"✅ JSON data saved: {json_file}\n")

if __name__ == "__main__":
    main()

