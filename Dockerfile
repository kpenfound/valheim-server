# syntax=docker/dockerfile:1
FROM golang:1.17
WORKDIR /go/src/github.com/kpenfound/valheim-server/
COPY dummy.go ./
COPY go.mod ./
COPY go.sum ./
RUN GOOS=linux go build -o dummy .

FROM alpine:latest
EXPOSE 2457/udp
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=0 /go/src/github.com/kpenfound/valheim-server/dummy ./
CMD ["./dummy"] 
