FROM ruby:3.4-alpine

RUN gem install typosquatting

ENTRYPOINT ["typosquatting"]
