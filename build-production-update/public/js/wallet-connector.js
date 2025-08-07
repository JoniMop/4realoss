/**
 * 4RealOSS Unified Wallet Connector
 * Supports multi-chain wallet connections (Solana, Ethereum/Arbitrum)
 */

class WalletConnector {
    constructor() {
        this.connectedWallet = null;
        this.connectedChain = null;
        // Order matters: Solana first (default), then disabled networks
        this.supportedChains = {
            solana: {
                name: 'Solana',
                icon: '/img/solana.svg',
                description: 'High-performance blockchain for DeFi & Web3',
                enabled: true,
                wallets: [
                    { name: 'Phantom', key: 'phantom', icon: '/img/phantom.svg', popular: true },
                    { name: 'Solflare', key: 'solflare', icon: '/img/solflare.svg', popular: true },
                    { name: 'Backpack', key: 'backpack', icon: '/img/backpack.svg', popular: true },
                    { name: 'Glow', key: 'glow', icon: '/img/glow.svg', popular: false },
                    { name: 'Slope', key: 'slope', icon: '/img/slope.svg', popular: false },
                    { name: 'Coin98', key: 'coin98', icon: '/img/coin98.svg', popular: false },
                    { name: 'Moonshot', key: 'moonshot', icon: '/img/moonshot.svg', popular: false },
                    { name: 'MetaMask', key: 'metamask', icon: '/img/metamask.svg', popular: false }
                ]
            },
            ethereum: {
                name: 'Ethereum',
                icon: '/img/metamask.svg',
                description: 'Original smart contract blockchain',
                enabled: false,
                wallets: [
                    { name: 'MetaMask', key: 'metamask', icon: '/img/metamask.svg', popular: true },
                    { name: 'WalletConnect', key: 'walletconnect', icon: '/img/walletconnect.svg', popular: true },
                    { name: 'Coinbase Wallet', key: 'coinbase', icon: '/img/coinbase.svg', popular: true },
                    { name: 'Trust Wallet', key: 'trust', icon: '/img/trust.svg', popular: false }
                ]
            },
            arbitrum: {
                name: 'Arbitrum',
                icon: '/img/metamask.svg',
                description: 'Layer 2 scaling solution for Ethereum',
                enabled: false,
                wallets: [
                    { name: 'MetaMask', key: 'metamask', icon: '/img/metamask.svg', popular: true },
                    { name: 'WalletConnect', key: 'walletconnect', icon: '/img/walletconnect.svg', popular: true },
                    { name: 'Uniswap Wallet', key: 'uniswap', icon: '/img/uniswap.svg', popular: true },
                    { name: 'Coinbase Wallet', key: 'coinbase', icon: '/img/coinbase.svg', popular: false }
                ]
            }
        };
    }

    /**
     * Show the wallet connection modal
     */
    async showConnectModal() {
        return new Promise((resolve, reject) => {
            this.createModal(resolve, reject);
        });
    }

