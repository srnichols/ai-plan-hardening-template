#!/usr/bin/env bash
# Plan Forge — SessionStart Hook
# Injects Project Principles and current phase context into every agent session.
# Runs automatically when a new Copilot Agent session starts.

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Find repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"

CONTEXT_PARTS=()

# Inject Project Principles summary if file exists
PP_FILE="$REPO_ROOT/docs/plans/PROJECT-PRINCIPLES.md"
if [[ -f "$PP_FILE" ]]; then
    # Extract core principles (table rows with | N |)
    PRINCIPLES=$(grep -E '^\|\s*[0-9]+\s*\|' "$PP_FILE" 2>/dev/null | head -7 || true)
    if [[ -n "$PRINCIPLES" ]]; then
        CONTEXT_PARTS+=("PROJECT PRINCIPLES (non-negotiable): $PRINCIPLES")
    fi

    # Extract forbidden patterns
    FORBIDDEN=$(awk '/## Forbidden Patterns/,/^## /' "$PP_FILE" | grep -E '^\|\s*[0-9]+\s*\|' 2>/dev/null | head -5 || true)
    if [[ -n "$FORBIDDEN" ]]; then
        CONTEXT_PARTS+=("FORBIDDEN PATTERNS: $FORBIDDEN")
    fi
fi

# Inject current phase info from roadmap
ROADMAP="$REPO_ROOT/docs/plans/DEPLOYMENT-ROADMAP.md"
if [[ -f "$ROADMAP" ]]; then
    IN_PROGRESS=$(grep -B2 "In Progress" "$ROADMAP" | grep -E "^### Phase" | head -1 || true)
    if [[ -n "$IN_PROGRESS" ]]; then
        CONTEXT_PARTS+=("CURRENT PHASE: $IN_PROGRESS")
    fi
fi

# Inject forge version
FORGE_JSON="$REPO_ROOT/.forge.json"
if [[ -f "$FORGE_JSON" ]]; then
    VERSION=$(grep '"templateVersion"' "$FORGE_JSON" | sed 's/.*: *"\([^"]*\)".*/\1/' || true)
    PRESET=$(grep '"preset"' "$FORGE_JSON" | sed 's/.*: *"\([^"]*\)".*/\1/' || true)
    if [[ -n "$VERSION" ]]; then
        CONTEXT_PARTS+=("Plan Forge v$VERSION ($PRESET preset)")
    fi
fi

# Build output
if [[ ${#CONTEXT_PARTS[@]} -gt 0 ]]; then
    JOINED=$(printf '%s\n' "${CONTEXT_PARTS[@]}")
    # Output JSON for VS Code to consume
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"$JOINED\"}}"
else
    echo "{}"
fi
