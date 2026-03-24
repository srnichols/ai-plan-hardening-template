# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Plan Forge, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead:

1. **Use GitHub's private vulnerability reporting**: Go to the [Security tab](https://github.com/srnichols/plan-forge/security/advisories/new) and click "Report a vulnerability"
2. **Or email**: Describe the vulnerability, steps to reproduce, and potential impact

## What to Expect

- **Acknowledgment**: Within 48 hours of your report
- **Assessment**: We'll evaluate severity and impact within 1 week
- **Fix**: Critical vulnerabilities targeted for fix within 2 weeks
- **Disclosure**: We'll coordinate disclosure timing with you

## Scope

Plan Forge is a **template repository** — it generates configuration files (Markdown, JSON, shell scripts) for other projects. Security concerns most likely involve:

- **Hook scripts** (`.github/hooks/scripts/`) — these execute shell commands during Copilot sessions
- **Setup scripts** (`setup.ps1`, `setup.sh`) — these copy files to target projects
- **CLI scripts** (`pforge.ps1`, `pforge.sh`) — these manage project files and run git commands

### In Scope
- Command injection in hook scripts or CLI commands
- Path traversal in file copy operations
- Malicious content in generated instruction/prompt files
- Secrets accidentally included in template files

### Out of Scope
- Security of projects *created from* this template (that's the user's responsibility)
- VS Code or GitHub Copilot vulnerabilities (report those to Microsoft/GitHub)
- Vulnerabilities in third-party tools referenced in instruction files

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest (master) | ✅ |
| Older versions | ❌ (template repos don't have traditional versioning — always use latest) |