    /**
     * Create and display the wallet selection modal
     */
    createModal(resolve, reject) {
        // Remove existing modal if any
        const existingModal = document.getElementById('wallet-connect-modal');
        if (existingModal) existingModal.remove();

        // Create minimalist modal HTML (Dark theme)
        const modalHtml = `
            <div id="wallet-connect-modal" style="
                position: fixed;
                top: 0;
                left: 0;
                width: 100vw;
                height: 100vh;
                background: rgba(0, 0, 0, 0.8);
                backdrop-filter: blur(8px);
                z-index: 9999;
                display: flex;
                align-items: center;
                justify-content: center;
                animation: fadeIn 0.2s ease;
            ">
                <div style="
                    background: #1a1a1a;
                    border: 1px solid #333;
                    border-radius: 20px;
                    width: 420px;
                    max-width: 90vw;
                    max-height: 80vh;
                    overflow: auto;
                    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
                    animation: slideUp 0.3s ease;
                ">
                    <!-- Header -->
                    <div style="
                        padding: 24px 24px 0;
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                        border-bottom: 1px solid #333;
                        padding-bottom: 20px;
                        margin-bottom: 20px;
                    ">
                        <h2 style="
                            margin: 0;
                            font-size: 20px;
                            font-weight: 600;
                            color: #fff;
                        ">Connect a wallet</h2>
                        <button id="close-modal" style="
                            background: none;
                            border: none;
                            font-size: 24px;
                            cursor: pointer;
                            color: #888;
                            padding: 0;
                            width: 32px;
                            height: 32px;
                            display: flex;
                            align-items: center;
                            justify-content: center;
                            border-radius: 8px;
                        ">&times;</button>
                    </div>
                    
                    <!-- Chain Selection -->
                    <div id="chain-selection" style="padding: 0 24px 24px;">
                        <div style="
                            font-size: 14px;
                            color: #aaa;
                            margin-bottom: 16px;
                        ">Choose Network</div>
                        <div style="display: flex; flex-direction: column; gap: 8px;">
                            ${this.renderMinimalChainCards()}
                        </div>
                    </div>
                    
                    <!-- Wallet Selection -->
                    <div id="wallet-selection" style="display: none; padding: 0 24px 24px;">
                        <div style="
                            display: flex;
                            align-items: center;
                            margin-bottom: 16px;
                        ">
                            <button id="back-to-chains" style="
                                background: none;
                                border: none;
                                cursor: pointer;
                                color: #aaa;
                                margin-right: 12px;
                                padding: 4px;
                            ">←</button>
                            <div style="
                                font-size: 14px;
                                color: #aaa;
                            ">Select Wallet</div>
                        </div>
                        <div id="wallet-cards" style="display: flex; flex-direction: column; gap: 8px;"></div>
                        
                        <div id="more-wallets" style="margin-top: 16px;">
                            <button id="show-more-wallets" style="
                                width: 100%;
                                background: #2a2a2a;
                                border: 1px solid #444;
                                border-radius: 12px;
                                padding: 12px;
                                color: #aaa;
                                font-size: 14px;
                                cursor: pointer;
                                transition: all 0.2s ease;
                            ">Show more options</button>
                        </div>
                    </div>
                    
                    <!-- Connection Status -->
                    <div id="connection-status" style="display: none; padding: 24px; text-align: center;">
                        <div style="
                            width: 48px;
                            height: 48px;
                            border: 3px solid #333;
                            border-top: 3px solid #fff;
                            border-radius: 50%;
                            animation: spin 1s linear infinite;
                            margin: 0 auto 16px;
                        "></div>
                        <div style="font-weight: 600; margin-bottom: 8px; color: #fff;">Requesting connection</div>
                        <div id="connection-message" style="color: #aaa; font-size: 14px;">
                            Open your wallet to connect
                        </div>
                    </div>
                </div>
            </div>
            
            <style>
            @keyframes fadeIn {
                from { opacity: 0; }
                to { opacity: 1; }
            }
            
            @keyframes slideUp {
                from { 
                    opacity: 0;
                    transform: translateY(20px);
                }
                to { 
                    opacity: 1;
                    transform: translateY(0);
                }
            }
            
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
            
            #show-more-wallets:hover {
                background: #333;
                color: #fff;
            }
            
            #close-modal:hover {
                background: #333;
                color: #fff;
            }
            </style>
        `;

        // Add modal to page
        document.body.insertAdjacentHTML('beforeend', modalHtml);
        const modal = document.getElementById('wallet-connect-modal');

        // Handle modal close
        const closeModal = () => {
            modal.remove();
            reject(new Error('Connection cancelled'));
        };
        
        modal.querySelector('#close-modal').onclick = closeModal;
        modal.onclick = (e) => {
            if (e.target === modal) closeModal();
        };

        // Add event listeners
        this.setupModalEventListeners(modal, resolve, reject);
    }

