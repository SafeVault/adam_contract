// Wallet Authentication Client Interface
// This provides TypeScript interfaces for frontend integration

import { Contract, Account, cairo, CallData, hash } from "starknet";

// Wallet Authentication Contract Interface
export interface IWalletAuthenticator {
  // Connect a traditional account to a Starknet wallet
  connectWallet(accountId: string, walletAddress: string): Promise<boolean>;
  
  // Verify wallet ownership with signature
  verifyWalletOwnership(
    accountId: string, 
    walletAddress: string,
    signature: [string, string],
    messageHash: string
  ): Promise<boolean>;
  
  // Verify with nonce to prevent replay attacks
  verifyWalletWithNonce(
    accountId: string,
    walletAddress: string,
    signature: [string, string]
  ): Promise<boolean>;
  
  // Self-verify wallet ownership
  selfVerifyWallet(
    accountId: string,
    signature: [string, string]
  ): Promise<boolean>;
  
  // Disconnect wallet from account
  disconnectWallet(accountId: string): Promise<boolean>;
  
  // Storage query functions
  getWalletByAccount(accountId: string): Promise<string>;
  getAccountByWallet(walletAddress: string): Promise<string>;
  isAccountConnected(accountId: string): Promise<boolean>;
  isWalletConnected(walletAddress: string): Promise<boolean>;
  
  // Admin functions
  transferOwnership(newOwner: string): Promise<void>;
}

// Implementation class for interacting with the contract
export class WalletAuthClient implements IWalletAuthenticator {
  private contractAddress: string;
  private adminAccount: Account;
  private contract: Contract;
  
  constructor(contractAddress: string, adminAccount: Account) {
    this.contractAddress = contractAddress;
    this.adminAccount = adminAccount;
    
    // Initialize contract with ABI
    this.contract = new Contract(
      WalletAuthABI,
      contractAddress,
      adminAccount
    );
  }
  
  // Connect wallet to account (admin only)
  async connectWallet(accountId: string, walletAddress: string): Promise<boolean> {
    try {
      const { transaction_hash } = await this.contract.connect_wallet(
        accountId,
        walletAddress
      );
      
      // Wait for transaction to be accepted
      await this.adminAccount.waitForTransaction(transaction_hash);
      return true;
    } catch (error) {
      console.error("Failed to connect wallet:", error);
      return false;
    }
  }
  
  // Verify wallet ownership with signature
  async verifyWalletOwnership(
    accountId: string, 
    walletAddress: string,
    signature: [string, string],
    messageHash: string
  ): Promise<boolean> {
    try {
      const result = await this.contract.call("verify_wallet_ownership", [
        accountId,
        walletAddress,
        signature,
        messageHash
      ]);
      return Boolean(result);
    } catch (error) {
      console.error("Failed to verify wallet ownership:", error);
      return false;
    }
  }
  
  // Verify with nonce to prevent replay attacks
  async verifyWalletWithNonce(
    accountId: string,
    walletAddress: string,
    signature: [string, string]
  ): Promise<boolean> {
    try {
      const result = await this.contract.call("verify_wallet_with_nonce", [
        accountId,
        walletAddress,
        signature
      ]);
      return Boolean(result);
    } catch (error) {
      console.error("Failed to verify wallet with nonce:", error);
      return false;
    }
  }
  
  // Self-verify wallet ownership
  async selfVerifyWallet(
    accountId: string,
    signature: [string, string]
  ): Promise<boolean> {
    try {
      const result = await this.contract.call("self_verify_wallet", [
        accountId,
        signature
      ]);
      return Boolean(result);
    } catch (error) {
      console.error("Failed to self-verify wallet:", error);
      return false;
    }
  }
  
  // Disconnect wallet from account
  async disconnectWallet(accountId: string): Promise<boolean> {
    try {
      const { transaction_hash } = await this.contract.disconnect_wallet(
        accountId
      );
      
      // Wait for transaction to be accepted
      await this.adminAccount.waitForTransaction(transaction_hash);
      return true;
    } catch (error) {
      console.error("Failed to disconnect wallet:", error);
      return false;
    }
  }
  
