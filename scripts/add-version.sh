#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Uso: $0 <major.minor> <major.minor.patch>" >&2
  echo "Exemplo: $0 1.26 1.26.8" >&2
  exit 1
fi

VERSION="$1"
PATCH_VERSION="$2"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo "Versao invalida: use o formato MAJOR.MINOR, como 1.26" >&2
  exit 1
fi
if [[ ! "$PATCH_VERSION" =~ ^${VERSION//./\.}\.[0-9]+$ ]]; then
  echo "Versao de patch invalida: use uma versao da linha $VERSION, como $VERSION.0" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSIONS_FILE="$ROOT_DIR/versions.txt"
DEPENDABOT_FILE="$ROOT_DIR/.github/dependabot.yml"

if grep -qx "$VERSION" "$VERSIONS_FILE"; then
  echo "A versao $VERSION ja existe em $VERSIONS_FILE" >&2
  exit 1
fi

TEMPLATE_VERSION="$(grep -v '^#' "$VERSIONS_FILE" | tail -n 1)"
if [[ -z "$TEMPLATE_VERSION" ]]; then
  echo "Nao foi possivel descobrir uma versao base em $VERSIONS_FILE" >&2
  exit 1
fi
TEMPLATE_DIR="$ROOT_DIR/$TEMPLATE_VERSION"
TARGET_DIR="$ROOT_DIR/$VERSION"

if [[ ! -f "$TEMPLATE_DIR/Dockerfile" ]]; then
  echo "Dockerfile base nao encontrado em $TEMPLATE_DIR/Dockerfile" >&2
  exit 1
fi
if ! grep -Eq '^FROM golang:[0-9]+\.[0-9]+\.[0-9]+-bookworm$' "$TEMPLATE_DIR/Dockerfile"; then
  echo "Dockerfile base sem patch Go fixado: $TEMPLATE_DIR/Dockerfile" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
sed -E \
  -e "s/^FROM golang:[0-9]+\.[0-9]+\.[0-9]+-bookworm$/FROM golang:$PATCH_VERSION-bookworm/" \
  -e "s/ARG GO_VERSION=$TEMPLATE_VERSION/ARG GO_VERSION=$VERSION/" \
  "$TEMPLATE_DIR/Dockerfile" > "$TARGET_DIR/Dockerfile"
printf '%s\n' "$VERSION" >> "$VERSIONS_FILE"

{
  printf 'version: 2\n'
  printf 'updates:\n'
  first=true

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    case "$line" in
      \#*) continue ;;
      *) ;;
    esac

    if [[ "$first" == true ]]; then
      first=false
    else
      printf '\n'
    fi
    cat <<EOF
  - package-ecosystem: "docker"
    directory: "/$line"
    schedule:
      interval: "weekly"
      day: "sunday"
    open-pull-requests-limit: 3
    target-branch: "main"
    ignore:
      - dependency-name: "golang"
        update-types: ["version-update:semver-major", "version-update:semver-minor"]
EOF
  done < "$VERSIONS_FILE"
} > "$DEPENDABOT_FILE"

echo "Versao $VERSION adicionada com sucesso."
echo "Atualize o README e o AGENTS se quiser refletir a nova linha suportada na documentacao."
