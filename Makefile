# Makefile for compiling Juvix files

# Define directories
COMPILED_DIR := .compiled
SRC_DIR := Spacebucks

# Find all Juvix source files in the current directory
JUVIX_FILES := $(wildcard $(SRC_DIR)/*.juvix)

# Define output files by replacing .juvix with .nockma and moving to .compiled/
NOCKMA_FILES := $(patsubst $(SRC_DIR)/%.juvix,$(COMPILED_DIR)/%.nockma,$(JUVIX_FILES))

# Rule for compiling a single Juvix file to .compiled/file.nockma
$(COMPILED_DIR)/%.nockma: $(SRC_DIR)/%.juvix
	@mkdir -p $(COMPILED_DIR)
	juvix compile anoma $< -o $@

# remove all compiled files
clean:
	rm -rf $(COMPILED_DIR)
	juvix clean

# run the example
run: .compiled/Spacebuck.nockma .compiled/GetMessage.nockma .compiled/Logic.nockma
	elixir run.exs

# Add .PHONY to specify targets that don't represent files
.PHONY: clean run