    /**
     * Render minimal chain selection cards (Uniswap style)
     */
    renderMinimalChainCards() {
        return Object.entries(this.supportedChains).map(([chainKey, chain]) => {
            const isEnabled = chain.enabled !== false;
            const buttonStyle = !isEnabled ? 
                `width: 100%;
                background: #1a1a1a;
                border: 1px solid #333;
                border-radius: 12px;
                padding: 16px;
                cursor: not-allowed;
                transition: all 0.2s ease;
                display: flex;
                align-items: center;
                gap: 12px;
                text-align: left;
                opacity: 0.5;` :
                `width: 100%;
                background: #2a2a2a;
                border: 1px solid #444;
                border-radius: 12px;
                padding: 16px;
                cursor: pointer;
                transition: all 0.2s ease;
                display: flex;
                align-items: center;
                gap: 12px;
                text-align: left;`;
            
            const hoverEvents = !isEnabled ? '' : 
                `onmouseover="this.style.background='#333'; this.style.borderColor='#555'" 
                 onmouseout="this.style.background='#2a2a2a'; this.style.borderColor='#444'"`;
                
            const statusText = !isEnabled ? 'Coming Soon' : `${chain.wallets.length} ${chain.wallets.length === 1 ? 'wallet' : 'wallets'}`;
            const titleColor = !isEnabled ? '#888' : '#fff';
            const statusColor = !isEnabled ? '#666' : '#aaa';
            
            return `
            <button class="chain-card" data-chain="${chainKey}" style="${buttonStyle}" ${hoverEvents} ${!isEnabled ? 'disabled' : ''}>
                <img src="${chain.icon}" alt="${chain.name}" style="
                    width: 32px; 
                    height: 32px; 
                    border-radius: 8px;
                    flex-shrink: 0;
                    ${!isEnabled ? 'filter: grayscale(100%);' : ''}
                ">
                <div style="flex: 1;">
                    <div style="font-weight: 600; color: ${titleColor}; margin-bottom: 2px;">${chain.name}</div>
                    <div style="font-size: 12px; color: ${statusColor};">${statusText}</div>
                </div>
                <div style="color: #666;">${!isEnabled ? '⏰' : '→'}</div>
            </button>
        `;
        }).join('');
    }

    /**
     * Render chain selection cards (legacy - keeping for compatibility)
     */
    renderChainCards() {
        return this.renderMinimalChainCards();
    }

