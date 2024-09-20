# EigenlayerEx To-Do List

`eigenlayer-ex` is a set of modules for running an AVS and interacting with EigenLayer contracts.

## quick run 
- clone the repo
- run `mix deps.get`
- run `iex -S mix` to open an interactive elixir shell
- query all available functions of a moduleexample `iex> EigenlayerEx.Contracts.DelegationManager.__info__(:functions)`
                                        `iex(2)> EigenlayerEx.ELContracts.Reader.__info__(:functions)`

## Core Functionality
- [X] Implement ELContracts Reader
- [X] Implement ELContracts Writer
- [X] Implement Hello World AVS in elixir
- [ ] Implement AVSRegistryReader
- [ ] Implement AVSRegistryWriter

## Testing
- [ ] Write tests for ELContracts Reader
- [ ] Write tests for ELContracts Writer
- [ ] Write tests for AVSRegistryReader
- [ ] Write tests for AVSRegistryWriter

## Miscellaneous
- [ ] complete in-code to-do's
- [ ] maybe define custom exceptions and errors specific to EL
- [ ] Set up dev and prod envs in config/

