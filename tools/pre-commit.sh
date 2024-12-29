#!/usr/bin/env bash

set -euo pipefail

function error_ln() {
  printf "\033[1;32;31m%s\n\033[m" "${1}"
}

while IFS='' read -r line; do files+=("${line}"); done < <(git diff-index --cached --name-only HEAD --diff-filter=ACM)
for file in "${files[@]}"; do
  if git check-ignore -q --no-index "${file}"; then
    error_ln "Error: '${file}' is not allowed to be committed (ignored by .gitignore)" >&2
    exit 1
  fi
  stat_command="stat -c %s"
  if [[ "Darwin" == "$(uname)" ]]; then
      stat_command="stat -f %z"
  fi
  if [ "$($stat_command "${file}")" -gt 1048576 ]; then
    error_ln "Error: '${file}' is too large (more than 1MB)" >&2
    exit 1
  fi
  if file "${file}" | grep -q "ELF"; then
    error_ln "Error: '${file}' is a compiled executable file and not allowed to be committed" >&2
    exit 1
  fi
done