package loggingdomain

type Repository interface {
	Info(service string, content string, fields Fields)
	Warn(service string, content string, fields Fields)
	Error(service string, content string, fields Fields)
	Critical(service string, content string, fields Fields)
}
