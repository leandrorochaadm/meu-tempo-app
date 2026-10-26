#!/usr/bin/env bash
# Local, disposable PocketBase for validating migrations and permission tests.
set -euo pipefail
cd "$(dirname "$0")/.."

PB_VERSION=0.40.5
PB_PORT="${PB_PORT:-8095}"
BIN_DIR="tool/.bin/$PB_VERSION"
DATA_DIR="${PB_DATA_DIR:-.pb/pb_data}"
MIGRATIONS_DIR="pocketbase/pb_migrations"

download() {
  local os arch zip
  case "$(uname -s)" in
    Linux) os=linux ;;
    Darwin) os=darwin ;;
    *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
  esac
  case "$(uname -m)" in
    x86_64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
  zip="pocketbase_${PB_VERSION}_${os}_${arch}.zip"
  gh release download "v$PB_VERSION" --repo pocketbase/pocketbase \
    --pattern "$zip" --pattern checksums.txt --dir "$BIN_DIR" --clobber
  if ! (cd "$BIN_DIR" && shasum -a 256 --check --ignore-missing checksums.txt); then
    rm -f "${BIN_DIR:?}/${zip:?}"
    echo "Checksum mismatch for $zip" >&2
    exit 1
  fi
  unzip -o -q "$BIN_DIR/$zip" pocketbase -d "$BIN_DIR"
  rm -f "${BIN_DIR:?}/${zip:?}"
}

[ -x "$BIN_DIR/pocketbase" ] || download

case "${1:-}" in
  serve)
    exec "$BIN_DIR/pocketbase" serve --http="127.0.0.1:$PB_PORT" \
      --dir="$DATA_DIR" --migrationsDir="$MIGRATIONS_DIR" --automigrate=false
    ;;
  superuser)
    email="${2:?Usage: tool/pb.sh superuser <email>}"
    read -rs -p "Password: " password
    echo
    "$BIN_DIR/pocketbase" superuser upsert "$email" "$password" \
      --dir="$DATA_DIR" --migrationsDir="$MIGRATIONS_DIR"
    ;;
  *)
    echo "Usage: tool/pb.sh serve | superuser <email>" >&2
    exit 2
    ;;
esac
