import Config

config :ethers,
  rpc_client: Ethereumex.HttpClient, # Defaults to: Ethereumex.HttpClient
  keccak_module: ExKeccak, # Defaults to: ExKeccak
  json_module: Jason, # Defaults to: Jason
  secp256k1_module: ExSecp256k1, # Defaults to: ExSecp256k1
  default_signer: nil, # Defaults to: nil, see Ethers.Signer for more info
  default_signer_opts: [] # Defaults to: []

# we don't need this
config :ethereumex, url: "https://eth-mainnet.public.blastapi.io"
# Configure logging level for Ethereumex
config :logger, :console, sync: true, level: :info
