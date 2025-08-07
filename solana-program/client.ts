import {
  Connection,
  PublicKey,
  Transaction,
  TransactionInstruction,
  SystemProgram,
  Keypair,
  sendAndConfirmTransaction,
} from '@solana/web3.js';
import * as borsh from 'borsh';

// Program ID (will be set after deployment)
export const REPOSITORY_PROGRAM_ID = new PublicKey('11111111111111111111111111111111'); // Placeholder

// Repository instruction schema
export class RepositoryInstruction {
  tag: number;
  project_name: string;
  ipfs_cid: string;
  description: string;

  constructor(fields: {
    tag: number;
    project_name: string;
    ipfs_cid: string;
    description: string;
  }) {
    this.tag = fields.tag;
    this.project_name = fields.project_name;
    this.ipfs_cid = fields.ipfs_cid;
    this.description = fields.description;
  }
}

// Borsh schema for instruction
export const RepositoryInstructionSchema = new Map([
  [
    RepositoryInstruction,
    {
      kind: 'struct',
      fields: [
        ['tag', 'u8'],
        ['project_name', 'string'],
        ['ipfs_cid', 'string'],
        ['description', 'string'],
      ],
    },
  ],
]);

// Repository data schema
export class Repository {
  owner: PublicKey;
  project_name: string;
  ipfs_cid: string;
  description: string;
  timestamp: number;
  is_initialized: boolean;

  constructor(fields: {
    owner: PublicKey;
    project_name: string;
    ipfs_cid: string;
    description: string;
    timestamp: number;
    is_initialized: boolean;
  }) {
    this.owner = fields.owner;
    this.project_name = fields.project_name;
    this.ipfs_cid = fields.ipfs_cid;
    this.description = fields.description;
    this.timestamp = fields.timestamp;
    this.is_initialized = fields.is_initialized;
  }
}

export const RepositorySchema = new Map([
  [
    Repository,
    {
      kind: 'struct',
      fields: [
        ['owner', [32]], // PublicKey as 32 bytes
        ['project_name', 'string'],
        ['ipfs_cid', 'string'],
        ['description', 'string'],
        ['timestamp', 'i64'],
        ['is_initialized', 'u8'],
      ],
    },
  ],
]);

// Client functions
export class RepositoryClient {
  connection: Connection;
  programId: PublicKey;

  constructor(connection: Connection, programId: PublicKey) {
    this.connection = connection;
    this.programId = programId;
  }

  // Add repository to Solana
  async addRepository(
    owner: Keypair,
    projectName: string,
    ipfsCid: string,
    description: string
  ): Promise<string> {
    // Generate a new keypair for the repository account
    const repositoryAccount = Keypair.generate();

    // Create instruction data
    const instructionData = new RepositoryInstruction({
      tag: 0, // AddRepository variant
      project_name: projectName,
      ipfs_cid: ipfsCid,
      description: description,
    });

    // Serialize instruction
    const serializedInstruction = borsh.serialize(
      RepositoryInstructionSchema,
      instructionData
    );

    // Create instruction
    const instruction = new TransactionInstruction({
      keys: [
        { pubkey: owner.publicKey, isSigner: true, isWritable: false },
        { pubkey: repositoryAccount.publicKey, isSigner: true, isWritable: true },
        { pubkey: SystemProgram.programId, isSigner: false, isWritable: false },
      ],
      programId: this.programId,
      data: Buffer.from(serializedInstruction),
    });

    // Create transaction
    const transaction = new Transaction().add(instruction);

    // Send transaction
    const signature = await sendAndConfirmTransaction(
      this.connection,
      transaction,
      [owner, repositoryAccount]
    );

    return signature;
  }

  // Get repository data
  async getRepository(repositoryPublicKey: PublicKey): Promise<Repository | null> {
    try {
      const accountInfo = await this.connection.getAccountInfo(repositoryPublicKey);
      if (!accountInfo) return null;

      const repository = borsh.deserialize(
        RepositorySchema,
        Repository,
        accountInfo.data
      );

      return repository;
    } catch (error) {
      console.error('Error fetching repository:', error);
      return null;
    }
  }
}

// Browser-compatible functions for frontend
export async function addRepositoryToSolana(
  projectName: string,
  ipfsCid: string,
  description: string,
  walletAdapter: any // Phantom wallet adapter
): Promise<string> {
  try {
    // Connect to Solana devnet (change to mainnet for production)
    const connection = new Connection('https://api.devnet.solana.com', 'confirmed');
    
    // Create client
    const client = new RepositoryClient(connection, REPOSITORY_PROGRAM_ID);
    
    // Get wallet public key
    const publicKey = walletAdapter.publicKey;
    if (!publicKey) throw new Error('Wallet not connected');

    // Generate repository account
    const repositoryAccount = Keypair.generate();

    // Create instruction data
    const instructionData = new RepositoryInstruction({
      tag: 0,
      project_name: projectName,
      ipfs_cid: ipfsCid,
      description: description,
    });

    // Serialize instruction
    const serializedInstruction = borsh.serialize(
      RepositoryInstructionSchema,
      instructionData
    );

    // Create instruction
    const instruction = new TransactionInstruction({
      keys: [
        { pubkey: publicKey, isSigner: true, isWritable: false },
        { pubkey: repositoryAccount.publicKey, isSigner: true, isWritable: true },
        { pubkey: SystemProgram.programId, isSigner: false, isWritable: false },
      ],
      programId: REPOSITORY_PROGRAM_ID,
      data: Buffer.from(serializedInstruction),
    });

    // Create transaction
    const transaction = new Transaction().add(instruction);
    transaction.feePayer = publicKey;

    // Get recent blockhash
    const { blockhash } = await connection.getLatestBlockhash();
    transaction.recentBlockhash = blockhash;

    // Partial sign with repository account
    transaction.partialSign(repositoryAccount);

    // Sign and send transaction via wallet
    const signedTransaction = await walletAdapter.signTransaction(transaction);
    const signature = await connection.sendRawTransaction(signedTransaction.serialize());

    // Confirm transaction
    await connection.confirmTransaction(signature);

    return signature;
  } catch (error) {
    console.error('Error adding repository to Solana:', error);
    throw error;
  }
}