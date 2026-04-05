<h1 align="center">FireStep</h1>

<p align="center">
  <a href="./README.md"><strong>English</strong></a> |
  <a href="./README.ru.md">Русский</a>
</p>

<p align="center">
  <img src="./.github/assets/project-icon.svg" alt="FireStep icon" width="160" />
</p>

<p align="center">
  <i>Scenario-based training project with a Godot client, a Go gRPC backend, shared protobuf contracts, and a Next.js web frontend.</i>
</p>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-AGPL--3.0-3e4c75.svg?style=flat-square" alt="AGPL-3.0 license" /></a>
  <img src="https://img.shields.io/badge/stack-Godot%20%2B%20Go%20%2B%20gRPC%20%2B%20PostgreSQL%20%2B%20Next.js-222?style=flat-square" alt="Tech stack" />
  <img src="https://img.shields.io/badge/platform-Windows%20%2B%20Web-0078D6?style=flat-square" alt="Platforms" />
</p>

## Overview

`FireStep` is a monorepo for a training project built around a native Godot client, a Go backend, shared gRPC
contracts, and a web interface.

- `client/`: Godot 4 client project, assets, scenes, and C# gRPC client bindings
- `backend/`: Go gRPC server, domain and application layers, PostgreSQL repositories, migrations
- `api/`: protobuf contracts and Buf generation config for backend and C# client code
- `web/`: Next.js 16 frontend with API routes and a server-side gRPC bridge

## Current State

- The native client is a Godot 4 project with scenario scenes such as briefing, control lab, evacuation, shutdown, and
  debrief flows.
- The backend uses Go, gRPC, `sqlc`, and PostgreSQL with schema files stored in `backend/internal/migrations/`.
- API contracts currently cover `LoginService`, `UserService`, `StatsService`, `SessionsService`, and `SeancesService`.
- The C# client layer includes generated gRPC contracts and a shared channel factory with the default backend address
  set in code.
- The web frontend is located in `web/` and includes auth, stats, admin, and client session flows.

## Repository Layout

```text
FireStep/
|-- api/                    # Protobuf contracts and Buf generation
|-- backend/                # Go gRPC backend and PostgreSQL integration
|-- client/                 # Godot client, assets, scenes, C# bindings
|-- web/                    # Next.js web frontend
|-- .github/assets/         # Repository assets, including README icon
|-- README.md
`-- README.ru.md
```

## Local Start

1. Apply the PostgreSQL schema from `backend/internal/migrations/scheme/scheme.sql`.
2. Start the backend:

```bash
cd backend
go run ./cmd/fire-stepd
```

3. Open `client/project.godot` in Godot 4.6 to run the native client.
4. Start the web frontend if needed:

```bash
cd web
npm install
npm run dev
```

If the backend is not available at `127.0.0.1:8080`, set `FIRESTEP_GRPC_ADDR` before starting the web app.

5. Regenerate contracts after protobuf changes:

```bash
cd api
buf generate
```

## Docker

The web Docker image must be built from the repository root because the Next.js server reads protobuf files from
`api/` at runtime.

```bash
docker build -f web/Dockerfile -t fire-step-web .
docker run --rm -p 3000:3000 -e FIRESTEP_GRPC_ADDR=host.docker.internal:8080 fire-step-web
```

The container listens on `PORT` and defaults to `3000`, so you can remap it if needed:

```bash
docker run --rm -p 8081:8081 -e PORT=8081 -e FIRESTEP_GRPC_ADDR=host.docker.internal:8080 fire-step-web
```

## License

This project is licensed under the [GNU AGPL-3.0](./LICENSE).
