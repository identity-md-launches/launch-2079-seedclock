// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SeedClockFixture, MockIMD} from "./helpers/Fixtures.sol";
import {SeedClock} from "../src/SeedClock.sol";
import {RoyaltyDistributor} from "../src/RoyaltyDistributor.sol";

contract RoyaltyHandler is Test {
    SeedClock public immutable clock;
    RoyaltyDistributor public immutable distributor;
    MockIMD public immutable currency;
    address[4] public actors;
    mapping(address => uint256) public nativeCredit;
    mapping(address => uint256) public tokenCredit;
    uint256 public receivedNative;
    uint256 public claimedNative;
    uint256 public receivedToken;
    uint256 public claimedToken;

    constructor(SeedClock clock_, RoyaltyDistributor distributor_, address[4] memory actors_) {
        clock = clock_;
        distributor = distributor_;
        actors = actors_;
        currency = new MockIMD();
        for (uint256 i; i < 4; ++i) {
            MockIMD(clock.IMD()).mint(actors[i], 1 ether);
        }
        vm.deal(address(this), 1_000_000 ether);
    }

    function mint(uint8 who, uint8 count) external {
        address actor = actors[who % 4];
        uint256 remaining = 5 - clock.publicMinted(actor);
        if (remaining == 0) return;
        uint256 quantity = uint256(count) % remaining + 1;
        vm.prank(actor);
        clock.mint(quantity);
    }

    function transfer(uint16 input, uint8 who) external {
        uint256 id = uint256(input) % clock.totalSupply() + 1;
        address from = clock.ownerOf(id);
        vm.prank(from);
        clock.transferFrom(from, actors[who % 4], id);
    }

    function receiveNative(uint96 input) external {
        uint256 amount = uint256(input) % (10 ether);
        _credit(amount, true);
        receivedNative += amount;
        (bool ok,) = address(distributor).call{value: amount}("");
        require(ok);
    }

    function receiveToken(uint96 input) external {
        uint256 amount = uint256(input) % 10_000_000;
        _credit(amount, false);
        receivedToken += amount;
        currency.mint(address(distributor), amount);
        distributor.syncToken(address(currency));
    }

    function claimNative(uint8 who) external {
        address actor = actors[who % 4];
        // Claims with no pending receipt can revert NothingToClaim. All successful transfers must
        // match the independent receipt-time model (at most 64 receipts in a depth-64 sequence).
        try distributor.claimFor(address(0), actor) returns (uint256 amount) {
            assertEq(amount, nativeCredit[actor]);
            nativeCredit[actor] -= amount;
            claimedNative += amount;
        } catch {
            assertEq(nativeCredit[actor], 0);
        }
    }

    function claimToken(uint8 who) external {
        address actor = actors[who % 4];
        try distributor.claimFor(address(currency), actor) returns (uint256 amount) {
            assertEq(amount, tokenCredit[actor]);
            tokenCredit[actor] -= amount;
            claimedToken += amount;
        } catch {
            assertEq(tokenCredit[actor], 0);
        }
    }

    function _credit(uint256 amount, bool nativeAsset) private {
        uint256 perToken = amount / clock.totalSupply();
        uint256 dust = amount % clock.totalSupply();
        address firstOwner = clock.ownerOf(1);
        for (uint256 i; i < 4; ++i) {
            address actor = actors[i];
            uint256 earned = clock.balanceOf(actor) * perToken;
            if (actor == firstOwner) earned += dust;
            if (nativeAsset) nativeCredit[actor] += earned;
            else tokenCredit[actor] += earned;
        }
    }
}

contract StatefulTest is SeedClockFixture {
    RoyaltyHandler private handler;
    address[4] private actors;

    function setUp() public override {
        super.setUp();
        actors = [treasury, alice, bob, operator];
        handler = new RoyaltyHandler(clock, distributor, actors);
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = handler.mint.selector;
        selectors[1] = handler.transfer.selector;
        selectors[2] = handler.receiveNative.selector;
        selectors[3] = handler.receiveToken.selector;
        selectors[4] = handler.claimNative.selector;
        selectors[5] = handler.claimToken.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    function invariant_allSharesMatchERC721Balances() public view {
        uint256 sum;
        for (uint256 i; i < 4; ++i) {
            uint256 balance = clock.balanceOf(actors[i]);
            assertEq(distributor.shares(actors[i]), balance);
            assertLe(clock.publicMinted(actors[i]), 5);
            sum += balance;
        }
        assertEq(sum, clock.totalSupply());
        assertEq(sum, distributor.totalShares());
        assertLe(sum, 5555);
        assertEq(distributor.firstTokenOwner(), clock.ownerOf(1));
    }

    function invariant_nativeAssetsConservedAndAllFundsClaimable() public view {
        uint256 liabilities;
        for (uint256 i; i < 4; ++i) {
            assertEq(distributor.claimable(actors[i]), handler.nativeCredit(actors[i]));
            liabilities += handler.nativeCredit(actors[i]);
        }
        assertEq(address(distributor).balance, liabilities);
        assertEq(distributor.accountedBalance(address(0)), liabilities);
        assertEq(handler.receivedNative(), handler.claimedNative() + liabilities);
        assertEq(handler.receivedNative(), distributor.totalReceived(address(0)));
        assertEq(handler.claimedNative(), distributor.totalClaimed(address(0)));
    }

    function invariant_erc20AssetsConservedAndAllFundsClaimable() public view {
        address currency = address(handler.currency());
        uint256 liabilities;
        for (uint256 i; i < 4; ++i) {
            (uint256 amount,) = distributor.claimable(currency, actors[i]);
            assertEq(amount, handler.tokenCredit(actors[i]));
            liabilities += amount;
        }
        assertEq(MockIMD(currency).balanceOf(address(distributor)), liabilities);
        assertEq(distributor.accountedBalance(currency), liabilities);
        assertEq(handler.receivedToken(), handler.claimedToken() + liabilities);
        assertEq(handler.receivedToken(), distributor.totalReceived(currency));
        assertEq(handler.claimedToken(), distributor.totalClaimed(currency));
    }
}
