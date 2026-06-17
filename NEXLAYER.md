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
An open-source learning platform providing interactive coding challenges and certifications across various web development and machine learning curricula.
<!-- nexlayer:end -->

## Technology Stack
<!-- nexlayer:section agent-managed=tech_stack -->
| Name | Kind | Version | Detected From |
|------|------|---------|---------------|
| Node.js | language | 24 | .nvmrc, package.json |
| pnpm | tool | 10 | package.json, pnpm-workspace.yaml |
| MongoDB | database | latest | sample.env |
| TurboRepo | build | 2.8.7 | turbo.json |
| Gatsby | framework | latest | nexlayer_error.md |
| TypeScript | language | 5.9.3 | packages/challenge-linter/package.json |
<!-- nexlayer:end -->

## Repository Structure
<!-- nexlayer:section agent-managed=structure_map -->
- api/ — Backend server providing REST/GraphQL APIs
- client/ — Gatsby-based frontend application
- curriculum/ — Curriculum definitions and challenge content
- packages/shared/ — Common configuration and utility functions
- packages/challenge-builder/ — Logic for building and rendering challenges
- tools/ — Helper scripts for challenge management and seeding
<!-- nexlayer:end -->

## External Services Required
<!-- nexlayer:section agent-managed=external_deps -->
Services that must be configured separately (not deployed by Nexlayer):

- Auth0 (OAuth 2.0)
- Stripe (Payments)
- PayPal (Payments)
- Patreon (Payments)
- Algolia (Search)
- Sentry (Error Tracking)
- Growthbook (A/B Testing)
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
| `client` | `NODE_ENV` | `"production"` | plain |
| `api` | `PORT` | `"3000"` | plain |
| `api` | `MONGOHQ_URL` | `"mongodb://${mongodb:27017}/freecodecamp"` | inter-pod |

### nexlayer.yaml

```yaml
application:
  name: bold-lake-freecodecamp
  pods:
    - name: client
      image: "# filled by pipeline"
      servicePorts:
        - 8000
      vars:
        NODE_ENV: "production"
    - name: api
      image: "# filled by pipeline"
      servicePorts:
        - 3000
      vars:
        PORT: "3000"
        MONGOHQ_URL: "mongodb://${mongodb:27017}/freecodecamp"
    - name: mongodb
      image: mirror.gcr.io/library/mongo:7
      servicePorts:
        - 27017
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
**Last deployed:** 2026-06-17T22:35:34Z  
**Live URL:** https://bold-lake-freecodecamp.nexlayer.ai  
**Runtime:**  · **Port:** auto-detected  
**Deploy branch:** nexlayer  

```yaml
application:
  name: bold-lake-freecodecamp
  pods:
    - name: client
      image: "# filled by pipeline"
      servicePorts:
        - 8000
      vars:
        NODE_ENV: "production"
    - name: api
      image: "# filled by pipeline"
      servicePorts:
        - 3000
      vars:
        PORT: "3000"
        MONGOHQ_URL: "mongodb://${mongodb:27017}/freecodecamp"
    - name: mongodb
      image: mirror.gcr.io/library/mongo:7
      servicePorts:
        - 27017
```
<!-- nexlayer:end -->

## Build History
<!-- nexlayer:section agent-managed=build_history -->
| Date | Status | Notes |
|------|--------|-------|
| 2026-06-17T22:00:23Z | analyzed | initial repo analysis |
| 2026-06-17T22:35:34Z | success | deployed https://bold-lake-freecodecamp.nexlayer.ai |
<!-- nexlayer:end -->




