all:
	cd rust && cargo build --bins && cargo build --release --bins
