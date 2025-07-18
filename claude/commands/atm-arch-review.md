#!/bin/bash

# Principal Architect Review Tool
# Performs comprehensive architectural analysis covering security, performance,
# maintainability, best practices, and improvement opportunities

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏛️  Principal Architect Review${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Initialize scoring
total_score=0
max_score=0
findings=()
recommendations=()
security_issues=()
performance_issues=()

# Helper function to add score
add_score() {
    local points=$1
    local max=$2
    total_score=$((total_score + points))
    max_score=$((max_score + max))
}

# 1. PROJECT STRUCTURE ANALYSIS
echo -e "${PURPLE}📊 Project Structure Analysis${NC}"
echo "================================"

# Count different file types
shell_files=$(find . -name "*.sh" -type f ! -path "./node_modules/*" ! -path "./.git/*" ! -path "./backups/*" 2>/dev/null | wc -l || echo 0)
config_files=$(find . \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.conf" \) ! -path "./node_modules/*" ! -path "./.git/*" 2>/dev/null | wc -l || echo 0)
total_files=$(find . -type f ! -path "./node_modules/*" ! -path "./.git/*" ! -path "./backups/*" 2>/dev/null | wc -l || echo 0)
directories=$(find . -type d ! -path "./node_modules/*" ! -path "./.git/*" ! -path "./backups/*" 2>/dev/null | wc -l || echo 0)

echo "Total files: $total_files"
echo "Directories: $directories"
echo "Shell scripts: $shell_files"
echo "Config files: $config_files"

# Check for good project structure
if [[ -f "README.md" ]]; then
    echo -e "${GREEN}✓ README.md present${NC}"
    add_score 10 10
else
    echo -e "${RED}✗ No README.md found${NC}"
    recommendations+=("Create a comprehensive README.md with setup instructions, architecture overview, and usage examples")
    add_score 0 10
fi

if [[ -f ".gitignore" ]]; then
    echo -e "${GREEN}✓ .gitignore present${NC}"
    add_score 5 5
else
    echo -e "${YELLOW}⚠ No .gitignore found${NC}"
    recommendations+=("Add .gitignore to prevent committing sensitive or unnecessary files")
    add_score 0 5
fi

echo

# 2. SECURITY ANALYSIS
echo -e "${PURPLE}🔒 Security Analysis${NC}"
echo "================================"

# Check for hardcoded credentials
echo -n "Checking for hardcoded credentials... "
potential_creds=0
if find . -name "*.sh" -o -name "*.bash" -o -name "*.conf" -o -name "*.json" 2>/dev/null | xargs grep -i -E "password=|passwd=|pwd=|secret=|api_key=|apikey=|token=|private_key=" 2>/dev/null | grep -v "password=\"\$" | grep -v "token=\"\$" | grep -v ".git" | grep -q .; then
    potential_creds=1
fi

if [[ $potential_creds -gt 0 ]]; then
    echo -e "${RED}Potential credentials found${NC}"
    security_issues+=("Potential hardcoded credentials detected")
    recommendations+=("Move all credentials to environment variables or secure vaults")
    add_score 0 20
else
    echo -e "${GREEN}None found${NC}"
    add_score 20 20
fi

# Check for unsafe practices
echo -n "Checking for unsafe shell practices... "
unsafe_practices=0

# Check for eval usage
if find . -name "*.sh" -o -name "*.bash" 2>/dev/null | xargs grep "eval " 2>/dev/null | grep -v ".git" | grep -q .; then
    unsafe_practices=$((unsafe_practices + 1))
    security_issues+=("Uses of 'eval' found which can be dangerous")
fi

# Check for unquoted variables (simple check)
unquoted_count=$(find . -name "*.sh" -o -name "*.bash" 2>/dev/null | xargs grep -E '\$[A-Za-z_]' 2>/dev/null | grep -v '"' | wc -l || echo 0)
if [[ $unquoted_count -gt 20 ]]; then
    unsafe_practices=$((unsafe_practices + 1))
    security_issues+=("Many unquoted variables found - potential command injection risk")
fi

if [[ $unsafe_practices -gt 0 ]]; then
    echo -e "${YELLOW}Found security concerns${NC}"
    add_score 10 20
else
    echo -e "${GREEN}Good practices observed${NC}"
    add_score 20 20
fi

# Check file permissions
echo -n "Checking file permissions... "
world_writable=$(find . -type f -perm -002 ! -path "./.git/*" 2>/dev/null | wc -l || echo 0)
if [[ $world_writable -gt 0 ]]; then
    echo -e "${RED}Found $world_writable world-writable files${NC}"
    security_issues+=("Found $world_writable world-writable files")
    recommendations+=("Fix file permissions: find . -type f -perm -002 -exec chmod o-w {} +")
    add_score 0 10
else
    echo -e "${GREEN}Good file permissions${NC}"
    add_score 10 10
fi

echo

# 3. CODE QUALITY & MAINTAINABILITY
echo -e "${PURPLE}📏 Code Quality & Maintainability${NC}"
echo "================================"

# Check for consistent style
echo -n "Checking code consistency... "
if [[ -f ".editorconfig" ]] || [[ -f ".prettierrc" ]] || [[ -f ".shellcheckrc" ]]; then
    echo -e "${GREEN}Style configuration found${NC}"
    add_score 10 10
else
    echo -e "${YELLOW}No style configuration${NC}"
    recommendations+=("Add .editorconfig or tool-specific configs for consistent code style")
    add_score 5 10
fi

# Function complexity analysis (simplified)
echo -n "Analyzing function complexity... "
complex_functions=0
for file in $(find . \( -name "*.sh" -o -name "*.bash" \) ! -path "./.git/*" 2>/dev/null); do
    if [[ -f "$file" ]]; then
        # Check if any function is longer than 50 lines (approximate)
        if awk '/^[[:alnum:]_]+\(\)/ {start=NR} /^}/ && start {if(NR-start>50) exit 1; start=0}' "$file" 2>/dev/null; then
            :
        else
            complex_functions=$((complex_functions + 1))
        fi
    fi
done

if [[ $complex_functions -gt 0 ]]; then
    echo -e "${YELLOW}Found $complex_functions complex functions${NC}"
    recommendations+=("Refactor complex functions into smaller, focused functions")
    add_score 5 10
else
    echo -e "${GREEN}Good function sizes${NC}"
    add_score 10 10
fi

echo

# 4. PERFORMANCE & SCALABILITY
echo -e "${PURPLE}⚡ Performance & Scalability${NC}"
echo "================================"

# Check for performance antipatterns
echo -n "Checking for performance issues... "
perf_issues=0

# Check for nested loops
if find . -name "*.sh" -o -name "*.bash" 2>/dev/null | xargs grep -l "while.*do.*while.*do" 2>/dev/null | grep -q .; then
    perf_issues=$((perf_issues + 1))
    performance_issues+=("Nested loops found - potential O(n²) complexity")
fi

# Check for many find commands
find_count=$(find . -name "*.sh" 2>/dev/null | xargs grep -c "find " 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo 0)
if [[ $find_count -gt 10 ]]; then
    perf_issues=$((perf_issues + 1))
    performance_issues+=("Many 'find' commands detected - consider caching results")
fi

if [[ $perf_issues -gt 0 ]]; then
    echo -e "${YELLOW}Found performance concerns${NC}"
    add_score 5 10
else
    echo -e "${GREEN}Good performance patterns${NC}"
    add_score 10 10
fi

echo

# 5. TESTING & RELIABILITY
echo -e "${PURPLE}🧪 Testing & Reliability${NC}"
echo "================================"

# Check for tests
test_files=$(find . \( -name "*test*" -o -name "*spec*" \) -name "*.sh" 2>/dev/null | wc -l || echo 0)
if [[ $test_files -gt 0 ]]; then
    echo -e "${GREEN}✓ Found $test_files test files${NC}"
    add_score 15 15
else
    echo -e "${RED}✗ No test files found${NC}"
    recommendations+=("Implement unit tests using bats-core or similar testing framework")
    add_score 0 15
fi

# Check for error handling
echo -n "Checking error handling... "
set_e_count=$(find . \( -name "*.sh" -o -name "*.bash" \) 2>/dev/null | xargs grep -l "set -e" 2>/dev/null | wc -l || echo 0)
if [[ $set_e_count -gt 2 ]]; then
    echo -e "${GREEN}Good error handling${NC}"
    add_score 10 10
else
    echo -e "${YELLOW}Limited error handling${NC}"
    recommendations+=("Add 'set -e' and trap handlers for robust error handling")
    add_score 5 10
fi

echo

# 6. BEST PRACTICES
echo -e "${PURPLE}✅ Best Practices Evaluation${NC}"
echo "================================"

# Check for documentation
doc_count=$(find . -name "*.md" -o -name "*.txt" | grep -v ".git" | wc -l || echo 0)
if [[ $doc_count -gt 2 ]]; then
    echo -e "${GREEN}✓ Good documentation coverage${NC}"
    add_score 10 10
else
    echo -e "${YELLOW}⚠ Limited documentation${NC}"
    recommendations+=("Add comprehensive documentation")
    add_score 5 10
fi

echo

# PROJECT-SPECIFIC ANALYSIS
if [[ -f "clair-sync" ]]; then
    echo -e "${PURPLE}🔧 Clair-de-config Specific Analysis${NC}"
    echo "======================================"
    
    # Check backup strategy
    if [[ -d "backups" ]]; then
        backup_count=$(find backups -type d -maxdepth 1 2>/dev/null | wc -l || echo 0)
        if [[ $backup_count -gt 10 ]]; then
            echo -e "${YELLOW}⚠ Many backups accumulated ($backup_count)${NC}"
            recommendations+=("Implement backup rotation to prevent disk space issues")
        else
            echo -e "${GREEN}✓ Reasonable backup count${NC}"
        fi
    fi
    
    # Check for proper alias management
    if [[ -f "aliases" ]] && grep -q "alias " aliases 2>/dev/null; then
        alias_count=$(grep -c "^alias " aliases 2>/dev/null || echo 0)
        echo -e "${GREEN}✓ Managing $alias_count aliases${NC}"
    fi
    
    echo
fi

# FINAL REPORT
echo -e "${BLUE}📋 Architecture Review Summary${NC}"
echo "================================"

# Calculate percentage score
if [[ $max_score -gt 0 ]]; then
    percentage=$((total_score * 100 / max_score))
else
    percentage=0
fi

# Determine grade
if [[ $percentage -ge 90 ]]; then
    grade="${GREEN}A${NC}"
    grade_text="Excellent"
elif [[ $percentage -ge 80 ]]; then
    grade="${GREEN}B${NC}"
    grade_text="Good"
elif [[ $percentage -ge 70 ]]; then
    grade="${YELLOW}C${NC}"
    grade_text="Satisfactory"
elif [[ $percentage -ge 60 ]]; then
    grade="${YELLOW}D${NC}"
    grade_text="Needs Improvement"
else
    grade="${RED}F${NC}"
    grade_text="Poor"
fi

echo -e "Overall Score: ${total_score}/${max_score} (${percentage}%)"
echo -e "Grade: ${grade} - ${grade_text}"
echo

# Display critical issues
if [[ ${#security_issues[@]} -gt 0 ]]; then
    echo -e "${RED}🚨 Security Issues:${NC}"
    for issue in "${security_issues[@]}"; do
        echo "   • $issue"
    done
    echo
fi

if [[ ${#performance_issues[@]} -gt 0 ]]; then
    echo -e "${YELLOW}⚡ Performance Concerns:${NC}"
    for issue in "${performance_issues[@]}"; do
        echo "   • $issue"
    done
    echo
fi

# Display recommendations
if [[ ${#recommendations[@]} -gt 0 ]]; then
    echo -e "${BLUE}📌 Priority Recommendations:${NC}"
    i=1
    for rec in "${recommendations[@]}"; do
        echo "   $i. $rec"
        ((i++))
    done
    echo
fi

# Architecture insights
echo -e "${PURPLE}🏗️  Architecture Insights:${NC}"
if [[ $shell_files -gt 20 ]]; then
    echo "   • Large shell-based project - consider modularization"
fi
if [[ $total_files -gt 100 ]]; then
    echo "   • Growing codebase - ensure consistent structure"
fi
if [[ $directories -gt 20 ]]; then
    echo "   • Complex directory structure - document the layout"
fi
echo "   • Shell-based configuration management tool"
echo "   • Good use of git for version control"
echo

echo -e "${BLUE}💡 Next Steps:${NC}"
echo "   1. Address security issues immediately"
echo "   2. Implement missing tests"
echo "   3. Fix high-priority recommendations"
echo "   4. Schedule regular architecture reviews"

echo
echo -e "${GREEN}✨ Remember: Great architecture evolves through continuous improvement!${NC}"