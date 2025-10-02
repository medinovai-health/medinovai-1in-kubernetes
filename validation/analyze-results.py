#!/usr/bin/env python3
"""
5-Model Validation Results Analyzer
Aggregates scores and feedback from all 5 Ollama models
"""

import re
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple

VALIDATION_DIR = Path("/Users/dev1/github/medinovai-infrastructure/validation")
RESULTS_DIR = VALIDATION_DIR / "results"
REPORTS_DIR = VALIDATION_DIR / "reports"

MODELS = {
    "qwen2.5-72b": "Chief Architect",
    "deepseek-coder-33b": "Technical Reviewer",
    "llama3.1-70b": "Healthcare Expert",
    "mixtral-8x22b": "Multi-Perspective Analyst",
    "codellama-70b": "Infrastructure Expert"
}

DOCUMENTS = [
    "COMPREHENSIVE_JOURNEY_VALIDATION_PLAN.md",
    "JOURNEY_VALIDATION_PLAN_SUMMARY.md",
    "JOURNEY_VALIDATION_SUMMARY.md",
    "JOURNEY_QUICK_REFERENCE.md",
    "JOURNEY_VALIDATION_INDEX.md"
]


def extract_score(text: str, pattern: str) -> float:
    """Extract numerical score from text using regex pattern"""
    match = re.search(pattern, text, re.IGNORECASE | re.MULTILINE)
    if match:
        score_str = match.group(1).strip()
        # Handle formats like "9.5/10" or just "9.5"
        score_str = score_str.split('/')[0]
        try:
            return float(score_str)
        except ValueError:
            return 0.0
    return 0.0


def parse_result_file(filepath: Path) -> Dict:
    """Parse a model result file and extract scores and feedback"""
    if not filepath.exists():
        return {"error": "File not found"}
    
    content = filepath.read_text()
    
    result = {
        "model": filepath.stem.replace("-result", ""),
        "overall_score": 0.0,
        "doc_scores": [],
        "strengths": [],
        "issues": [],
        "recommendations": [],
        "raw_content": content
    }
    
    # Extract overall score
    result["overall_score"] = extract_score(content, r"OVERALL SCORE.*?(\d+\.?\d*)")
    
    # Extract document scores
    for i in range(1, 6):
        score = extract_score(content, rf"Doc(?:ument)? {i}[:\s]+(\d+\.?\d*)")
        result["doc_scores"].append(score)
    
    # Extract strengths
    strengths_section = re.search(
        r"STRENGTHS.*?\n(.*?)(?=\n===|$)", 
        content, 
        re.DOTALL | re.IGNORECASE
    )
    if strengths_section:
        strengths = re.findall(r'\d+\.\s+(.+)', strengths_section.group(1))
        result["strengths"] = [s.strip() for s in strengths]
    
    # Extract issues
    issues_section = re.search(
        r"(?:CRITICAL ISSUES|BLOCKERS|CONCERNS).*?\n(.*?)(?=\n===|$)", 
        content, 
        re.DOTALL | re.IGNORECASE
    )
    if issues_section:
        issues_text = issues_section.group(1).strip()
        if "NONE" not in issues_text.upper() and issues_text:
            result["issues"] = [issues_text]
    
    # Extract recommendations
    rec_section = re.search(
        r"RECOMMENDATIONS.*?\n(.*?)(?=\n===|$)", 
        content, 
        re.DOTALL | re.IGNORECASE
    )
    if rec_section:
        recs = re.findall(r'\d+\.\s+(.+)', rec_section.group(1))
        result["recommendations"] = [r.strip() for r in recs]
    
    return result


def generate_score_matrix(results: List[Dict]) -> str:
    """Generate ASCII table of scores"""
    lines = []
    lines.append("\n" + "="*100)
    lines.append("SCORE MATRIX")
    lines.append("="*100)
    
    # Header
    header = f"{'Model':<25} | {'Overall':<8} | {'Doc1':<6} | {'Doc2':<6} | {'Doc3':<6} | {'Doc4':<6} | {'Doc5':<6}"
    lines.append(header)
    lines.append("-" * 100)
    
    # Rows
    for result in results:
        model = result.get("model", "Unknown")
        overall = result.get("overall_score", 0.0)
        doc_scores = result.get("doc_scores", [0]*5)
        
        # Pad doc_scores if needed
        while len(doc_scores) < 5:
            doc_scores.append(0.0)
        
        row = f"{model:<25} | {overall:<8.1f} | {doc_scores[0]:<6.1f} | {doc_scores[1]:<6.1f} | {doc_scores[2]:<6.1f} | {doc_scores[3]:<6.1f} | {doc_scores[4]:<6.1f}"
        lines.append(row)
    
    lines.append("-" * 100)
    
    # Calculate averages
    if results:
        avg_overall = sum(r.get("overall_score", 0) for r in results) / len(results)
        avg_docs = []
        for i in range(5):
            scores = [r.get("doc_scores", [0]*5)[i] for r in results]
            avg_docs.append(sum(scores) / len(scores) if scores else 0.0)
        
        avg_row = f"{'AVERAGE':<25} | {avg_overall:<8.1f} | {avg_docs[0]:<6.1f} | {avg_docs[1]:<6.1f} | {avg_docs[2]:<6.1f} | {avg_docs[3]:<6.1f} | {avg_docs[4]:<6.1f}"
        lines.append(avg_row)
    
    lines.append("="*100)
    
    return "\n".join(lines)


