// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Reproducible art input, NOT cryptographic randomness.
/// @dev Historical source (CC0 reproduction code):
/// https://www.anthropic.com/research/ecdsa-curve-origins (2026-10-16).
/// curve = (tokenId-1) % 5, in order P-192, P-224, P-256, P-384, P-521.
/// candidate = publishedCandidate[curve] + floor((tokenId-1)/5), one-based.
/// srand48 initializes x = (timestamp << 16) | 0x330e.
/// Advance x = (0x5deece66d*x + 11) mod 2^48, 20*(candidate-1) times.
/// Then advance another 20 times, concatenating x>>40 as big-endian bytes.
/// artSeed = keccak256(abi.encodePacked("SeedClock/v1", candidateBytes20, uint256(tokenId))).
/// Affine exponentiation skips the discarded outputs in O(log candidate) time.
library SeedData {
    error InvalidTokenId();

    uint256 private constant MASK = (1 << 48) - 1;

    struct Data {
        uint32 timestamp;
        uint32 candidate;
        uint8 curve;
        bytes20 historicalSeed;
        bytes32 artSeed;
    }

    function derive(uint256 tokenId) internal pure returns (Data memory d) {
        if (tokenId == 0 || tokenId > 5555) revert InvalidTokenId();
        d.curve = uint8((tokenId - 1) % 5);
        (d.timestamp, d.candidate) = origin(d.curve);
        d.candidate += uint32((tokenId - 1) / 5);
        d.historicalSeed = candidateSeed(d.timestamp, d.candidate);
        d.artSeed = keccak256(abi.encodePacked("SeedClock/v1", d.historicalSeed, tokenId));
    }

    function origin(uint8 curve) internal pure returns (uint32 timestamp, uint32 candidate) {
        if (curve == 0) return (863966734, 139); // P-192: 1997-05-18 14:45:34 UTC
        if (curve == 1) return (891607927, 7026); // P-224: 1998-04-03 12:52:07 UTC
        if (curve == 2) return (871696354, 1842); // P-256: 1997-08-16 01:52:34 UTC
        if (curve == 3) return (872952608, 2688); // P-384: 1997-08-30 14:50:08 UTC
        return (871002724, 1136); // P-521: 1997-08-08 01:12:04 UTC
    }

    function candidateSeed(uint32 timestamp, uint32 candidate) internal pure returns (bytes20 result) {
        uint256 steps = 20 * (uint256(candidate) - 1);
        uint256 x = (uint256(timestamp) << 16) | 0x330e;
        uint256 a = 0x5deece66d;
        uint256 c = 11;
        while (steps != 0) {
            if (steps & 1 != 0) x = (a * x + c) & MASK;
            c = (a * c + c) & MASK;
            a = (a * a) & MASK;
            steps >>= 1;
        }
        uint160 seed;
        for (uint256 i; i < 20; ++i) {
            x = (0x5deece66d * x + 11) & MASK;
            seed = (seed << 8) | uint160(x >> 40);
        }
        result = bytes20(seed);
    }

    function curveName(uint8 curve) internal pure returns (string memory) {
        if (curve == 0) return "P-192";
        if (curve == 1) return "P-224";
        if (curve == 2) return "P-256";
        if (curve == 3) return "P-384";
        return "P-521";
    }
}
