#!/bin/bash
set -u -o pipefail

run_sbcl() {
    local log_file
    log_file="$(mktemp)"
    sbcl \
        --noinform \
        --non-interactive \
        --load alive-lsp.asd \
        --eval "(asdf:load-system \"alive-lsp/test\")" \
        --eval "(alive/test/coverage:run)" 2>&1 | tee "$log_file"
    sbcl_last="$(tail -n 1 "$log_file")"
    rm -f "$log_file"
}

run_lispworks() {
    local lw_bin="$1"
    local log_file
    log_file="$(mktemp)"
    "$lw_bin" -load ./run-tests-lw.lisp 2>&1 | tee "$log_file"
    lw_last="$(tail -n 1 "$log_file")"
    rm -f "$log_file"
}

found=0
sbcl_last="not run"
lw_last="not run"
status=0

if command -v sbcl >/dev/null 2>&1; then
    if ! run_sbcl; then
        status=1
    fi
    found=1
fi

if command -v lw-console >/dev/null 2>&1; then
    if ! run_lispworks "$(command -v lw-console)"; then
        status=1
    fi
    found=1
elif command -v lispworks >/dev/null 2>&1; then
    if ! run_lispworks "$(command -v lispworks)"; then
        status=1
    fi
    found=1
fi

if [ "$found" -eq 0 ]; then
    echo "No SBCL or LispWorks found in PATH." >&2
    exit 1
fi

echo "SBCL: $sbcl_last"
echo "LispWorks: $lw_last"
exit "$status"
