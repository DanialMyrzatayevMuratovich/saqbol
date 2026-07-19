package ml

import (
	"context"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	mlv1 "github.com/saqbol/backend/proto/ml/v1"
)

type GRPCClassifier struct {
	conn    *grpc.ClientConn
	client  mlv1.ScamClassifierClient
	timeout time.Duration
}

func NewGRPC(addr string) (*GRPCClassifier, error) {
	conn, err := grpc.NewClient(addr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, err
	}
	return &GRPCClassifier{
		conn:    conn,
		client:  mlv1.NewScamClassifierClient(conn),
		timeout: 3 * time.Second,
	}, nil
}

func (c *GRPCClassifier) Close() error {
	return c.conn.Close()
}

func (c *GRPCClassifier) Classify(ctx context.Context, req Request) (Result, error) {
	callCtx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	response, err := c.client.Classify(callCtx, &mlv1.ClassifyRequest{
		Text:    req.Text,
		Channel: req.Channel,
	})
	if err != nil {
		return Result{}, err
	}

	triggers := response.GetTriggers()
	if triggers == nil {
		triggers = []string{}
	}

	return Result{
		Verdict:      response.GetVerdict(),
		Probability:  response.GetProbability(),
		Category:     response.GetCategory(),
		Triggers:     triggers,
		Advice:       response.GetAdvice(),
		LatencyMs:    int(response.GetLatencyMs()),
		ModelVersion: response.GetModelVersion(),
	}, nil
}
