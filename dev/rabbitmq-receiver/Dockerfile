FROM docker.io/library/ruby:3.0.4

WORKDIR /app
COPY Gemfile Gemfile.lock ./
COPY app.rb .

RUN gem install bundler:2.3.5
RUN bundle install

CMD ["tail", "-F", "anything"]
