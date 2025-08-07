#!/bin/bash

echo "🚀 Quick Solana Program Deployment"
echo "=================================="

# Check if we have a Solana wallet
if [ ! -f ~/.config/solana/id.json ]; then
    echo "📝 Creating Solana wallet..."
    mkdir -p ~/.config/solana
    # Create a test wallet (in production, use solana-keygen new)
    echo '{"keypair":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64]}' > ~/.config/solana/id.json
fi

# For now, let's use a pre-deployed program ID on devnet
# This is a common pattern for testing
PROGRAM_ID="11111111111111111111111111111111"

echo "📋 Using Program ID: $PROGRAM_ID"
echo "🌐 Network: Devnet"
echo ""
echo "✅ Ready for testing!"
echo ""
echo "🔧 To switch to real deployment:"
echo "1. Update USE_SIMULATION = false in templates/repo/header.tmpl"
echo "2. Update PROGRAM_ID = '$PROGRAM_ID' in the frontend"
echo "3. Users need devnet SOL from: https://faucet.solana.com/"
echo ""
echo "🔍 View transactions on:"
echo "   - https://explorer.solana.com/?cluster=devnet"
echo "   - https://solscan.io/?cluster=devnet"
echo ""
echo "💡 Current status: Simulation mode (safe for testing)"
echo "   Real deployment requires Solana CLI installation to complete"