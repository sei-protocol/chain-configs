from operator import ge
import argparse
import os
import json
import subprocess
import shutil
from pathlib import Path

'''
Resets the genesis.json file to the default values & clears all balances / accounts
Then will generate all the commands to add balances for all gentxs
Assumes you've already run confirm-gen-txs.py
'''

EXP_SEND = [{"denom": "usei","enabled": True}]

def main(chain_id, home_dir, initial_balance):
    reset_genesis_file(home_dir)
    create_genesis_account_cmds(initial_balance)
    print("seid add vals to genesis")
    subprocess.run("bash ./add_val_to_genesis.sh", stdout=subprocess.PIPE, shell=True, check=True)
    copy_gentx_folder(chain_id, home_dir)

def reset_genesis_file(home_dir):
    genesis_file = home_dir + "/config/genesis.json"
    # load genesis.json & remove all values for accounts & supply
    with open(genesis_file) as f:
        genesis = json.load(f)
        genesis["app_state"]['bank']["params"]["send_enabled"] = EXP_SEND
        genesis["app_state"]['genutil']["gen_txs"] = []

    # save genesis.json
    with open(genesis_file, 'w') as f:
        json.dump(genesis, f, indent=4)
    print(f"# RESET: {genesis_file}\n")


def create_genesis_account_cmds(initial_balance):
    print("-- Run the following commands to create genesis accounts --")
    with open('gentx-output.csv') as f:
        for line in f:
            validator_address = line.split(',')[0]
            cmd = f"seid add-genesis-account {validator_address} {initial_balance}"
            print(f"Running: {cmd}")
            completed_process = subprocess.run(cmd, stdout=subprocess.PIPE, shell=True, check=False)
            if completed_process.returncode != 0:
                if "cannot add account at existing address" in completed_process.stdout.decode('utf-8'):
                    print("Account already exists, skipping")
                    continue


def copy_gentx_folder(chain_id, home_dir):
    gentx_dir = home_dir + "/config/gentx"
    shutil.rmtree(gentx_dir, True)
    os.makedirs(os.path.dirname(gentx_dir), exist_ok=True)
    shutil.copytree(chain_id + "/gentx", home_dir + "/config/gentx")
    print(f"gentx folder copied to {home_dir}/config/gentx")

    cmd = "seid collect-gentxs"
    print(f"Running: {cmd}")
    subprocess.run(cmd, stdout=subprocess.PIPE, shell=True, check=True)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--chain-id', type=str)
    parser.add_argument('--home-dir', type=str)
    parser.add_argument('--initial-balance', type=str)
    args = parser.parse_args()
    assert (args.initial_balance[-4:] == 'usei')
    main(args.chain_id, args.home_dir, args.initial_balance)
