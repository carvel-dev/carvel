FROM golang:1.10.1 AS build-env
WORKDIR /go/src/github.com/mchmarny/simple-app/
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -v -o app

FROM scratch
COPY --from=build-env /go/src/github.com/mchmarny/simple-app/app .
EXPOSE 8080
ENTRYPOINT ["/app"]
