#!/usr/bin/env bash
# Chamado pelo semantic-release (prepareCmd) com a versão calculada pelos commits.
# Gera build/Remendo-<versão>.zip assinado com EdDSA e o build/appcast.xml apontando pra ele.
#   SPARKLE_PRIVATE_KEY=... scripts/package-release.sh 1.2.3
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$1"
TAG="v$VERSION"
ZIP="build/Remendo-$VERSION.zip"
REPO="${GITHUB_REPOSITORY:-GustavoMelloGit/Remendo}"

VERSION="$VERSION" ./build.sh
ditto -c -k --keepParent build/Remendo.app "$ZIP"

SIG=$(echo "$SPARKLE_PRIVATE_KEY" | .build/artifacts/sparkle/Sparkle/bin/sign_update --ed-key-file - "$ZIP")

cat > build/appcast.xml <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Remendo</title>
    <item>
      <title>$VERSION</title>
      <pubDate>$(date -R)</pubDate>
      <sparkle:version>$VERSION</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>https://github.com/$REPO/releases/tag/$TAG</sparkle:releaseNotesLink>
      <enclosure url="https://github.com/$REPO/releases/download/$TAG/Remendo-$VERSION.zip" type="application/octet-stream" $SIG />
    </item>
  </channel>
</rss>
XML
