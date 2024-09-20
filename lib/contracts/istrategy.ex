defmodule EigenlayerEx.Contracts.IStrategy do
  use Ethers.Contract,
    abi_file: "lib/contracts/abi/IStrategy.json"
end