    /**
     * Render minimal wallet selection cards (Uniswap style)
     */
    renderWalletCards(chainKey, popularOnly = false) {
        const chain = this.supportedChains[chainKey];
        const wallets = popularOnly ? chain.wallets.filter(w => w.popular) : chain.wallets;
        
        return wallets.map(wallet => `
            <button class="wallet-card" data-wallet="${wallet.key}" data-chain="${chainKey}" style="
                width: 100%;
                background: #2a2a2a;
                border: 1px solid #444;
                border-radius: 12px;
                padding: 16px;
                cursor: pointer;
                transition: all 0.2s ease;
                display: flex;
                align-items: center;
                gap: 12px;
                text-align: left;
                position: relative;
            " onmouseover="this.style.background='#333'; this.style.borderColor='#555'" 
               onmouseout="this.style.background='#2a2a2a'; this.style.borderColor='#444'">
                ${wallet.popular ? `<div style="
                    position: absolute;
                    top: 8px;
                    right: 8px;
                    background: #ff6b35;
                    color: white;
                    font-size: 10px;
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-weight: 600;
                ">POPULAR</div>` : ''}
                <img src="${wallet.icon}" alt="${wallet.name}" style="
                    width: 32px; 
                    height: 32px; 
                    border-radius: 8px;
                    flex-shrink: 0;
                ">
                <div style="flex: 1;">
                    <div style="font-weight: 600; color: #fff; margin-bottom: 2px;">${wallet.name}</div>
                    <div style="font-size: 12px; color: #aaa;">${this.getWalletStatus(wallet.key)}</div>
                </div>
            </button>
        `).join('');
    }
    
    /**
     * Get wallet installation status
     */
    getWalletStatus(walletKey) {
        switch(walletKey) {
            case 'phantom':
                return window.solana && window.solana.isPhantom ? 'Ready to connect' : 'Install Phantom';
            case 'metamask':
                return window.ethereum ? 'Ready to connect' : 'Install MetaMask';
            case 'solflare':
                return window.solflare ? 'Ready to connect' : 'Install Solflare';
            case 'backpack':
                return window.backpack ? 'Ready to connect' : 'Install Backpack';
            case 'glow':
                return window.glow ? 'Ready to connect' : 'Install Glow';
            case 'slope':
                return window.slope ? 'Ready to connect' : 'Install Slope';
            case 'coin98':
                return window.coin98 && window.coin98.sol ? 'Ready to connect' : 'Install Coin98';
            case 'moonshot':
                return window.moonshot ? 'Ready to connect' : 'Install Moonshot';
            case 'walletconnect':
                return 'Scan QR code';
            default:
                return 'Click to connect';
        }
    }

    /**
     * Setup modal event listeners
     */
    setupModalEventListeners(modal, resolve, reject) {
        // Chain selection
        modal.addEventListener('click', (e) => {
            if (e.target.closest('.chain-card')) {
                const chainButton = e.target.closest('.chain-card');
                const chainKey = chainButton.dataset.chain;
                const chain = this.supportedChains[chainKey];
                
                // Prevent clicking on disabled chains
                if (chainButton.disabled || !chain.enabled) {
                    return;
                }
                
                this.showWalletSelection(modal, chainKey);
            }
        });

        // Wallet selection
        modal.addEventListener('click', async (e) => {
            if (e.target.closest('.wallet-card')) {
                const walletKey = e.target.closest('.wallet-card').dataset.wallet;
                const chainKey = e.target.closest('.wallet-card').dataset.chain;
                
                try {
                    await this.connectWallet(modal, chainKey, walletKey, resolve, reject);
                } catch (error) {
                    this.showError(modal, error.message);
                }
            }
        });
    }

    /**
     * Show wallet selection for a specific chain (minimal design)
     */
    showWalletSelection(modal, chainKey) {
        const walletSelection = modal.querySelector('#wallet-selection');
        const walletCards = modal.querySelector('#wallet-cards');
        const chainSelection = modal.querySelector('#chain-selection');
        const backButton = modal.querySelector('#back-to-chains');
        const showMoreButton = modal.querySelector('#show-more-wallets');

        // Hide chain selection and show wallet selection
        chainSelection.style.display = 'none';
        walletSelection.style.display = 'block';
        
        // Show popular wallets initially
        const chain = this.supportedChains[chainKey];
        const popularWallets = chain.wallets.filter(w => w.popular);
        walletCards.innerHTML = this.renderWalletCards(chainKey, true);
        
        // Back button functionality
        backButton.onclick = () => {
            walletSelection.style.display = 'none';
            chainSelection.style.display = 'block';
        };

        // Show more wallets functionality
        let showingAll = false;
        showMoreButton.onclick = () => {
            showingAll = !showingAll;
            if (showingAll) {
                walletCards.innerHTML = this.renderWalletCards(chainKey, false);
                showMoreButton.textContent = 'Show less options';
            } else {
                walletCards.innerHTML = this.renderWalletCards(chainKey, true);
                showMoreButton.textContent = 'Show more options';
            }
        };
    }

    /**
     * Connect to a specific wallet
     */
    async connectWallet(modal, chainKey, walletKey, resolve, reject) {
        const statusDiv = modal.querySelector('#connection-status');
        const messageEl = modal.querySelector('#connection-message');
        
        // Show connecting status
        statusDiv.style.display = 'block';
        modal.querySelector('#wallet-selection').style.display = 'none';

        try {
            let connection;
            
            if (chainKey === 'solana') {
                connection = await this.connectSolanaWallet(walletKey, messageEl);
            } else if (chainKey === 'ethereum' || chainKey === 'arbitrum') {
                connection = await this.connectEthereumWallet(walletKey, chainKey, messageEl);
            }

            // Store connection info
            this.connectedWallet = walletKey;
            this.connectedChain = chainKey;
            
            // Close modal and resolve
            $(modal).modal('hide');
            resolve(connection);
            
        } catch (error) {
            this.showError(modal, error.message);
            reject(error);
        }
    }

    /**
     * Connect to Solana wallet
     */
    async connectSolanaWallet(walletKey, messageEl) {
        messageEl.textContent = `Connecting to ${walletKey.charAt(0).toUpperCase() + walletKey.slice(1)} wallet...`;
        
        let walletObject;
        
        switch(walletKey) {
            case 'phantom':
                if (window.solana && window.solana.isPhantom) {
                    walletObject = window.solana;
                } else {
                    throw new Error('Phantom wallet not found. Please install Phantom from phantom.app');
                }
                break;
                
            case 'solflare':
                if (window.solflare && window.solflare.isSolflare) {
                    walletObject = window.solflare;
                } else {
                    throw new Error('Solflare wallet not found. Please install Solflare from solflare.com');
                }
                break;
                
            case 'backpack':
                if (window.backpack && window.backpack.isBackpack) {
                    walletObject = window.backpack;
                } else {
                    throw new Error('Backpack wallet not found. Please install Backpack from backpack.app');
                }
                break;
                
            case 'glow':
                if (window.glow) {
                    walletObject = window.glow;
                } else {
                    throw new Error('Glow wallet not found. Please install Glow wallet');
                }
                break;
                
            case 'slope':
                if (window.slope) {
                    walletObject = window.slope;
                } else {
                    throw new Error('Slope wallet not found. Please install Slope wallet');
                }
                break;
                
            case 'coin98':
                if (window.coin98 && window.coin98.sol) {
                    walletObject = window.coin98.sol;
                } else {
                    throw new Error('Coin98 wallet not found. Please install Coin98 wallet');
                }
                break;
                
            case 'moonshot':
                if (window.moonshot) {
                    walletObject = window.moonshot;
                } else {
                    throw new Error('Moonshot wallet not found. Please install Moonshot wallet');
                }
                break;
                
            case 'metamask':
                // MetaMask for Solana (using Solana adapter or direct connection)
                if (window.ethereum && window.ethereum.isMetaMask) {
                    // For now, redirect to Phantom as MetaMask doesn't natively support Solana
                    throw new Error('MetaMask for Solana is coming soon. Please use Phantom or Solflare for Solana connections.');
                } else {
                    throw new Error('MetaMask not found. Please install MetaMask');
                }
                break;
                
            default:
                throw new Error(`Unsupported Solana wallet: ${walletKey}`);
        }

        messageEl.textContent = 'Please approve the connection in your wallet...';
        const response = await walletObject.connect();
        const address = response.publicKey.toString();

        return {
            chain: 'solana',
            wallet: walletKey,
            address: address,
            walletObject: walletObject
        };
    }

    /**
     * Connect to Ethereum/Arbitrum wallet
     */
    async connectEthereumWallet(walletKey, chainKey, messageEl) {
        messageEl.textContent = `Connecting to ${walletKey.charAt(0).toUpperCase() + walletKey.slice(1)}...`;
        
        let walletObject;
        let accounts;
        
        switch(walletKey) {
            case 'metamask':
                if (!window.ethereum || !window.ethereum.isMetaMask) {
                    throw new Error('MetaMask not found. Please install MetaMask from metamask.io');
                }
                walletObject = window.ethereum;
                accounts = await walletObject.request({ method: 'eth_requestAccounts' });
                break;
                
            case 'walletconnect':
                // WalletConnect integration would require WalletConnect library
                throw new Error('WalletConnect support coming soon. Please use MetaMask for now.');
                
            case 'coinbase':
                if (window.ethereum && window.ethereum.isCoinbaseWallet) {
                    walletObject = window.ethereum;
                    accounts = await walletObject.request({ method: 'eth_requestAccounts' });
                } else {
                    throw new Error('Coinbase Wallet not found. Please install Coinbase Wallet');
                }
                break;
                
            case 'trust':
                if (window.ethereum && window.ethereum.isTrust) {
                    walletObject = window.ethereum;
                    accounts = await walletObject.request({ method: 'eth_requestAccounts' });
                } else {
                    throw new Error('Trust Wallet not found. Please install Trust Wallet');
                }
                break;
                
            case 'uniswap':
                // Uniswap wallet would need specific integration
                throw new Error('Uniswap Wallet support coming soon. Please use MetaMask for now.');
                
            default:
                throw new Error(`Unsupported Ethereum wallet: ${walletKey}`);
        }

        const address = accounts[0];

        // Switch to correct network if needed
        if (chainKey === 'arbitrum') {
            messageEl.textContent = 'Switching to Arbitrum network...';
            await this.switchToArbitrum();
        }

        return {
            chain: chainKey,
            wallet: walletKey,
            address: address,
            walletObject: walletObject
        };
    }

    /**
     * Switch MetaMask to Arbitrum network
     */
    async switchToArbitrum() {
        const arbitrumChainId = '0xA4B1'; // Arbitrum One mainnet
        
        try {
            await window.ethereum.request({
                method: 'wallet_switchEthereumChain',
                params: [{ chainId: arbitrumChainId }]
            });
        } catch (switchError) {
            // This error code indicates that the chain has not been added to MetaMask
            if (switchError.code === 4902) {
                await window.ethereum.request({
                    method: 'wallet_addEthereumChain',
                    params: [{
                        chainId: arbitrumChainId,
                        chainName: 'Arbitrum One',
                        nativeCurrency: {
                            name: 'ETH',
                            symbol: 'ETH',
                            decimals: 18
                        },
                        rpcUrls: ['https://arb1.arbitrum.io/rpc'],
                        blockExplorerUrls: ['https://arbiscan.io/']
                    }]
                });
            } else {
                throw switchError;
            }
        }
    }

    /**
     * Show error message in modal
     */
    showError(modal, errorMessage) {
        const statusDiv = modal.querySelector('#connection-status');
        const iconEl = statusDiv.querySelector('.icon');
        const headerEl = statusDiv.querySelector('.header');
        const messageEl = statusDiv.querySelector('#connection-message');

        iconEl.className = 'exclamation triangle icon';
        headerEl.textContent = 'Connection Failed';
        messageEl.textContent = errorMessage;
        statusDiv.querySelector('.message').className = 'ui icon error message';

        // Add retry button
        statusDiv.insertAdjacentHTML('beforeend', `
            <button class="ui primary button" onclick="location.reload()">Try Again</button>
        `);
    }

    /**
     * Sign message with connected wallet
     */
    async signMessage(message, walletConnection) {
        if (walletConnection.chain === 'solana') {
            return await this.signSolanaMessage(message, walletConnection);
        } else {
            return await this.signEthereumMessage(message, walletConnection);
        }
    }

    /**
     * Sign message with Solana wallet
     */
    async signSolanaMessage(message, walletConnection) {
        const encodedMessage = new TextEncoder().encode(message);
        const signResult = await walletConnection.walletObject.signMessage(encodedMessage, 'utf8');
        return btoa(String.fromCharCode(...new Uint8Array(signResult.signature)));
    }

    /**
     * Sign message with Ethereum wallet
     */
    async signEthereumMessage(message, walletConnection) {
        const signature = await walletConnection.walletObject.request({
            method: 'personal_sign',
            params: [message, walletConnection.address]
        });
        return signature.startsWith('0x') ? signature.slice(2) : signature;
    }

    /**
     * Get current connection info
     */
    getConnection() {
        return {
            wallet: this.connectedWallet,
            chain: this.connectedChain
        };
    }

    /**
     * Disconnect wallet
     */
    disconnect() {
        this.connectedWallet = null;
        this.connectedChain = null;
    }
}

// Create global instance
window.walletConnector = new WalletConnector();