  // Get wallet address by account ID
  async getWalletByAccount(accountId: string): Promise<string> {
    try {
      const result = await this.contract.call("get_wallet_by_account", [accountId]);
      return result.toString();
    } catch (error) {
      console.error("Failed to get wallet by account:", error);
      return "0x0";
    }
  }
  
  // Get account ID by wallet address
  async getAccountByWallet(walletAddress: string): Promise<string> {
    try {
      const result = await this.contract.call("get_account_by_wallet", [walletAddress]);
      return result.toString();
    } catch (error) {
      console.error("Failed to get account by wallet:", error);
      return "0";
    }
  }
  
  // Check if account has connected wallet
  async isAccountConnected(accountId: string): Promise<boolean> {
    try {
      const result = await this.contract.call("is_account_connected", [accountId]);
      return Boolean(result);
    } catch (error) {
      console.error("Failed to check if account is connected:", error);
      return false;
    }
  }
  
  // Check if wallet is connected to any account
  async isWalletConnected(walletAddress: string): Promise<boolean> {
    try {
      const result = await this.contract.call("is_wallet_connected", [walletAddress]);
      return Boolean(result);
    } catch (error) {
      console.error("Failed to check if wallet is connected:", error);
      return false;
    }
  }
  
  // Transfer contract ownership (admin only)
  async transferOwnership(newOwner: string): Promise<void> {
    try {
      const { transaction_hash } = await this.contract.transfer_ownership(newOwner);
      
      // Wait for transaction to be accepted
      await this.adminAccount.waitForTransaction(transaction_hash);
    } catch (error) {
      console.error("Failed to transfer ownership:", error);
      throw error;
    }
  }
  
  // Helper method to create a signed message for wallet verification
  static async createSignedMessage(
    account: Account,
    accountId: string,
    nonce: number
  ): Promise<{
    messageHash: string;
    signature: [string, string];
  }> {
    // Create message hash from account ID and nonce
    const messageHash = hash.pedersen([BigInt(accountId), BigInt(nonce)]).toString();
    
    // Sign the message hash
    const signature = await account.signMessage(messageHash);
    
    return {
      messageHash,
      signature: [signature[0], signature[1]],
    };
  }
}

// ABI definition for the WalletAuthenticator contract
const WalletAuthABI = [
  {
    "type": "function",
    "name": "connect_wallet",
    "inputs": [
      {"name": "account_id", "type": "felt252"},
      {"name": "wallet_address", "type": "felt252"}
    ],
    "outputs": [{"name": "success", "type": "bool"}]
  },
  {
    "type": "function",
    "name": "verify_wallet_ownership",
    "inputs": [
      {"name": "account_id", "type": "felt252"},
      {"name": "wallet_address", "type": "felt252"},
      {"name": "signature", "type": "(felt252, felt252)"},
      {"name": "message_hash", "type": "felt252"}
    ],
    "outputs": [{"name": "is_valid", "type": "bool"}]
  },
  {
    "type": "function",
    "name": "verify_wallet_with_nonce",
    "inputs": [
      {"name": "account_id", "type": "felt252"},
      {"name": "wallet_address", "type": "felt252"},
      {"name": "signature", "type": "(felt252, felt252)"}
    ],
    "outputs": [{"name": "is_valid", "type": "bool"}]
  },
  {
    "type": "function",
    "name": "self_verify_wallet",
    "inputs": [
      {"name": "account_id", "type": "felt252"},
      {"name": "signature", "type": "(felt252, felt252)"}
    ],
    "outputs": [{"name": "is_valid", "type": "bool"}]
  },
  {
    "type": "function",
    "name": "disconnect_wallet",
    "inputs": [{"name": "account_id", "type": "felt252"}],
    "outputs": [{"name": "success", "type": "bool"}]
  },
  {
    "type": "function",
    "name": "get_wallet_by_account",
    "inputs": [{"name": "account_id", "type": "felt252"}],
    "outputs": [{"name": "wallet_}] }