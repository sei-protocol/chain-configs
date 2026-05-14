# Becoming A Validator
**How to validate on the Sei Testnet**
*This is the Sei Testnet-1 (sei-testnet-1)*

> Genesis [Published](https://github.com/sei-protocol/testnet/blob/main/sei-testnet-1/genesis.json)

> Peers [Published](https://github.com/sei-protocol/testnet/blob/main/sei-testnet-1/addrbook.json)

## Hardware Requirements
**Minimum**
* 8 GB RAM
* 100 GB NVME SSD
* 3.2 GHz x4 CPU

**Recommended**
* 16 GB RAM
* 500 GB NVME SSD
* 4.2 GHz x6 CPU

## Operating System

> Linux (x86_64) or Linux (amd64) Reccomended Arch Linux

**Dependencies**
> Prerequisite: go1.18+ required.
* Arch Linux: `pacman -S go`
* Ubuntu: `sudo snap install go --classic`

> Prerequisite: git.
* Arch Linux: `pacman -S git`
* Ubuntu: `sudo apt-get install git`

> Optional requirement: GNU make.
* Arch Linux: `pacman -S make`
* Ubuntu: `sudo apt-get install make`

## Seid Installation Steps

**Clone git repository**

```bash
git clone https://github.com/sei-protocol/sei-chain
cd sei-chain
git checkout origin/1.0.1beta-upgrade
make install
mv $HOME/go/bin/seid /usr/bin/
```
**Generate keys**

* `seid keys add [key_name]`

* `seid keys add [key_name] --recover` to regenerate keys with your mnemonic

* `seid keys add [key_name] --ledger` to generate keys with ledger device

## Validator setup instructions

* Install seid binary

* Initialize node: `seid init <moniker> --chain-id sei-testnet-1`

* Download the Genesis file: `https://github.com/sei-protocol/testnet/raw/main/sei-testnet-1/genesis.json -P $HOME/.sei/config/`

* Start seid by creating a systemd service to run the node in the background
`nano /etc/systemd/system/seid.service`
> Copy and paste the following text into your service file. Be sure to edit as you see fit.

```bash
[Unit]
Description=Sei-Network Node
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/
ExecStart=/root/go/bin/seid start
Restart=on-failure
StartLimitInterval=0
RestartSec=3
LimitNOFILE=65535
LimitMEMLOCK=209715200

[Install]
WantedBy=multi-user.target
```
## Start the node
* Reload the service files: `sudo systemctl daemon-reload`
* Create the symlinlk: `sudo systemctl enable seid.service`
* Start the node sudo: `systemctl start seid && journalctl -u seid -f`

### Create Validator Transaction
```bash
seid tx staking create-validator \
--from {{KEY_NAME}} \
--chain-id="sei-testnet-2"  \
--moniker="<VALIDATOR_NAME>" \
--commission-max-change-rate=0.01 \
--commission-max-rate=1.0 \
--commission-rate=0.05 \
--details="<description>" \
--security-contact="<contact_information>" \
--website="<your_website>" \
--pubkey $(seid tendermint show-validator) \
--min-self-delegation="1" \
--amount <token delegation>usei \
--node localhost:26657
```
