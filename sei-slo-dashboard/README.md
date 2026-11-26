# Sei SLO Grafana Dashboard

This directory is a portable export of the Sei SLO dashboard. It is intended for operators who want to import the dashboard into their own Grafana and point it at their own Prometheus data.

## Files

- `sei_slo.json`: Grafana dashboard JSON.
- `recording_rules.yaml`: Prometheus recording rules required by the dashboard SLO panels.

## Import Steps

1. Add `recording_rules.yaml` to your Prometheus rule files and reload Prometheus.
2. Import `sei_slo.json` into Grafana.
3. In the dashboard variables, choose your Prometheus datasource.
4. Set `validator_component` and `webapp_component` if your Prometheus labels differ from the defaults.
5. Select one or more `chain_id` values from the dashboard variable.

No rewrite script is required for `id` or datasource UID. The dashboard has `id: null`, which lets Grafana assign the local ID at import time, and all Prometheus panels use the `datasource` dashboard variable instead of a fixed datasource UID.

## Local Import Test

To verify that Grafana accepts the dashboard JSON, run:

```bash
./test_import.sh
```

The script starts a disposable Grafana 12.0.0 container on `http://127.0.0.1:13000`, creates a dummy Prometheus datasource, imports `sei_slo.json`, fetches it back by UID, and prints the local dashboard URL. It does not require a running Prometheus server because the test only validates Grafana import/storage.

Set `PORT=...` to use a different local port, or `KEEP_RUNNING=0` to stop Grafana after the import check.

## Required Prometheus Data

The dashboard expects these raw metrics, all served by seid on its Prometheus endpoint (`:26660/metrics` by default):

- `tendermint_consensus_latest_block_height`
- `tendermint_consensus_block_interval_seconds_bucket`
- `tendermint_consensus_block_interval_seconds_count`
- `tendermint_consensus_propose_latency_bucket`
- `sei_chain_tx_duration_seconds_count`
- `sei_chain_run_msg_latency_seconds_count`
- `sei_chain_cosmos_validators_missed_blocks`
- `sei_chain_cosmos_params_signed_blocks_window`
- `sei_chain_cosmos_validators_active`
- `sei_chain_cosmos_validators_jailed`

The `sei_chain_cosmos_*` series are reported by seid itself from v6.8.0, but only when the `[cosmos_metrics]` section of `app.toml` has `enabled = true`; it is off by default. Enable it on the nodes behind the `validators` and `webapp` components. Nodes on an older release, or with the section off, can keep running the external `sei-cosmos-exporter`: the validator rules and the jailed panel fall back to its unprefixed `cosmos_*` names when a node reports no native series.

The useful labels are `chain_id`, `component`, `moniker`, `address`, `pubkey_hash`, `proposer_address`, and `mode`. seid adds `chain_id` to its `sei_chain_*` series itself. If your scrape jobs use different label names or component values, update `recording_rules.yaml` and the matching Grafana variables.

## Recording Rules

The included rules generate the SLO series used by the dashboard:

- `blocks_per_second`
- `slo_consensus_block_speed_*`
- `slo_blocks_per_second_*`
- `block_miss_percentage_sliding_window`
- `validator_propose_latency`
- `slo_block_miss_*`
- `slo_validator_proposal_latency_*`

## Notes

The Prometheus rules still assume the default component labels `validators` and `webapp`. If your metrics use different values, replace those strings in `recording_rules.yaml` before loading the rules.
