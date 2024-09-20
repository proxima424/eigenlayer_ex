defmodule EigenlayerEx.Contracts.ISlasher do
  use Ethers.Contract,
    abi_file: "lib/contracts/abi/ISlasher.json"
end
