FROM ubuntu:20.04

LABEL org.opencontainers.image.source https://github.com/icgc-argo/benchmark-data-submission

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y && \
    apt-get install -y software-properties-common python3-pip python3-dev curl

RUN mkdir /tools

# Install s5cmd
ARG s5cmd_version=1.4.0
RUN cd /tools \
    && curl -sSL -o s5cmd.tar.gz --retry 10 https://github.com/peak/s5cmd/releases/download/v${s5cmd_version}/s5cmd_${s5cmd_version}_Linux-64bit.tar.gz \
    && tar -xzf s5cmd.tar.gz

RUN groupadd -g 1000 ubuntu && \
    useradd -l -u 1000 -g ubuntu ubuntu && \
    install -d -m 0755 -o ubuntu -g ubuntu /home/ubuntu

ENV PATH="/tools:${PATH}"

COPY *.py /tools/

WORKDIR /tools

USER ubuntu

ENTRYPOINT ["/usr/bin/env"]

CMD ["/bin/bash"]

