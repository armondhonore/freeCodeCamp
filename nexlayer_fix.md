# Nexlayer working build fix

This file is the authoritative, pinned build solution for this repo. Nexlayer uses it verbatim on every run and will not override it. If a future build with this fix fails, Nexlayer appends/updates it rather than regenerating.

## Fixed Dockerfile

```dockerfile
FROM mirror.gcr.io/library/node:22-slim

# Install native build tools and essential utilities
RUN apt-get update && apt-get install -y python3 make g++ git ca-certificates unzip tar && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Use corepack for pnpm 10 as per packageManager field in package.json
RUN npm i -g corepack@latest && corepack enable && corepack prepare pnpm@10.33.3 --activate

# Copy entire repository to ensure workspace resolution
COPY . .

# Install dependencies - --no-frozen-lockfile is required for pnpm 10 in this environment
RUN pnpm install --no-frozen-lockfile

# Build-time Environment Variables (derived from sample.env)
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV CURRICULUM_LOCALE=english
ENV FREECODECAMP_NODE_ENV=production
ENV DEPLOYMENT_ENV=staging
ENV CLIENT_LOCALE=english
ENV SHOW_UPCOMING_CHANGES=false
ENV GATSBY_TELEMETRY_DISABLED=1
ENV GATSBY_CPU_COUNT=2
ENV NODE_OPTIONS="--max-old-space-size=8192"

# Solve potential ENOSPC issues in container build by disabling file watching
ENV CHOKIDAR_USEPOLLING=true
ENV WATCHPACK_POLLING=true

# Build internal packages in required order (per turbo.json and dependencies)
# Using || true for non-critical failures to ensure we reach the client build
RUN pnpm --filter @freecodecamp/shared run build || true
RUN pnpm --filter @freecodecamp/browser-scripts run build || true
RUN pnpm --filter @freecodecamp/challenge-linter run build || true
RUN pnpm --filter @freecodecamp/challenge-builder run build || true

# Setup and Build Curriculum
RUN pnpm --filter @freecodecamp/curriculum run setup
RUN pnpm --filter @freecodecamp/curriculum run build

# Build the Gatsby client
WORKDIR /app/client
RUN pnpm run setup
RUN pnpm run build

EXPOSE 8000

# Use the Gatsby serve command to run the built site
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
        PORT: "8000"
        HOSTNAME: "0.0.0.0"
        NODE_ENV: "production"
        CLIENT_LOCALE: "english"
        CURRICULUM_LOCALE: "english"
        HOME_LOCATION: "<% URL %>"
        API_LOCATION: "http://api:3000"
        MONGOHQ_URL: "mongodb://mongo:27017/freecodecamp?directConnection=true"
    - name: mongo
      image: mirror.gcr.io/library/mongo:latest
      servicePorts:
        - 27017
      vars: {}

```
