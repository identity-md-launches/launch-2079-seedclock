# Vendored dependencies

All dependencies are ordinary source files, with no submodule, npm installation, or network requirement at build time.

| Dependency | Pinned upstream release | Local path | License |
|---|---|---|---|
| OpenZeppelin Contracts | `v5.1.0` | `lib/openzeppelin-contracts` | MIT, included |
| forge-std | `v1.9.7` | `lib/forge-std` | MIT / Apache-2.0, included |

Sources were downloaded from the tagged GitHub release archives. ERC-721, safe ERC-20 handling, checked full-precision multiplication, strings/base64, and the reentrancy guard use OpenZeppelin. Tests and the non-broadcasting script use forge-std. SeedClock manually implements the documented ERC721-C discovery and validation interface on top of ERC-721; it does not inherit a mutable owner-controlled validator implementation.

`test/fixtures/MainnetValidatorCode.sol` and `MainnetValidator.sol` reconstruct the mainnet OpenSea StrictAuthorizedTransferSecurityRegistry runtime and exercised default-policy storage at block 26212558. The fixture is test-only. Its canonical verified source is linked in `test/fixtures/mainnet-validator.json` / the Solidity header, and the bytecode hash is recorded there. Production always calls the canonical mainnet registry.

Historical seed values and recurrence are reproduced from Anthropic's CC0 reproduction in [Claude reveals ECDSA curve origins](https://www.anthropic.com/research/ecdsa-curve-origins). The project's independently written code is MIT licensed.
