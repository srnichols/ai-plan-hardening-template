#!/usr/bin/env bash
# Plan Forge — PostToolUse Hook: Auto-Format
# Runs the project's formatter on edited files after each edit.
# Detects the formatter from the project's tech stack.

set -euo pipefail

INPUT=$(cat)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"

TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name":"[^"]*"' | sed 's/"tool_name":"//;s/"//' || true)
FILE_PATH=$(echo "$INPUT" | grep -o '"filePath":"[^"]*"' | sed 's/"filePath":"//;s/"//' || true)

# Only format after file-editing tools
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
    *.md|*.json|*.txt|*.csv|*.xml)
        echo "{}"
        exit 0
        ;;
esac

# Detect and run formatter based on project stack
FORMAT_RAN=false

# .NET — dotnet format
if [[ -f "$REPO_ROOT/global.json" ]] || ls "$REPO_ROOT"/*.sln 1>/dev/null 2>&1; then
    dotnet format --include "$FILE_PATH" --no-restore 2>/dev/null && FORMAT_RAN=true
fi

# Node/TypeScript — prettier or eslint
if [[ -f "$REPO_ROOT/package.json" ]] && [[ "$FORMAT_RAN" != true ]]; then
    if [[ -f "$REPO_ROOT/node_modules/.bin/prettier" ]]; then
        npx prettier --write "$FILE_PATH" 2>/dev/null && FORMAT_RAN=true
    elif [[ -f "$REPO_ROOT/node_modules/.bin/eslint" ]]; then
        npx eslint --fix "$FILE_PATH" 2>/dev/null && FORMAT_RAN=true
    fi
fi

# Python — ruff or black
if [[ -f "$REPO_ROOT/pyproject.toml" ]] || [[ -f "$REPO_ROOT/requirements.txt" ]]; then
    if command -v ruff &>/dev/null && [[ "$FORMAT_RAN" != true ]]; then
        ruff format "$FILE_PATH" 2>/dev/null && FORMAT_RAN=true
    elif command -v black &>/dev/null && [[ "$FORMAT_RAN" != true ]]; then
        black "$FILE_PATH" 2>/dev/null && FORMAT_RAN=true
    fi
fi

# Go — gofmt
if [[ -f "$REPO_ROOT/go.mod" ]] && [[ "$FILE_PATH" == *.go ]] && [[ "$FORMAT_RAN" != true ]]; then
    gofmt -w "$FILE_PATH" 2>/dev/null && FORMAT_RAN=true
fi

# Java — google-java-format (if available)
if [[ -f "$REPO_ROOT/pom.xml" ]] || [[ -f "$REPO_ROOT/build.gradle" ]]; then
    if command -v google-java-format &>/dev/null && [[ "$FORMAT_RAN" != true ]]; then
        google-java-format --replace "$FILE_PATH" 2>/dev/null && FORMAT_RAN=true
    fi
fi

echo "{}"
