FROM ruby:3.4.3-alpine

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
# openssh and python3 removed — not needed at runtime.
# jq and gnupg kept for potential scripting; review if unused.
RUN apk update && apk upgrade && \
    apk add --no-cache binutils tar \
                       curl bash \
                       build-base nodejs npm tzdata postgresql-dev gcompat

WORKDIR /app

# ---------------------------------------------------------------------------
# Ruby gems (production only — no dev/test gems in the image)
# ---------------------------------------------------------------------------
COPY vendor ./vendor/
COPY Gemfile Gemfile.lock ./

RUN bundle config set without "development test" && \
    bundle install -j "$(getconf _NPROCESSORS_ONLN)" --retry 5

# ---------------------------------------------------------------------------
# Node / Vite asset build
# ---------------------------------------------------------------------------
COPY package.json package-lock.json ./

# Install all packages (including devDependencies) for the Vite build step,
# then immediately remove node_modules to keep the final image lean.
# Devtools are not present at runtime.
RUN npm ci && npx vite build && rm -rf node_modules

ENV NODE_ENV=production \
    RAILS_ENV=production \
    RACK_ENV=production \
    RAILS_ROOT=/app

# ---------------------------------------------------------------------------
# Application source
# ---------------------------------------------------------------------------
COPY . ./

# Precompile Sprockets assets.
# SECRET_KEY_BASE=dummy is safe here because precompile never starts the
# app server and does not touch the database.
RUN SECRET_KEY_BASE=dummy \
    RAILS_ENV=production \
    DATABASE_URL=postgresql://dummy:dummy@localhost/dummy \
    ./bin/rails assets:precompile

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
EXPOSE 3000
