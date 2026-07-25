#!/usr/bin/env bash
# End-to-end test for `ezenv account`, run entirely inside a throwaway $HOME.
#
# This exists because the account commands write to ~/.ssh/config and
# ~/.gitconfig — the two files where a bad edit hurts most. Everything is
# redirected via HOME plus the EZENV_* overrides, so a run can never touch your
# real config. Run: test/account.sh
set -uo pipefail

EZENV="$(cd "$(dirname "$0")/.." && pwd)/bin/ezenv"
pass=0 fail=0

ok()   { pass=$((pass + 1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf '  FAIL %s\n' "$1"; }
check(){ if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (want '$3', got '$2')"; fi; }
has()  { if grep -qF "$2" "$3" 2>/dev/null; then ok "$1"; else bad "$1"; fi; }
# Match captured output with a bash pattern instead of piping into `grep -q`:
# grep exits on the first match, upstream ezenv takes SIGPIPE, and `pipefail`
# then reports the whole pipeline as failed even though nothing went wrong.
saw()  { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" ;; esac; }

# Resolve physically: on macOS mktemp hands back a /var path that is really
# /private/var, and git matches includeIf against real paths (see _acct_abspath).
TMP="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
export EZENV_SSH_CONFIG="$TMP/.ssh/config"
export EZENV_GITCONFIG="$TMP/.gitconfig"
export EZENV_SSH_KEY_DIR="$TMP/.ssh"
export EZENV_RC="$TMP/.zshrc"
# Keep the test's own git calls from reading the developer's real config.
export GIT_CONFIG_GLOBAL="$TMP/.gitconfig"
export GIT_CONFIG_NOSYSTEM=1

echo "== add =="
mkdir -p "$TMP/code/work"
"$EZENV" account add work --email me@work.com --dir "$TMP/code/work" >/dev/null 2>&1
[ -f "$TMP/.ssh/id_ed25519_work" ]     && ok "private key created"  || bad "private key created"
[ -f "$TMP/.ssh/id_ed25519_work.pub" ] && ok "public key created"   || bad "public key created"
has "ssh host alias written"  "Host github.com-work"  "$EZENV_SSH_CONFIG"
has "IdentitiesOnly set"      "IdentitiesOnly yes"    "$EZENV_SSH_CONFIG"
has "ssh sentinel written"    "# ezenv:account:work BEGIN" "$EZENV_SSH_CONFIG"
has "identity file written"   "me@work.com"           "$TMP/.gitconfig-work"
has "includeIf written"       "gitdir:$TMP/code/work/" "$EZENV_GITCONFIG"
check "ssh config perms" "$(stat -f '%Lp' "$EZENV_SSH_CONFIG" 2>/dev/null || stat -c '%a' "$EZENV_SSH_CONFIG")" "600"

echo "== idempotence =="
before="$(cat "$EZENV_SSH_CONFIG")"
"$EZENV" account add work --email me@work.com >/dev/null 2>&1
check "re-add does not duplicate ssh block" "$(cat "$EZENV_SSH_CONFIG")" "$before"
check "one sentinel only" "$(grep -c '# ezenv:account:work BEGIN' "$EZENV_SSH_CONFIG")" "1"

echo "== identity actually applies =="
git init -q "$TMP/code/work/repo" 2>/dev/null
check "git resolves the bound identity" \
  "$(git -C "$TMP/code/work/repo" config user.email)" "me@work.com"

echo "== list / key =="
out="$("$EZENV" account list)"
saw "list shows account"     "$out" "work"
saw "list shows bound dir"   "$out" "code/work"
saw "key prints pubkey"      "$("$EZENV" account key work)" "ssh-ed25519"

echo "== check: healthy =="
if "$EZENV" account check >/dev/null 2>&1; then ok "check passes when healthy"
else bad "check passes when healthy"; fi
saw "check verifies end-to-end" "$("$EZENV" account check 2>&1)" "verified"

echo "== check: catches the rename =="
# The whole reason this feature exists: move the bound directory and the
# includeIf silently stops applying. check must notice.
mv "$TMP/code/work" "$TMP/code/work-renamed"
if "$EZENV" account check >/dev/null 2>&1; then bad "check fails after rename"
else ok "check fails after rename"; fi
saw "check reports BROKEN" "$("$EZENV" account check 2>&1)" "BROKEN"

echo "== second account coexists =="
"$EZENV" account add personal --email me@home.com >/dev/null 2>&1
out="$("$EZENV" account list)"
saw "work still listed"     "$out" "work"
saw "personal now listed"   "$out" "personal"

echo "== validation =="
"$EZENV" account add "bad name" --email x@y.com >/dev/null 2>&1 \
  && bad "rejects invalid name" || ok "rejects invalid name"
"$EZENV" account add nomail >/dev/null 2>&1 \
  && bad "requires --email" || ok "requires --email"
"$EZENV" account bind ghost /tmp >/dev/null 2>&1 \
  && bad "bind rejects unknown account" || ok "bind rejects unknown account"

echo ""
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
