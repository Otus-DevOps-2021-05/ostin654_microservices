FROM ubuntu:18.04

RUN apt-get update
RUN apt-get install -y mongodb-server ruby-full ruby-dev build-essential git ruby-bundler

COPY ./ /reddit

RUN cd /reddit && rm Gemfile.lock && bundle install
RUN chmod 0777 /reddit/start.sh

CMD ["/reddit/start.sh"]
