ARG BUILD_FROM
FROM $BUILD_FROM

# Set environment variables
ENV LANG C.UTF-8

# Try multiple package mirrors
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.14/main' > /etc/apk/repositories && \
    echo 'http://dl-cdn.alpinelinux.org/alpine/v3.14/community' >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache git bash

# Add jq and curl separately to isolate issues
RUN apk add --no-cache jq curl || echo "Warning: Could not install jq and curl, continuing anyway"

# Set proper permissions for script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
