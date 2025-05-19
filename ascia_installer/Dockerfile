ARG BUILD_FROM
FROM $BUILD_FROM
ENV LANG C.UTF-8
RUN apk add --no-cache git bash
COPY run.sh /run.sh
CMD ["/run.sh"]