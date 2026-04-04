package loggingservice

import (
	"log"
	"os"
	"time"

	loggingdomain "github.com/aesterial/fire-step/backend/internal/domain/logging"
)

type Logger struct {
	logger *log.Logger
}

func NewLogger() *Logger {
	return &Logger{logger: log.New(os.Stdout, "", 0)}
}

func (l *Logger) Info(service string, content string, fields loggingdomain.Fields) {
	l.log(loggingdomain.LevelInfo, service, content, fields)
}

func (l *Logger) Warn(service string, content string, fields loggingdomain.Fields) {
	l.log(loggingdomain.LevelWarning, service, content, fields)
}

func (l *Logger) Error(service string, content string, fields loggingdomain.Fields) {
	l.log(loggingdomain.LevelError, service, content, fields)
}

func (l *Logger) Critical(service string, content string, fields loggingdomain.Fields) {
	l.log(loggingdomain.LevelCritical, service, content, fields)
}

func (l *Logger) log(level loggingdomain.Level, service string, content string, fields loggingdomain.Fields) {
	l.logger.Println(loggingdomain.NewEntry(time.Now().UTC(), service, level, content, fields).Render())
}

func (l *Logger) SetDefault() {
	def = l
}

var def *Logger

func Info(service string, content string, fields ...loggingdomain.Field) {
	if def == nil {
		return
	}
	def.Info(service, content, fields)
}

func Warning(service string, content string, fields ...loggingdomain.Field) {
	if def == nil {
		return
	}
	def.Warn(service, content, fields)
}

func Error(service string, content string, fields ...loggingdomain.Field) {
	if def == nil {
		return
	}
	def.Error(service, content, fields)
}

func Critical(service string, content string, fields ...loggingdomain.Field) {
	if def == nil {
		return
	}
	def.Critical(service, content, fields)
}

var FD = loggingdomain.FD
