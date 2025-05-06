#[starknet::contract]
mod WalletAuthenticator {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::contract_address_const;
    use array::ArrayTrait;
    use box::BoxTrait;
    use ecdsa::check_ecdsa_signature;
    use option::OptionTrait;
    use zeroable::Zeroable;
    use serde::Serde;
    use traits::Into;
    use traits::TryInto;

    //
    // Storage
    //
    #[storage]
    struct Storage {
        // Maps traditional account identifiers (e.g., usernames or email hashes) to wallet addresses
        account_to_wallet: LegacyMap::<felt252, ContractAddress>,
        // Maps wallet addresses to traditional account identifiers for reverse lookup
        wallet_to_account: LegacyMap::<ContractAddress, felt252>,
        // Tracks if a wallet is connected to any account
        is_wallet_connected: LegacyMap::<ContractAddress, bool>,
        // Tracks if an account has a connected wallet
        is_account_connected: LegacyMap::<felt252, bool>,
        // Owner of the contract with admin privileges
        contract_owner: ContractAddress,
        // Nonce for each wallet to prevent replay attacks
        wallet_nonces: LegacyMap::<ContractAddress, u128>,
    }

    //
    // Events
    //
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        WalletConnected: WalletConnected,
        WalletDisconnected: WalletDisconnected,
        OwnershipTransferred: OwnershipTransferred,
    }

    #[derive(Drop, starknet::Event)]
    struct WalletConnected {
        account_id: felt252,
        wallet_address: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct WalletDisconnected {
        account_id: felt252,
        wallet_address: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        previous_owner: ContractAddress,
        new_owner: ContractAddress,
    }

    //
    // Constructor
    //
    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        // Initialize with the contract owner
        self.contract_owner.write(owner);
    }

    //
    // External functions
    //
    #[external(v0)]
    impl WalletAuthenticatorImpl of super::IWalletAuthenticator<ContractState> {
        // 1. Create verification system for wallet ownership
        fn connect_wallet(
            ref self: ContractState, 
            account_id: felt252, 
            wallet_address: ContractAddress
        ) -> bool {
            // Only contract owner can connect wallets (centralized approach)
            let caller = get_caller_address();
            assert(caller == self.contract_owner.read(), 'Only owner can connect');
            
            // Ensure wallet is not already connected to another account
            assert(!self.is_wallet_connected.read(wallet_address), 'Wallet already connected');
            
            // Check if account already has a wallet
            if self.is_account_connected.read(account_id) {
                // Remove previous wallet mapping
                let previous_wallet = self.account_to_wallet.read(account_id);
                self.is_wallet_connected.write(previous_wallet, false);
                self.wallet_to_account.write(previous_wallet, 0);
            }
            
            // Create the mapping connections
            self.account_to_wallet.write(account_id, wallet_address);
            self.wallet_to_account.write(wallet_address, account_id);
            
            // Update connection flags
            self.is_wallet_connected.write(wallet_address, true);
            self.is_account_connected.write(account_id, true);
            
            // Emit wallet connected event
            self.emit(WalletConnected {
                account_id: account_id,
                wallet_address: wallet_address,
                timestamp: starknet::get_block_timestamp(),
            });
            
            true
        }
        
        // 2. Implement signature-based verification for enhanced security
        fn verify_wallet_ownership(
            ref self: ContractState,
            account_id: felt252,
            wallet_address: ContractAddress,
            signature: (felt252, felt252),
            message_hash: felt252
        ) -> bool {
            // Verify the wallet is connected to the specified account
            let connected_wallet = self.account_to_wallet.read(account_id);
            assert(connected_wallet == wallet_address, 'Wallet not connected to account');
            
            // Get public key from the wallet address (this is simplified - in reality would need more complex logic)
            // For demo purposes, we'll derive a public key from the wallet address
            let public_key = wallet_address.into();
            
            // Verify signature
            check_ecdsa_signature(
                message_hash,
                public_key,
                signature.0,
                signature.1
            )
        }
        
        // Another signature verification method that uses nonces to prevent replay attacks
        fn verify_wallet_with_nonce(
            ref self: ContractState,
            account_id: felt252,
            wallet_address: ContractAddress,
            signature: (felt252, felt252)
        ) -> bool {
            // Get current nonce for this wallet
            let nonce = self.wallet_nonces.read(wallet_address);
            
            // Create message hash including the nonce
            // In a real implementation, you'd hash these values together properly
            let message_hash = nonce.into() + account_id;
            
            // Verify signature
            let result = self.verify_wallet_ownership(account_id, wallet_address, signature, message_hash);
            
            // If verification succeeds, increment nonce
            if result {
                self.wallet_nonces.write(wallet_address, nonce + 1);
            }
            
            result
        }
        
        // Self-verification method where wallet proves its own ownership
        fn self_verify_wallet(
            ref self: ContractState,
            account_id: felt252,
            signature: (felt252, felt252)
        ) -> bool {
            let caller = get_caller_address();
            
            // Ensure the wallet is connected to the specified account
            let connected_account = self.wallet_to_account.read(caller);
            assert(connected_account == account_id, 'Caller not connected to account');
            
            // Get current nonce
            let nonce = self.wallet_nonces.read(caller);
            
            // Create message hash with nonce to prevent replay attacks
            let message_hash = nonce.into() + account_id;
            
            // Get public key from the wallet address (simplified)
            let public_key = caller.into();
            
            // Verify signature
            let is_valid = check_ecdsa_signature(
                message_hash,
                public_key,
                signature.0,
                signature.1
            );
            
            // Increment nonce on successful verification
            if is_valid {
                self.wallet_nonces.write(caller, nonce + 1);
            }
            
            is_valid
        }
        
        // Disconnect a wallet from an account
        fn disconnect_wallet(ref self: ContractState, account_id: felt252) -> bool {
            // Only contract owner or the wallet owner can disconnect
            let caller = get_caller_address();
            let connected_wallet = self.account_to_wallet.read(account_id);
            
            assert(
                caller == self.contract_owner.read() || caller == connected_wallet,
                'Not authorized to disconnect'
            );
            
            // Ensure account has a connected wallet
            assert(self.is_account_connected.read(account_id), 'No wallet connected');
            
            // Remove mappings
            let wallet_address = self.account_to_wallet.read(account_id);
            self.account_to_wallet.write(account_id, contract_address_const::<0>());
            self.wallet_to_account.write(wallet_address, 0);
            
            // Update connection flags
            self.is_wallet_connected.write(wallet_address, false);
            self.is_account_connected.write(account_id, false);
            
            // Emit wallet disconnected event
            self.emit(WalletDisconnected {
                account_id: account_id,
                wallet_address: wallet_address,
                timestamp: starknet::get_block_timestamp(),
            });
            
            true
        }
        
        // 3. Storage structure query functions
        fn get_wallet_by_account(self: @ContractState, account_id: felt252) -> ContractAddress {
            self.account_to_wallet.read(account_id)
        }
        
        fn get_account_by_wallet(self: @ContractState, wallet_address: ContractAddress) -> felt252 {
            self.wallet_to_account.read(wallet_address)
        }
        
        fn is_account_connected(self: @ContractState, account_id: felt252) -> bool {
            self.is_account_connected.read(account_id)
        }
        
        fn is_wallet_connected(self: @ContractState, wallet_address: ContractAddress) -> bool {
            self.is_wallet_connected.read(wallet_address)
        }
        
        // Admin functions
        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            let caller = get_caller_address();
            assert(caller == self.contract_owner.read(), 'Only owner can transfer');
            
            let previous_owner = self.contract_owner.read();
            self.contract_owner.write(new_owner);
            
            // Emit ownership transfer event
            self.emit(OwnershipTransferred {
                previous_owner: previous_owner,
                new_owner: new_owner,
            });
        }
    }
}

