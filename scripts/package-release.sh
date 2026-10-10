#!/usr/bin/env bash
# Chamado pelo semantic-release (prepareCmd) com a versão calculada pelos commits.
# Gera build/Remendo-<versão>.zip assinado com EdDSA e o build/appcast.xml apontando pra ele.
# O 2º argumento são as release notes (markdown) em base64; o Sparkle renderiza nativo.
#   SPARKLE_PRIVATE_KEY=... scripts/package-release.sh 1.2.3 [notas-em-base64]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$1"
TAG="v$VERSION"
ZIP="build/Remendo-$VERSION.zip"
REPO="${GITHUB_REPOSITORY:-GustavoMelloGit/Remendo}"
# Tira o título "## [x.y.z](link) (data)": o diálogo do Sparkle já mostra a versão.
NOTES=$(echo "${2:-}" | base64 --decode | sed '1{/^#/d;}')

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
      <description sparkle:format="markdown"><![CDATA[$NOTES]]></description>
      <enclosure url="https://github.com/$REPO/releases/download/$TAG/Remendo-$VERSION.zip" type="application/octet-stream" $SIG />
    </item>
  </channel>
</rss>
XML
