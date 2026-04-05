# Build stage
FROM golang:alpine AS builder

# Install build dependencies if needed
RUN apk add --no-cache git

WORKDIR /app

# Copy go.mod and go.sum first to leverage Docker cache
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the binary with CGO disabled for a static build
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/fire-stepd ./cmd/fire-stepd

# Final stage
FROM alpine:latest

# Install CA certificates and tzdata for external TLS connections and timezone handling
RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /app/fire-stepd /usr/local/bin/fire-stepd

# Expose a default port, though this relies on cfg.Port config
EXPOSE 8080
EXPOSE 50051

# Command to run the application
ENTRYPOINT ["fire-stepd"]
