defmodule EigenlayerEx.Contracts.ECDSAStakeRegistry do
  use Ethers.Contract,
    abi_file: "lib/contracts/abi/ECDSAStakeRegistry.json"
end
