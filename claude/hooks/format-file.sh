#!/bin/bash
# Manual file formatter wrapper
# Usage: format-file.sh <file_path>

set -euo pipefail

FILE_PATH="${1:-}"

if [[ -z "$FILE_PATH" ]]; then
    echo "Usage: format-file.sh <file_path>"
    echo "Formats a file using the appropriate linters/formatters"
    exit 1
fi

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
    echo "Error: File not found: $FILE_PATH"
    exit 1
fi

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check what linters are available
LINT_INFO=$("$SCRIPT_DIR/needs-lint.sh" "$FILE_PATH")
NEEDS_LINT=$(echo "$LINT_INFO" | jq -r '.needs_lint')

if [[ "$NEEDS_LINT" == "false" ]]; then
    echo "No linters available for: $FILE_PATH"
    exit 0
fi

echo "Available linters: $(echo "$LINT_INFO" | jq -r '.linters | join(", ")')"
echo ""

# Create a fake hook data structure for the formatter
HOOK_DATA=$(cat <<EOF
{
  "cwd": "$(pwd)",
  "tool": {
    "name": "Edit"
  },
  "params": {
    "file_path": "$FILE_PATH"
  }
}
EOF
)

# Run the formatter
echo "$HOOK_DATA" | "$SCRIPT_DIR/formatter.sh"