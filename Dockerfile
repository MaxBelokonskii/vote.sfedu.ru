FROM ruby:3.4.3-alpine

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
# openssh and python3 removed — not needed at runtime.
# jq and gnupg kept for potential scripting; review if unused.
RUN apk update && apk upgrade && \
    apk add --no-cache binutils tar \
                       curl bash \
                       build-base nodejs npm tzdata postgresql-dev gcompat \
                       yaml-dev

WORKDIR /app

# ---------------------------------------------------------------------------
# Ruby gems (production only — no dev/test gems in the image)
# ---------------------------------------------------------------------------
COPY vendor ./vendor/
COPY Gemfile Gemfile.lock ./

RUN bundle config set without "development test" && \
    bundle install -j "$(getconf _NPROCESSORS_ONLN)" --retry 5

# ---------------------------------------------------------------------------
# Node dependencies (cached separately from app source)
# ---------------------------------------------------------------------------
COPY package.json package-lock.json ./
RUN npm ci

ENV NODE_ENV=production \
    RAILS_ENV=production \
    RACK_ENV=production \
    RAILS_ROOT=/app

# ---------------------------------------------------------------------------
# Application source
# ---------------------------------------------------------------------------
COPY . ./

# ---------------------------------------------------------------------------
# Asset build: Vite (Vue SPA) + Sprockets
# ---------------------------------------------------------------------------
# SECRET_KEY_BASE=dummy is safe here because precompile never starts the
# app server and does not touch the database.
RUN SECRET_KEY_BASE=dummy \
    RAILS_ENV=production \
    DATABASE_URL=postgresql://dummy:dummy@localhost/dummy \
    APPLICATION_HOST=dummy \
    S3_BUCKET=dummy \
    S3_ACCESS_KEY_ID=dummy \
    S3_SECRET_ACCESS_KEY=dummy \
    ./bin/rails assets:precompile && \
    rm -rf node_modules

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
EXPOSE 3000
