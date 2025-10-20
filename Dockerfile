# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t gitnix .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name gitnix gitnix

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.3
FROM ubuntu:24.04 AS base

# Rails app lives here
WORKDIR /rails

ENV DEBIAN_FRONTEND=noninteractive TZ=UTC

RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential locales ca-certificates tzdata \
    curl git unzip vim\
    libjemalloc2 \
    libvips \
    postgresql-client \
    cmake \
    pkg-config \
    libicu-dev libpq-dev libyaml-dev libgdbm-dev libffi-dev \
    libreadline-dev libssl-dev libncurses5-dev zlib1g-dev\
    openssh-server \
    ruby \
    && update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
    && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure locales \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Ruby from source
RUN curl -fSL "https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.3.tar.gz" | tar xz
RUN cd ruby-3.2.3 && \
    ./configure && \
    make && \
    make install && \
    cd .. && rm -rf ruby-3.2.3

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    GISIA_DOCKER="true" \
    SKIP_DATABASE_CONFIG_VALIDATION=true

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install application gems
COPY vendor ./vendor
COPY gems ./gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
  rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
  bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .


# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN cp config/gitlab.example.yml config/gitlab.yml
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
RUN rm config/gitlab.yml
RUN rm config/secrets.yml

# extra operations
RUN rm -f /etc/ssh/ssh_host_*
RUN rm -rf /rails/tmp

# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

COPY tmp /rails/tmp
RUN mkdir -p /services/
# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1010 rails && \
    useradd rails --uid 1010 --gid 1010 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage /rails/tmp

# RUN chown 1000:1000 config/secrets.yml
RUN chown -R rails:rails /rails/config /services/
RUN chown rails:rails /rails/

USER 1010:1010

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
CMD ["./bin/rails", "server"]
