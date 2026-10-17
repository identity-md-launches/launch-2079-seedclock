# Deployment and operations

## Launch inputs

Chain ID **1**. Two applications, in this order:

1. `RoyaltyDistributor(address treasury_)`, with the supplied launch owner as treasury.
2. `SeedClock(address treasury_, address distributor_)`, with the same treasury and the first application's address.

The launch owner/treasury is `0x3d6a89c8751a45dd577a4c1f3b34e71c58236193`. Neither contract has an owner or administrative role. Passing the factory or transaction origin as the treasury is incorrect. The constructor treasury must be able to manage ERC-721 tokens; reserve minting intentionally skips receiver callbacks. The supplied treasury is used directly, without a guessed substitute.

Use the pinned Foundry configuration, including `bytecode_hash = "none"`. There are no link placeholders or separately deployed renderer libraries. Both deployed runtimes must remain below 24,576 bytes and initcodes below 49,152 bytes. The local tests repeat the supplied protected runtime/opcode checks. No `launch.json` is supplied: IdentityMD's separate manifest step owns it.

## Atomic pairing

Both deployments **must occur in one transaction**, as in the supplied `ContractsDeploymentProbe.deployAll` / production factory. Deploying the distributor opens a transient capability. SeedClock's constructor immediately consumes it, fixes `collection`, and records the initial 55 treasury shares. The capability closes on use and also disappears at the transaction boundary. Treasury mismatch, different deployment caller, repeated binding, or binding from a contract with deployed code fails.

The binding capability assumes the reviewed factory performs these two deployments consecutively with no untrusted external call between them. The distributor constructor makes no calls; SeedClock binds before reserve minting, which has no receiver callbacks. **Do not deploy these applications as two separate `forge create` transactions.** Do not leave an orphan distributor or send money to one: it cannot later be initialized or recovered. The constructor call targets only the preceding application, not a mainnet dependency; IMD and validator code are checked on first use.

`forge script script/DeploySeedClock.s.sol:DeploySeedClock` runs a local CREATE2 rehearsal. `deploy(address treasury)` is directly tested. The script reads compiled artifacts, does not read environment variables or credentials, and never starts a broadcast. Its helper and salt choices are test infrastructure, not launch applications or mainnet address predictions.

## Marketplace enforcement

SeedClock implements the [ICreatorToken interface and validation hook documented by OpenSea](https://docs.opensea.io/docs/creator-fee-enforcement), plus ERC-2981. Every secondary transfer, including owner gifts, invokes `validateTransfer(caller, from, to, tokenId)` on the fixed strict registry. ERC-721 approval is checked independently. If the registry is missing or rejects the transfer, the whole transfer reverts.

`getTransferValidator()` is permanently `0xA000027A9B2802E1ddf7000061001e5c005A0000`. `getTransferValidationFunction()` returns `(0xcaee23ea, true)`. `setTransferValidator` always reverts. `royaltyInfo` and collection metadata specify the distributor and 690 bps. No collection caller can change a registry list on the collection's behalf.

Seaport 1.6 orders use the documented SignedZone, restricted order types, advanced fulfillment, and SIP-7 substandard 8. OpenSea provides the required royalty attestation in fulfillment `extraData`. The on-chain registry checks authorization; OpenSea's zone/oracle checks that its signed order includes the fee. The NFT itself cannot infer an order price from a bare `transferFrom` call. This relies on the external registry, its default policy/list administrators, and its trusted authorizer. It does not force unrelated marketplaces to integrate, nor detect private side payments. The registry's owner-to-owner gift path is intentional.

The offline fixture records mainnet registry runtime and exercised default-policy storage at block **26212558**, with hash in `test/fixtures/mainnet-validator.json`. Tests use that actual bytecode for unauthorized, authorized, token-specific, and cleared-authorization transfers. They impersonate the SignedZone at its boundary; they do not forge an OpenSea API signature or claim to have executed a live OpenSea sale.

## After launch

The deployment service and launch owner must:

- Deploy the reviewed bytecode atomically, verify both sources with Solidity 0.8.26 and the repository settings, and publish the confirmed addresses, transaction, block, and explorer verification links. Verification was not performed in this worker job.
- Confirm `distributor.collection()`, both treasury getters, the 55 initial owners, `totalSupply()`, and `royaltyConfiguration()` match the launch record. No post-deployment contract setter is required or available.
- Recheck mainnet IMD code/18 decimals and the canonical validator's active policy. The worker read these on mainnet; fixtures intentionally cannot attest to later changes in outside contracts.
- Confirm OpenSea detects the validator and 690 bps recipient correctly, complete any collection attribution/earnings setup through OpenSea, and validate a real signed listing/offer with a small sale before promoting secondary trading. Marketplace onboarding is an external service operation, not a contract setter.
- Publish the confirmed addresses to the website follow-up. Never use the local rehearsal addresses as production addresses.
- Obtain an independent adversarial review before release. The local test suite is not a security audit.

Ongoing holder actions are `syncToken(asset)` for ERC-20 receipts and paginated claims. Anyone can help with syncing and `claimFor`; ETH receipts account automatically. No keeper key, privileged server, or owner withdrawal is necessary.
