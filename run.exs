Mix.install([
  {:req, "~> 0.5.0"},
  {:eddy, "~> 1.0.0"}
])

host = "http://localhost:4000"

# -----------------------------------------------------------
# Create a keypair for the user.

private_key = Eddy.generate_key(encoding: :raw)
public_key = Eddy.get_pubkey(private_key, encoding: :raw)

IO.inspect(private_key, label: "priv key")
IO.inspect(public_key, label: "public key")
# ----------------------------------------------------------------------------
# Prove the logic function for Spacebucks to pass in as argument

nockma = File.read!(".compiled/Logic.nockma")

# run the nock code in the client by submitting it
payload = %{program: Base.encode64(nockma)}

%{body: %{"io" => hints, "result" => compiled_logic}} =
  Req.post!("#{host}/nock/prove", json: payload)

hints
|> Enum.map(&Base.decode64!/1)
|> Enum.each(&IO.inspect(&1, label: "logic.nockma hint: "))

# ----------------------------------------------------------------------------
# Create a transaction that creates our spacebucks

# read the compiled Spacebuck.nockma file
nockma = File.read!(".compiled/Spacebuck.nockma")

# run the nock code in the client by submitting it
payload = %{
  program: Base.encode64(nockma),
  public_inputs: [
    %{noun: compiled_logic},
    %{raw: Base.encode64(public_key)},
    %{raw: Base.encode64(private_key)}
  ]
}

%{body: %{"io" => hints, "result" => transaction}} =
  Req.post!("#{host}/nock/prove", json: payload)

hints
|> Enum.map(&Base.decode64!/1)
|> Enum.each(&IO.inspect(&1, label: "spacebuck.nockma hint: "))

# ----------------------------------------------------------------------------
# Submit the transaction to the mempool to make the spacebucks appear.

payload = %{transaction: transaction, transaction_type: "transparent_resource", wrap: false}

%{body: %{"message" => "transaction added"}} = Req.post!("#{host}/mempool/add", json: payload)

# # ----------------------------------------------------------------------------
# # List all the unspent resources

# # wait a bit for the block to be created that holds our very new and fresh resource.
# # well be rich in a minute.
# Process.sleep(5000)

# %{body: %{"unspent_resources" => [resource]}} = Req.get!("#{host}/indexer/unspent-resources")

# # ----------------------------------------------------------------------------
# # Get the label from our resource

# nockma = File.read!(".compiled/GetMessage.nockma")

# # run the nock code in the client by submitting it
# payload = %{program: Base.encode64(nockma), public_inputs: [resource]}
# %{body: %{"io" => _hints, "result" => label}} = Req.post!("#{host}/nock/prove", json: payload)

# # the label is a base64 encoded, jammed, noun.
# # To turn it into a string we need nock, which we don't have.
# # Trust me when I tell you that the binary should be
# # `<<0, 73, 164, 50, 54, 182, 55, 144, 171, 55, 57, 54, 178, 16, 5>>`
# IO.inspect(Base.decode64!(label))
