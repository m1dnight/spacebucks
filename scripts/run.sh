#!/bin/bash

# run all commands in the root directory of this repository
root_dir=$(dirname $(dirname -- "$(readlink -f -- "$BASH_SOURCE")"))
cd "${root_dir}"


#-----------------------------------------------------------
# Check that all setup has been done.

if [ ! -d "anoma" ]; then
  echo "anoma directory does exist. run ./scripts/setup.sh"
fi


if [ ! -f "bin/juvix" ]; then
  echo "juvix compiler does exist, run ./scripts/setup.sh"
fi


#-----------------------------------------------------------
# Run the controller and open up a tmux

tmux new-session -d -s anoma

# Rename the first window
tmux rename-window -t anoma:0 'phoenix-dev'

# Split the window horizontally
tmux split-window -h -t anoma:0

# In the left pane, start the Phoenix server
tmux send-keys -t anoma:0.0 'cd anoma && iex -S mix phx.server' C-m
tmux send-keys -t anoma:0.0 'Logger.configure(level: :debug)' C-m
tmux send-keys -t anoma:0.0 'client = Anoma.Client.Examples.EClient.create_example_client()' C-m
tmux send-keys -t anoma:0.0 'kudos = Anoma.Client.Examples.Apps.Kudos.setup(client)' C-m

# The right pane will be in the root folder (it is by default)
# No need to do anything special here

tmux send-keys -t anoma:0.1 'export PATH="bin:$PATH"' C-m

# Attach to the tmux session
tmux attach-session -t anoma