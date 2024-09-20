defmodule EigenlayerEx.Contracts.OperatorStateRetriever do
  @moduledoc """
  Documentation for `OperatorStateRetriever`.
  """
  use Ethers.Contract,
    abi_file: "lib/contracts/abi/OperatorStateRetriever.json"
end
