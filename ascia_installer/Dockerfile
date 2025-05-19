ARG BUILD_FROM
FROM $BUILD_FROM

# Add labels for better documentation
LABEL maintainer="Fayaz Khan <info@fayazk.com>"
LABEL description="Ascia UI Installer for Home Assistant"

# Set environment variables
ENV LANG C.UTF-8

# Install dependencies without version pinning
RUN apk add --no-cache \
    git \
    bash \
    jq \
    curl

# Set proper permissions for script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
