package configdomain

import "testing"

func TestDbTls_IsValid(t *testing.T) {
	tests := []struct {
	t	DbTls
	twant bool
	}{
	t{TLSDisable, true},
	t{TLSRequire, true},
	t{TLSFullCa, true},
	t{DbTls("invalid"), false},
	t}{
	for _, tt := range tests {
	t.Run(string(tt.t), func(t *testing.T) {
	ttif got := tt.t.IsValid(); got != tt.want {
	tttt.Errorf("DbTls.IsValid() = %v, want %v", got, tt.want)
	tt}
	t})
	}
}

func TestConfig_IsDatabaseValid(t *testing.T) {
	// Example test for database validation logic
	c := &Config{
	tMode: ModeProduction,
	tDatabase: Database{
	ttName: "db", Host: "localhost", Port: "5432", TLS: TLSDisable, User: "user", Password: "pass",
	t},
	}
	if c.IsDatabaseValid() {
	t.Error("IsDatabaseValid() should be false for TLSDisable in Production mode")
	}
}
