package statsdomain

import (
	"context"
)

type Repository interface {
	GetTitleStats(ctx context.Context, org string) (int32, int32, int32, error)
	GetErrorsPerHour(ctx context.Context, org string) (GraphPoints, error)
	GetActivityByDay(ctx context.Context, org string) (GraphPoints, error)
}
