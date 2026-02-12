# Go Builder Image 🚀

Imagem Docker, para build de aplicações Go, com suporte a cross-compile para linux/amd64 e linux/arm64.

## 📋 Sobre o Projeto

Este repositório contém uma imagem Docker otimizada para build de aplicações Go.

A imagem é projetada com foco em:

- **Build otimizado**: Cache de módulos e build
- **Cross-compile**: Suporte nativo para múltiplas arquiteturas
- **Segurança**: Execução com usuário não-root
- **Performance**: Otimização de layers e cache

## 🚀 Versões Disponíveis

### Go 1.24.0 (Latest)

- **Diretório**: `1.24.0/`
- **Base**: `golang:1.24.0-bookworm`
- **Tag**: `go-builder:1.24.0`

### Go 1.23.4

- **Diretório**: `1.23.4/`
- **Base**: `golang:1.23.4-bookworm`
- **Tag**: `go-builder:1.23.4`

## 🛠️ Características da Imagem

### Configurações de Ambiente

- **Timezone**: America/Sao_Paulo
- **Go**: Configurações otimizadas para build
- **Usuário**: Não-root (65532:65532)
- **Diretório de trabalho**: `/src`
- **Cache de módulos**: `/go/pkg/mod`
- **Cache de build**: `/root/.cache/go-build`

### Dependências Incluídas

- `curl` - Cliente HTTP
- `ca-certificates` - Certificados SSL/TLS
- `git` - Controle de versão
- `make` - Ferramenta de build
- `file` - Identificação de tipos de arquivo
- `pkg-config` - Configuração de pacotes
- `build-essential` - Ferramentas de compilação
- `gcc-aarch64-linux-gnu` - Compilador para ARM64
- `gcc-x86-64-linux-gnu` - Compilador para x86_64

### Cross-Compile

Esta imagem oferece suporte nativo para cross-compile entre arquiteturas:

- 🏗️ **Multi-arquitetura**: `linux/amd64` e `linux/arm64`
- ⚡ **Performance**: Compilação otimizada com cache
- 🔒 **Segurança**: Build estático (CGO_ENABLED=0)
- 📦 **Compatibilidade**: Suporte completo ao ecossistema Go

**Nota**: O Dockerfile inclui compiladores cross-compile, mas por padrão o `docker build` só gera a imagem para a arquitetura atual. Para gerar imagens para múltiplas arquiteturas, use `docker buildx build --platform`.

### Otimizações Aplicadas

- ✅ Cache de módulos Go persistente
- ✅ Cache de build Go persistente
- ✅ Build estático (CGO_ENABLED=0)
- ✅ Stripping de símbolos (-s -w)
- ✅ Trimpath para builds reproduzíveis
- ✅ Cross-compile para aarch64 e x86-64
- ✅ Ferramentas de build (git, make, curl)
- ✅ Timezone configurado

## 📖 Como Usar


### Construção da Imagem

Você pode construir a imagem para a versão desejada (ex: `1.24.0` ou `1.23.4`).

```bash
# Construir a imagem Go 1.24.0 (arquitetura atual)
cd 1.24.0
docker build -t go-builder:1.24.0 .

# Construir para múltiplas arquiteturas (requer Docker buildx)
docker buildx build --platform linux/amd64,linux/arm64 -t go-builder:1.24.0 .
```

### Uso como Base

```dockerfile
# Estágio de construção
# Você pode alterar a tag para 1.23.4 se necessário
FROM maiconschmitz/go-builder:1.24.0 AS builder

# Copiar os arquivos go.mod e go.sum
COPY go.mod go.sum ./

# Baixar as dependências
RUN go mod download

# Copiar todo o código-fonte
COPY . .

# Compilar a aplicação
RUN CGO_ENABLED=0 GOOS=linux go build -o dist/app main.go

# Estágio de execução
FROM alpine:latest

# Define o fuso horário
ENV TZ=America/Sao_Paulo

WORKDIR /app

# Instalar o tzdata para configurar o fuso horário e adicionar um usuário não-root
RUN apk add --no-cache tzdata && \
    adduser -D app

# Instalar os certificados de autoridades de certificação (CA)
RUN apk --no-cache add ca-certificates

# Copiar apenas o binário necessário do estágio anterior
COPY --from=builder /src/dist/app /app/

# Mudar para o usuário não-root
USER app

# Comando padrão de inicialização
CMD ["./app"]
```

### Exemplo com Docker Compose

```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - CGO_ENABLED=0
    volumes:
      - .:/src
```
