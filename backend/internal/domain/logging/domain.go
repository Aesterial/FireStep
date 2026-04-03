package loggingdomain

import (
	"fmt"
	"sort"
	"strings"
	"time"
)

type Level int

const (
	LevelInfo Level = iota
	LevelWarning
	LevelError
	LevelCritical
)

func (l Level) String() string {
	switch l {
	case LevelInfo:
		return "INFO"
	case LevelWarning:
		return "WARN"
	case LevelError:
		return "ERROR"
	case LevelCritical:
		return "CRITICAL"
	default:
		return "INFO"
	}
}

func ParseAny(v any) string {
	switch t := v.(type) {
	case nil:
		return ""
	case string:
		return any(t).(string)
	case fmt.Stringer:
		return t.String()
	case error:
		return t.Error()
	default:
		return fmt.Sprintf("%v", t)
	}
}

type Field struct {
	Key   string
	Value any
}

type Fields []Field

func (f Fields) Normalize() map[string]string {
	if f == nil || len(f) == 0 {
		return nil
	}
	out := make(map[string]string, len(f))
	for _, v := range f {
		key := strings.TrimSpace(v.Key)
		if key == "" {
			continue
		}
		out[key] = ParseAny(v.Value)
	}
	if len(out) == 0 {
		return nil
	}
	return out
}

func FD(key string, value any) Field {
	return Field{Key: key, Value: value}
}

type Entry struct {
	At      time.Time
	Caller  string
	Level   Level
	Content string
	Fields  map[string]string
}

func NewEntry(at time.Time, service string, level Level, content string, fields Fields) Entry {
	if at.IsZero() {
		at = time.Now().UTC()
	} else {
		at = at.UTC()
	}
	service = strings.TrimSpace(service)
	if service == "" {
		service = "unspecified"
	}
	return Entry{At: at, Caller: service, Level: level, Content: content, Fields: fields.Normalize()}
}

func (e Entry) Render() string {
	line := fmt.Sprintf("[%s]: %s | %s | %s", e.Level.String(), e.Caller, e.Content, e.At.Format(time.RFC3339Nano))
	if len(e.Fields) == 0 {
		return line
	}

	keys := make([]string, 0, len(e.Fields))
	for key := range e.Fields {
		keys = append(keys, key)
	}
	sort.Strings(keys)

	pairs := make([]string, 0, len(keys))
	for _, key := range keys {
		pairs = append(pairs, fmt.Sprintf("%s=%s", key, e.Fields[key]))
	}
	return line + " | " + strings.Join(pairs, ", ")
}
