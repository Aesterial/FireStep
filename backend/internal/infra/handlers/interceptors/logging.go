package interceptors

import (
	"context"
	"time"

	loggingservice "github.com/aesterial/fire-step/backend/internal/app/logging"
	loggingdomain "github.com/aesterial/fire-step/backend/internal/domain/logging"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func LoggingServerInterceptor() grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (resp any, err error) {
		startedAt := time.Now()
		resp, err = handler(ctx, req)

		fields := []loggingdomain.Field{
			loggingservice.FD("method", info.FullMethod),
			loggingservice.FD("duration_ms", time.Since(startedAt).Milliseconds()),
		}

		if err == nil {
			loggingservice.Info("logging", "grpc request handled", fields...)
			return resp, nil
		}

		st, ok := status.FromError(err)
		if !ok {
			st = status.New(codes.Unknown, err.Error())
		}
		fields = append(fields, loggingservice.FD("code", st.Code().String()), loggingservice.FD("error", err.Error()))

		switch st.Code() {
		case codes.InvalidArgument, codes.NotFound, codes.AlreadyExists, codes.PermissionDenied, codes.Unauthenticated, codes.FailedPrecondition, codes.Aborted, codes.OutOfRange, codes.Canceled, codes.ResourceExhausted:
			loggingservice.Warning("logging", "grpc request failed", fields...)
		default:
			loggingservice.Error("logging", "grpc request failed", fields...)
		}

		return resp, err
	}
}
