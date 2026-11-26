# Astroport genesis contracts

The audited Astroport contracts for genesis deployment. The artifacts are taken
from the original repositories below, but added to [artifacts](./artifacts) for simplicity.

- [Astroport Core v2.3.1](https://github.com/astroport-fi/astroport-core/releases/tag/v2.3.1)
- [Astroport IBC v1.1.0](https://github.com/astroport-fi/astroport_ibc/releases/tag/v1.1.0)

## Deployment script

`deploy_at_genesis.sh` is a bash script that will add store and instantiate messages
to the genesis file for Astroport contracts. It requires `seid` to be available
and will operate on the genesis file at the default `seid` path

**Executing the script**

_Tested on Sei v2.0.46beta_

Usage: `./deploy_at_genesis.sh /path/to/seid`

```shell
./deploy_at_genesis.sh seid
```

Once the script completes, all the Astroport contracts can be found in the genesis
file.

