FROM mesosphere/aws-cli:1.14.5

LABEL org.opencontainers.image.source https://github.com/icgc-argo/benchmark-data-submission

ENV PATH="/tools:${PATH}"

COPY *.py /tools/

ENTRYPOINT ["/usr/bin/env"]

CMD ["/bin/bash"]
