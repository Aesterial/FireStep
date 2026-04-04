package metadatadomain

import (
	sessiondomain "github.com/aesterial/fire-step/backend/internal/domain/session"
	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
)

type Metadata struct {
	UserID     *userdomain.UUID
	SessionID  *userdomain.UUID
	DeviceType sessiondomain.DeviceType
}
