# Website follow-up

The brief places the public website in a separate job. Its confirmed deployment-address input must come from IdentityMD's launch record. Do not populate mint or claim transactions with guessed addresses, dry-run addresses, or an unverified chain.

## Content

- **What is SeedClock:** 5,555 animated clocks generated entirely by immutable Ethereum code; SCLOCK; 55 treasury pieces and 5,500 free public mints; five lifetime public mints per wallet.
- **The timestamps story:** link [Anthropic's October 16, 2026 report](https://www.anthropic.com/research/ecdsa-curve-origins) and its reproduction code. Explain `srand48`, the 48-bit recurrence, Unix timestamps, and 20-byte candidates. P-256 uses timestamp 871696354 and candidate 1842, producing `c49d360886e704936a6678e1139d26b7819f7e90`. This clarifies provenance and increases confidence; it is not a cryptographic break or proof that every historical choice is explained.
- **How seeds map to art:** use the README's exact table and byte mapping. The five layers are background, body, accessory, face, and glasses; tempo and direction animate the result. On-chain data is base64 JSON containing base64 SVG with SMIL. No image CDN is required.
- **Mint:** connect a wallet on chain 1, read IMD balance, `totalSupply`, and `publicMinted`; choose 1–5 subject to the remaining allowance and supply. Call `mint(uint256)` with zero value. Explain the one-whole-IMD threshold, gas fees, and transaction failure states. No token approval or transfer is needed for eligibility.
- **Claim:** read `royaltyConfiguration` to find the distributor. Display `claimable(holder)` for ETH and `claimable(asset, holder)` for a selected standard ERC-20, the receipt cursor, and remaining batches. Offer permissionless `syncToken` (WETH also syncs on every mint and transfer), then `claim()` / `claim(asset)`. State the receipt/sync snapshot rule and retained earned claims after transfer. Repeat a claim only while `nextReceipt(asset, holder) < receiptCount(asset)` (more than 64 balance changes to settle). A rejecting wallet can choose its own `claimTo` destination.
- **Contracts:** publish both verified application addresses, chain ID, deployment transaction, immutable treasury, fixed IMD, fixed registry, and source links. Identify any deployment or explorer verification still pending explicitly.

Use responsive layouts, accessible wallet/error status, dark/light themes, and reduced-motion support for the page. Static files can be hosted on IPFS/ENS; wallet actions need only an EIP-1193 provider. SVG viewers may differ in animation support, so show the SVG directly and offer a standalone image link. Do not imply that holders must keep IMD after minting or that claims require an owner-run service.