// Interface for the WalletAuthenticator contract
#[starknet::interface]
trait IWalletAuthenticator<TContractState> {
    // Create verification system for wallet ownership
    fn connect_wallet(
        ref self: TContractState, 
        account_id: felt252, 
        wallet_address: ContractAddress
    ) -> bool;
    
    // Signature-based verification
    fn verify_wallet_ownership(
        ref self: TContractState,
        account_id: felt252,
        wallet_address: ContractAddress,
        signature: (felt252, felt252),
        message_hash: felt252
    ) -> bool;
    
    // Nonce-based verification to prevent replay attacks
    fn verify_wallet_with_nonce(
        ref self: TContractState,
        account_id: felt252,
        wallet_address: ContractAddress,
        signature: (felt252, felt252)
    ) -> bool;
    
    // Self-verification where wallet proves its own ownership
    fn self_verify_wallet(
        ref self: TContractState,
        account_id: felt252,
        signature: (felt252, felt252)
    ) -> bool;
    
    // Disconnect a wallet from an account
    fn disconnect_wallet(ref self: TContractState, account_id: felt252) -> bool;
    
    // Storage query functions
    fn get_wallet_by_account(self: @TContractState, account_id: felt252) -> ContractAddress;
    fn get_account_by_wallet(self: @TContractState, wallet_address: ContractAddress) -> felt252;
    fn is_account_connected(self: @TContractState, account_id: felt252) -> bool;
    fn is_wallet_connected(self: @TContractState, wallet_address: ContractAddress) -> bool;
    
    // Admin functions
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress) -> ();
}