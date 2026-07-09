
ARG AIDER_VERSION=v0.86.2

FROM paulgauthier/aider-full:${AIDER_VERSION}

# Set mode at copy time (BuildKit); avoids RUN chmod failing with EPERM on some setups.
COPY --chmod=755 entrypoint.sh /usr/local/bin/aider-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/aider-entrypoint.sh"]
