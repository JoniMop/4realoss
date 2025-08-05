# 4REALOSS Solana Program

This directory contains the Solana program (smart contract) for storing repository metadata on the Solana blockchain.

## Overview

The Repository Storage program allows users to:
- Store repository metadata (name, IPFS CID, description) on Solana blockchain
- Create immutable records of repository versions
- Provide decentralized proof of ownership and timestamps

## Files

- `src/lib.rs` - Main Solana program code
- `client.ts` - TypeScript client for interacting with the program
- `Cargo.toml` - Rust dependencies and build configuration
- `deploy.sh` - Deployment script for devnet/mainnet
- `README.md` - This documentation

## Program Structure

### Instructions
- `AddRepository` - Adds a new repository record to the blockchain

### Account Structure
```rust
pub struct Repository {
    pub owner: Pubkey,        // Repository owner's wallet address
    pub project_name: String, // Repository name
    pub ipfs_cid: String,     // IPFS content identifier
    pub description: String,  // Project description
    pub timestamp: i64,       // Unix timestamp
    pub is_initialized: bool, // Initialization flag
}
```

## Deployment

### Prerequisites
1. Install Solana CLI tools
2. Create a Solana wallet: `solana-keygen new`
3. Get devnet SOL: `solana airdrop 2`

### Deploy to Devnet
```bash
cd solana-program
./deploy.sh
```

### Deploy to Mainnet
```bash
# Set cluster to mainnet
solana config set --url https://api.mainnet-beta.solana.com

# Deploy (requires real SOL for deployment fees)
cargo build-bpf --manifest-path=Cargo.toml --bpf-out-dir=./target/deploy
solana program deploy ./target/deploy/repository_storage.so
```

## Integration

After deployment:

1. Copy the program ID from deployment output
2. Update `REPOSITORY_PROGRAM_ID` in `client.ts`
3. Update the frontend JavaScript in `templates/repo/header.tmpl`
4. Replace the simulated transaction with actual Solana program calls

## Frontend Integration

The frontend uses:
- Phantom wallet for user authentication
- @solana/web3.js for blockchain interactions
- Borsh for data serialization

## Testing

1. Install Phantom wallet browser extension
2. Switch Phantom to Devnet
3. Get devnet SOL from faucet
4. Test repository upload via the web interface

## Cost Estimation

- Program deployment: ~2-5 SOL (one-time)
- Repository creation: ~0.001-0.01 SOL per transaction
- Account rent: ~0.002 SOL per repository (recoverable)

## Security Considerations

- Only repository owners can create records for their repositories
- All data is public on the blockchain
- IPFS CIDs should be validated before storage
- Consider rate limiting to prevent spam

## Future Enhancements

- Multi-signature repository ownership
- Repository transfer functionality
- Version history tracking
- Integration with $4REAL token for fees/rewards