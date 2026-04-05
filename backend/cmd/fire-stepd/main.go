package main

import (
	"context"
	"errors"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	loginpb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/login"
	seancespb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/seances"
	sessionpb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/session"
	statspb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/stats"
	userpb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/user"
	seanceservice "github.com/aesterial/fire-step/backend/internal/app/seance"
	statsservice "github.com/aesterial/fire-step/backend/internal/app/stats"
	"github.com/aesterial/fire-step/backend/internal/infra/handlers/interceptors"

	configservice "github.com/aesterial/fire-step/backend/internal/app/config"
	loggingservice "github.com/aesterial/fire-step/backend/internal/app/logging"
	loginservice "github.com/aesterial/fire-step/backend/internal/app/login"
	sessionservice "github.com/aesterial/fire-step/backend/internal/app/sessions"
	userservice "github.com/aesterial/fire-step/backend/internal/app/user"
	client "github.com/aesterial/fire-step/backend/internal/infra/db"
	"github.com/aesterial/fire-step/backend/internal/infra/db/repositories"
	"github.com/aesterial/fire-step/backend/internal/infra/handlers"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/recovery"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

func main() {
	logger := loggingservice.NewLogger()
	logger.SetDefault()
	configservice.Ensure()
	cfg := configservice.Get()
	conn, err := client.NewClient()
	if err != nil {
		loggingservice.Critical("main", "failed to connect to db", loggingservice.FD("error", err))
		return
	}
	userRepository := repositories.NewUserRepository(conn.Querier())
	sessionRepository := repositories.NewSessionRepository(conn.Querier())
	seanceRepository := repositories.NewSeanceRepository(conn.Querier())
	statsRepository := repositories.NewStatsRepository(conn.Querier())
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	userService := userservice.NewUserService(userRepository)
	sessionService := sessionservice.NewSessionService(sessionRepository)
	seanceService := seanceservice.NewSeanceService(seanceRepository)
	statsService := statsservice.NewStatsService(statsRepository, seanceService, userService)
	loginService := loginservice.NewLoginService(userService, sessionService)
	auth := handlers.NewAuthentificator(sessionService, userService)
	loginHandler := handlers.NewLoginHandler(loginService, sessionService, auth)
	userHandler := handlers.NewUserHandler(userService, auth)
	sessionHandler := handlers.NewSessionsHandler(sessionService, auth)
	seanceHandler := handlers.NewSeanceHandler(seanceService, auth)
	statsHandler := handlers.NewStatsHandler(statsService, auth)

	server := grpc.NewServer(
		grpc.ChainUnaryInterceptor(
			interceptors.LoggingServerInterceptor(),
			recovery.UnaryServerInterceptor(
				recovery.WithRecoveryHandlerContext(interceptors.ServerPanicRecovery),
			),
		))
	if cfg.Mode.IsDebug() {
		reflection.Register(server)
	}
	loginpb.RegisterLoginServiceServer(server, loginHandler)
	userpb.RegisterUserServiceServer(server, userHandler)
	sessionpb.RegisterSessionsServiceServer(server, sessionHandler)
	seancespb.RegisterSeancesServiceServer(server, seanceHandler)
	statspb.RegisterStatsServiceServer(server, statsHandler)

	addr := "0.0.0.0:" + cfg.Port

	serveErr := make(chan error, 1)
	listener, err := net.Listen("tcp", addr)
	if err != nil {
		loggingservice.Critical("main", "failed to start gRPC server", loggingservice.FD("error", err))
		return
	}
	go func() {
		loggingservice.Info("main", "starting server at", loggingservice.FD("addr", addr))
		serveErr <- server.Serve(listener)
	}()

	select {
	case <-ctx.Done():
		loggingservice.Warning("main", "received stop signal")
		done := make(chan struct{})
		go func() {
			server.GracefulStop()
			close(done)
		}()

		select {
		case <-done:
		case <-time.After(10 * time.Second):
			server.Stop()
		}
		loggingservice.Info("main", "server is stopped")
	case <-serveErr:
		if err != nil && !errors.Is(err, grpc.ErrServerStopped) {
			loggingservice.Critical("main", "server is down", loggingservice.FD("error", err))
		}
	}
}
