package configdomain

import "testing"

func TestDbTls_IsValid(t *testing.T) {
	tests := []struct {
		t    DbTls
		want bool
	}{
		{TLSDisable, true},
		{TLSRequire, true},
		{TLSFullCa, true},
		{DbTls("invalid"), false},
	}
	for _, tt := range tests {
		t.Run(string(tt.t), func(t *testing.T) {
			if got := tt.t.IsValid(); got != tt.want {
				t.Errorf("DbTls.IsValid() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestConfig_IsDatabaseValid(t *testing.T) {
	c := &Config{
		Mode: ModeProduction,
		Database: Database{
			Name: "db", Host: "localhost", Port: "5432", TLS: TLSDisable, User: "user", Password: "pass",
		},
	}
	if c.IsDatabaseValid() {
		t.Error("IsDatabaseValid() should be false for TLSDisable in Production mode")
	}
}
