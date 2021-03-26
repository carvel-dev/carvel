package main

import (
	"context"
	"log"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (*events.APIGatewayProxyResponse, error) {
	for i := 0; i < 60; i++ {
		log.Println(i)
		time.Sleep(1 * time.Second)
	}
	return nil, nil
}

func main() {
	lambda.Start(handler)
}
