Mix.install([
  {:req, "~> 0.5.0"},
  {:eddy, "~> 1.0.0"}
])

host = "http://localhost:4000"

defmodule Anoma do
  @host "http://localhost:4000"

  def latest_root do
    Req.get!("#{@host}/indexer/root")
    |> Map.get(:body)
    |> Map.get("root")
  end

  def submit_transaction(transaction) do
    payload = %{transaction: transaction, transaction_type: "transparent_resource", wrap: false}

    %{body: %{"message" => "transaction added"}} =
      Req.post!("#{@host}/mempool/add", json: payload)

    :ok
  end

  def prove(nockma, public_inputs, private_inputs) do
    payload = %{
      program: Base.encode64(nockma),
      public_inputs: public_inputs,
      private_inputs: private_inputs
    }

    %{body: %{"io" => hints, "result" => proved}} =
      Req.post!("#{@host}/nock/prove", json: payload)

    hints =
      hints
      |> Enum.map(&Base.decode64!/1)

    {:ok, proved, hints}
  end

  def list_resources do
    Req.get!("#{@host}/indexer/unspent-resources")
    |> Map.get(:body)
    |> Map.get("unspent_resources")
  end
end

# -----------------------------------------------------------
# Create a keypair for the user.

# private_key = Eddy.generate_key(encoding: :raw)
# public_key = Eddy.get_pubkey(private_key, encoding: :raw)

private_key =
  <<136, 186, 195, 18, 178, 253, 71, 236, 111, 81, 216, 192, 171, 220, 112, 107, 85, 195, 249, 44,
    160, 149, 65, 210, 226, 199, 235, 217, 99, 50, 142, 88, 38, 10, 200, 104, 228, 209, 172, 183,
    104, 161, 128, 0, 231, 202, 245, 168, 246, 35, 29, 53, 228, 2, 91, 57, 65, 155, 95, 77, 13,
    212, 65, 82>>

# iex(9)> Noun.Jam.jam([" " | private_key]) |> IO.inspect(limit: :infinity)
# <<65, 65, 0, 254, 35, 234, 14, 75, 200, 246, 31, 177, 191, 69, 97, 3, 175, 114,
# 195, 173, 85, 13, 231, 179, 128, 86, 6, 73, 139, 31, 175, 103, 143, 201, 56,
# 98, 153, 40, 32, 163, 145, 71, 179, 222, 162, 133, 2, 2, 156, 43, 215, 163,
# 218, 143, 116, 212, 144, 11, 108, 229, 4, 109, 126, 53, 53, 80, 7, 73, 1>>

public_key =
  <<38, 10, 200, 104, 228, 209, 172, 183, 104, 161, 128, 0, 231, 202, 245, 168, 246, 35, 29, 53,
    228, 2, 91, 57, 65, 155, 95, 77, 13, 212, 65, 82>>

IO.inspect(private_key, label: "priv key")
IO.inspect(public_key, label: "public key")

# private_key2 =
#   <<78, 42, 80, 47, 207, 199, 23, 110, 80, 157, 232, 193, 112, 127, 206, 50, 116, 104, 139, 42,
#     211, 235, 136, 42, 42, 102, 36, 3, 89, 220, 107, 95>>

# public_key2 =
#   <<245, 225, 13, 55, 218, 30, 157, 95, 234, 19, 178, 77, 97, 112, 65, 167, 14, 47, 161, 150, 37,
#     87, 11, 243, 138, 192, 49, 52, 27, 73, 103, 221>>

# IO.inspect(private_key, label: "priv key2")
# IO.inspect(public_key, label: "public key2")

# ----------------------------------------------------------------------------
# Prove the logic function for Spacebucks to pass in as argument

nockma = File.read!(".compiled/Test.nockma")

# public_inputs = [
#   %{raw: Base.encode64(<<16, 6>>)},
#   %{raw: Base.encode64(private_key)},
#   %{raw: Base.encode64(public_key)}
# ]

public_inputs = [
  # %{
  #   noun:
  #     Base.encode64(
  #       <<65, 65, 0, 254, 35, 234, 14, 75, 200, 246, 31, 177, 191, 69, 97, 3, 175, 114, 195, 173,
  #         85, 13, 231, 179, 128, 86, 6, 73, 139, 31, 175, 103, 143, 201, 56, 98, 153, 40, 32, 163,
  #         145, 71, 179, 222, 162, 133, 2, 2, 156, 43, 215, 163, 218, 143, 116, 212, 144, 11, 108,
  #         229, 4, 109, 126, 53, 53, 80, 7, 73, 1>>
  #     )
  # },
  # %{raw: Base.encode64(private_key)}
]

{:ok, compiled_logic, hints} = Anoma.prove(nockma, public_inputs, [])

IO.inspect(compiled_logic)
Enum.each(hints, &IO.puts("hint: #{&1}"))
raise "done"
# ----------------------------------------------------------------------------
# Prove the logic function for Spacebucks to pass in as argument

nockma = File.read!(".compiled/Logic.nockma")

{:ok, compiled_logic, hints} = Anoma.prove(nockma, [], [])

# ----------------------------------------------------------------------------
# Create a transaction that creates our spacebucks

# read the compiled Spacebuck.nockma file
nockma = File.read!(".compiled/Spacebuck.nockma")

latest_root = Anoma.latest_root()

public_inputs = [
  %{noun: compiled_logic},
  %{raw: Base.encode64(public_key)},
  %{raw: Base.encode64(private_key)},
  %{raw: latest_root}
]

{:ok, transaction, hints} =  Anoma.prove(nockma, public_inputs, [])

Enum.each(hints, &IO.puts("hint: #{inspect &1}"))
# # ----------------------------------------------------------------------------
# # Submit the transaction to the mempool to make the spacebucks appear.

# :ok = Anoma.submit_transaction(transaction) |> tap(fn x -> IO.inspect(x, label: "transaction result") end)

# # ----------------------------------------------------------------------------
# # List all the unspent resources

# # wait a bit for the block to be created that holds our very new and fresh resource.
# # well be rich in a minute.
# Process.sleep(1000)

# resources = Anoma.list_resources()

# # -----------------------------------------------------------
# # Transfer to another user.

# IO.puts("doing transfer")
# # read the compiled Spacebuck.nockma file
# nockma = File.read!(".compiled/Transfer.nockma")

# # latest root
# latest_root = Anoma.latest_root()

# public_inputs = [
#   %{noun: compiled_logic},
#   %{raw: Base.encode64(public_key2)},
#   %{raw: Base.encode64(private_key2)},
#   %{raw: Base.encode64(public_key2)},
#   %{noun: hd(resources)},
#   %{raw: latest_root}
# ]

# {:ok, transaction, hints} = Anoma.prove(nockma, public_inputs, [])

# IO.inspect(hints, label: "transfer.nockma hints")
# # ----------------------------------------------------------------------------
# # Submit the transaction to the mempool to make the spacebucks appear.

# :ok = Anoma.submit_transaction(transaction)