def generate_summary_report(results: List[Dict]) -> str:
    """Generate comprehensive summary report"""
    report = []
    
    report.append("# 🤖 5-MODEL VALIDATION RESULTS")
    report.append(f"\n**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append(f"**Models Used**: {len(results)}")
    report.append(f"**Documents Validated**: {len(DOCUMENTS)}")
    
    # Overall statistics
    if results:
        avg_overall = sum(r.get("overall_score", 0) for r in results) / len(results)
        min_score = min(r.get("overall_score", 0) for r in results)
        max_score = max(r.get("overall_score", 0) for r in results)
        
        report.append(f"\n## 📊 Overall Statistics")
        report.append(f"- **Average Score**: {avg_overall:.2f}/10")
        report.append(f"- **Minimum Score**: {min_score:.2f}/10")
        report.append(f"- **Maximum Score**: {max_score:.2f}/10")
        report.append(f"- **Target Score**: 9.0/10")
        report.append(f"- **Status**: {'✅ TARGET MET' if avg_overall >= 9.0 else '⚠️  BELOW TARGET'}")
    
    # Score matrix
    report.append(f"\n## 📈 Score Matrix")
    report.append("```")
    report.append(generate_score_matrix(results))
    report.append("```")
    
    # Model-by-model analysis
    report.append(f"\n## 🤖 Model-by-Model Analysis")
    for result in results:
        model = result.get("model", "Unknown")
        role = MODELS.get(model, "Unknown Role")
        overall = result.get("overall_score", 0.0)
        
        report.append(f"\n### {model} ({role})")
        report.append(f"**Overall Score**: {overall:.1f}/10")
        
        # Strengths
        strengths = result.get("strengths", [])
        if strengths:
            report.append(f"\n**Top Strengths**:")
            for i, strength in enumerate(strengths[:5], 1):
                report.append(f"{i}. {strength}")
        
        # Issues
        issues = result.get("issues", [])
        if issues:
            report.append(f"\n**Critical Issues**:")
            for issue in issues:
                report.append(f"- {issue}")
        else:
            report.append(f"\n**Critical Issues**: None identified ✅")
        
        # Recommendations
        recs = result.get("recommendations", [])
        if recs:
            report.append(f"\n**Recommendations**:")
            for i, rec in enumerate(recs[:5], 1):
                report.append(f"{i}. {rec}")
    
    # Consensus analysis
    report.append(f"\n## 🎯 Consensus Analysis")
    
    all_strengths = []
    all_issues = []
    all_recs = []
    
    for result in results:
        all_strengths.extend(result.get("strengths", []))
        all_issues.extend(result.get("issues", []))
        all_recs.extend(result.get("recommendations", []))
    
    report.append(f"\n**Common Themes**:")
    report.append(f"- Total Strengths Identified: {len(all_strengths)}")
    report.append(f"- Total Issues Identified: {len(all_issues)}")
    report.append(f"- Total Recommendations: {len(all_recs)}")
    
    # Final verdict
    report.append(f"\n## ✅ Final Verdict")
    if results:
        avg_overall = sum(r.get("overall_score", 0) for r in results) / len(results)
        
        if avg_overall >= 9.5:
            report.append(f"**🎉 EXCELLENT** - Documentation exceeds all quality standards")
        elif avg_overall >= 9.0:
            report.append(f"**✅ APPROVED** - Documentation meets quality target (≥9.0/10)")
        elif avg_overall >= 8.0:
            report.append(f"**⚠️  NEEDS IMPROVEMENT** - Minor improvements required")
        else:
            report.append(f"**❌ REQUIRES REVISION** - Significant improvements needed")
        
        report.append(f"\n**Final Average Score**: {avg_overall:.2f}/10")
    
    return "\n".join(report)


def main():
    """Main execution function"""
    print("🔍 Analyzing validation results...")
    print(f"Results directory: {RESULTS_DIR}")
    
    # Create reports directory
    REPORTS_DIR.mkdir(exist_ok=True)
    
    # Parse all result files
    results = []
    for model_key in MODELS.keys():
        result_file = RESULTS_DIR / f"{model_key}-result.txt"
        print(f"   - Parsing {result_file.name}...")
        
        if result_file.exists():
            result = parse_result_file(result_file)
            results.append(result)
            print(f"     ✓ Score: {result.get('overall_score', 0):.1f}/10")
        else:
            print(f"     ⚠️  File not found")
    
    if not results:
        print("\n❌ No results found to analyze")
        return
    
    print(f"\n✅ Parsed {len(results)} model results")
    
    # Generate reports
    print("\n📝 Generating reports...")
    
    # 1. Summary report (Markdown)
    summary = generate_summary_report(results)
    summary_file = REPORTS_DIR / "validation-summary.md"
    summary_file.write_text(summary)
    print(f"   ✓ Summary report: {summary_file}")
    
    # 2. JSON export
    json_file = REPORTS_DIR / "validation-results.json"
    json_data = {
        "timestamp": datetime.now().isoformat(),
        "models": list(MODELS.keys()),
        "documents": DOCUMENTS,
        "results": results
    }
    json_file.write_text(json.dumps(json_data, indent=2))
    print(f"   ✓ JSON export: {json_file}")
    
    # 3. Quick stats
    if results:
        avg_overall = sum(r.get("overall_score", 0) for r in results) / len(results)
        print(f"\n{'='*60}")
        print(f"📊 QUICK STATS")
        print(f"{'='*60}")
        print(f"Average Score: {avg_overall:.2f}/10")
        print(f"Target: 9.0/10")
        print(f"Status: {'✅ MET' if avg_overall >= 9.0 else '⚠️  NOT MET'}")
        print(f"{'='*60}")
    
    print(f"\n✅ Analysis complete! Check reports in: {REPORTS_DIR}")


if __name__ == "__main__":
    main()

