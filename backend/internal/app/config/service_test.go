package configservice

import "testing"

func TestParseType(t *testing.T) {
	if got := parseType("123", 0); got != 123 {
	t.Errorf("parseType(123) = %v, want 123", got)
	}
	if got := parseType("true", false); got != true {
	t.Errorf("parseType(true) = %v, want true", got)
	}
	if got := parseType("  hello  ", "def"); got != "hello" {
	t.Errorf("parseType(hello) = %v, want hello", got)
	}
}
