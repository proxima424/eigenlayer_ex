defmodule EigenlayerEx.Proxima do
  require Logger

  alias EigenlayerEx.ELContracts.Writer, as: ELChainWriter
  alias EigenlayerEx.ELContracts.Reader, as: ELChainReader
  alias EigenlayerEx.Operator, as: Operator
  alias Ethers.Types
  alias ExSecp256k1
  alias EigenlayerEx.Contracts.ECDSAStakeRegistry

  @zero_address "0x0000000000000000000000000000000000000000"
  @default_slasher @zero_address
  @default_strategy @zero_address


  def fuck_off do

    Logger.info("Fuck off")
    IO.puts("Fuck off")

    operator_private_key = System.get_env("OPERATOR_PRIVATE_KEY")
    IO.puts("private key: #{operator_private_key}")

    rpc_url = System.get_env("RPC_PROVIDER")
    IO.puts("rpc url: #{rpc_url}")

    avs_service_manager = Ethers.Utils.to_checksum_address(System.get_env("HELLO_WORD_SERVICE_MANAGER"))
    IO.puts("AVS addresss: #{avs_service_manager}")

    weth_address = Ethers.Utils.to_checksum_address(System.get_env("WETH_ADDRESS"))
    IO.puts("WETH address: #{weth_address}")

    avs_directory = Ethers.Utils.to_checksum_address(System.get_env("AVS_DIRECTORY"))
    IO.puts("AVS Directory: #{avs_directory}")

    delegation_manager = Ethers.Utils.to_checksum_address(System.get_env("DELEGATION_MANAGER"))
    IO.puts("Delegation Manager: #{delegation_manager}")

    slasher = Ethers.Utils.to_checksum_address(System.get_env("SLASHER"))
    IO.puts("Slasher: #{slasher}")

    strategy_manager = Ethers.Utils.to_checksum_address(System.get_env("STRATEGY_MANAGER"))
    IO.puts("Strategy Manager: #{strategy_manager}")

    stake_registry = Ethers.Utils.to_checksum_address(System.get_env("STAKE_REGISTRY"))
    IO.puts("Stake Registry: #{stake_registry}")
    logger = Logger

    # create el chain reader instance
    el_chain_reader = ELChainReader.new(
      logger,
      "0x0000000000000000000000000000000000000000",
      delegation_manager,
      avs_directory,
      rpc_url
    )

    # create el chain writer instance
    el_chain_writer = ELChainWriter.new(
      delegation_manager,
      "0x0000000000000000000000000000000000000000",
      el_chain_reader,
      rpc_url,
      operator_private_key
    )

    # private key is in hex encoded format
    # have to get public address using Ethers
    wallet_address = case Ethers.Signer.Local.accounts(private_key: operator_private_key) do
      {:ok, [address | _]} ->
        Ethers.Utils.to_checksum_address(address)
      {:error, reason} ->
        IO.puts("damn: #{inspect(reason)}")
        nil
    end

    if wallet_address do
      IO.puts("Wallet address: #{wallet_address}")
    else
      IO.puts("Failed to get wallet address")
    end


    # create operator struct
    operator_struct = Operator.new(
      wallet_address,
      wallet_address,
      "0x0000000000000000000000000000000000000000",
      0,
      "nil"
    )

    # call elcontracts writer to register_as_operator
    # only need to do this once
    # {:ok, tx_hash} = ELChainWriter.register_as_operator(el_chain_writer, operator_struct)
    # IO.puts("tx hash bro this works maybe: #{tx_hash}")

    # reader, operator, avs, salt, expiry
    # declare salt and expiry
    # salt is of the type <<_::256>>
    salt = :crypto.strong_rand_bytes(32)
    now = System.system_time(:second)
    expiry = now + 3600

    # need to generate digest hash to be signed
    # digest hash is in binaries
    {:ok, digest_hash} = ELChainReader.calculate_operator_avs_registration_digest_hash(el_chain_reader, wallet_address, avs_service_manager, salt, expiry)
    formatted_hash = Base.encode16(digest_hash, case: :lower)
    formatted_private_key = operator_private_key |> Base.decode16!(case: :mixed)
    IO.puts("formatted private key: #{inspect(formatted_private_key)}")
    IO.puts("digest hash: #{formatted_hash}")

    # accepts both as binaries
    # raw_signature is { binary, binary, non-negative integer }
    {:ok,raw_signature} = ExSecp256k1.sign(digest_hash, formatted_private_key)
    IO.puts("raw signature: #{inspect(raw_signature)}")

    signature_bytes = convert_signature_to_bytes(raw_signature)
    signature_bytes_length = byte_size(signature_bytes)

    IO.puts("Length of signature bytes: #{signature_bytes_length}")
    IO.puts("signature bytes: #{inspect(Base.encode16(signature_bytes, case: :lower))}")

    # pass this signature bytes to struct
    signature_with_salt_and_expiry = {
      signature_bytes,
      salt,  # Assuming salt is already a 32-byte binary
      expiry  # This should be a regular integer
    }

   case ELChainReader.is_operator_registered(el_chain_reader,wallet_address) do
     {:ok, answer } ->
      IO.puts("Operator is registered bool: #{answer}")
     {:error, reason} ->
      IO.puts("Error wtf : #{inspect(reason)}")
   end

    # case ECDSAStakeRegistry.register_operator_with_signature(signature_with_salt_and_expiry, wallet_address )
    # |> Ethers.send([
    #   from: wallet_address,
    #   to: stake_registry,
    #   rpc_opts: [url: rpc_url],
    #   signer: Ethers.Signer.Local,
    #   signer_opts: [private_key: operator_private_key]
    # ]) do
    #   {:ok, tx_hash} ->
    #     IO.puts("tx hash: #{tx_hash}")
    #   {:error, reason} ->
    #     IO.puts("Error: #{inspect(reason)}")
    # end


  end

  defp pad_to_32_bytes(binary) do
    case byte_size(binary) do
      32 -> binary
      size when size < 32 -> String.pad_leading(binary, 32, <<0>>)
      _ -> binary |> binary_part(0, 32)
    end
  end

  defp format_address(address) when is_binary(address) do
    address
    |> String.trim_leading("0x")
    |> String.downcase()
    |> String.pad_leading(40, "0")
    |> (fn addr -> "0x" <> addr end).()
  end

  def convert_signature_to_bytes({r, s, v}) do
    r_bytes = pad_to_32_bytes(r)
    s_bytes = pad_to_32_bytes(s)
    v_byte = :binary.encode_unsigned(v)

    r_bytes <> s_bytes <> v_byte
  end

end
