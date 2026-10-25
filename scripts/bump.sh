#!/bin/bash
# bump.sh — point Casks/immurok.rb at a new release.
#
#   scripts/bump.sh 1.7.0 <sha256>     # sha256 of immurok-1.7.0.pkg
#   scripts/bump.sh 1.7.0              # downloads the pkg and hashes it
#
# Only rewrites the `version` and `sha256` lines; everything else in the
# cask is left alone. Called by immurok/app-macos' release.yml after it
# uploads the pkg, and usable by hand.
set -euo pipefail

VERSION="${1:?usage: bump.sh <version> [sha256]}"
SHA="${2:-}"
VERSION="${VERSION#v}"
CASK="$(cd "$(dirname "$0")/.." && pwd)/Casks/immurok.rb"
URL="https://github.com/immurok/app-macos/releases/download/v${VERSION}/immurok-${VERSION}.pkg"

if [[ -z "${SHA}" ]]
then
  TMP="$(mktemp)"
  trap 'rm -f "$TMP"' EXIT
  echo "Downloading ${URL}"
  curl -fsSL -o "${TMP}" "${URL}"
  SHA="$(shasum -a 256 "${TMP}" | cut -d' ' -f1)"
fi
[[ "${SHA}" =~ ^[0-9a-f]{64}$ ]] || {
  echo "bad sha256: ${SHA}" >&2
  exit 1
}

OLD_VERSION="$(sed -n 's/^  version "\(.*\)"$/\1/p' "${CASK}")"
if [[ "${OLD_VERSION}" = "${VERSION}" ]]
then
  echo "cask already at ${VERSION}"
fi

sed -i '' \
  -e "s|^  version \".*\"$|  version \"${VERSION}\"|" \
  -e "s|^  sha256 \".*\"$|  sha256 \"${SHA}\"|" \
  "${CASK}"

if ! grep -q "version \"${VERSION}\"" "${CASK}" || ! grep -q "sha256 \"${SHA}\"" "${CASK}"
then
  echo "failed to rewrite ${CASK}" >&2
  exit 1
fi

echo "immurok: ${OLD_VERSION} -> ${VERSION}"
echo "sha256:  ${SHA}"
