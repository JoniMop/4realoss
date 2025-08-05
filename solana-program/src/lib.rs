use borsh::{BorshDeserialize, BorshSerialize};
use solana_program::{
    account_info::{next_account_info, AccountInfo},
    entrypoint,
    entrypoint::ProgramResult,
    msg,
    program_error::ProgramError,
    pubkey::Pubkey,
    rent::Rent,
    system_instruction,
    system_program,
    sysvar::Sysvar,
    program::invoke,
};

// Program entrypoint
entrypoint!(process_instruction);

// Program instruction
#[derive(BorshSerialize, BorshDeserialize, Debug)]
pub enum RepositoryInstruction {
    /// Add a new repository
    /// Accounts expected:
    /// 0. `[signer]` Owner of the repository
    /// 1. `[writable]` Repository account to be created
    /// 2. `[]` System program
    AddRepository {
        project_name: String,
        ipfs_cid: String,
        description: String,
    },
}

// Repository data structure
#[derive(BorshSerialize, BorshDeserialize, Debug)]
pub struct Repository {
    pub owner: Pubkey,
    pub project_name: String,
    pub ipfs_cid: String,
    pub description: String,
    pub timestamp: i64,
    pub is_initialized: bool,
}

impl Repository {
    pub const LEN: usize = 32 + 4 + 64 + 4 + 64 + 4 + 256 + 8 + 1; // Approximate size
}

// Process instruction
pub fn process_instruction(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    instruction_data: &[u8],
) -> ProgramResult {
    let instruction = RepositoryInstruction::try_from_slice(instruction_data)
        .map_err(|_| ProgramError::InvalidInstructionData)?;

    match instruction {
        RepositoryInstruction::AddRepository {
            project_name,
            ipfs_cid,
            description,
        } => {
            msg!("Adding repository: {}", project_name);
            add_repository(program_id, accounts, project_name, ipfs_cid, description)
        }
    }
}

// Add repository function
pub fn add_repository(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    project_name: String,
    ipfs_cid: String,
    description: String,
) -> ProgramResult {
    let account_info_iter = &mut accounts.iter();
    let owner_info = next_account_info(account_info_iter)?;
    let repository_info = next_account_info(account_info_iter)?;
    let system_program_info = next_account_info(account_info_iter)?;

    // Verify owner signed the transaction
    if !owner_info.is_signer {
        return Err(ProgramError::MissingRequiredSignature);
    }

    // Verify system program
    if system_program_info.key != &system_program::id() {
        return Err(ProgramError::IncorrectProgramId);
    }

    // Calculate rent
    let rent = Rent::get()?;
    let space = Repository::LEN;
    let lamports = rent.minimum_balance(space);

    // Create repository account
    invoke(
        &system_instruction::create_account(
            owner_info.key,
            repository_info.key,
            lamports,
            space as u64,
            program_id,
        ),
        &[
            owner_info.clone(),
            repository_info.clone(),
            system_program_info.clone(),
        ],
    )?;

    // Initialize repository data
    let mut repository_data = Repository::try_from_slice(&repository_info.data.borrow())?;
    if repository_data.is_initialized {
        return Err(ProgramError::AccountAlreadyInitialized);
    }

    repository_data.owner = *owner_info.key;
    repository_data.project_name = project_name;
    repository_data.ipfs_cid = ipfs_cid;
    repository_data.description = description;
    repository_data.timestamp = solana_program::clock::Clock::get()?.unix_timestamp;
    repository_data.is_initialized = true;

    repository_data.serialize(&mut &mut repository_info.data.borrow_mut()[..])?;

    msg!("Repository added successfully!");
    Ok(())
}