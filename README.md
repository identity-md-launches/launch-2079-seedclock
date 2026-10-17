# SeedClock · SCLOCK

Immutable ERC721-C compatible collection for Ethereum mainnet: **5,555 animated, fully on-chain clocks**, a free IMD-holder mint, and **6.9% royalties distributed to holders**. This repository is the tested source and deployment handoff. **No mainnet transaction or explorer verification was performed in this worker job.** IdentityMD's attested launch supplies the final addresses.

## Build and check offline

Dependencies are vendored as ordinary files. Solidity **0.8.26**, Cancun, optimizer 200 runs, via IR, metadata hash disabled. No FFI, filesystem permissions, RPC, environment reads, or external packages are required by the tests.

```sh
forge build
FOUNDRY_FUZZ_SEED=0x55a48c5d337f0d6c29fbb3835c83a0c14364d678c92a24a117a6ddba89dbdd00 forge test
forge fmt --check
forge script script/DeploySeedClock.s.sol:DeploySeedClock
python3 tools/reproduce.py 3 --verify
```

The script is a local rehearsal without broadcasting. Tests cover supply exhaustion, IMD eligibility, callback failures, authorization, real mainnet registry bytecode, royalty accounting, pagination, reentrancy, published seeds, metadata, deployment limits, and stateful conservation.

## Contracts and addresses

| Item | Ethereum mainnet address / launch parameter |
|---|---|
| `RoyaltyDistributor` | Assigned and verified by the launch service; deploy first with `treasury_ = $owner` |
| `SeedClock` | Assigned and verified by the launch service; deploy second with `treasury_ = $owner`, `distributor_ = $contract:RoyaltyDistributor` |
| Treasury / `$owner` | `0x3d6a89c8751a45dd577a4c1f3b34e71c58236193` |
| IMD, 18 decimals | `0xD34a99Bc0f67aE1bbd63C660e6d0b0dd03E263B7` |
| OpenSea strict transfer validator | `0xA000027A9B2802E1ddf7000061001e5c005A0000` |
| OpenSea SignedZone | `0x000056F7000000EcE9003ca63978907a00FFD100` |

**The two application deployments must be in one atomic factory transaction, with no untrusted call between them.** A constructor-only transient handshake binds the distributor to SeedClock. This closes the circular reference without a post-deployment initializer or any owner power. Separate deployment transactions fail. Both constructors are nonpayable; the renderer is internal. See [deployment and marketplace responsibilities](docs/DEPLOYMENT.md).

## Mint and claim

IDs 1–55 go to the immutable treasury during deployment. `mint(quantity)` is immediately and permanently open for IDs 56–5555, costs no ETH, and requires `IMD.balanceOf(msg.sender) >= 10^18`. Each address can publicly mint five in its lifetime; transfers do not reset this allowance. The treasury reserve is exempt. There is no owner mint, pause, upgrade, burn, royalty setter, or withdrawal administrator. Gas is still paid by the caller.

The distributor snapshots balances on each ETH receipt. Mainnet WETH (`0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`, the currency of OpenSea offers) is synced automatically before every mint or transfer, so WETH that arrived earlier belongs to the holders of record at that time. For any other ERC-20, anyone calls `syncToken(asset)` and ownership **at sync time** applies. `claim()` pays the caller's ETH entitlement, `claim(asset)` pays an ERC-20 entitlement, and `claimFor(asset, holder)` always pays that holder. `claimTo(asset, receiver)` lets only the entitled holder choose a recipient.

A claim's cost does not depend on how many receipts exist. Receipts store a running per-token total, and a claim settles each stretch in which the holder's balance was constant with two binary searches. A wallet that joins after 1,000 receipts claims its first royalty in one call of under 200k gas. Each call settles at most **64 balance segments**. Only a holder whose own balance changed more than 64 times between receipts needs to repeat the call, until `nextReceipt(asset, holder) == receiptCount(asset)`.

Each minted token receives `floor((receipt + carry) / currentSupply)`. The remainder, less than `currentSupply` base units, is carried into that asset's next receipt (`undistributed(asset)`) instead of going to any one holder. Amounts below one unit per token only add to the carry and create no receipt. Accrued claims remain with the snapshot holder after a transfer; new holders receive future receipts. Tokens cannot be transferred to the distributor or to SeedClock itself (`ERC721InvalidReceiver`), because neither could ever claim that token's share. Fee-on-transfer, rebasing, and balance-confiscating ERC-20s are unsupported. No one can sweep funds. See [accounting and review notes](docs/SECURITY.md).

## Exact seed-to-art mapping

Source: Anthropic's [October 16, 2026 report and CC0 reproduction code](https://www.anthropic.com/research/ecdsa-curve-origins). The report explains the timestamp-seeded `lrand48` construction; it increases confidence in curve provenance rather than proving the absence of every possible backdoor. Some selection criteria and base-point origins remain unexplained.

For token `id`, choose row `(id - 1) % 5`, and candidate `base + floor((id - 1) / 5)`:

| Row | Curve | Unix timestamp | UTC | Base candidate |
|---|---|---:|---|---:|
| 0 | P-192 | 863966734 | 1997-05-18 14:45:34 | 139 |
| 1 | P-224 | 891607927 | 1998-04-03 12:52:07 | 7026 |
| 2 | P-256 | 871696354 | 1997-08-16 01:52:34 | 1842 |
| 3 | P-384 | 872952608 | 1997-08-30 14:50:08 | 2688 |
| 4 | P-521 | 871002724 | 1997-08-08 01:12:04 | 1136 |

Initialize `x = (timestamp << 16) | 0x330e`. Each draw updates `x = (0x5deece66d*x + 11) mod 2^48` and emits byte `x >> 40`. Discard `20*(candidate-1)` draws, then concatenate 20 bytes in draw order. `artSeed = keccak256(abi.encodePacked("SeedClock/v1", bytes20(candidateSeed), uint256(id)))`.

Count digest bytes **from the least significant end**. Bytes 0–6 select background `%6`, body `%5`, accessory `%6`, face `%5`, glasses `%5`, tempo `%4` (12/20/32/48 seconds), and direction `%2` (0 clockwise). Lattice bits 64–95 and particle bytes at bit offsets 104,112,…,144 add detail. Pulsing particles and a 120-second second hand accompany the tempo-controlled hand. This is public deterministic art, with no randomness or rarity fairness claim. [SeedData.sol](src/art/SeedData.sol) and [SeedArt.sol](src/art/SeedArt.sol) are the complete specification.

The public wallet website is the separate follow-up described in the brief; [SITE-HANDOFF.md](docs/SITE-HANDOFF.md) supplies its content and integration requirements.

An offline [art gallery](docs/GALLERY.html) includes six standalone SVGs decoded from the Solidity renderer.
