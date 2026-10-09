#!/usr/bin/env bash
# Compila o Remendo e monta o Remendo.app.
#   ./build.sh           -> gera build/Remendo.app
#   ./build.sh install   -> gera, copia pra /Applications e apaga a cópia do build
#   VERSION=1.2.0 ./build.sh -> carimba essa versão no Info.plist (usado pelo CI nas releases)
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Remendo.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/Remendo"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp "$BIN" "$APP/Contents/MacOS/Remendo"
cp Support/Info.plist "$APP/Contents/Info.plist"
cp Support/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
# ditto preserva os symlinks do framework.
ditto "$(dirname "$BIN")/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"

if [[ -n "${VERSION:-}" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP/Contents/Info.plist"
fi

codesign --force --sign - "$APP"

echo "Pronto: $APP"

if [[ "${1:-}" == "install" ]]; then
    pkill -x Remendo 2>/dev/null || true
    rm -rf /Applications/Remendo.app
    cp -R "$APP" /Applications/

    # Some com a cópia do build pra não aparecer dois Remendos no Spotlight/Launchpad.
    "$LSREGISTER" -u "$APP" 2>/dev/null || true
    rm -rf "$APP"

    # Força o macOS a reler o ícone.
    touch /Applications/Remendo.app
    "$LSREGISTER" -f /Applications/Remendo.app

    open /Applications/Remendo.app
    echo "Instalado em /Applications/Remendo.app"
fi
