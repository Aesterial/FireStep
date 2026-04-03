package client

import (
	"context"

	"github.com/aesterial/fire-step/backend/internal/infra/db/connection"
	"github.com/aesterial/fire-step/backend/internal/infra/db/sqlc"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Client struct {
	Pool    *pgxpool.Pool
	Queries *sqlc.Queries
}

func NewClient() (*Client, error) {
	pool, err := connection.NewConnection()
	if err != nil {
		return nil, err
	}
	err = pool.Ping(context.Background())
	if err != nil {
		return nil, err
	}
	return &Client{Pool: pool, Queries: sqlc.New(pool)}, nil
}

func (c *Client) Querier() sqlc.Querier {
	if c == nil || c.Queries == nil {
		return nil
	}
	return c.Queries
}

func (c *Client) Close() {
	if c == nil || c.Pool == nil {
		return
	}
	c.Pool.Close()
}
