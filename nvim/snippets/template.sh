#!/usr/bin/env bash
# {{FILE}} — {{AUTHOR}}
# Created: {{DATE}}

set -euo pipefail

{{CURSOR}}

main() {
    echo "Hello from {{FILE}}"
}

main "$@"
