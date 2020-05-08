FROM ruby:2.6.3

WORKDIR /code
EXPOSE 2999

ENV BUNDLE_PATH="/bundle_cache"\
  BUNDLE_BIN="/bundle_cache/bin"\
  BUNDLE_APP_CONFIG="/bundle_cache"\
  RAILS_ENV="production" \
  GEM_HOME="/bundle_cache"\
  BUNDLE_WITHOUT="development test" \
  PATH=/bundle_cache/bin:/bundle_cache/gems/bin:$PATH\
  PORT=2999

RUN gem install bundler

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
RUN mv config/secrets.yml.docker config/secrets.yml && \
  rake assets:precompile

CMD ["bundle", "exec", "rails", "server", "--binding", "0.0.0.0", "--port", "2999"]
