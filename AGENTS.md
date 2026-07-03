# AGENTS.md

Guia rápido para agentes trabalhando neste repositório.

## Objetivo do projeto

Este repositório mantém imagens Docker prontas para build de aplicações Go.
Cada versão do Go vive em um diretório separado e gera uma imagem própria.
A lista de versões suportadas fica em `versions.txt`.

O foco das imagens é build reprodutível, suporte a cross-compile para `linux/amd64` e `linux/arm64`, e uma base consistente para pipelines de CI.

## Estrutura principal

- `README.md`: documentação de uso e visão geral.
- `AGENTS.md`: guia de manutenção para agentes.
- `versions.txt`: lista central das versões suportadas.
- `taskfile.yml`: comandos locais para build.
- `1.x/Dockerfile`: definições das imagens por versão, uma pasta por linha em `versions.txt`.
- `.github/workflows/docker-build-push.yml`: pipeline de build e publicação.
- `.github/dependabot.yml`: automação de updates para as versões suportadas.
- `scripts/add-version.sh`: helper para criar uma nova versão e regenerar a configuração de suporte.
- `scripts/test-builds.sh`: validação ponta a ponta reutilizável por `task test` e pelo CI.

## Convenções do repositório

- O diretório da imagem deve corresponder à versão do Go.
- A variável `GO_VERSION` no `Dockerfile` deve bater com a pasta da imagem.
- A tag `latest` acompanha a última versão listada em `versions.txt`.
- `versions.txt` é a fonte de verdade para o conjunto suportado e é lido pelo `Taskfile`, pela workflow e pelo helper de scaffolding.
- O Dependabot deve acompanhar `PATCH` updates apenas nas versões já existentes.
- Novas `MINOR` ou `MAJOR` versions não surgem automaticamente: crie a nova pasta e atualize a automação do repositório.
- Se uma nova versão for adicionada, atualize também:
  - `versions.txt`
  - `taskfile.yml`
  - `.github/workflows/docker-build-push.yml`
  - `README.md`
  - `.github/dependabot.yml`, se continuar em uso

## Build local

Use `task` para reproduzir os builds da imagem:

- `task` lista os comandos disponíveis.
- `task build VERSION=1.25` constrói uma versão específica.
- `task build-all` constrói todas as versões.
- `task buildx VERSION=1.25` faz build multi-arquitetura.
- `task buildx-all` roda todas as versões em multi-arquitetura.
- `task test` executa a validação ponta a ponta em todas as versões suportadas.
- `task test VERSION=1.25` executa a validação em apenas uma versão.

Observação: o `Taskfile` tagueia as imagens locais como `maiconschmitz/go-builder:<versão>`, adicionando `latest` para a última versão listada em `versions.txt`.
O helper `scripts/add-version.sh` cria a nova pasta, deriva o `Dockerfile` da última versão suportada e recompõe o Dependabot.
O helper `scripts/test-builds.sh` cria um app temporário `hello world`, constrói cada imagem e compila o binário dentro dela.

## O que observar ao editar

- Não altere arquivos fora do escopo sem necessidade.
- Não reverta mudanças do usuário.
- Mantenha os `Dockerfile`s consistentes entre si, mudando apenas o que realmente varia por versão.
- Preserve o uso de `bookworm`, `TZ=America/Sao_Paulo` e as ferramentas instaladas, a menos que exista um motivo claro para mudar.
- Se mexer na pipeline, confira se os filtros de caminho e a matriz de versões continuam alinhados com os diretórios existentes.

## Resumo técnico

As imagens usam a base oficial `golang:<versão>-bookworm`, instalam dependências para build e cross-compile, e deixam o `WORKDIR` em `/src`.
