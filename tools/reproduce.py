#!/usr/bin/env python3
"""Independent SeedClock reproduction. Standard Python + Foundry's offline `cast keccak`.

Historical timestamps/candidates: Anthropic's CC0 reproduction published 2026-10-16:
https://www.anthropic.com/research/ecdsa-curve-origins#code-to-reproduce-the-seeds
This implementation deliberately uses a linear recurrence, independent of the Solidity skip-ahead.
"""

import argparse
import json
import subprocess
from datetime import datetime, timezone

ORIGINS = [
    ("P-192", "1997-05-18 14:45:34", 139, "3045ae6fc8422f64ed579528d38120eae12196d5"),
    ("P-224", "1998-04-03 12:52:07", 7026, "bd71344799d5c7fcdc45b59fa3b9ab8f6a948bc5"),
    ("P-256", "1997-08-16 01:52:34", 1842, "c49d360886e704936a6678e1139d26b7819f7e90"),
    ("P-384", "1997-08-30 14:50:08", 2688, "a335926aa319a27a1d00896a6773a4827acdac73"),
    ("P-521", "1997-08-08 01:12:04", 1136, "d09e8800291cb85396cc6717393284aaa0da64ba"),
]


def unix(date):
    return int(datetime.fromisoformat(date).replace(tzinfo=timezone.utc).timestamp())


def candidate_seed(timestamp, candidate):
    state = (timestamp << 16) | 0x330E
    out = bytearray()
    for step in range(20 * candidate):
        state = (0x5DEECE66D * state + 11) % (1 << 48)
        if step >= 20 * (candidate - 1):
            out.append(state >> 40)
    return bytes(out)


def reproduce(token_id):
    if not 1 <= token_id <= 5555:
        raise ValueError("token ID must be in 1..5555")
    curve, date, base, _ = ORIGINS[(token_id - 1) % 5]
    timestamp = unix(date)
    candidate = base + (token_id - 1) // 5
    seed = candidate_seed(timestamp, candidate)
    packed = b"SeedClock/v1" + seed + token_id.to_bytes(32, "big")
    digest = subprocess.check_output(["cast", "keccak", "0x" + packed.hex()], text=True).strip()
    art = int(digest, 16)
    traits = [(art >> (8 * i)) & 255 for i in range(7)]
    return {
        "tokenId": token_id,
        "curve": curve,
        "timestamp": timestamp,
        "utc": date,
        "candidate": candidate,
        "historicalSeed": "0x" + seed.hex(),
        "artSeed": digest,
        "traits": {
            "background": traits[0] % 6,
            "body": traits[1] % 5,
            "accessory": traits[2] % 6,
            "face": traits[3] % 5,
            "glasses": traits[4] % 5,
            "tempo": [12, 20, 32, 48][traits[5] % 4],
            "direction": "counterclockwise" if traits[6] % 2 else "clockwise",
        },
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("token_id", nargs="?", type=int, default=3)
    parser.add_argument("--verify", action="store_true", help="also verify all five published NIST seeds")
    args = parser.parse_args()
    if args.verify:
        for curve, date, candidate, expected in ORIGINS:
            actual = candidate_seed(unix(date), candidate).hex()
            if actual != expected:
                raise SystemExit(f"{curve}: expected {expected}, got {actual}")
        print("All five published NIST seed vectors match.")
    print(json.dumps(reproduce(args.token_id), indent=2))


if __name__ == "__main__":
    main()
