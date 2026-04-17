# Stage 1: Build the Go binary
FROM golang:1.22-alpine AS builder
RUN apk add --no-cache git
WORKDIR /app
COPY ice_gate_auth/go.mod ./
RUN go mod download
COPY ice_gate_auth/ .
RUN CGO_ENABLED=0 GOOS=linux go build -o passkey-hub ./cmd/server/main.go

# Stage 2: Production environment
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/passkey-hub .
EXPOSE 8080
CMD ["./passkey-hub"]
