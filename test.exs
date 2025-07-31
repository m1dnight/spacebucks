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
    160, 149, 65, 210, 226, 199, 235, 217, 99, 50, 142, 88, 38, 10, 200, 104, 228, 209, 172, 183,
    104, 161, 128, 0, 231, 202, 245, 168, 246, 35, 29, 53, 228, 2, 91, 57, 65, 155, 95, 77, 13,
    212, 65, 82>>

public_key =
  <<38, 10, 200, 104, 228, 209, 172, 183, 104, 161, 128, 0, 231, 202, 245, 168, 246, 35, 29, 53,
    228, 2, 91, 57, 65, 155, 95, 77, 13, 212, 65, 82>>


nockma = File.read!(".compiled/Test.nockma")

{:ok, result, hints} = Anoma.prove(nockma, [], [])


Enum.each(hints, &IO.puts("hint: #{&1}"))
