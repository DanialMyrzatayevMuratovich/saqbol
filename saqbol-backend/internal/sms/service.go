package sms

import (
	"context"

	"github.com/saqbol/backend/internal/ml"
	"github.com/saqbol/backend/internal/store"
)

const scamReputationIncrement = 0.2

type Service struct {
	classifier ml.Classifier
	store      *store.Store
}

func NewService(classifier ml.Classifier, dataStore *store.Store) *Service {
	return &Service{classifier: classifier, store: dataStore}
}

// CheckBatch classifies each message independently. A failing message yields an
// error entry instead of aborting the batch, so a partial inbox scan still
// returns everything it managed to classify.
func (s *Service) CheckBatch(ctx context.Context, userID string, req BatchCheckRequest) BatchCheckResponse {
	results := make([]BatchCheckResult, 0, len(req.Messages))
	for _, item := range req.Messages {
		if ctx.Err() != nil {
			break
		}

		response, err := s.Check(ctx, userID, CheckRequest{
			Text:         item.Text,
			SourceNumber: item.SourceNumber,
		})
		if err != nil {
			results = append(results, BatchCheckResult{
				ExternalID: item.ExternalID,
				Error:      "failed to check message",
			})
			continue
		}

		results = append(results, BatchCheckResult{
			ExternalID:    item.ExternalID,
			CheckResponse: response,
		})
	}

	return BatchCheckResponse{Results: results}
}

func (s *Service) Check(ctx context.Context, userID string, req CheckRequest) (CheckResponse, error) {
	result, err := s.classifier.Classify(ctx, ml.Request{Text: req.Text, Channel: ml.ChannelSMS})
	if err != nil {
		return CheckResponse{}, err
	}

	messageID, err := s.store.Messages.Create(ctx, store.CreateMessageParams{
		UserID:          userID,
		Channel:         ml.ChannelSMS,
		RawText:         req.Text,
		SourceNumber:    req.SourceNumber,
		ScamProbability: result.Probability,
		Verdict:         result.Verdict,
	})
	if err != nil {
		return CheckResponse{}, err
	}

	categoryID, err := s.store.Categories.IDByName(ctx, result.Category)
	if err != nil {
		return CheckResponse{}, err
	}

	if _, err := s.store.Detections.Create(ctx, store.CreateDetectionParams{
		MessageID:   messageID,
		CategoryID:  categoryID,
		Probability: result.Probability,
		Triggers:    result.Triggers,
		LatencyMs:   result.LatencyMs,
	}); err != nil {
		return CheckResponse{}, err
	}

	if result.Verdict == ml.VerdictScam && req.SourceNumber != "" {
		if err := s.store.Numbers.RegisterScam(ctx, req.SourceNumber, scamReputationIncrement); err != nil {
			return CheckResponse{}, err
		}
	}

	return CheckResponse{
		MessageID:    messageID,
		Verdict:      result.Verdict,
		Probability:  result.Probability,
		Category:     result.Category,
		Triggers:     result.Triggers,
		Advice:       result.Advice,
		ModelVersion: result.ModelVersion,
	}, nil
}
