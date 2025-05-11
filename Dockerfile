FROM alpine:3.19 AS builder
# Download binary with minimal dependencies
RUN apk add --no-cache curl && \
    mkdir -p /app && \
    if [ "$(uname -m)" = "x86_64" ]; then \
        curl -s -L --connect-timeout 30 --retry 3 -o /app/nx-app https://github.com/dsadsadsss/plutonodes/releases/download/xr/linux-amd64-cctun; \
    elif [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then \
        curl -s -L --connect-timeout 30 --retry 3 -o /app/nx-app https://github.com/dsadsadsss/plutonodes/releases/download/xr/linux-arm64-cctun; \
    else \
        echo "Unsupported architecture"; \
        exit 1; \
    fi && \
    chmod +x /app/nx-app

# Use minimal Alpine for the final image
FROM alpine:3.19

# Set environment variables in a single layer
ENV NX_PORT="7860" VM_PORT="8001" VL_PORT="8002" MPATH="vms" VPATH="vls" NEZ_KEY="zmmznnzzm"

# Install minimal dependencies and setup directories in a single layer
RUN apk add --no-cache --virtual .run-deps ca-certificates libstdc++ procps && \
    mkdir -p /app

# Set working directory
WORKDIR /app

# Copy only the application binary
COPY --from=builder /app/nx-app /app/nx-app

# Expose port
EXPOSE 7860

# Set entrypoint
CMD ["/app/nx-app"]
