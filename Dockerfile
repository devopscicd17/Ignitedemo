#
# Copyright 2019 Confluent Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG DOCKER_UPSTREAM_REGISTRY
ARG DOCKER_UPSTREAM_TAG=ubi8-latest

FROM confluentinc/cp-base-new:latest

ARG PROJECT_VERSION
ARG ARTIFACT_ID
ARG GIT_COMMIT
USER root
RUN dnf update -y
RUN dnf install libksba

LABEL maintainer="partner-support@confluent.io"
LABEL vendor="Confluent"
LABEL version=$GIT_COMMIT
LABEL release=$PROJECT_VERSION
LABEL name=$ARTIFACT_ID
LABEL summary="Confluent platform Kafka."
LABEL io.confluent.docker=true
LABEL io.confluent.docker.git.id=$GIT_COMMIT
ARG BUILD_NUMBER=-1
LABEL io.confluent.docker.build.number=$BUILD_NUMBER
LABEL io.confluent.docker.git.repo="confluentinc/kafka-images"

ARG CONFLUENT_VERSION
ARG CONFLUENT_PACKAGES_REPO
ARG CONFLUENT_PLATFORM_LABEL

# allow arg override of required env params
ARG KAFKA_ZOOKEEPER_CONNECT
ENV KAFKA_ZOOKEEPER_CONNECT=${KAFKA_ZOOKEEPER_CONNECT}
ARG KAFKA_ADVERTISED_LISTENERS
ENV KAFKA_ADVERTISED_LISTENERS=${KAFKA_ADVERTISED_LISTENERS}

ENV COMPONENT=kafka
ENV CONFLUENT_PACKAGES_REPO=https://packages.confluent.io/clients/rpm
# primary
EXPOSE 9092

USER root
#Copying vulnerability jar files 


COPY confluent-kafka-7.2.0-1.noarch.rpm .
COPY jetty-io-9.4.47.v20220610.jar .
COPY jackson-databind-2.14.0-rc2.jar .
COPY snakeyaml-1.33.jar .
COPY jmx_prometheus_javaagent-0.17.2.jar .
RUN echo "===> Installing ${COMPONENT}..." \
    && echo "===> Adding confluent repository...${CONFLUENT_PACKAGES_REPO}" \
    && rpm --import ${CONFLUENT_PACKAGES_REPO}/archive.key \
#    && printf "[Confluent.dist] \n\
#name=Confluent repository (dist) \n\
#baseurl=${CONFLUENT_PACKAGES_REPO}/\$releasever \n\
#gpgcheck=1 \n\
#gpgkey=https://packages.confluent.io/rpm/7.2/archive.key \n\
#enabled=1 \n\
#\n\
#[Confluent] \n\
#name=Confluent repository \n\
#baseurl=${CONFLUENT_PACKAGES_REPO}/ \n\
#gpgcheck=1 \n\
#gpgkey=${CONFLUENT_PACKAGES_REPO}/archive.key \n\
#enabled=1 " > /etc/yum.repos.d/confluent.repo \
    && yum install -y confluent-kafka-7.2.0-1.noarch.rpm \
    && echo "===> clean up ..."  \
    && yum clean all \
    && rm -rf /tmp/* /etc/yum.repos.d/confluent.repo \
    && echo "===> Setting up ${COMPONENT} dirs" \
    && mkdir -p /var/lib/${COMPONENT}/data /etc/${COMPONENT}/secrets \
    && chown appuser:root -R /etc/kafka /var/log/kafka /var/log/confluent /var/lib/kafka /var/lib/zookeeper /etc/${COMPONENT}/secrets /var/lib/${COMPONENT} /etc/${COMPONENT} \
    && chmod -R ug+w /etc/kafka /var/log/kafka /var/log/confluent /var/lib/kafka /var/lib/zookeeper /var/lib/${COMPONENT} /etc/${COMPONENT}/secrets /etc/${COMPONENT}

VOLUME ["/var/lib/${COMPONENT}/data", "/etc/${COMPONENT}/secrets"]

RUN mv jetty-io-9.4.47.v20220610.jar /usr/share/java/kafka/ \
    && mv /usr/share/java/kafka/jetty-io-9.4.44.v20210927.jar /usr/share/java/kafka/jetty-io-9.4.44.v20210927.jar_bkp \
    && rm -rf confluent-kafka-7.2.0-1.noarch.rpm
RUN cp jackson-databind-2.14.0-rc2.jar /usr/share/java/kafka/ \
    &&  mv jackson-databind-2.14.0-rc2.jar /usr/share/java/cp-base-new/ \
    && mv /usr/share/java/kafka/jackson-databind-2.13.2.2.jar /usr/share/java/kafka/jackson-databind-2.13.2.2.jar_bkp \
    && mv /usr/share/java/cp-base-new/jackson-databind-2.13.2.2.jar /usr/share/java/cp-base-new/jackson-databind-2.13.2.2.jar_bkp 

RUN mv snakeyaml-1.33.jar /usr/share/java/cp-base-new/ \
    && mv /usr/share/java/cp-base-new/snakeyaml-1.30.jar /usr/share/java/cp-base-new/snakeyaml-1.30.jar_bkp
RUN mv jmx_prometheus_javaagent-0.17.2.jar /usr/share/java/cp-base-new/ \
    && mv /usr/share/java/cp-base-new/jmx_prometheus_javaagent-0.14.0.jar /usr/share/java/cp-base-new/jmx_prometheus_javaagent-0.14.0.jar_bkp
COPY --chown=appuser:appuser include/etc/confluent/docker /etc/confluent/docker

USER appuser
CMD ["/etc/confluent/docker/run"]
