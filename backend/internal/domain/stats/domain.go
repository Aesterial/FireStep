package statsdomain

import (
	"time"

	seancesdomain "github.com/aesterial/fire-step/backend/internal/domain/seances"
	"google.golang.org/protobuf/types/known/timestamppb"
)
import statspb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/stats"

type GraphPoint struct {
	At    time.Time
	Value int32
}

func (g *GraphPoint) Protobuf() *statspb.GraphPoint {
	if g == nil {
		return nil
	}
	return &statspb.GraphPoint{
		At:    timestamppb.New(g.At),
		Count: g.Value,
	}
}

type GraphPoints []*GraphPoint

func (g *GraphPoints) Protobuf() []*statspb.GraphPoint {
	if g == nil {
		return nil
	}
	var list = make([]*statspb.GraphPoint, len(*g))
	for i, e := range *g {
		list[i] = e.Protobuf()
	}
	return list
}

type GraphStats struct {
	Errors   GraphPoints
	Activity GraphPoints
}

func (g *GraphStats) Protobuf() *statspb.GraphStatsResponse {
	return &statspb.GraphStatsResponse{
		Errors:        g.Errors.Protobuf(),
		UsersActivity: g.Activity.Protobuf(),
	}
}

type TitleStats struct {
	Seances    int32
	Errors     int32
	AvgSeconds int32
	Latest     seancesdomain.Seances
}

func (t *TitleStats) Protobuf() *statspb.Stats {
	if t == nil {
		return nil
	}
	return &statspb.Stats{
		SeanceCount: t.Seances,
		ErrorsCount: t.Errors,
		AvgSeconds:  t.AvgSeconds,
		Latest:      t.Latest.Protobuf().List,
	}
}
