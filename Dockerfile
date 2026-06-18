FROM mirror.gcr.io/library/node:24
# build-time env seeded from sample.env
ENV ALGOLIA_API_KEY=nexlayer-placeholder
ENV ALGOLIA_APP_ID=nexlayer-placeholder
ENV API_LOCATION=http://localhost:3000
ENV AUTH0_CLIENT_ID=nexlayer-placeholder
ENV AUTH0_CLIENT_SECRET=nexlayer-placeholder
ENV AUTH0_DOMAIN=example.auth0.com
ENV COOKIE_SECRET=a_cookie_secret
ENV EMAIL_PROVIDER=nodemailer
ENV FCC_API_LOG_LEVEL=info
ENV FCC_API_LOG_TRANSPORT=pretty
ENV FCC_ENABLE_DEV_LOGIN_MODE=true
ENV FCC_ENABLE_SENTRY_ROUTES=false
ENV FCC_ENABLE_SHADOW_CAPTURE=false
ENV FCC_ENABLE_SWAGGER_UI=true
ENV FORUM_LOCATION=https://forum.freecodecamp.org
ENV GATSBY_UPDATE_SCHEMA_SNAPSHOT=false
ENV GROWTHBOOK_FASTIFY_API_HOST=nexlayer-placeholder
ENV GROWTHBOOK_FASTIFY_CLIENT_KEY=nexlayer-placeholder
ENV GROWTHBOOK_URI=nexlayer-placeholder
ENV HOME_LOCATION=http://localhost:8000
ENV JWT_SECRET=a_jwt_secret
ENV MONGOHQ_URL=mongodb://127.0.0.1:27017/freecodecamp?directConnection=true
ENV NEWS_LOCATION=https://www.freecodecamp.org/news
ENV PATREON_CLIENT_ID=nexlayer-placeholder
ENV PAYPAL_CLIENT_ID=nexlayer-placeholder
ENV RADIO_LOCATION=https://coderadio.freecodecamp.org
ENV SENTRY_CLIENT_DSN=nexlayer-placeholder
ENV SENTRY_DSN=nexlayer-placeholder
ENV SENTRY_ENVIRONMENT=development
ENV SESSION_SECRET=a_thirty_two_plus_character_session_secret
ENV SES_SMTP_HOST=email-smtp.us-east-1.amazonaws.com
ENV SES_SMTP_PASSWORD=nexlayer-placeholder
ENV SES_SMTP_USERNAME=nexlayer-placeholder
ENV SOCRATES_API_KEY=something
ENV SOCRATES_ENDPOINT=https://localhost:4000
ENV STRIPE_PUBLIC_KEY=nexlayer-placeholder
ENV STRIPE_SECRET_KEY=nexlayer-placeholder

RUN apt-get update && apt-get install -y python3 make g++ git ca-certificates unzip tar && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN npm i -g corepack@latest && corepack enable && corepack prepare pnpm@10.33.3 --activate

COPY . .

ENV PUPPETEER_SKIP_DOWNLOAD=true

RUN pnpm install --no-frozen-lockfile

RUN pnpm --filter @freecodecamp/shared run build

RUN pnpm --filter @freecodecamp/browser-scripts run build

RUN pnpm --filter @freecodecamp/challenge-linter run build

RUN pnpm --filter @freecodecamp/challenge-builder run build

ENV CURRICULUM_LOCALE=english
RUN pnpm --filter @freecodecamp/curriculum run setup

RUN pnpm --filter @freecodecamp/curriculum run build

ENV FREECODECAMP_NODE_ENV=production
ENV DEPLOYMENT_ENV=staging
ENV CLIENT_LOCALE=english
ENV SHOW_UPCOMING_CHANGES=false
ENV GATSBY_TELEMETRY_DISABLED=1
ENV GATSBY_CPU_COUNT=4
ENV NODE_OPTIONS="--max-old-space-size=8192"
ENV CHOKIDAR_USEPOLLING=true
ENV WATCHPACK_POLLING=true

RUN rm -rf curriculum/challenges

RUN pnpm --filter @freecodecamp/client run setup

RUN pnpm --filter @freecodecamp/client run build

EXPOSE 8000

WORKDIR /app/client

CMD ["node_modules/.bin/serve", "-l", "tcp://0.0.0.0:8000", "public"]