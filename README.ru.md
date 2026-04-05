<h1 align="center">FireStep</h1>

<p align="center">
  <a href="./README.md">English</a> |
  <a href="./README.ru.md"><strong>Русский</strong></a>
</p>

<p align="center">
  <img src="./.github/assets/project-icon.svg" alt="FireStep icon" width="160" />
</p>

<p align="center">
  <i>Сценарный тренировочный проект с клиентом на Godot, Go gRPC backend, общими protobuf-контрактами и веб-фронтендом на Next.js.</i>
</p>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-AGPL--3.0-3e4c75.svg?style=flat-square" alt="AGPL-3.0 license" /></a>
  <img src="https://img.shields.io/badge/stack-Godot%20%2B%20Go%20%2B%20gRPC%20%2B%20PostgreSQL%20%2B%20Next.js-222?style=flat-square" alt="Tech stack" />
  <img src="https://img.shields.io/badge/platform-Windows%20%2B%20Web-0078D6?style=flat-square" alt="Platforms" />
</p>

## Обзор

`FireStep` это монорепозиторий тренировочного проекта, в котором нативный клиент на Godot, backend на Go и общий слой
gRPC-контрактов, а также веб-интерфейс.

- `client/`: проект клиента на Godot 4, ассеты, сцены и C# gRPC-обвязка
- `backend/`: Go gRPC сервер, доменные и прикладные слои, PostgreSQL-репозитории, миграции
- `api/`: protobuf-контракты и Buf-конфигурация для генерации кода backend и C# клиента
- `web/`: фронтенд на Next.js 16 с API routes и серверным gRPC-мостом

## Текущее состояние

- Нативный клиент собран как проект Godot 4 со сценарными сценами вроде briefing, control lab, evacuation, shutdown и
  debrief.
- Backend использует Go, gRPC, `sqlc` и PostgreSQL, схема лежит в `backend/internal/migrations/`.
- Сейчас в `api/` заведены контракты для `LoginService`, `UserService`, `StatsService`, `SessionsService` и `SeancesService`.
- В C#-клиенте уже есть сгенерированные gRPC-контракты и фабрика общего канала с дефолтным адресом backend в коде.
- Веб-фронтенд находится в `web/` и уже включает auth, stats, admin и client session сценарии.

## Структура репозитория

```text
FireStep/
|-- api/                    # Protobuf-контракты и Buf generation
|-- backend/                # Go gRPC backend и PostgreSQL-интеграция
|-- client/                 # Godot-клиент, ассеты, сцены, C# bindings
|-- web/                    # Next.js веб-фронтенд
|-- .github/assets/         # Ассеты репозитория, включая иконку для README
|-- README.md
`-- README.ru.md
```

## Быстрый локальный старт

1. Примените PostgreSQL-схему из `backend/internal/migrations/scheme/scheme.sql`.
2. Запустите backend:

```bash
cd backend
go run ./cmd/fire-stepd
```

3. Откройте `client/project.godot` в Godot 4.6, чтобы запустить нативный клиент.
4. Если нужен веб-фронтенд, запустите его отдельно:

```bash
cd web
npm install
npm run dev
```

Если backend доступен не по `127.0.0.1:8080`, перед запуском задайте `FIRESTEP_GRPC_ADDR`.

5. После изменений в protobuf перегенерируйте контракты:

```bash
cd api
buf generate
```

## Docker

Образ веб-фронтенда нужно собирать из корня репозитория, потому что Next.js-сервер читает protobuf-файлы из `api/`
во время выполнения.

```bash
docker build -f web/Dockerfile -t fire-step-web .
docker run --rm -p 3000:3000 -e FIRESTEP_GRPC_ADDR=host.docker.internal:8080 fire-step-web
```

Контейнер слушает порт из `PORT`, по умолчанию это `3000`, так что при необходимости порт можно поменять:

```bash
docker run --rm -p 8081:8081 -e PORT=8081 -e FIRESTEP_GRPC_ADDR=host.docker.internal:8080 fire-step-web
```

## Лицензия

Проект распространяется под лицензией [GNU AGPL-3.0](./LICENSE).
