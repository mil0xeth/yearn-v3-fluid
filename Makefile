-include .env

# deps
update:; forge update
build  :; forge build
size  :; forge build --sizes

# storage inspection
inspect :; forge inspect ${contract} storage-layout --pretty

# mainnet:
test  :; forge test -vv --evm-version shanghai
trace  :; forge test -vvv --evm-version shanghai
gas  :; forge test --gas-report
test-contract  :; forge test -vv --match-contract $(contract) --evm-version shanghai
test-contract-gas  :; forge test --gas-report --match-contract ${contract}
trace-contract  :; forge test -vvv --match-contract $(contract) --evm-version shanghai
test-test  :; forge test -vv --match-test $(test)
trace-test  :; forge test -vvv --match-test $(test)
coverage :; forge coverage --evm-version shanghai
coverage-report :; forge coverage --report lcov --evm-version shanghai

clean  :; forge clean
snapshot :; forge snapshot