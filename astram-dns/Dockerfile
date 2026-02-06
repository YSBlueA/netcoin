# Build stage
FROM rust:1.83-slim as builder

WORKDIR /app

# Install dependencies
RUN apt-get update && \
    apt-get install -y pkg-config libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy manifests
COPY Cargo.toml ./

# Copy source code
COPY src ./src

# Build the application
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

# Copy the binary from builder
COPY --from=builder /app/target/release/netcoin-dns /usr/local/bin/netcoin-dns

# Create a non-root user
RUN useradd -m -u 1000 netcoin && \
    chown -R netcoin:netcoin /usr/local/bin/netcoin-dns

USER netcoin

EXPOSE 8053

ENTRYPOINT ["/usr/local/bin/netcoin-dns"]
CMD ["--port", "8053", "--max-age", "3600"]
