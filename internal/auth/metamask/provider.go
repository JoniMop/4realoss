package metamask

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/crypto"
	log "unknwon.dev/clog/v2"

	"gogs.io/gogs/internal/auth"
	"gogs.io/gogs/internal/cryptoutil"
	"gogs.io/gogs/internal/database"
)

// Provider implements the auth.Provider interface for Metamask authentication.
type Provider struct {
	*Config
}

// NewProvider creates a new Metamask authentication provider.
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

// verifySignature verifies that the signature was signed by the given Ethereum address
func (p *Provider) verifySignature(message string, signature string, address string) bool {
	// Normalize address to lowercase without '0x' prefix
	address = strings.ToLower(strings.TrimPrefix(address, "0x"))
	log.Trace("Verifying signature for address: %s", address)

	// Add '0x' prefix to signature if not present
	if !strings.HasPrefix(signature, "0x") {
		signature = "0x" + signature
	}
	log.Trace("Using signature: %s", signature)

	// Convert signature to bytes
	sigBytes, err := hexutil.Decode(signature)
	if err != nil {
		log.Error("Failed to decode signature: %v", err)
		return false
	}

	// The signature should be 65 bytes: R (32) + S (32) + V (1)
	if len(sigBytes) != 65 {
		log.Error("Invalid signature length: got %d, want 65", len(sigBytes))
		return false
	}

	// Adjust V value if needed (Metamask adds 27 to V)
	if sigBytes[64] >= 27 {
		sigBytes[64] -= 27
	}

	// Prepare the message hash
	// Ethereum signed message prefix
	prefix := fmt.Sprintf("\x19Ethereum Signed Message:\n%d", len(message))
	// Hash the prefix + message
	msgHash := crypto.Keccak256Hash([]byte(prefix + message))
	log.Trace("Message hash: %s", msgHash.Hex())

	// Recover the public key from the signature
	pubKey, err := crypto.Ecrecover(msgHash.Bytes(), sigBytes)
	if err != nil {
		log.Error("Failed to recover public key: %v", err)
		return false
	}

	// Convert public key to uncompressed format and get the address
	pubKeyECDSA, err := crypto.UnmarshalPubkey(pubKey)
	if err != nil {
		log.Error("Failed to unmarshal public key: %v", err)
		return false
	}
	recoveredAddr := crypto.PubkeyToAddress(*pubKeyECDSA)
	recoveredAddrStr := strings.ToLower(recoveredAddr.Hex()[2:]) // Remove "0x" and convert to lowercase
	log.Trace("Recovered address: %s", recoveredAddrStr)

	matches := recoveredAddrStr == address
	log.Trace("Signature verification result: %v", matches)
	return matches
}

// createUser creates a new user for the given Ethereum address
func (p *Provider) createUser(ctx context.Context, address string) (*database.User, error) {
	log.Info("Creating new user for address: %s", address)

	// Generate a random password
	password := cryptoutil.MD5(fmt.Sprintf("%d%s", time.Now().UnixNano(), address))

	// Create the user
	username := "eth_" + address[:8] // Use first 8 chars of address as username
	email := "0x" + address          // Use full address as email

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

// VerifyAddress verifies the Ethereum address and creates a user if it doesn't exist
func (p *Provider) VerifyAddress(ctx context.Context, address string) (*database.User, error) {
	// Normalize address to lowercase without '0x' prefix
	address = strings.ToLower(strings.TrimPrefix(address, "0x"))
	log.Trace("Looking up user for address: %s", address)

	// Try to find existing user
	emailAddress := "0x" + address
	log.Trace("Looking up user by email: %s", emailAddress)

	user, err := database.Handle.Users().GetByEmail(ctx, emailAddress)
	if err != nil {
		if database.IsErrUserNotExist(err) {
			log.Info("User not found, creating new user for address: %s", address)
			return p.createUser(ctx, address)
		}
		log.Error("Failed to get user by address: %v", err)
		return nil, fmt.Errorf("get user by address: %v", err)
	}

	log.Trace("Found existing user: %s", user.Name)
	return user, nil
}

// Authenticate verifies the signature from Metamask.
func (p *Provider) Authenticate(ctx context.Context, address, signature string) (*database.User, error) {
	log.Info("Authenticating Metamask login - Address: %s", address)

	// First verify the signature
	message := "Sign this message to login to 4RealOSS"
	if !p.verifySignature(message, signature, address) {
		log.Warn("Invalid signature for address: %s", address)
		return nil, auth.ErrBadCredentials{Args: map[string]any{
			"reason": "invalid signature",
		}}
	}

	log.Trace("Signature verified successfully")

	// Then verify the address exists or create a new user
	return p.VerifyAddress(ctx, address)
}
