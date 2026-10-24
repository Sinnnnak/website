#!/usr/bin/env bash
# Publishes this folder to here.now. Run from Terminal:  bash publish.sh
# Optional: export HERENOW_API_KEY=... first for a permanent site on your account.
set -euo pipefail
cd "$(dirname "$0")"
CLIENT="claude-design/publish-sh"
AUTH=()
if [ -n "${HERENOW_API_KEY:-}" ]; then AUTH=(-H "Authorization: Bearer $HERENOW_API_KEY"); fi
size() { wc -c < "$1" | tr -d ' '; }
BODY=$(printf '{"displayName":"Mohamed Elmojtaba - Portfolio","files":[{"path":"index.html","size":%s,"contentType":"text/html; charset=utf-8"},{"path":"uploads/Mohamed-Elmojtaba-CV.pdf","size":%s,"contentType":"application/pdf"}]}' "$(size index.html)" "$(size uploads/Mohamed-Elmojtaba-CV.pdf)")
curl -sS https://here.now/api/v1/publish ${AUTH[@]+"${AUTH[@]}"} -H "X-HereNow-Client: $CLIENT" -H "content-type: application/json" -d "$BODY" > .herenow-response.json
py() { python3 -c "import json; d=json.load(open('.herenow-response.json')); $1"; }
py "
if 'upload' not in d: raise SystemExit('here.now error: ' + json.dumps(d))
for u in d['upload']['uploads']: print(u['path'] + '\t' + u['url'])
" | while IFS=$'\t' read -r path url; do
  ct="text/html; charset=utf-8"; case "$path" in *.pdf) ct="application/pdf";; esac
  curl -sS -X PUT "$url" -H "Content-Type: $ct" --data-binary @"$path" -o /dev/null -w "uploaded $path (%{http_code})\n"
done
FINALIZE=$(py "print(d['upload']['finalizeUrl'])")
VERSION=$(py "print(d['upload']['versionId'])")
curl -sS -X POST "$FINALIZE" ${AUTH[@]+"${AUTH[@]}"} -H "X-HereNow-Client: $CLIENT" -H "content-type: application/json" -d "{\"versionId\":\"$VERSION\"}" -o /dev/null
py "
print('\nLive: ' + d['siteUrl'])
print('Claim link (sign in to keep it permanently): ' + d['claimUrl']) if d.get('claimUrl') else print('Saved to your here.now account.')
"
