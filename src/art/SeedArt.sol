// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SeedData} from "./SeedData.sol";

/// @notice Entire renderer is compiled into SeedClock; every library function is internal.
library SeedArt {
    using Strings for uint256;

    struct Traits {
        uint8 background;
        uint8 body;
        uint8 accessory;
        uint8 face;
        uint8 glasses;
        uint8 tempo;
        bool reverse;
    }

    /// @dev Seven disjoint bytes, taken from the LEAST significant end of artSeed.
    /// byte 0 % 6: palette, byte 1 % 5: body, byte 2 % 6: accessory,
    /// byte 3 % 5: face, byte 4 % 5: glasses, byte 5 % 4: tempo, byte 6 % 2: direction.
    function traits(bytes32 seed) internal pure returns (Traits memory t) {
        uint256 n = uint256(seed);
        t.background = uint8(n) % 6;
        t.body = uint8(n >> 8) % 5;
        t.accessory = uint8(n >> 16) % 6;
        t.face = uint8(n >> 24) % 5;
        t.glasses = uint8(n >> 32) % 5;
        t.tempo = uint8(n >> 40) % 4;
        t.reverse = uint8(n >> 48) % 2 == 1;
    }

    function tokenURI(uint256 tokenId) internal pure returns (string memory) {
        SeedData.Data memory d = SeedData.derive(tokenId);
        Traits memory t = traits(d.artSeed);
        string memory svg = render(tokenId, d, t);
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name":"SeedClock #',
                        tokenId.toString(),
                        '","description":"A clock from a recovered 1997-1998 Unix timestamp. '
                        "Deterministic lrand48 seed particles, seven generative layers and motions. "
                        'Art and animation live entirely on Ethereum.","image":"data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '","attributes":[',
                        attributes(d, t),
                        "]}"
                    )
                )
            )
        );
    }

    function attributes(SeedData.Data memory d, Traits memory t) internal pure returns (string memory) {
        return string.concat(
            attr("Background", backgroundName(t.background)),
            ",",
            attr("Body", bodyName(t.body)),
            ",",
            attr("Accessory", accessoryName(t.accessory)),
            ",",
            attr("Face", faceName(t.face)),
            ",",
            attr("Glasses", glassesName(t.glasses)),
            ",",
            attr("Tempo", tempoName(t.tempo)),
            ",",
            attr("Direction", t.reverse ? "Counterclockwise" : "Clockwise"),
            ",",
            attr("Curve origin", SeedData.curveName(d.curve)),
            ',{"display_type":"number","trait_type":"Unix timestamp","value":',
            uint256(d.timestamp).toString(),
            '},{"display_type":"number","trait_type":"Candidate","value":',
            uint256(d.candidate).toString(),
            "}"
        );
    }

    function render(uint256 id, SeedData.Data memory d, Traits memory t)
        internal
        pure
        returns (string memory)
    {
        (string memory bg, string memory accent, string memory ink) = palette(t.background);
        string memory duration = periodSeconds(t.tempo).toString();
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 480 480" role="img" aria-label="SeedClock ',
            id.toString(),
            '"><title>SeedClock ',
            id.toString(),
            " / ",
            SeedData.curveName(d.curve),
            '</title><defs><pattern id="grid" width="24" height="24" patternUnits="userSpaceOnUse">'
            '<path d="M24 0H0V24" fill="none" stroke="',
            ink,
            '" stroke-opacity=".09"/></pattern></defs>',
            '<path fill="',
            bg,
            '" d="M0 0h480v480H0z"/><path fill="url(#grid)" d="M0 0h480v480H0z"/>',
            lattice(d.artSeed, ink),
            '<g font-family="monospace" fill="',
            ink,
            '"><text x="28" y="36" font-size="13" '
            'font-weight="bold" letter-spacing="2">SEEDCLOCK</text><text x="452" y="36" '
            'text-anchor="end" font-size="11">SC / ',
            id.toString(),
            '</text><path d="M28 48h424" stroke="',
            ink,
            '" opacity=".3"/></g>',
            body(t.body, accent),
            accessory(t.accessory, accent, ink),
            face(t.face, accent),
            ticks(ink),
            hands(duration, t.reverse, accent),
            glasses(t.glasses, ink),
            seeds(d.artSeed, accent, duration),
            '<g font-family="monospace" fill="',
            ink,
            '"><text x="28" y="440" font-size="11">UNIX / ',
            uint256(d.timestamp).toString(),
            '</text><text x="452" y="440" text-anchor="end" font-size="11">',
            SeedData.curveName(d.curve),
            " / ",
            uint256(d.candidate).toString(),
            '</text><text x="28" y="458" font-size="8" letter-spacing="2" opacity=".65">'
            '48 BITS. ONE MOMENT. STILL ALIVE.</text><path d="M28 422h424" stroke="',
            ink,
            '" opacity=".3"/></g></svg>'
        );
    }

    function lattice(bytes32 seed, string memory ink) private pure returns (string memory s) {
        s = string.concat('<g fill="', ink, '" opacity=".12" shape-rendering="crispEdges">');
        for (uint256 i; i < 32; ++i) {
            if ((uint256(seed) >> (64 + i)) & 1 == 1) {
                uint256 x = 36 + (i % 4) * 120;
                uint256 y = 70 + (i / 4) * 44;
                s = string.concat(s, '<path d="M', x.toString(), " ", y.toString(), 'h8v8h-8z"/>');
            }
        }
        return string.concat(s, "</g>");
    }

    function body(uint8 kind, string memory accent) private pure returns (string memory s) {
        s = string.concat(
            '<g stroke="#172328" stroke-width="6" stroke-linejoin="round"><path fill="#172328" '
            'd="M170 380h40v24h-52v-12h12zm100 0h40v12h12v12h-52z"/><path fill="',
            accent,
            '" d="M164 294h152v26h18v60H146v-60h18z"/>'
        );
        if (kind == 0) {
            s = string.concat(
                s,
                '<path fill="#f5f1dc" d="M176 322h128v40H176z"/><path fill="#172328" '
                'd="M187 332h20v20h-20zm86 0h20v20h-20z"/><path d="M218 342h44"/>'
            );
        } else if (kind == 1) {
            s = string.concat(
                s,
                '<path fill="#f5f1dc" d="M183 310h114v24H183zm0 40h114v30H183z"/>'
                '<path d="M212 360h54m-54 10h36" stroke-width="3"/>'
            );
        } else if (kind == 2) {
            s = string.concat(
                s,
                '<path fill="#172328" d="M174 314h132v20H174zm0 36h132v12H174z"/>'
                '<path d="M186 324h8m8 0h8m8 0h8" stroke="#f5f1dc" stroke-width="5"/>'
            );
        } else if (kind == 3) {
            s = string.concat(
                s,
                '<path d="M166 320h30v22h88v-22h30m-74 22v30m-57-14h25v14m64-14h25v14" '
                'fill="none" stroke-width="4"/><path fill="#f5f1dc" d="M223 326h34v32h-34z"/>'
            );
        } else {
            s = string.concat(
                s,
                '<path fill="#f5f1dc" d="m240 310 55 34-55 32-55-32z"/>'
                '<path d="m240 310-17 34 17 32 17-32zm-55 34h110" fill="none" stroke-width="3"/>'
            );
        }
        return string.concat(s, "</g>");
    }

    function accessory(uint8 kind, string memory accent, string memory ink)
        private
        pure
        returns (string memory)
    {
        string memory a;
        if (kind == 0) {
            a = '<path d="M240 106V77h28"/><path d="M266 70h14v14h-14z"/>';
        } else if (kind == 1) {
            a = '<ellipse cx="240" cy="215" rx="148" ry="44" transform="rotate(-30 240 215)"/>';
        } else if (kind == 2) {
            a =
                '<path d="M240 109V75m0 24-26-20m26 9 23-19"/><path d="m210 70 18 8-13 12zm49-12 18 7-14 12z"/>';
        } else if (kind == 3) {
            a = '<path d="m125 240-34 36h25l-17 36 42-45h-26zm230-84 33-36h-24l17-36-42 45h26z"/>';
        } else if (kind == 4) {
            a = '<path d="m141 273-26 46 31-9 10 26 31-46m151-17 27 46-31-9-10 26-31-46"/>';
        } else {
            a = '<path d="M151 120h-22V94h47v20m153 148h29v24h-39"/><circle cx="139" cy="106" r="4"/>';
        }
        return string.concat(
            '<g fill="',
            accent,
            '" stroke="',
            ink,
            '" stroke-width="5" stroke-linecap="square" stroke-linejoin="round">',
            a,
            "</g>"
        );
    }

    function face(uint8 kind, string memory accent) private pure returns (string memory) {
        string memory shape;
        if (kind == 0) {
            shape = '<circle cx="240" cy="212" r="105"/>';
        } else if (kind == 1) {
            shape = '<rect x="135" y="107" width="210" height="210" rx="18"/>';
        } else if (kind == 2) {
            shape = '<path d="M192 107h96l57 57v96l-57 57h-96l-57-57v-96z"/>';
        } else if (kind == 3) {
            shape = '<circle cx="240" cy="212" r="105"/><circle cx="240" cy="212" r="86" stroke-width="2"/>';
        } else {
            shape = '<path d="M240 107a105 105 0 0 1 0 210H135V107z"/>';
        }
        return string.concat(
            '<g fill="#f5f1dc" stroke="#172328" stroke-width="8">',
            shape,
            '</g><circle cx="240" cy="212" r="74" fill="',
            accent,
            '" opacity=".13"/><text x="240" y="280" text-anchor="middle" fill="#172328" '
            'font-family="monospace" font-size="10" letter-spacing="3">LRAND48</text>'
        );
    }

    function ticks(string memory) private pure returns (string memory s) {
        s = '<g stroke="#172328" stroke-width="4">';
        for (uint256 i; i < 12; ++i) {
            s = string.concat(
                s, '<path d="M240 119v10" transform="rotate(', (i * 30).toString(), ' 240 212)"/>'
            );
        }
        return string.concat(s, "</g>");
    }

    function hands(string memory duration, bool reverse, string memory accent)
        private
        pure
        returns (string memory)
    {
        string memory turn = reverse ? "-360 240 212" : "360 240 212";
        return string.concat(
            '<g><path d="M240 224v-77" stroke="#172328" stroke-width="7" stroke-linecap="square"/>'
            '<animateTransform attributeName="transform" type="rotate" from="0 240 212" to="',
            turn,
            '" dur="',
            duration,
            's" repeatCount="indefinite"/></g><g><path d="M228 212h65" stroke="',
            accent,
            '" stroke-width="5"/><animateTransform attributeName="transform" type="rotate" '
            'from="0 240 212" to="',
            turn,
            '" dur="120s" repeatCount="indefinite"/></g>'
            '<circle cx="240" cy="212" r="9" fill="#172328"/><circle cx="240" cy="212" r="3" fill="#f5f1dc"/>'
        );
    }

    function glasses(uint8 kind, string memory) private pure returns (string memory) {
        if (kind == 0) {
            return '<path d="M156 165h72v18h24v-18h72v40h-72v-12h-24v12h-72z" '
                'fill="#172328"/><path d="M168 175h45v20h-45zm99 0h45v20h-45z" fill="#f5f1dc" opacity=".8"/>';
        }
        if (kind == 1) {
            return '<path d="M156 171h168v24H156z" fill="#172328"/>'
                '<path d="M168 179h42m14 0h12m15 0h61" stroke="#f5f1dc" stroke-width="3"/>';
        }
        if (kind == 2) {
            return '<g fill="none" stroke="#172328" stroke-width="5">'
                '<circle cx="285" cy="181" r="22"/><path d="M307 181h19v53m-151-53h39"/></g>';
        }
        if (kind == 3) {
            return '<g fill="none" stroke="#172328" stroke-width="3">'
                '<rect x="159" y="162" width="64" height="37"/><rect x="257" y="162" width="64" height="37"/>'
                '<path d="M223 178h34"/></g>';
        }
        return '<path d="M184 175h14v13h-14zm98 0h14v13h-14z" fill="#172328"/>';
    }

    function seeds(bytes32 seed, string memory accent, string memory duration)
        private
        pure
        returns (string memory s)
    {
        s = string.concat('<g fill="', accent, '" stroke="#172328" stroke-width="2">');
        for (uint256 i; i < 6; ++i) {
            uint256 n = uint8(uint256(seed) >> (104 + i * 8));
            uint256 x = i < 3 ? 56 + n % 33 : 374 + n % 33;
            uint256 y = 104 + (i % 3) * 95 + n % 30;
            s = string.concat(
                s,
                '<rect x="',
                x.toString(),
                '" y="',
                y.toString(),
                '" width="10" height="10"><animate attributeName="y" values="',
                y.toString(),
                ";",
                (y - 14).toString(),
                ";",
                y.toString(),
                '" dur="',
                duration,
                's" repeatCount="indefinite"/><animate attributeName="opacity" values="1;.35;1" dur="',
                (3 + i).toString(),
                's" repeatCount="indefinite"/></rect>'
            );
        }
        return string.concat(s, "</g>");
    }

    function attr(string memory name, string memory value) private pure returns (string memory) {
        return string.concat('{"trait_type":"', name, '","value":"', value, '"}');
    }

    function palette(uint8 n)
        internal
        pure
        returns (string memory bg, string memory accent, string memory ink)
    {
        if (n == 0) return ("#142a35", "#a9ed9e", "#d7e7e8");
        if (n == 1) return ("#eee9dc", "#f19c66", "#253642");
        if (n == 2) return ("#c3dec9", "#56bca0", "#253642");
        if (n == 3) return ("#eac3ac", "#da795e", "#353141");
        if (n == 4) return ("#28233f", "#bba8ed", "#e4daf5");
        return ("#1f4085", "#8ddce0", "#dce8f8");
    }

    function periodSeconds(uint8 n) internal pure returns (uint256) {
        if (n == 0) return 12;
        if (n == 1) return 20;
        if (n == 2) return 32;
        return 48;
    }

    function backgroundName(uint8 n) private pure returns (string memory) {
        if (n == 0) return "Midnight";
        if (n == 1) return "Parchment";
        if (n == 2) return "CRT Mint";
        if (n == 3) return "Oxide";
        if (n == 4) return "Violet Terminal";
        return "Cobalt";
    }

    function bodyName(uint8 n) private pure returns (string memory) {
        if (n == 0) return "Cassette";
        if (n == 1) return "Floppy";
        if (n == 2) return "Mainframe";
        if (n == 3) return "Circuit";
        return "Crystal";
    }

    function accessoryName(uint8 n) private pure returns (string memory) {
        if (n == 0) return "Antenna";
        if (n == 1) return "Orbit";
        if (n == 2) return "Sprout";
        if (n == 3) return "Lightning";
        if (n == 4) return "Ribbon";
        return "Data Tabs";
    }

    function faceName(uint8 n) private pure returns (string memory) {
        if (n == 0) return "Round";
        if (n == 1) return "Square";
        if (n == 2) return "Octagon";
        if (n == 3) return "Radar";
        return "Split";
    }

    function glassesName(uint8 n) private pure returns (string memory) {
        if (n == 0) return "Block";
        if (n == 1) return "Visor";
        if (n == 2) return "Monocle";
        if (n == 3) return "Wireframe";
        return "Pixel Eyes";
    }

    function tempoName(uint8 n) private pure returns (string memory) {
        if (n == 0) return "12 seconds";
        if (n == 1) return "20 seconds";
        if (n == 2) return "32 seconds";
        return "48 seconds";
    }
}
