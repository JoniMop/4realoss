package solana

import (
	"context"
	"crypto/ed25519"
	"encoding/base64"
	"fmt"
	"time"

	"github.com/mr-tron/base58"
	log "unknwon.dev/clog/v2"

	"gogs.io/gogs/internal/auth"
	"gogs.io/gogs/internal/cryptoutil"
	"gogs.io/gogs/internal/database"
)

// Provider implements the auth.Provider interface for Solana wallet authentication.
type Provider struct {
	*Config
}

// NewProvider creates a new Solana authentication provider.
func NewProvider(config *Config) *Provider {
	return &Provider{
		Config: config,
	}
}

// Init initializes the provider.
func (p *Provider) Init() error {
	return nil
}

// Destroy performs cleanup tasks for the provider.
func (p *Provider) Destroy() error {
	return nil
}

// HasTLS returns true if the provider requires TLS.
func (p *Provider) HasTLS() bool {
	return true
}

// verifySignature verifies that the signature was signed by the given Solana address
func (p *Provider) verifySignature(message string, signature string, address string) bool {
	log.Trace("Verifying Solana signature for address: %s", address)

	// Decode the signature from base64
	sigBytes, err := base64.StdEncoding.DecodeString(signature)
	if err != nil {
		log.Error("Failed to decode signature: %v", err)
		return false
	}

	// Decode the address from base58
	addrBytes, err := base58.Decode(address)
	if err != nil {
		log.Error("Failed to decode address: %v", err)
		return false
	}

	// Verify the signature
	messageBytes := []byte(message)
	if !ed25519.Verify(addrBytes, messageBytes, sigBytes) {
		log.Error("Invalid signature for address: %s", address)
		return false
	}

	log.Trace("Solana signature verified successfully")
	return true
}



// createUser creates a new user for the given Solana address
func (p *Provider) createUser(ctx context.Context, address string) (*database.User, error) {
	log.Info("Creating new user for Solana address: %s", address)

	// Generate a random password
	password := cryptoutil.MD5(fmt.Sprintf("%d%s", time.Now().UnixNano(), address))

	// Create the user
	username := "sol_" + address[:8] // Use first 8 chars of address as username
	email := address                  // Use full address as email

	user, err := database.Handle.Users().Create(ctx, username, email, database.CreateUserOptions{
		Password:  password,
		Activated: true,
	})

	if err != nil {
		log.Error("Failed to create user: %v", err)
		return nil, fmt.Errorf("create user: %v", err)
	}

	log.Info("Created new user: %s", user.Name)
	return user, nil
}

// VerifyAddress verifies the Solana address and creates a user if it doesn't exist
func (p *Provider) VerifyAddress(ctx context.Context, address string) (*database.User, error) {
	log.Trace("Looking up user for Solana address: %s", address)

	// Try to find existing user
	emailAddress := address
	log.Trace("Looking up user by email: %s", emailAddress)

	user, err := database.Handle.Users().GetByEmail(ctx, emailAddress)
	if err != nil {
		if database.IsErrUserNotExist(err) {
			log.Info("User not found, creating new user for Solana address: %s", address)
			return p.createUser(ctx, address)
		}
		log.Error("Failed to get user by address: %v", err)
		return nil, fmt.Errorf("get user by address: %v", err)
	}

	log.Trace("Found existing user: %s", user.Name)
	return user, nil
}

// Authenticate verifies the signature from Solana wallet.
func (p *Provider) Authenticate(ctx context.Context, address, signature string) (*database.User, error) {
	log.Info("Authenticating Solana wallet login - Address: %s", address)

	// First verify the signature
	message := "Sign this message to login to 4RealOSS"
	if !p.verifySignature(message, signature, address) {
		log.Warn("Invalid signature for Solana address: %s", address)
		return nil, auth.ErrBadCredentials{Args: map[string]any{
			"reason": "invalid signature",
		}}
	}

	log.Trace("Solana signature verified successfully")

	// Then verify the address exists or create a new user
	return p.VerifyAddress(ctx, address)
} 