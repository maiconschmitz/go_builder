#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSIONS_FILE="$ROOT_DIR/versions.txt"

tmpdirs=()
cleanup() {
  if [[ "${#tmpdirs[@]}" -gt 0 ]]; then
    rm -rf "${tmpdirs[@]}"
  fi
}
trap cleanup EXIT

validate_version() {
  local version="$1"
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "Versao invalida: use o formato MAJOR.MINOR, como 1.26" >&2
    exit 1
  fi
  if ! grep -qx "$version" "$VERSIONS_FILE"; then
    echo "A versao $version nao existe em $VERSIONS_FILE" >&2
    exit 1
  fi
}

run_test() {
  local version="$1"
  local tmpdir appdir image

  validate_version "$version"

  tmpdir="$(mktemp -d "${TMPDIR:-/private/tmp}/go-builder-test.${version}.XXXXXX")"
  tmpdirs+=("$tmpdir")
  appdir="$tmpdir/app"
  mkdir -p "$appdir"

  cat > "$appdir/main.go" <<'EOF'
package main

import "fmt"

func main() {
	fmt.Println("hello world")
}
EOF

  cat > "$appdir/go.mod" <<EOF
module example.com/hello

go $version
EOF

  image="go-builder-test:$version"
  echo "🚦 Validando build ponta a ponta para Go $version..."
  docker build --pull -t "$image" "$ROOT_DIR/$version"
  docker run --rm -v "$appdir":/src -w /src "$image" sh -lc '
    set -e
    /usr/local/go/bin/go version
    CGO_ENABLED=0 GOOS=linux /usr/local/go/bin/go build -o /tmp/hello-world ./main.go
    /tmp/hello-world | grep -qx "hello world"
  '
  echo "✅ Go $version validado com sucesso."
}

if [[ "$#" -gt 1 ]]; then
  echo "Uso: $0 [versao]" >&2
  echo "Exemplo: $0 1.26" >&2
  exit 1
fi

if [[ "$#" -eq 1 ]]; then
  run_test "$1"
  exit 0
fi

versions="$(awk 'NF && $1 !~ /^#/' "$VERSIONS_FILE")"
if [[ -z "$versions" ]]; then
  echo "Nao ha versoes listadas em $VERSIONS_FILE" >&2
  exit 1
fi

for version in $versions; do
  run_test "$version"
done
