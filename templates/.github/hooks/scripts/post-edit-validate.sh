#!/usr/bin/env bash
# Plan Forge — PostToolUse Hook
# Runs validation after file edits: checks for deferred-work markers
# that the Completeness Sweep would catch later.
# This provides early warning during execution, not just at sweep time.

set -euo pipefail

INPUT=$(cat)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"

# Extract tool name and file path
TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name":"[^"]*"' | sed 's/"tool_name":"//;s/"//' || true)
FILE_PATH=$(echo "$INPUT" | grep -o '"filePath":"[^"]*"' | sed 's/"filePath":"//;s/"//' || true)

# Only check after file-editing tools
case "$TOOL_NAME" in
    editFiles|create_file|replace_string_in_file|insert_edit_into_file|multi_replace_string_in_file)
        ;;
    *)
        echo "{}"
        exit 0
        ;;
esac

if [[ -z "$FILE_PATH" ]] || [[ ! -f "$FILE_PATH" ]]; then
    echo "{}"
    exit 0
fi

# Skip non-code files
case "$FILE_PATH" in
    *.md|*.json|*.yml|*.yaml|*.xml|*.txt|*.csv)
        echo "{}"
        exit 0
        ;;
esac

# Scan the edited file for deferred-work markers
MARKERS=$(grep -n -iE 'TODO|HACK|FIXME|will be replaced|placeholder|stub|mock data|Simulate|Seed with sample' "$FILE_PATH" 2>/dev/null | head -5 || true)

if [[ -n "$MARKERS" ]]; then
    # Warning only — don't block, just notify
    ESCAPED=$(echo "$MARKERS" | tr '\n' ' ' | sed 's/"/\\"/g')
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"WARNING: Deferred-work markers found in edited file. These must be resolved before the Completeness Sweep (Step 4): $ESCAPED\"}}"
else
    echo "{}"
fi
