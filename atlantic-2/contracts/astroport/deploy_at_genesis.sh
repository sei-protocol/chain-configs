#!/usr/bin/env bash

set -eu

if [ $# -lt 1 ]; then
	echo "Dependencies: jq"
	echo "Astroport contracts wasm files must be in ./artifacts"
	echo "Usage: $0 [node_executable_name]"
	echo "Flags:
	--awm		use add-wasm-message command instead of add-wasm-genesis-message
	--track_lp	Track user LP token balances
	-r string	Register native token precisions (optional, e. g. -r '[[\"ustake\", 6],..]' )"
	exit 1
fi

wasmd=$1
shift

awm=false
track_lp=false
register_coin_precisions=

while [ $# -gt 0 ]; do
	case $1 in
	--awm)
		awm=true
		shift
		;;
	--track_lp)
		track_lp=true
		shift
		;;
	-r)
		register_coin_precisions=$2
		shift
		shift
		;;
	*)
		echo "Parameter $1 is wrong"
		exit 1
		;;
	esac
done

pubkey='{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"AwXTNYpzNCDfRu9Gx2RxPTSY27GRxnOCPNNrJ18IiH4P"}'

echo 'Adding Astroport key...'
$wasmd keys add astroport --pubkey $pubkey

if [ $awm == "true" ]; then
	wasm_genesis=add-wasm-message
else
	wasm_genesis=add-wasm-genesis-message
fi

get_latest_code_id() {
	$wasmd $wasm_genesis list-codes | jq '.[. | length - 1].code_id'
}

get_latest_contract_address() {
	$wasmd $wasm_genesis list-contracts | jq -r '.[. | length - 1].contract_address'
}

echo 'Getting address from Astroport key...'
owner=$($wasmd keys show -a astroport)
echo "Astroport account address: $owner"

echo 'Adding Astroport account to genesis...'
$wasmd add-genesis-account $owner ''

# Token
echo 'Storing Astroport token code...'
if [ $track_lp == "true" ]; then
	$wasmd $wasm_genesis store artifacts/astroport_xastro_token.wasm --run-as astroport
else
	$wasmd $wasm_genesis store artifacts/astroport_token.wasm --run-as astroport
fi
token_code=$(get_latest_code_id)
echo "Astroport token code id: $token_code"

# XYK pair
echo 'Storing Astroport XYK pair code...'
$wasmd $wasm_genesis store artifacts/astroport_pair.wasm --run-as astroport
xyk_code=$(get_latest_code_id)
echo "Astroport XYK pair code id: $xyk_code"

# Stable pair
echo 'Storing Astroport Stable pair code...'
$wasmd $wasm_genesis store artifacts/astroport_pair_stable.wasm --run-as astroport
pair_stable_code=$(get_latest_code_id)
echo "Astroport Stable pair code id: $pair_stable_code"

# Generator
echo 'Storing Astroport Generator code...'
$wasmd $wasm_genesis store artifacts/astroport_generator.wasm --run-as astroport
generator_code=$(get_latest_code_id)
echo "Astroport Generator code id: $generator_code"

# Vesting
echo 'Storing Astroport Vesting code...'
$wasmd $wasm_genesis store artifacts/astroport_vesting.wasm --run-as astroport
vesting_code=$(get_latest_code_id)
echo "Astroport Vesting code id: $vesting_code"

# Maker
echo 'Storing Astroport Maker code...'
$wasmd $wasm_genesis store artifacts/astroport_maker.wasm --run-as astroport
maker_code=$(get_latest_code_id)
echo "Astroport Maker code id: $maker_code"

# Satellite
echo 'Storing Astroport Satellite code...'
$wasmd $wasm_genesis store artifacts/astroport_satellite.wasm --run-as astroport
satellite_code=$(get_latest_code_id)
echo "Astroport Satellite code id: $satellite_code"

# Native coin registry
echo 'Storing Astroport native coin registry code...'
$wasmd $wasm_genesis store artifacts/astroport_native_coin_registry.wasm --run-as astroport
registry_code=$(get_latest_code_id)
echo "Astroport native coin registry code id: $registry_code"

echo 'Instantiating Astroport native coin registry...'
registry_msg='{"owner": "'$owner'"}'
$wasmd $wasm_genesis instantiate-contract $registry_code "$registry_msg" --label "Astroport Native Coin Registry" --run-as astroport --admin "$owner"
registry_address=$(get_latest_contract_address)
echo "Astroport native coin registry address: $registry_address"

if [ "$register_coin_precisions" ]; then
	echo 'Registering native coin precisions...'
	registry_add_coins_msg='{
	"add": {
		"native_coins": '$register_coin_precisions'
	}
}'
	$wasmd $wasm_genesis execute $registry_address "$registry_add_coins_msg" --run-as astroport
fi

# Factory
echo 'Storing Astroport Factory code...'
$wasmd $wasm_genesis store artifacts/astroport_factory.wasm --run-as astroport
factory_code=$(get_latest_code_id)
echo "Astroport Factory code id: $factory_code"

echo 'Instantiating Astroport Factory...'
factory_msg='
{
	"pair_configs": [
		{
			"code_id": '$xyk_code',
			"pair_type": {
				"xyk": {}
			},
			"total_fee_bps": 30,
			"maker_fee_bps": 3333,
			"is_disabled": false,
			"is_generator_disabled": false
		},
		{
			"code_id": '$pair_stable_code',
			"pair_type": {
				"stable": {}
			},
			"total_fee_bps": 5,
			"maker_fee_bps": 5000,
			"is_disabled": false,
			"is_generator_disabled": false
		}
	],
	"token_code_id": '$token_code',
	"owner": "'$owner'",
	"whitelist_code_id": '0',
	"coin_registry_address": "'$registry_address'"
}'

$wasmd $wasm_genesis instantiate-contract $factory_code "$factory_msg" --label "Astroport Factory" --run-as astroport --admin $owner
factory_address=$(get_latest_contract_address)
echo "Astroport Factory address: $factory_address"

# Router
echo 'Storing Astroport Router code...'
$wasmd $wasm_genesis store artifacts/astroport_router.wasm --run-as astroport
router_code=$(get_latest_code_id)
echo "Astroport Router code id: $router_code"

echo 'Instantiating Astroport Router...'
router_msg='{
	"astroport_factory": "'$factory_address'"
}'

$wasmd $wasm_genesis instantiate-contract $router_code "$router_msg" --label "Astroport Router" --run-as astroport --admin $owner
router_address=$(get_latest_contract_address)
echo "Astroport Router address: $router_address"
