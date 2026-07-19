package calls

import (
	"context"

	"github.com/saqbol/backend/internal/ml"
	"github.com/saqbol/backend/internal/store"
)

type Service struct {
	classifier ml.Classifier
	store      *store.Store
	scamThreshold float64
}

func NewService(classifier ml.Classifier, dataStore *store.Store, scamThreshold float64) *Service {
	return &Service{classifier: classifier, store: dataStore, scamThreshold: scamThreshold}
}

func (s *Service) Classify(ctx context.Context, transcript string) (ml.Result, error) {
	return s.classifier.Classify(ctx, ml.Request{Text: transcript, Channel: ml.ChannelCall})
}

func (s *Service) SaveSession(ctx context.Context, userID, transcript string, maxProbability float64, alertTriggered bool) (string, error) {
	return s.store.Calls.Create(ctx, store.CreateCallParams{
		UserID:         userID,
		Transcript:     transcript,
		MaxProbability: maxProbability,
		AlertTriggered: alertTriggered,
	})
}

func (s *Service) ScamThreshold() float64 {
	return s.scamThreshold
}
