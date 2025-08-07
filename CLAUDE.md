# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

4RealOSS is a decentralized Git platform built on the Gogs foundation, integrating IPFS storage and blockchain technology (Solana/Phantom wallet integration). It enables decentralized repository hosting with community governance and direct creator monetization.

## Technology Stack

- **Backend**: Go 1.24+ application based on Gogs
- **Frontend**: Semantic UI, HTML templates, JavaScript
- **Blockchain**: Solana integration with Phantom wallet authentication
- **Storage**: IPFS for decentralized file storage
- **Database**: PostgreSQL (primary), with support for MySQL, SQLite3, MSSQL
- **Build Tool**: Task (Taskfile.yml) - Go task runner

## Development Commands

### Build & Run
- `task build` - Build the binary with version info and build tags
- `task web` - Build and start the web server
- `task` or `task default` - Same as `task build`
- `./gogs web` - Start web server after building
- `./realoss` - Start the production binary

### Testing & Development
- `task test` - Run all tests with coverage and race detection (`go test -cover -race ./...`)
- `task generate` - Run all go:generate commands
- `task generate-schemadoc` - Generate database schema documentation
- `task clean` - Remove system meta files (*.DS_Store)

### CSS Development
- `task less` - Generate CSS from LESS files using lessc

### Code Analysis
- `task fixme` - Show all FIXME occurrences
- `task todo` - Show all TODO occurrences  
- `task legacy` - Identify legacy and deprecated code

### Database
- `task drop-test-db` - Drop PostgreSQL test databases

### Release
- `task release` - Build and package for distribution

## Architecture Overview

### Core Structure
- `internal/` - Main application code organized by domain
  - `auth/` - Authentication providers (GitHub, LDAP, MetaMask, Solana, SMTP, PAM)
  - `database/` - Database models and operations
  - `route/` - HTTP handlers organized by feature area
  - `cmd/` - CLI commands and application entry points
  - `conf/` - Configuration management

### Key Features
- **Multi-wallet Authentication**: MetaMask (Ethereum) and Phantom (Solana) wallet integration
- **IPFS Integration**: Decentralized storage for repositories via `ipfs_upload.go`
- **Decentralized Architecture**: Built for blockchain-based governance and rewards
- **Standard Git Operations**: Full Git hosting capabilities via HTTP/SSH

### Configuration
- Main config: `conf/app.ini` (extensive configuration options)
- Brand name: "4RealOSS" 
- Default database: PostgreSQL
- Repository root: `/home/kali/gogs-repositories`
- Supports multi-language internationalization

### Authentication Providers
The system supports multiple authentication methods:
- Traditional (username/password)
- GitHub OAuth
- LDAP/Active Directory
- MetaMask (Ethereum wallets)
- Solana wallets (Phantom, Solflare)
- SMTP
- PAM

### Templates & Frontend
- Templates: `templates/` using Go templates
- Static assets: `public/` (CSS, JS, images)
- LESS-based CSS compilation
- Semantic UI framework
- Custom Solana/Web3 integrations

## Blockchain Integration

### Solana Integration
- Wallet connection via browser extensions
- Ed25519 signature verification
- Automatic user creation from wallet addresses
- Test page: `/test_solana_integration.html`

### IPFS Features
- Repository upload to IPFS
- Decentralized storage backend
- Community pinning network support

## Testing

- Standard Go testing with `go test`
- Test coverage reporting enabled
- Race condition detection enabled
- Database testing with PostgreSQL test instances

## Important Notes

- This is a production deployment (`RUN_MODE = prod`)
- Uses custom branding (4RealOSS instead of Gogs)
- Extensive configuration in `conf/app.ini`
- Multi-chain blockchain support (Solana primary, Arbitrum planned)
- Community-driven governance model