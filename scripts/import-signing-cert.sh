#!/usr/bin/env bash
# Só pro CI: importa o certificado "Remendo" num keychain temporário pro build.sh assinar com ele.
#   SIGNING_CERT_P12=<.p12 em base64> SIGNING_CERT_PASSWORD=... scripts/import-signing-cert.sh
set -euo pipefail

: "${RUNNER_TEMP:?Só roda no CI. Localmente o certificado já está no Keychain.}"
KEYCHAIN="$RUNNER_TEMP/remendo.keychain-db"
KEYCHAIN_PASSWORD="$(uuidgen)"
P12="$RUNNER_TEMP/remendo.p12"

echo "$SIGNING_CERT_P12" | base64 --decode > "$P12"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
# Não tranca no meio do build.
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security import "$P12" -k "$KEYCHAIN" -P "$SIGNING_CERT_PASSWORD" -T /usr/bin/codesign
rm "$P12"

# Deixa o codesign usar a chave sem abrir o pedido de senha.
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN" > /dev/null
# Entra na busca do codesign, junto dos keychains que já estavam lá.
security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | tr -d '"')
