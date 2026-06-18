# Nexlayer Build Failure Report

**Pipeline:** 19ed805ea95
**Repository:** https://github.com/armondhonore/freeCodeCamp
**Error category:** invalid_yaml
**Error summary:** nexlayer.yaml is malformed.

## Build log
```

```

## Repository build artifacts

These are the actual files from the repository. Use these to understand how the project
is SUPPOSED to be built — do not rely solely on the broken Dockerfile below.

_No build artifact files were captured from the repository._


## Last attempted Dockerfile
```dockerfile
FROM mirror.gcr.io/library/node:24-slim

# Install native build tools
RUN apt-get update && apt-get install -y python3 make g++ git ca-certificates unzip tar && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Use corepack for pnpm 10 as per packageManager field
RUN npm i -g corepack@latest && corepack enable && corepack prepare pnpm@10.33.3 --activate

# Copy entire repo
COPY . .

# Install dependencies - --no-frozen-lockfile is required for pnpm 10 in this env
RUN pnpm install --no-frozen-lockfile

# Build-time Environment Variables
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV CURRICULUM_LOCALE=english
ENV FREECODECAMP_NODE_ENV=production
ENV DEPLOYMENT_ENV=staging
ENV CLIENT_LOCALE=english
ENV SHOW_UPCOMING_CHANGES=false
ENV GATSBY_TELEMETRY_DISABLED=1
ENV GATSBY_CPU_COUNT=2
ENV NODE_OPTIONS="--max-old-space-size=8192"

# CRITICAL: Solve ENOSPC by disabling file watching entirely
# In a container build, we do not need watchers. Polling is a fallback, 
# but the best way is to ensure NO watcher is spawned.
ENV CHOKIDAR_USEPOLLING=true
ENV WATCHPACK_POLLING=true

# Build internal packages in strict order
# We use '|| true' to bypass non-critical failures but focus on the client build
RUN pnpm --filter @freecodecamp/shared run build || true
RUN pnpm --filter @freecodecamp/browser-scripts run build || true
RUN pnpm --filter @freecodecamp/challenge-linter run build || true
RUN pnpm --filter @freecodecamp/challenge-builder run build || true

# Setup and Build Curriculum
RUN pnpm --filter @freecodecamp/curriculum run setup || true
RUN pnpm --filter @freecodecamp/curriculum run build || true

# Build Client (Gatsby)
# We run setup then build. We wrap the build in a way that ensures it doesn't 
# hang on watchers by setting the env vars above.
RUN pnpm --filter @freecodecamp/client run setup || true
RUN pnpm --filter @freecodecamp/client run build

# Final Runtime Configuration
EXPOSE 8000
WORKDIR /app/client

# Use gatsby serve to host the static site
CMD ["node_modules/.bin/gatsby", "serve", "-p", "8000", "--host", "0.0.0.0"]
```

## Last attempted nexlayer.yaml
```yaml

```

## Instructions for frontier model

CRITICAL: Before writing any fix, read the repository build artifacts above and answer:
1. What language/runtime does this project use? (go.mod, package.json, pom.xml, Cargo.toml, requirements.txt)
2. What is the actual build command? (package.json scripts.build, Makefile targets, pom.xml goals, gradle tasks)
3. What is the actual start command? (package.json scripts.start, Makefile run target, Procfile)
4. What port does it serve? (EXPOSE, ENV PORT=, --port flag, framework default)
5. What dependencies does it need at runtime? (docker-compose.yml services, .env.example vars)

Then create a correct Dockerfile from scratch based on your analysis:
- All FROM base images must be standard public images (library/, gcr.io, ghcr.io, etc.)
- Use `mirror.gcr.io/library/` prefix for Docker Hub official images (node:*, python:*, golang:*, etc.)
- DO NOT copy broken steps from the "last attempted Dockerfile" — build from what the repo actually needs

Fix nexlayer.yaml if needed:
- Inter-pod service references MUST use `${podName:port}` template syntax
- Example: `DATABASE_URL: postgresql://user:pass@${postgres:5432}/db`

Create a file named `nexlayer_fix.md` on THIS branch (`nexlayer`) with this structure:

---
# Nexlayer Fix

## Fixed Dockerfile
```dockerfile
<your fixed Dockerfile>
```

## Fixed nexlayer.yaml
```yaml
<your fixed nexlayer.yaml>
```

## Notes
<explain: what build command you found, what was wrong with the previous Dockerfile, what you changed and why>
---

Nexlayer detects `nexlayer_fix.md` on the next pipeline run and applies your fixes automatically.
