Mix.install([
  {:req, "~> 0.5.0"},
  {:eddy, "~> 1.0.0"}
])

require Logger

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

    case Req.post!("#{@host}/mempool/add", json: payload) do
      %{body: %{"message" => "transaction added"}} ->
        {:ok, :added}

      %{body: body} ->
        {:error, body}
    end
  end

  def prove(nockma, public_inputs, private_inputs) do
    payload = %{
      program: Base.encode64(nockma),
      public_inputs: public_inputs,
      private_inputs: private_inputs
    }

      case Req.post!("#{@host}/nock/prove", json: payload) do
        %{body: %{"io" => hints, "result" => "error"}} ->
          {:error, :failed_to_prove, hints}

        %{body: %{"io" => hints, "result" => proved}} ->
          {:ok, proved, hints}
      end
  end

  def list_resources do
    Req.get!("#{@host}/indexer/unspent-resources")
    |> Map.get(:body)
    |> Map.get("unspent_resources")
  end
end

resources = Anoma.list_resources()

# -----------------------------------------------------------
# Create a keypair for the user.

# private_key = Eddy.generate_key(encoding: :raw)
# public_key = Eddy.get_pubkey(private_key, encoding: :raw)

private_key =
  <<136, 186, 195, 18, 178, 253, 71, 236, 111, 81, 216, 192, 171, 220, 112, 107, 85, 195, 249, 44,
    160, 149, 65, 210, 226, 199, 235, 217, 99, 50, 142, 88,
    38, 10, 200, 104, 228, 209, 172, 183,
    104, 161, 128, 0, 231, 202, 245, 168, 246, 35, 29, 53, 228, 2, 91, 57, 65, 155, 95, 77, 13,
    212, 65, 82>>

public_key =
  <<38, 10, 200, 104, 228, 209, 172, 183, 104, 161, 128, 0, 231, 202, 245, 168, 246, 35, 29, 53,
    228, 2, 91, 57, 65, 155, 95, 77, 13, 212, 65, 82>>

IO.inspect(private_key, label: "priv key")
IO.inspect(public_key, label: "public key")

private_key2 =
  <<78, 42, 80, 47, 207, 199, 23, 110, 80, 157, 232, 193, 112, 127, 206, 50, 116, 104, 139, 42,
    211, 235, 136, 42, 42, 102, 36, 3, 89, 220, 107, 95>>

public_key2 =
  <<245, 225, 13, 55, 218, 30, 157, 95, 234, 19, 178, 77, 97, 112, 65, 167, 14, 47, 161, 150, 37,
    87, 11, 243, 138, 192, 49, 52, 27, 73, 103, 221>>

# ----------------------------------------------------------------------------
# Prove the logic function for Spacebucks to pass in as argument
Logger.debug("Proving logic")

nockma = File.read!(".compiled/Logic.nockma")

{:ok, compiled_logic, hints} = Anoma.prove(nockma, [], [])

# ----------------------------------------------------------------------------
# Create a transaction that creates our spacebucks
Logger.debug("Creating Spacebuck init transaction")

# read the compiled Spacebuck.nockma file
nockma = File.read!(".compiled/Mint.nockma")

latest_root = Anoma.latest_root()

public_inputs = [
  %{noun: compiled_logic},
  %{raw: Base.encode64(public_key)},
  %{raw: Base.encode64(private_key)},
  %{raw: latest_root}
]

{:ok, transaction, hints} = Anoma.prove(nockma, public_inputs, [])


Enum.each(hints, &IO.puts("hint: #{&1}"))

# ----------------------------------------------------------------------------
# Submit the transaction to the mempool to make the spacebucks appear.
Logger.debug("Submit Spacebuck init transaction")

Anoma.submit_transaction(transaction)
|> tap(fn x -> IO.inspect(x, label: "") end)

# ----------------------------------------------------------------------------
# List all the unspent resources
Logger.debug("Listing resources")

# wait a bit for the block to be created that holds our very new and fresh resource.
# well be rich in a minute.
IO.gets("Continue?\n")

resources = Anoma.list_resources()

# -----------------------------------------------------------
# Transfer to another user.
Logger.debug("Creating Spacebuck transfer transaction")

# read the compiled Spacebuck.nockma file
nockma = File.read!(".compiled/Transfer.nockma")

# latest root
latest_root = Anoma.latest_root()

public_inputs = [
  %{noun: compiled_logic},
  %{raw: Base.encode64(public_key)},
  %{raw: Base.encode64(private_key)},
  %{raw: Base.encode64(public_key2)},
  %{noun: hd(resources)},
  %{raw: latest_root}
]

{:ok, transaction, hints} = Anoma.prove(nockma, public_inputs, [])

Enum.each(hints, &IO.puts("hint: #{&1}"))

# ----------------------------------------------------------------------------
# Submit the transaction to the mempool to make the spacebucks appear.

Logger.debug("Submitting  Spacebuck transfer transaction")

IO.puts("submitting transfer transaction")

Anoma.submit_transaction(transaction)
|> tap(fn x -> IO.inspect(x, label: "") end)
