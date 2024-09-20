defmodule EigenlayerEx.Operator do
  alias Ethers.Types

  @type t :: %__MODULE__{
    address: Types.t_address(),
    earnings_receiver_address: Types.t_address(),
    delegation_approver_address: Types.t_address(),
    staker_opt_out_window_blocks: non_neg_integer(),
    metadata_url: String.t() | nil
  }

  @enforce_keys [:address, :earnings_receiver_address, :delegation_approver_address, :staker_opt_out_window_blocks]
  defstruct [:address, :earnings_receiver_address, :delegation_approver_address, :staker_opt_out_window_blocks, :metadata_url]

  @spec new(Types.t_address(), Types.t_address(), Types.t_address(), non_neg_integer(), String.t() | nil) :: t()
  def new(address, earnings_receiver_address, delegation_approver_address, staker_opt_out_window_blocks, metadata_url \\ nil) do
    %__MODULE__{
      address: address,
      earnings_receiver_address: earnings_receiver_address,
      delegation_approver_address: delegation_approver_address,
      staker_opt_out_window_blocks: staker_opt_out_window_blocks,
      metadata_url: metadata_url
    }
  end

end
