# Security

## Threat Model

Astram assumes a standard PoW threat model:

- An attacker with significant hash power can attempt reorgs or double spends.
- Network attackers can attempt Eclipse or partition attacks.
- Malicious peers can attempt DoS via malformed or excessive traffic.

## Key Assets

- Private keys stored in the local wallet file.
- Chain data stored in the node data directory.
- Network reachability of the P2P port and DNS registration.

## Wallet Security

- Wallet keys are stored as JSON files on disk.
- Users must protect this file using OS-level permissions and backups.
- Do not expose wallet files on shared systems.

## Node Security

- P2P ports should be exposed only as needed.
- HTTP and JSON-RPC servers default to localhost and should remain private unless explicitly exposed.
- DNS registration requires reachable public ports; only do this on a secured host.
- Consensus validation enforces numeric PoW targets (`hash_u256 < target_u256`) instead of prefix-only checks.
- Difficulty retargeting applies bounded timespan clamps and per-block damping to reduce abrupt oscillations.

## Network Security

- DNS discovery is centralized and should be treated as a convenience, not a trust anchor.
- Nodes should validate all incoming blocks and transactions.

## Operational Hardening Checklist

- Run the node under a dedicated OS user.
- Use a firewall to restrict HTTP/JSON-RPC to trusted hosts.
- Keep data directories on storage with proper access controls.
- Monitor logs for repeated peer failures or suspicious registrations.

## Open Items

- Formal protocol-level security analysis is pending.
- DoS and resource-exhaustion limits should be revisited as the network grows.
