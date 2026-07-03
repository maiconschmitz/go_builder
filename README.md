# Go Builder Image

Imagens Docker para build de aplicações Go, com suporte a cross-compile para `linux/amd64` e `linux/arm64`.

## Visão geral

Este repositório mantém uma imagem por versão suportada do Go.
A lista de versões suportadas fica em [versions.txt](/Users/maiconschmitz/projects/mcn/go_builder/versions.txt). Cada linha corresponde a uma pasta de versão, como `1.23/`, `1.24/` ou `1.25/`.

Cada imagem usa a base oficial `golang:<versão>-bookworm`, instala dependências úteis para build e deixa o ambiente pronto para compilar projetos Go em pipelines de CI ou em builds locais. O arquivo `versions.txt` é consumido pelo `Taskfile`, pela workflow do GitHub Actions e pelo helper de scaffolding.

## O que a imagem entrega

- Base oficial do Go em Debian Bookworm
- Suporte a cross-compile com `gcc-aarch64-linux-gnu` e `gcc-x86-64-linux-gnu`
- Ferramentas de build comuns como `git`, `make`, `curl`, `file` e `pkg-config`
- Variáveis de ambiente úteis para builds reproduzíveis
- `WORKDIR` definido em `/src`
- Timezone configurado para `America/Sao_Paulo`

## Versões suportadas

A imagem para cada linha suportada é gerada a partir do diretório correspondente em `versions.txt`.
O helper `scripts/add-version.sh` cria a nova pasta e o Dockerfile com base na última versão já suportada.

## Build local

Este projeto usa [`Taskfile`](https://taskfile.dev/) para facilitar builds locais e reproduzir a lógica da pipeline.

Pré-requisitos:

1. Docker ou Docker Desktop instalado
2. `go-task` instalado
3. `docker buildx` habilitado se você quiser build multi-arquitetura

Se for a primeira vez usando buildx:

```bash
docker buildx create --use
```

Comandos principais:

```bash
task
task build VERSION=1.25
task build-all
task buildx VERSION=1.25
task buildx-all
task test
task test VERSION=1.25
```

Observações:

- `task build` gera a imagem para a arquitetura atual.
- `task buildx` gera a imagem para `linux/amd64` e `linux/arm64`.
- O `Taskfile` adiciona a tag `latest` automaticamente quando a versão é `1.25`.
- `task test` chama um script dedicado que constrói cada imagem e compila um app temporário `hello world` dentro dela.
- `task test VERSION=1.25` valida apenas uma versão específica, o que ajuda em verificações pontuais e no CI.

## Uso como imagem base

Exemplo de uso em um `Dockerfile` de aplicação:

```dockerfile
FROM maiconschmitz/go-builder:1.25 AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /src/dist/app ./main.go

FROM alpine:3.20

ENV TZ=America/Sao_Paulo
WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata && \
    adduser -D app

COPY --from=builder /src/dist/app /app/app

USER app
CMD ["/app/app"]
```

## Publicação e CI

A publicação automatizada acontece pela workflow `.github/workflows/docker-build-push.yml`:

- executa build para todas as versões listadas em `versions.txt`
- usa `docker buildx`
- publica imagens multi-arquitetura no Docker Hub
- aplica a tag `latest` apenas para a última versão da lista

## Dependabot

O arquivo `.github/dependabot.yml` está configurado para acompanhar as imagens Docker dos diretórios atuais.
Na prática, ele ajuda a manter cada versão existente atualizada com os `PATCH` releases da respectiva linha do Go.

Isso significa:

- `1.23` continua recebendo correções da linha `1.23.x`
- `1.24` continua recebendo correções da linha `1.24.x`
- `1.25` continua recebendo correções da linha `1.25.x`

Quando surgir uma nova versão menor ou maior, como `1.26`, a adição precisa ser feita manualmente no repositório, criando:

- a nova pasta `1.26/`
- o novo `Dockerfile`
- as atualizações no `Taskfile`
- as mudanças na workflow de CI
- a entrada correspondente no Dependabot

## Manutenção

Se você adicionar uma nova versão do Go, atualize junto:

- `versions.txt`
- o diretório da imagem
- o `Taskfile`
- a workflow do GitHub Actions
- a entrada correspondente no Dependabot
- este `README.md`

O arquivo `AGENTS.md` contém orientações de manutenção mais detalhadas para agentes e colaboradores.

Para facilitar esse fluxo, há um helper em [scripts/add-version.sh](/Users/maiconschmitz/projects/mcn/go_builder/scripts/add-version.sh) que cria a nova pasta, gera o `Dockerfile` e recompõe o Dependabot a partir da linha mais recente já suportada.
A validação ponta a ponta fica em [scripts/test-builds.sh](/Users/maiconschmitz/projects/mcn/go_builder/scripts/test-builds.sh) e é a mesma usada por `task test`.
