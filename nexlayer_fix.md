# Nexlayer working build fix

This file is the authoritative, pinned build solution for this repo. Nexlayer uses it verbatim on every run and will not override it. If a future build with this fix fails, Nexlayer appends/updates it rather than regenerating.

## Fixed Dockerfile

```dockerfile
FROM mirror.gcr.io/library/node:24-slim

# Install native build tools and essential utilities
RUN apt-get update && apt-get install -y python3 make g++ git ca-certificates unzip tar && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Use corepack for pnpm 10 as per packageManager field
RUN npm i -g corepack@latest && corepack enable && corepack prepare pnpm@10.33.3 --activate

# CRITICAL: In pnpm workspaces with 'workspace:*' dependencies, 
# copying only manifests causes ERR_PNPM_WORKSPACE_PKG_NOT_FOUND 
# because pnpm needs to see the actual package.json of the workspace dependencies.
# We copy the entire repo first to ensure all workspace members are present.
COPY . .

# Install dependencies
RUN pnpm install --no-frozen-lockfile

# Environment variables for build
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV CURRICULUM_LOCALE=english
ENV FREECODECAMP_NODE_ENV=production
ENV DEPLOYMENT_ENV=staging
ENV CLIENT_LOCALE=english
ENV SHOW_UPCOMING_CHANGES=false
ENV GATSBY_TELEMETRY_DISABLED=1
ENV GATSBY_CPU_COUNT=4
ENV NODE_OPTIONS="--max-old-space-size=8192"
ENV CHOKIDAR_USEPOLLING=true
ENV WATCHPACK_POLLING=true

# Build sequence using Turbo/pnpm filters to avoid OOM and build-all issues
# Build internal packages first
RUN pnpm --filter @freecodecamp/shared run build
RUN pnpm --filter @freecodecamp/browser-scripts run build
RUN pnpm --filter @freecodecamp/challenge-linter run build
RUN pnpm --filter @freecodecamp/challenge-builder run build

# Build curriculum
RUN pnpm --filter @freecodecamp/curriculum run setup
RUN pnpm --filter @freecodecamp/curriculum run build

# Clean up challenge files to save space/avoid conflicts
RUN rm -rf curriculum/challenges

# Build the primary client app
RUN pnpm --filter @freecodecamp/client run setup
RUN pnpm --filter @freecodecamp/client run build

EXPOSE 8000

WORKDIR /app/client

# Gatsby serve command
CMD ["node_modules/.bin/gatsby", "serve", "-p", "8000", "--host", "0.0.0.0"]
```

## Fixed nexlayer.yaml

```yaml
application:
  name: freecodecamp
  pods:
    - name: app
      image: "# filled by pipeline"
      servicePorts:
        - 8000
      vars:
        NODE_OPTIONS: "--max-old-space-size=8192"
        PORT: "8000"
        HOSTNAME: "0.0.0.0"
        CLIENT_LOCALE: "english"
        CURRICULUM_LOCALE: "english"
```
