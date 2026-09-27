#!/data/data/com.termux/files/usr/bin/bash
# kincode auto-installer (arm32, custom build) — for Termux on Android
set -e

FILE_ID="1Db-ujaCwTCGWIwRTL9r2447c5-01RSmG"
BIN_NAME="kincode"
DEST="$PREFIX/bin/$BIN_NAME"
TMP="$HOME/.kincode-download.bin"

echo "==> Checking dependencies..."
command -v curl >/dev/null 2>&1 || pkg install -y curl

echo "==> Downloading kincode (arm32 build) from Google Drive..."

# Handle Google Drive's confirm-token flow for larger files
CONFIRM_PAGE=$(curl -sc /tmp/gdrive-cookies "https://drive.google.com/uc?export=download&id=${FILE_ID}")
CONFIRM_TOKEN=$(echo "$CONFIRM_PAGE" | grep -o 'confirm=[a-zA-Z0-9_-]*' | head -n1 | cut -d= -f2)

if [ -n "$CONFIRM_TOKEN" ]; then
  curl -Lb /tmp/gdrive-cookies "https://drive.google.com/uc?export=download&confirm=${CONFIRM_TOKEN}&id=${FILE_ID}" -o "$TMP"
else
  curl -L "https://drive.google.com/uc?export=download&id=${FILE_ID}" -o "$TMP"
fi

rm -f /tmp/gdrive-cookies

# sanity check: file should be a real ELF binary, not an HTML error page
if ! head -c4 "$TMP" | grep -q $'\x7fELF'; then
  echo "!! Download failed or Google Drive returned an HTML page instead of the binary."
  echo "!! Open this link in a browser once to confirm access, then re-run this script:"
  echo "   https://drive.google.com/file/d/${FILE_ID}/view"
  rm -f "$TMP"
  exit 1
fi

echo "==> Installing to $DEST"
mkdir -p "$PREFIX/bin"
mv "$TMP" "$DEST"
chmod +x "$DEST"

echo "==> Done. Verifying:"
"$DEST" -version 2>/dev/null || "$DEST" --help | head -n1

cat <<'EOF'

Quick start:

  # DeepSeek
  kincode -provider openai -endpoint https://api.deepseek.com/v1 \
          -api-key sk-xxxx -model deepseek-chat

  # Gemini
  kincode -provider openai \
          -endpoint https://generativelanguage.googleapis.com/v1beta/openai \
          -api-key AIza-xxxx -model gemini-2.5-flash

EOF
