defmodule EigenlayerEx.AVSRegistry.Reader do
  @moduledoc """
  Documentation for `AVSRegistry.Reader`.
  """
  require Logger

  alias Ethers.Types
  alias EigenlayerEx.OperatorStateRetriever

  @operator_socket_update_event "OperatorSocketUpdate(bytes32,string)"
  @new_pubkey_registration_event "NewPubkeyRegistration(address,uint256[2],uint256[2][2])"


    @enforce_keys [
      :logger,
      :bls_apk_registry_addr,
      :registry_coordinator_addr,
      :operator_state_retriever,
      :stake_registry_addr,
      :provider
    ]

    defstruct [
      :logger,
      :bls_apk_registry_addr,
      :registry_coordinator_addr,
      :operator_state_retriever,
      :stake_registry_addr,
      :provider
    ]

    @type t :: %__MODULE__{
      logger: any(),  # Assuming SharedLogger type, adjust as needed
      bls_apk_registry_addr: Types.t_address(),
      registry_coordinator_addr: Types.t_address(),
      operator_state_retriever: Types.t_address(),
      stake_registry_addr: Types.t_address(),
      provider: String.t()
    }

    @doc """
    Creates a new AvsRegistryChainReader struct.
    """
    def new(
      logger,
      bls_apk_registry_addr,
      registry_coordinator_addr,
      operator_state_retriever,
      stake_registry_addr,
      provider
    ) do
      %__MODULE__{
        logger: logger,
        bls_apk_registry_addr: bls_apk_registry_addr,
        registry_coordinator_addr: registry_coordinator_addr,
        operator_state_retriever: operator_state_retriever,
        stake_registry_addr: stake_registry_addr,
        provider: provider
      }
    end

    @spec query_existing_registered_operator_sockets(t(), non_neg_integer(), non_neg_integer()) ::
    {:ok, %{<<_::256>> => String.t()}} | {:error, term()}
    def query_existing_registered_operator_sockets(%__MODULE__{} = self, start_block, stop_block) do
      query_block_range = 1000

      recursive_query = fn recursive_query, cur_block, operator_socket_map ->
        if cur_block <= stop_block do
          end_block = min(cur_block + query_block_range - 1, stop_block)

          filter =
            Ethers.EventFilter.new(@operator_socket_update_event)
            |> Map.put(:address, self.registry_coordinator_address)
            |> Map.put(:fromBlock, cur_block)
            |> Map.put(:toBlock, end_block)

            case Ethers.get_logs(filter, rpc_opts: [ url: self.provider]) do
              {:ok, logs} ->
                relevant_logs =
                  Enum.reduce(logs, %{}, fn log, temp ->
                    case Ethers.Event.decode(log, @operator_socket_update_event) do
                      %Ethers.Event{data: [operator_id, socket]} when is_binary(operator_id) and byte_size(operator_id) == 32 ->
                        Map.put(temp, operator_id, socket)
                        _ ->
                        temp
                    end
                  end)

                ## logger thingy

                updated_operator_socket_map = Map.merge(operator_socket_map, relevant_logs)

                if end_block >= stop_block or stop_block == 0 do
                  {:ok, updated_operator_socket_map}
                else
                  recursive_query.(recursive_query, end_block + 1, updated_operator_socket_map)
                end

              {:error, reason} ->
                {:error, "Failed to get logs damn: #{inspect(reason)}"}
            end
        else
          {:ok, operator_socket_map}
        end
      end

      recursive_query.(recursive_query, start_block, %{})
    end

  def query_existing_registered_operator_pub_keys(%__MODULE__{} = self, start_block, stop_block) do
    #
  end
  end
