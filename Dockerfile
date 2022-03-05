# syntax=docker/dockerfile:1
FROM golang:1.17
WORKDIR /go/src/github.com/kpenfound/valheim-server/
COPY dummy.go ./
COPY go.mod ./
COPY go.sum ./
RUN GOOS=linux go build -o dummy

FROM debian:bookworm-slim
RUN apt update
RUN apt install -y ca-certificates
EXPOSE 2457/udp
WORKDIR /root/
COPY --from=0 /go/src/github.com/kpenfound/valheim-server/dummy ./
CMD ["./dummy"] 
