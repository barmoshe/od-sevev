#!/usr/bin/env bash
# Deploys build/web (from tools/build_web.sh) to Vercel. The Vercel project is
# $OD_VERCEL_PROJECT and has NO default: deploying "עוד סבב" is Bar's gated call (the studio's
# scope ends at the build, invariant I5), so the script refuses to guess a target.
#   OD_VERCEL_PROJECT=od-sevev-test tools/deploy_web.sh
# Needs the Vercel CLI (npm i -g vercel) and a one-time `vercel login`. Behind an HTTPS proxy,
# Node needs NODE_USE_ENV_PROXY=1 (set here).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
WEB="$HERE/../build/web"
[ -f "$WEB/index.html" ] || { echo "[deploy_web] no build: run tools/build_web.sh first" >&2; exit 1; }
PROJECT="${OD_VERCEL_PROJECT:-}"
[ -n "$PROJECT" ] || { echo "[deploy_web] set OD_VERCEL_PROJECT=<vercel project name> (no default: the deploy is a gated call)" >&2; exit 2; }
cp "$HERE/web/vercel.json" "$HERE/web/.vercelignore" "$WEB/"
export NODE_USE_ENV_PROXY=1 VERCEL_TELEMETRY_DISABLED=1
[ -f /root/.ccr/ca-bundle.crt ] && export NODE_EXTRA_CA_CERTS=/root/.ccr/ca-bundle.crt
cd "$WEB"
# a global `vercel` if there is one, otherwise the CLI through npx
command -v vercel >/dev/null 2>&1 || vercel() { npx -y vercel@latest "$@"; }
vercel link --yes --project "$PROJECT" >/dev/null
# link pulls a short-lived OIDC token into .env.local; the site needs no env, so drop it
rm -f .env.local
vercel deploy --prod --yes
