# Sei SLO Grafana Dashboard

This directory is a portable export of the Sei SLO dashboard. It is intended for operators who want to import the dashboard into their own Grafana and point it at their own Prometheus data.

## Files

- `sei_slo.json`: Grafana dashboard JSON.
- `recording_rules.yaml`: Prometheus recording rules required by the dashboard SLO panels.

## What Was Generalized

The internal dashboard had a few repo-local values that should not be published as-is:

- Grafana datasource UID `PBFA97CFB590B2093` was replaced with a dashboard variable named `datasource`.
- Dashboard `id` was set to `null`, and dashboard `uid` was changed to `sei-slo`.
- The default `chain_id` value `pacific-1` was removed. The dashboard now discovers chain IDs from `tendermint_consensus_latest_block_height`.
- `chain_id="$chain_id"` selectors were changed to regex selectors so `All` and multi-chain selections work.
- Hardcoded component labels are exposed as dashboard variables:
  - `validator_component`, default `validators`
  - `webapp_component`, default `webapp`
- The public copy fixes the blocks-per-second 7-day panel to query `slo_blocks_per_second_7d`.

## Import Steps

1. Add `recording_rules.yaml` to your Prometheus rule files and reload Prometheus.
2. Import `sei_slo.json` into Grafana.
3. In the dashboard variables, choose your Prometheus datasource.
4. Set `validator_component` and `webapp_component` if your Prometheus labels differ from the defaults.
5. Select one or more `chain_id` values from the dashboard variable.

## Required Prometheus Data

The dashboard expects these raw metrics:

- `tendermint_consensus_latest_block_height`
- `tendermint_consensus_block_interval_seconds_bucket`
- `tendermint_consensus_block_interval_seconds_count`
- `sei_cosmos_throughput_transaction_count`
- `sei_cosmos_throughput_message_count`
- `cosmos_validators_missed_blocks`
- `cosmos_params_signed_blocks_window`
- `cosmos_validators_active`
- `tendermint_consensus_propose_latency_bucket`
- `cosmos_validators_jailed`

The useful labels are `chain_id`, `component`, `moniker`, `address`, `pubkey_hash`, `proposer_address`, and `mode`. If your exporters use different label names or component values, update `recording_rules.yaml` and the matching Grafana variables.

## Recording Rules

The included rules generate the SLO series used by the dashboard:

- `blocks_per_second`
- `slo_consensus_block_speed_*`
- `slo_blocks_per_second_*`
- `block_miss_percentage_sliding_window`
- `validator_propose_latency`
- `slo_block_miss_*`
- `slo_validator_proposal_latency_*`

The price update table depends on `slo_price_update_*{chain_id,denom}` series. Those rules were not present next to the original dashboard in this repo, so they are not included here. If you do not publish price update SLO metrics, remove or hide the "Price Update SLO" panel.

## Notes

The Prometheus rules still assume the default component labels `validators` and `webapp`. If your metrics use different values, replace those strings in `recording_rules.yaml` before loading the rules.
