defmodule EigenlayerEx.Contracts.DelegationManager do
  use Ethers.Contract,
    abi_file: "lib/contracts/abi/DelegationManager.json"
end
