FROM ruby:3.4.3-alpine

ENV PATH /root/.yarn/bin:$PATH

RUN apk update && apk upgrade && \
    apk add --no-cache binutils tar gnupg \
                       curl jq python3 bash openssh \
                       build-base nodejs npm tzdata postgresql-dev gcompat

WORKDIR /app

COPY vendor ./vendor/
COPY Gemfile Gemfile.lock ./

RUN bundle config set without 'development test' && \
    bundle install -j "$(getconf _NPROCESSORS_ONLN)" --retry 5

COPY package.json package-lock.json ./
RUN npm ci --production=false && npx vite build

ENV NODE_ENV production
ENV RAILS_ENV production
ENV RACK_ENV production
ENV RAILS_ROOT /app

ARG SECRET_KEY_BASE
ENV SECRET_KEY_BASE $SECRET_KEY_BASE

ARG APPLICATION_HOST
ENV APPLICATION_HOST $APPLICATION_HOST

COPY . ./
RUN SECRET_KEY_BASE=testtest RAILS_ENV=production DATABASE_URL=postgresql:does_not_exist ./bin/rails assets:precompile

EXPOSE 3000
