# Nexlayer — freeCodeCamp

<!-- nexlayer:meta version=1 analyzed=2026-06-16T20:38:55Z repo=https://github.com/armondhonore/freeCodeCamp branch=nexlayer -->

> **For AI agents (Claude Code, Cursor, Gemini CLI, Copilot):**
> This file is the **project context** for this Nexlayer deployment — tech stack, env vars, secrets, live URL.
> For full platform detail (nexlayer.yaml schema, Dockerfile rules, CI/CD, task recipes) read **`nexlayer.skills`** in this repo.
>
> **Critical rules (full detail in `nexlayer.skills`):**
> - Inter-pod refs: `${podName:port}` only — never `localhost` or bare hostnames
> - Docker Hub images: prefix with `mirror.gcr.io/library/` — bare tags fail on the cluster
> - Secrets: set in the Nexlayer dashboard — never commit to `nexlayer.yaml` or Dockerfile
>
> **This file:** `agent-managed` sections update automatically. `user-editable` sections (Local Development Setup, Nexlayer Deployment Plan, Build Notes) are yours — preserved across re-analysis.

## Project Summary
<!-- nexlayer:section agent-managed=project_summary -->
An open-source learning platform providing an interactive full-stack web development and machine learning curriculum through coding challenges and certifications.
<!-- nexlayer:end -->

## Technology Stack
<!-- nexlayer:section agent-managed=tech_stack -->
| Name | Kind | Version | Detected From |
|------|------|---------|---------------|
| Node.js | language | >=24 | package.json, .nvmrc |
| pnpm | tool | >=10 | package.json |
| TurboRepo | build | latest | turbo.json |
| TypeScript | language | 5.9.3 | packages/challenge-linter/package.json |
| MongoDB | database | latest | turbo.json |
<!-- nexlayer:end -->

## Repository Structure
<!-- nexlayer:section agent-managed=structure_map -->
- api/ — Backend API services
- client/ — Frontend user interface
- curriculum/ — Challenge definitions and generated content
- packages/shared/ — Shared configurations and utilities
- packages/challenge-builder/ — Logic for rendering and testing challenges
- packages/challenge-linter/ — Validation tools for curriculum content
<!-- nexlayer:end -->

## External Services Required
<!-- nexlayer:section agent-managed=external_deps -->
Services that must be configured separately (not deployed by Nexlayer):

- MongoDB (via MONGOHQ_URL)
<!-- nexlayer:end -->

## Local Development Setup
<!-- nexlayer:section user-editable=local_setup -->
### Prerequisites

- Node.js >= 24
- pnpm >= 10

### Environment variables

Copy `.env.example` to `.env.local` and fill in:

```
MONGOHQ_URL=mongodb://localhost:27017/freecodecamp
```

### Steps

1. `pnpm install` — Install all workspace dependencies
2. `pnpm run build` — Build shared packages and applications via Turbo
3. `pnpm run develop` — Start development servers for client and api

<!-- nexlayer:end -->

## Nexlayer Setup
<!-- nexlayer:section agent-managed=nexlayer_setup -->
### Pod Environment Variables

| Pod | Variable | Value | Kind |
|-----|----------|-------|------|
| `app` | `NODE_ENV` | `production` | plain |
| `app` | `PORT` | `"3000"` | plain |
| `app` | `HOSTNAME` | `"0.0.0.0"` | plain |
| `app` | `MONGO_URL` | `"mongodb://${mongo:27017}/freecodecamp"` | inter-pod |
| `app` | `NEXTAUTH_SECRET` | _(set via Nexlayer dashboard)_ | secret |
| `app` | `NEXTAUTH_URL` | _(set via Nexlayer dashboard)_ | secret |
| `mongo` | `command` | `"mongod --replSet rs0 --bind_ip_all"` | plain |

### Secrets Required

Set these in the Nexlayer dashboard before deploying:

- `NEXTAUTH_SECRET` (`app` pod)
- `NEXTAUTH_URL` (`app` pod)

### nexlayer.yaml

```yaml
application:
  name: bold-lake-freecodecamp
  pods:
    - name: app
      image: "# filled by pipeline"
      path: /
      servicePorts:
        - 3000
      vars:
        NODE_ENV: production
        PORT: "3000"
        HOSTNAME: "0.0.0.0"
        MONGO_URL: "mongodb://${mongo:27017}/freecodecamp"
        NEXTAUTH_SECRET: "placeholder_secret_change_me"
        NEXTAUTH_URL: "http://app:3000"
    - name: mongo
      image: mirror.gcr.io/library/mongo:7
      servicePorts:
        - 27017
      command: "mongod --replSet rs0 --bind_ip_all"
      vars: {}
```

<!-- nexlayer:end -->

## Nexlayer Deployment Plan
<!-- nexlayer:section user-editable=deployment_plan -->
### Pod Topology

| Pod | Image | Port | Role |
|-----|-------|------|------|
| api | mirror.gcr.io/library/node:24-alpine | 8080 | web |
| client | mirror.gcr.io/library/node:24-alpine | 3000 | web |
| mongodb | mirror.gcr.io/library/mongodb:latest | 27017 | database |

### Inter-pod environment variables

- `api` pod: `MONGOHQ_URL=${mongodb:27017}`
- `client` pod: `API_URL=${api:8080}`

### Deployment notes

- Inter-pod communication for the API to reach the database uses ${mongodb:27017}.
- Client pod connects to the API using ${api:8080}.
- Images use mirror.gcr.io to comply with Nexlayer cluster restrictions.

<!-- nexlayer:end -->

## Build Notes
<!-- nexlayer:section user-editable=build_notes -->
<!-- Add notes for future builds here — preserved across re-analysis -->
<!-- nexlayer:end -->

## Nexlayer Configuration
<!-- nexlayer:section agent-managed=nexlayer_config -->
**Last deployed:** 2026-06-16T21:01:44Z  
**Live URL:** https://relaxed-weasel-bold-lake-freecodecamp.cloud.nexlayer.ai  
**Runtime:** node · **Port:** 3000  
**Deploy branch:** nexlayer  

```yaml
application:
  name: bold-lake-freecodecamp
  pods:
    - name: app
      image: "# filled by pipeline"
      path: /
      servicePorts:
        - 3000
      vars:
        NODE_ENV: production
        PORT: "3000"
        HOSTNAME: "0.0.0.0"
        MONGO_URL: "mongodb://${mongo:27017}/freecodecamp"
        NEXTAUTH_SECRET: "placeholder_secret_change_me"
        NEXTAUTH_URL: "http://app:3000"
    - name: mongo
      image: mirror.gcr.io/library/mongo:7
      servicePorts:
        - 27017
      command: "mongod --replSet rs0 --bind_ip_all"
      vars: {}
```
<!-- nexlayer:end -->

## Build History
<!-- nexlayer:section agent-managed=build_history -->
| Date | Status | Notes |
|------|--------|-------|
| 2026-06-16T20:38:55Z | analyzed | initial repo analysis |
| 2026-06-16T21:01:44Z | success | deployed https://relaxed-weasel-bold-lake-freecodecamp.cloud.nexlayer.ai |
<!-- nexlayer:end -->
