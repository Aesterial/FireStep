package configdomain

type Mode int

const (
	ModeProduction Mode = iota
	ModeDebug
)

type DbTls string

const (
	TLSDisable DbTls = "disable"
	TLSRequire DbTls = "require"
	TLSFullCa  DbTls = "full-ca"
)

func (d DbTls) String() string {
	return string(d)
}

func (d DbTls) IsValid() bool {
	switch d {
	case TLSDisable, TLSRequire, TLSFullCa:
		return true
	default:
		return false
	}
}

type Database struct {
	Name     string
	Host     string
	Port     string
	TLS      DbTls
	CaPath   *string
	User     string
	Password string
}

func (d Database) IsValid() bool {
	if d.Name == "" || d.Host == "" || d.Port == "" || d.TLS == TLSFullCa && d.CaPath == nil || d.User == "" || d.Password == "" {
		return false
	}
	return true
}

type Config struct {
	Database Database
	Mode     Mode
	loaded   bool
}

func (c *Config) IsLoaded() bool {
	return c.loaded
}

func (c *Config) MarkLoaded() {
	c.loaded = true
}

func (c Mode) IsDebug() bool {
	return c == ModeDebug
}

func (c Mode) IsProduction() bool {
	return c == ModeProduction
}

func (c *Config) IsDatabaseValid() bool {
	if c.Database.TLS == TLSDisable && c.Mode.IsProduction() {
		return false
	}
	if !c.Database.IsValid() {
		return false
	}
	return true
}
