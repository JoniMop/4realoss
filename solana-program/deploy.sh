#!/bin/bash

# Deploy Solana program to devnet
# Make sure you have Solana CLI installed and configured

echo "🚀 Deploying Repository Storage Program to Solana Devnet..."

# Set cluster to devnet
solana config set --url https://api.devnet.solana.com

# Check balance
echo "📊 Checking SOL balance..."
solana balance

# Build the program
echo "🔨 Building Solana program..."
cargo build-bpf --manifest-path=Cargo.toml --bpf-out-dir=./target/deploy

# Deploy the program
echo "🚀 Deploying program..."
PROGRAM_ID=$(solana program deploy ./target/deploy/repository_storage.so --keypair ~/.config/solana/id.json)

echo "✅ Program deployed successfully!"
echo "📋 Program ID: $PROGRAM_ID"
echo ""
echo "🔧 Next steps:"
echo "1. Update the REPOSITORY_PROGRAM_ID constant in client.ts with: $PROGRAM_ID"
echo "2. Update the frontend JavaScript with the new program ID"
echo "3. Test the integration"
echo ""
echo "💡 To interact with the program:"
echo "   - Use Phantom wallet on devnet"
echo "   - Get devnet SOL from: https://faucet.solana.com/"
echo "   - Make sure your wallet is set to Devnet in Phantom settings"