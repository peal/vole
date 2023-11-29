ifeq (, $(shell which cargo))
 $(error "No rust compiler (cargo) in path, please install. See https://rustup.rs/ , or run the following command: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh")
 endif

all:
	cd rust && cargo build --bins && cargo build --release --bins

doc:
	../../gap -A -q -r --quitonbreak makedoc.g
# We should really go and find gap 'properly', but this is just for doc building

.PHONY: doc
