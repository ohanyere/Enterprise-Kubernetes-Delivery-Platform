FROM golang:1.25 AS builder

WORKDIR /src

COPY apps/sample-go-service/go.mod apps/sample-go-service/go.mod
WORKDIR /src/apps/sample-go-service
RUN go mod download

COPY apps/sample-go-service/ ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o /out/sample-go-service ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /
COPY --from=builder /out/sample-go-service /sample-go-service

USER nonroot:nonroot
EXPOSE 8080

ENTRYPOINT ["/sample-go-service"]
