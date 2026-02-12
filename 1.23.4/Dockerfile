# Base oficial do Go com Debian Bookworm
FROM golang:1.26.0-bookworm

# Versão do Go
ARG GO_VERSION=1.23.4

# Metadados da imagem
LABEL maintainer="maiconschmitz@gmail.com" \
    version="1.0" \
    description="Imagem para build de aplicações Go ${GO_VERSION}, com suporte a cross-compile para linux/amd64 e linux/arm64" \
    go.version="${GO_VERSION}"

# Variáveis de ambiente
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=America/Sao_Paulo \
    GOPROXY=https://proxy.golang.org,direct \
    GOSUMDB=sum.golang.org \
    GOFLAGS=-trimpath \
    GOMODCACHE=/go/pkg/mod \
    GOCACHE=/root/.cache/go-build

# Configuração do diretório de trabalho
WORKDIR /src

# Instalação otimizada em uma única camada
RUN set -eux; \
    # Atualiza e instala dependências essenciais
    apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    make \
    file \
    pkg-config \
    build-essential \
    gcc-aarch64-linux-gnu \
    gcc-x86-64-linux-gnu && \
    # Limpeza completa
    rm -rf /var/lib/apt/lists/*

# Finaliza a imagem
CMD ["go", "version"]