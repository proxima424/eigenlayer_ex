defmodule EigenlayerEx.ELContracts.Reader do
  require Logger
  alias Ethers.Types
  alias EigenlayerEx.Operator

  alias EigenlayerEx.Contracts.DelegationManager
  alias EigenlayerEx.Contracts.IStrategy
  alias EigenlayerEx.Contracts.AVSDirectory
  alias EigenlayerEx.Contracts.ISlasher

  @zero_address "0x0000000000000000000000000000000000000000"
  @default_slasher @zero_address
  @default_strategy @zero_address

  @enforce_keys [:logger, :slasher, :delegation_manager, :avs_directory, :provider]
  defstruct [:logger, :slasher, :delegation_manager, :avs_directory, :provider]

  @type t :: %__MODULE__{
    logger: any(),
    slasher: Types.t_address(),
    delegation_manager: Types.t_address(),
    avs_directory: Types.t_address(),
    provider: String.t()
  }

  @doc """
  Creates a new ELChainReader struct.
  """
  @spec new(any(), Types.t_address(), Types.t_address(), Types.t_address(), String.t()) :: t()
  def new(logger, slasher, delegation_manager, avs_directory, provider) do
    %__MODULE__{
      logger: logger,
      slasher: slasher,
      delegation_manager: delegation_manager,
      avs_directory: avs_directory,
      provider: provider
    }
  end

  @spec is_operator_registered(t(), Types.t_address()) :: {:ok, boolean()} | {:error, term()}
  def is_operator_registered(%__MODULE__{} = reader, operator) do
    rpc_opts = [url: reader.provider]
    case DelegationManager.is_operator(operator)
      |> Ethers.call(
        to: reader.delegation_manager,
        rpc_opts: rpc_opts
      ) do
        {:ok, is_operator} ->
          {:ok, is_operator}
          # reader.logger.info("Operator #{operator} is registered: #{is_operator}")
        {:error, reason} ->
          {:error, "error bruhh"}
          # reader.logger.error("Error checking operator registration status: #{inspect(reason)}")
      end
  end

  @spec get_operator_details(t(), Types.t_address()) :: {:ok, Operator.t()} | {:error, term()}
  def get_operator_details(%__MODULE__{} = reader, operator) do
    rpc_opts = [url: reader.provider]
    case DelegationManager.operator_details(operator)
      |> Ethers.call(
        to: reader.delegation_manager,
        rpc_opts: rpc_opts
      ) do
        {:ok, details} ->
          operator_struct = %Operator{
            address: operator,
            earnings_receiver_address: details.earningsReceiver,
            delegation_approver_address: details.delegationApprover,
            staker_opt_out_window_blocks: details.stakerOptOutWindowBlocks,
            metadata_url: nil
          }
          {:ok, operator_struct}
          # reader.logger.info("Operator details: #{inspect(operator_struct)}")
        {:error, reason} ->
          {:error, "error error"}
          # reader.logger.error("Error getting operator details: #{inspect(reason)}")
      end
  end

  def get_strategy_and_underlying_erc20_token(%__MODULE__{} = reader, strategy_addr) do
    rpc_opts = [url: reader.provider]
    # reader.logger.info("Getting strategy and underlying ERC20 token for strategy: #{strategy_addr}")
    case IStrategy.underlying_token()
      |> Ethers.call(
        to: strategy_addr,
        rpc_opts: rpc_opts
      ) do
        {:ok, underlying_token} ->
          {:ok, {strategy_addr, underlying_token, underlying_token}}
        {:error, reason} ->
          {:error, "error error"}
          # reader.logger.error("Error getting strategy and underlying ERC20 token: #{inspect(reason)}")
      end
  end


  @spec service_manager_can_slash_operator_until_block(t(), Types.t_address(), Types.t_address()) :: {:ok, non_neg_integer()} | {:error, term()}
  def service_manager_can_slash_operator_until_block(%__MODULE__{} = reader, operator, service_manager) do
    rpc_opts = [url: reader.provider]

    case ISlasher.contract_can_slash_operator_until_block(operator, service_manager)
       |> Ethers.call(
        to: reader.slasher,
        rpc_opts: rpc_opts
       ) do
        {:ok, block_number} ->
          {:ok, block_number}
        {:error, reason} ->
          {:error, "Failed to get slashing status: #{inspect(reason)}"}
       end
  end

  def operator_is_frozen(%__MODULE__{} = reader, operator) do
    rpc_opts = [url: reader.provider]
    case ISlasher.is_frozen(operator)
      |> Ethers.call(
        to: reader.slasher,
        rpc_opts: rpc_opts
      ) do
        {:ok, is_frozen} ->
          {:ok, is_frozen}
        {:error, reason} ->
          {:error, "Can't get operator frozen status: #{inspect(reason)}"}
      end
  end

  ## has to return uint256
  def get_operator_shares_in_strategy(%__MODULE__{} = reader, operator, strategy ) do
   rpc_opts = [url: reader.provider]
   case DelegationManager.operator_shares(operator,strategy)
       |> Ethers.call(
        to: reader.delegation_manager,
        rpc_opts: rpc_opts
       )   do
        {:ok, shares} ->
          {:ok, shares}
        {:error, reason} ->
          {:error, "Can't get operator shares in strategy: #{inspect(reason)}"}
       end
  end


  # to-do : expiry is uint256
  @spec calculate_operator_avs_registration_digest_hash(t(), Types.t_address(), Types.t_address(), <<_::256>>, non_neg_integer()) :: {:ok, <<_::256>>} | {:error, String.t()}
  def calculate_operator_avs_registration_digest_hash(%__MODULE__{} = reader, operator, avs, salt, expiry) do
    rpc_opts = [url: reader.provider]

    case AVSDirectory.calculate_operator_avs_registration_digest_hash(operator,avs,salt,expiry)
     |> Ethers.call(
      to: reader.avs_directory,
      rpc_opts: rpc_opts
     ) do
      {:ok, digest_hash} ->
        {:ok, digest_hash}
      {:error, reason} ->
        {:error, "Can't calculate operator AVS registration digest hash: #{inspect(reason)}"}
     end
  end

  @spec calculate_delegation_approval_digest_hash(t(), Types.t_address(), Types.t_address(), Types.t_address(), <<_::256>>, non_neg_integer()) :: {:ok, <<_::256>>} | {:error, String.t()}
  def calculate_delegation_approval_digest_hash(%__MODULE__{} = reader, staker,operator,delegation_approver,approve_salt, expiry) do
    rpc_opts = [url: reader.provider]
    case DelegationManager.calculate_delegation_approval_digest_hash(staker,operator,delegation_approver,approve_salt,expiry)
    |> Ethers.call(
      to: reader.delegation_manager,
      rpc_opts: rpc_opts
    ) do
      {:ok, digest_hash} ->
        {:ok, digest_hash}
      {:error, reason} ->
        {:error, "Can't calculate delegation approval digest hash: #{inspect(reason)}"}
    end
  end
  @moduledoc """
  """
end

# delegationmanager, avsdirecotry, ISlasher, IStrategy, IERC20
