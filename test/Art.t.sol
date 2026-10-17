// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SeedClockFixture} from "./helpers/Fixtures.sol";
import {SeedData} from "../src/art/SeedData.sol";
import {SeedArt} from "../src/art/SeedArt.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract ArtTest is SeedClockFixture {
    function test_allFivePublishedSeedsReproduceExactly() public view {
        bytes20[5] memory expected = [
            bytes20(hex"3045ae6fc8422f64ed579528d38120eae12196d5"),
            bytes20(hex"bd71344799d5c7fcdc45b59fa3b9ab8f6a948bc5"),
            bytes20(hex"c49d360886e704936a6678e1139d26b7819f7e90"),
            bytes20(hex"a335926aa319a27a1d00896a6773a4827acdac73"),
            bytes20(hex"d09e8800291cb85396cc6717393284aaa0da64ba")
        ];
        for (uint256 i; i < 5; ++i) {
            SeedData.Data memory d = clock.seedData(i + 1);
            assertEq(d.historicalSeed, expected[i]);
            assertEq(d.artSeed, keccak256(abi.encodePacked("SeedClock/v1", expected[i], i + 1)));
        }
    }

    function test_candidateMappingAndTraitsRemainStableAcrossTimeAndOwnership() public {
        SeedData.Data memory first = clock.seedData(3);
        SeedData.Data memory next = clock.seedData(8);
        assertEq(first.timestamp, 871696354);
        assertEq(first.candidate, 1842);
        assertEq(next.timestamp, first.timestamp);
        assertEq(next.candidate, 1843);
        string memory beforeURI = clock.tokenURI(3);
        vm.warp(2_000_000_000);
        vm.roll(99_000_000);
        move(treasury, alice, 3);
        assertEq(clock.tokenURI(3), beforeURI);
    }

    function test_metadataIsValidJSONWithEmbeddedAnimatedLayeredSVG() public view {
        string memory json = string(decodeURI(clock.tokenURI(3), "data:application/json;base64,"));
        assertEq(vm.parseJsonString(json, ".name"), "SeedClock #3");
        string memory image = vm.parseJsonString(json, ".image");
        string memory svg = string(decodeURI(image, "data:image/svg+xml;base64,"));
        assertTrue(contains(svg, '<svg xmlns="http://www.w3.org/2000/svg"'));
        assertTrue(contains(svg, 'viewBox="0 0 480 480"'));
        assertTrue(contains(svg, "</svg>"));
        assertTrue(contains(svg, "<animateTransform"));
        assertTrue(contains(svg, "<animate attributeName=\"opacity\""));
        assertTrue(contains(svg, 'repeatCount="indefinite"'));
        assertTrue(contains(svg, "LRAND48"));
        assertTrue(contains(svg, "871696354"));
        assertFalse(contains(svg, "<script"));
        assertFalse(contains(svg, "<image"));
        assertFalse(contains(svg, "href="));
        assertLt(bytes(svg).length, 12_000);
        assertEq(vm.parseJsonString(json, ".attributes[0].trait_type"), "Background");
        assertEq(vm.parseJsonString(json, ".attributes[1].trait_type"), "Body");
        assertEq(vm.parseJsonString(json, ".attributes[2].trait_type"), "Accessory");
        assertEq(vm.parseJsonString(json, ".attributes[3].trait_type"), "Face");
        assertEq(vm.parseJsonString(json, ".attributes[4].trait_type"), "Glasses");
        assertEq(vm.parseJsonString(json, ".attributes[5].trait_type"), "Tempo");
        assertEq(vm.parseJsonString(json, ".attributes[6].trait_type"), "Direction");
        assertEq(vm.parseJsonUint(json, ".attributes[8].value"), 871696354);
        assertEq(vm.parseJsonUint(json, ".attributes[9].value"), 1842);
    }

    function test_contractMetadataHasPermanentRoyaltyRecipient() public view {
        string memory json = string(decodeURI(clock.contractURI(), "data:application/json;base64,"));
        assertEq(vm.parseJsonString(json, ".name"), "SeedClock");
        assertEq(vm.parseJsonUint(json, ".seller_fee_basis_points"), 690);
        assertEq(vm.parseJsonAddress(json, ".fee_recipient"), address(distributor));
    }

    function test_uriForNonexistentTokenRevertsAndPreviewIsBounded() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 56));
        clock.tokenURI(56);
        vm.expectRevert(SeedData.InvalidTokenId.selector);
        clock.seedData(0);
        vm.expectRevert(SeedData.InvalidTokenId.selector);
        clock.seedData(5556);
        assertEq(clock.seedData(5555).curve, 4);
    }

    function testFuzz_skipAheadMatchesIndependentLinearRecurrence(uint32 timestamp, uint8 n) public pure {
        uint32 candidate = uint32(n) + 1;
        uint256 state = (uint256(timestamp) << 16) + 0x330e;
        uint160 output;
        for (uint256 i; i < uint256(candidate) * 20; ++i) {
            state = (25214903917 * state + 11) % 281474976710656;
            if (i >= uint256(candidate - 1) * 20) output = (output << 8) | uint160(state / 1099511627776);
        }
        assertEq(SeedData.candidateSeed(timestamp, candidate), bytes20(output));
    }

    function testFuzz_traitRangesAndExactMapping(uint16 input) public view {
        uint256 id = bound(input, 1, 5555);
        SeedData.Data memory d = clock.seedData(id);
        SeedArt.Traits memory t = clock.artTraits(id);
        uint256 n = uint256(d.artSeed);
        assertEq(t.background, (n & 255) % 6);
        assertEq(t.body, ((n >> 8) & 255) % 5);
        assertEq(t.accessory, ((n >> 16) & 255) % 6);
        assertEq(t.face, ((n >> 24) & 255) % 5);
        assertEq(t.glasses, ((n >> 32) & 255) % 5);
        assertEq(t.tempo, ((n >> 40) & 255) % 4);
        assertEq(t.reverse, ((n >> 48) & 255) % 2 == 1);
        assertGe(d.timestamp, 852076800);
        assertLt(d.timestamp, 915148800);
    }

    function decodeURI(string memory value, string memory prefix) internal pure returns (bytes memory out) {
        bytes memory input = bytes(value);
        bytes memory pre = bytes(prefix);
        require(input.length >= pre.length, "prefix");
        for (uint256 i; i < pre.length; ++i) {
            require(input[i] == pre[i], "prefix mismatch");
        }
        uint256 len = input.length - pre.length;
        require(len % 4 == 0 && len > 0, "base64 length");
        uint256 padding = input[input.length - 1] == "=" ? 1 : 0;
        if (input[input.length - 2] == "=") ++padding;
        out = new bytes(len / 4 * 3 - padding);
        uint256 cursor;
        for (uint256 i = pre.length; i < input.length; i += 4) {
            uint256 value24 = digit(input[i]) << 18 | digit(input[i + 1]) << 12 | digit(input[i + 2]) << 6
                | digit(input[i + 3]);
            if (cursor < out.length) out[cursor++] = bytes1(uint8(value24 >> 16));
            if (cursor < out.length) out[cursor++] = bytes1(uint8(value24 >> 8));
            if (cursor < out.length) out[cursor++] = bytes1(uint8(value24));
        }
    }

    function digit(bytes1 input) private pure returns (uint256) {
        uint8 c = uint8(input);
        if (c >= 65 && c <= 90) return c - 65;
        if (c >= 97 && c <= 122) return c - 71;
        if (c >= 48 && c <= 57) return c + 4;
        if (c == 43) return 62;
        if (c == 47) return 63;
        require(c == 61, "base64 digit");
        return 0;
    }

    function contains(string memory input, string memory part) internal pure returns (bool) {
        bytes memory haystack = bytes(input);
        bytes memory needle = bytes(part);
        if (needle.length > haystack.length) return false;
        for (uint256 i; i <= haystack.length - needle.length; ++i) {
            bool match_ = true;
            for (uint256 j; j < needle.length; ++j) {
                if (haystack[i + j] != needle[j]) {
                    match_ = false;
                    break;
                }
            }
            if (match_) return true;
        }
        return false;
    }
}
