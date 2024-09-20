defmodule EigenlayerEx.ELContracts.Writer do
  require Logger
  alias EigenlayerEx.Operator
  alias EigenlayerEx.ELContracts.Reader, as: ELChainReader
  alias Ethers.Types

  # contracts
  alias EigenlayerEx.Contracts.DelegationManager
  alias Ethers.Contract.ERC20

  @enforce_keys [:delegation_manager, :strategy_manager, :el_chain_reader, :provider, :signer]
  defstruct [:delegation_manager, :strategy_manager, :el_chain_reader, :provider, :signer]

  @type t :: %__MODULE__{
    delegation_manager: Types.t_address(),
    strategy_manager: Types.t_address(),
    el_chain_reader: ELChainReader.t(),
    provider: String.t(),
    signer: String.t()
  }

  @spec new(Types.t_address(), Types.t_address(), ELChainReader.t(), String.t(), String.t()) :: t()
  def new(delegation_manager, strategy_manager, el_chain_reader, provider, signer) do
    %__MODULE__{
      delegation_manager: delegation_manager,
      strategy_manager: strategy_manager,
      el_chain_reader: el_chain_reader,
      provider: provider,
      signer: signer
    }
  end

  # do error handling on contract calls
  # Registers operator
  @spec register_as_operator(t(), Operator.t()) :: {:ok, String.t()} | {:error, any()}
  def register_as_operator(%__MODULE__{} = writer, %Operator{} = operator) do
    op_details = {
      operator.earnings_receiver_address,
      operator.delegation_approver_address,
      operator.staker_opt_out_window_blocks
    }

    case DelegationManager.register_as_operator(op_details, operator.metadata_url)
         |> Map.put(:gas, 300000)
         |> Ethers.send([
           from: operator.address,
           to: writer.delegation_manager,
           rpc_opts: [url: writer.provider],
           signer: Ethers.Signer.Local,
           signer_opts: [private_key: writer.signer]
         ]) do
      {:ok, tx_hash} ->
        {:ok, tx_hash}
      {:error, reason} ->
        {:error, "Failed to register as operator: #{inspect(reason)}"}
    end
  end

  # add logger
  @spec update_operator_details(t(), Operator.t()) :: {:ok, String.t()} | {:error, any()}
  def update_operator_details(%__MODULE__{} = writer, %Operator{} = operator) do
    op_details = {
      operator.earnings_receiver_address,
      operator.delegation_approver_address,
      operator.staker_opt_out_window_blocks
    }

    case DelegationManager.modify_operator_details(op_details)
      |> Ethers.send([
         from: operator.address,
         to: writer.delegation_manager,
         rpc_opts: [url: writer.provider],
         signer: Ethers.Signer.Local,
         signer_opts: [private_key: writer.signer]
       ]) do
    {:ok, tx_hash} ->
      writer.el_chain_reader.logger.info("Updated operator details tx: #{tx_hash}, operator: #{operator.address}")
      {:error, reason} ->
        {:error, "Failed to modify operator details: #{inspect(reason)}"}
      end

    case DelegationManager.update_operator_metadata_uri(operator.metadata_url)
      |> Ethers.send([
        from: operator.address,
        to: writer.delegation_manager,
        rpc_opts: [url: writer.provider],
        signer: Ethers.Signer.Local,
        signer_opts: [private_key: writer.signer]
      ]) do
        {:ok, tx_hash} ->
          writer.el_chain_reader.logger.info("Updated operator metadata URI tx: #{tx_hash}, operator: #{operator.address}")
          {:ok, tx_hash}
        {:error, reason} ->
          {:error, "Failed to update operator metadata URI: #{inspect(reason)}"}
      end
 end

  # List of functions
  # - register_as_operator done
  # - update_operator_details done
  # - deposit_erc20__into_strategy

  @spec deposit_erc20_into_strategy(t(), Types.t_address(), non_neg_integer()) :: {:ok, Types.t_tx_hash()} | {:error, String.t()}
  def deposit_erc20_into_strategy(%__MODULE__{} = writer, strategy_addr, amount) do
  writer.el_chain_reader.logger.info("Depositing #{amount} tokens into strategy #{strategy_addr}")

  case writer.el_chain_reader.get_strategy_and_underlying_erc20_token(strategy_addr) do
    {:ok, {_, underlying_token_contract, underlying_token}} ->
      with {:ok, _approve} <- approve_token(writer, underlying_token_contract, amount),
           {:ok, tx_hash} <- deposit_into_strategy(writer, strategy_addr, underlying_token, amount) do
      writer.el_chain_reader.logger.info("Deposited #{amount} tokens into strategy #{strategy_addr}")
        {:ok, tx_hash}
      else
        {:error, reason} -> {:error, "Failed to deposit: #{inspect(reason)}"}
      end
    {:error, reason} ->
      {:error, "Failed to get strategy and underlying token: #{inspect(reason)}"}
  end
end

  defp approve_token(writer, token_contract, amount) do
    IERC20.approve(token_contract, writer.strategy_manager, amount)
    |> Ethers.send([
      from: writer.signer,
      to: token_contract,
      rpc_opts: [url: writer.provider],
      signer: Ethers.Signer.Local,
      signer_opts: [private_key: writer.signer]
    ])
  end

  defp deposit_into_strategy(writer, strategy_addr, underlying_token, amount) do
    StrategyManager.deposit_into_strategy(writer.strategy_manager, strategy_addr, underlying_token, amount)
    |> Ethers.send([
      from: writer.signer,
      to: writer.strategy_manager,
      rpc_opts: [url: writer.provider],
      signer: Ethers.Signer.Local,
      signer_opts: [private_key: writer.signer]
    ])
  end








  # function to create Ethers.Signer module from private key
  # function to get public key address from private key





end
