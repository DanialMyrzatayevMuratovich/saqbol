package httpx

import "github.com/gin-gonic/gin"

const (
	userIDKey = "userID"
	roleKey   = "role"
)

func SetUserID(c *gin.Context, userID string) {
	c.Set(userIDKey, userID)
}

func UserID(c *gin.Context) string {
	value, ok := c.Get(userIDKey)
	if !ok {
		return ""
	}
	id, _ := value.(string)
	return id
}

func SetRole(c *gin.Context, role string) {
	c.Set(roleKey, role)
}

func Role(c *gin.Context) string {
	value, ok := c.Get(roleKey)
	if !ok {
		return ""
	}
	role, _ := value.(string)
	return role
}
