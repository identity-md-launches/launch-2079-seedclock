# Accounting and review notes

## Monetary model

The distributor mirrors the NFT's balances. SeedClock is the only allowed share updater. After deployment, each mint or transfer increments the revision and appends affected account balances. A receipt stores that revision and its integer per-token amount. Claims use a binary search of balance history at the stored revision, never today's balance multiplied by old revenue. A new mint cannot collect pre-mint royalties and moving a token cannot duplicate an old entitlement.

For each receipt `A` with minted supply `S`, each holder gets `floor(A/S) * snapshotBalance`. The holder of token 1 at that time receives `A % S` base units of dust. There is no unallocated remainder or administrative sweep. Dust-only receipts do not append an empty receipt. At a fixed snapshot, the sum of all allocations is exactly `A`.

`accountedBalance[asset]` is recorded receipts minus successful claims. ERC-20 `syncToken` records only `balanceOf(distributor) - accountedBalance[asset]`, making repeat syncs idempotent. Native `receive` does the same, including any forced ETH previously unsynced. Receipt processing is constant time; balance changes have constant storage writes; a claim visits at most 64 receipts and binary-searches historical balances. Long histories may need repeated claims, including empty batches for holders who joined late.

Claim cursors, rounding credit, accounting, and totals update before external payment. A reentrancy guard covers claim variants and ERC-20 synchronization. A failing payment reverts all its accounting and does not affect other holders. A receiver can direct only its own entitlement elsewhere with `claimTo`. `claimFor` always pays the named holder. Receiving a new ETH donation during a successful claim callback creates a new entitlement safely; the previous claim cannot overwrite it.

## Trust and limits

- The atomic deployment factory is trusted to run the reviewed distributor and SeedClock constructors consecutively; see the binding-window discussion in [DEPLOYMENT.md](DEPLOYMENT.md). After pairing it has no continuing powers.
- The mainnet IMD contract controls its balance reporting. Eligibility is checked at each mint, not locked or consumed. One IMD can qualify several wallets if moved between them. The quota is per address, not per person.
- Transfer approval also depends on OpenSea's external strict registry and authorizer. This is normal ERC721-C marketplace enforcement, with the registry's direct-gift exception. Its external policy administrators are a trust dependency; SeedClock cannot change or disable the validator.
- A royalty is apportioned when ETH is received, or when ERC-20 receipts are synced. Anyone can sync ERC-20s. Unsynced ERC-20 amounts do not reserve entitlements for prior holders. Transaction ordering can affect the snapshot.
- Standard, fixed-balance ERC-20s are supported. Rebases, confiscations, sender/recipient fees, reentrant/malicious token semantics, and paused/blocklisted token transfers cannot be repaired by an administrator. A broken asset does not enter any loop used by other assets, mints, or NFT transfers. Holders can still claim unaffected assets.
- Royalty payments must supply enough gas for accounting. Seaport's native calls do; a 2,300-gas Solidity `transfer` payment does not.
- There is no burn, rescue, pause, upgrade, extra mint, external renderer, metadata setter, or owner. Immutable bugs cannot be patched in place. Reserve recipients must be able to manage their tokens because reserve minting intentionally avoids callbacks.
- Art is deterministic and visible before mint. There is no promise of unpredictable rarity. The lrand48 construction is historical art data, not a source of secure randomness.

## Local review performed

Success and failure tests exercise full supply, fractional-IMD rejection, per-wallet mint history, safe-mint rollback, mint reentrancy, invalid and unauthorized transfers, both safe transfer overloads, missing dependency code, immutable settings, ETH/ERC-20 royalty receipts, new-mint exclusion, transfer snapshots, repeated claims, dust, pagination, forced ETH, payment failure, claim reentrancy, callbacks that donate royalties, false-returning ERC-20s, and negative rebases.

The stateful handler maintains its own allocation model, based on ERC-721 balances at each receipt. Random sequences of mints, token movements, native/token receipts, and claims check exact liabilities, total asset conservation, mint quotas, and agreement between the NFT and distributor balances. Handler reverts fail the invariant run. Seed tests match all five published vectors and compare affine skip-ahead against an independent linear recurrence. Metadata is decoded and parsed in tests.

Bytecode checks repeat the protected runtime size and forbidden-opcode scan. Foundry's default lints were reviewed: low-byte casts are intentional art selection, supply bounds make share casts safe, reserve `_mint` avoids deployment callbacks, claim destinations are holder-authorized, and the mint loop is bounded to five. The validator call is a static call. The distributor hook has no external callback. Mint receiver callbacks see fully consistent token and share balances.

No Slither/Mythril audit, independent contributor audit, live marketplace signature test, or mainnet broadcast occurred in this job. The supplied protected launch tests rely on the later manifest/factory environment and are not substituted by a claim that local tests ran that external harness.
