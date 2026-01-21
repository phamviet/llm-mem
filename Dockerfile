FROM rust:1.92-slim-bookworm AS builder

WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN cargo install cortex-mem-service

FROM debian:bookworm-slim

RUN groupadd -g 1000 appuser && \
    useradd -u 1000 -g appuser -s /bin/sh appuser

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/cargo/bin/ /usr/local/bin/
COPY cortex-mem-service.toml /etc/config.template.toml

RUN touch /etc/config.toml && chown appuser:appuser /etc/config.toml && cat >/usr/local/bin/docker-entrypoint <<EOF
#!/usr/bin/env sh
envsubst < /etc/config.template.toml > /etc/config.toml
cortex-mem-service --config /etc/config.toml
EOF

RUN chmod +x /usr/local/bin/docker-entrypoint

ENV OPENAI_BASE_URL=https://api.openai.com/v1 \
    QDRANT_URL=http://qdrant:6334 \
    QDRANT_COLLECTION_NAME=cortex-memory \
    LLM_MODEL=gpt-5-mini \
    EMBEDDING_MODEL=text-embedding-3-small

USER appuser

EXPOSE 8000

ENTRYPOINT ["docker-entrypoint"]
