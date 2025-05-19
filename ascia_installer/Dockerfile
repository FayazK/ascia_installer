ARG BUILD_FROM
FROM $BUILD_FROM

# Add labels for better documentation
LABEL maintainer="Fayaz Khan <info@fayazk.com>"
LABEL description="Ascia UI Installer for Home Assistant"

# Set environment variables
ENV LANG C.UTF-8

# Install dependencies with version pinning for security
RUN apk add --no-cache \
    git=2.36.5-r0 \
    bash=5.2.15-r0 \
    jq=1.6-r2 \
    curl=7.83.1-r5

# Create a non-root user for better security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set proper permissions for script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Run as non-root user when possible (script will need to switch to root for certain operations)
USER appuser

CMD ["/run.sh"]
