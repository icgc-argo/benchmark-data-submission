FROM python:3.7.5-slim-buster

LABEL org.opencontainers.image.source https://github.com/icgc-argo/benchmark-data-submission

ENV PATH="/tools:${PATH}"

COPY *.py /tools/

ENTRYPOINT ["/usr/bin/env"]

CMD ["/bin/bash"]
