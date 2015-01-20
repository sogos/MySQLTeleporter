# Dockerfile for rundeck

FROM debian:wheezy

MAINTAINER Thibault CORDIER

ENV MYSQL_SERVER_1_HOST null
ENV MYSQL_SERVER_2_HOST null
ENV MYSQL_SERVER_1_USERNAME null
ENV MYSQL_SERVER_2_USERNAME null
ENV MYSQL_SERVER_1_PASSWORD null
ENV MYSQL_SERVER_2_PASSWORD null
ENV MYSQL_DATABASE_SOURCE_NAME null
ENV MYSQL_DATABASE_TARGET_NAME null

RUN apt-get -qq update && apt-get -qqy upgrade && apt-get -qqy install --no-install-recommends php5-cli openssh-client mysql-client pwgen && apt-get clean

ADD run.sh /opt/run
ADD extract_keys.php /opt/extract_keys.php

RUN chmod +x /opt/run


VOLUME ["/tmp"]

# Start Supervisor
ENTRYPOINT ["/opt/run"]
