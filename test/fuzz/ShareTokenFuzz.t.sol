// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ShareToken} from "../../contracts/token/ShareToken.sol";

/// @dev Minimal Foundry cheatcode interface (subset).
interface Vm {
    function assume(bool condition) external;
    function expectRevert(bytes calldata revertData) external;
}

/// @dev Minimal Foundry-style Test base (subset of forge-std/Test.sol).
abstract contract Test {
    // keccak256("hevm cheat code")
    address internal constant HEVM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(HEVM_ADDRESS);

    function _bound(uint256 x, uint256 min, uint256 max) internal pure returns (uint256) {
        require(min <= max, "bound: min>max");
        if (min == max) return min;
        uint256 size = max - min + 1;
        if (size == 0) return x; // full uint256 range
        return min + (x % size);
    }

    function _assertEq(uint256 a, uint256 b, string memory err) internal pure {
        require(a == b, err);
    }

    function _err(string memory reason) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("Error(string)", reason);
    }
}

/// @notice Fuzz tests for ShareToken (Foundry).
contract ShareTokenFuzz is Test {

    uint256 internal constant TOKENS_PER_UNIT = 1000;
    uint256 internal constant BPS_DENOMINATOR = 10000;
    uint256 internal constant TREASURY_BPS = 1000;
    uint256 internal constant LP_BPS = 500;
    uint256 internal constant MAX_RATE_CHANGE_BPS = 2000;

    ShareToken internal token;

    address internal treasury;
    address internal lp;

    function setUp() public {
        treasury = address(0xBEEF);
        lp = address(0xCAFE);

        token = new ShareToken();
        token.initialize("ShareToken", "SHARE", address(this), treasury, lp);
    }

    // ============ Minting (mintByUsage) ============

    function testFuzz_mintByUsage_distribution_mathAddsUp(
        uint256 tokenConsumedSeed,
        address provider,
        uint8 modelIndex
    ) public {
        vm.assume(provider != address(0));
        vm.assume(provider != treasury && provider != lp);

        string memory model = _modelFromIndex(modelIndex);
        uint256 rate = token.getMintingRate(model);
        // Sanity: selected model must exist.
        vm.assume(rate > 0);

        // Ensure tokenConsumed > 0 and amount > 0.
        uint256 minConsumed = _minTokenConsumedForNonZeroAmount(rate);
        uint256 maxConsumed = type(uint256).max / rate; // avoid overflow in tokenConsumed * rate
        vm.assume(minConsumed <= maxConsumed);

        uint256 tokenConsumed = _bound(tokenConsumedSeed, minConsumed, maxConsumed);

        uint256 beforeProvider = token.balanceOf(provider);
        uint256 beforeTreasury = token.balanceOf(treasury);
        uint256 beforeLp = token.balanceOf(lp);
        uint256 beforeSupply = token.totalSupply();

        token.mintByUsage(model, tokenConsumed, provider);

        uint256 amount = (tokenConsumed * rate) / TOKENS_PER_UNIT;
        // By construction, amount > 0.
        uint256 expectedTreasury = (amount * TREASURY_BPS) / BPS_DENOMINATOR;
        uint256 expectedLp = (amount * LP_BPS) / BPS_DENOMINATOR;
        uint256 expectedProvider = amount - expectedTreasury - expectedLp;

        _assertEq(token.balanceOf(provider) - beforeProvider, expectedProvider, "provider minted != expected");
        _assertEq(token.balanceOf(treasury) - beforeTreasury, expectedTreasury, "treasury minted != expected");
        _assertEq(token.balanceOf(lp) - beforeLp, expectedLp, "lp minted != expected");
        _assertEq(token.totalSupply() - beforeSupply, amount, "totalSupply delta != amount");

        // Precision invariant: provider + treasury + lp == amount
        _assertEq(expectedProvider + expectedTreasury + expectedLp, amount, "85/10/5 sum != amount");
    }

    function testFuzz_mintByUsage_largeAmounts_succeeds(uint256 tokenConsumedSeed, address provider) public {
        vm.assume(provider != address(0));
        vm.assume(provider != treasury && provider != lp);

        // Use the highest initial rate model to exercise large mint amounts.
        string memory model = "seedance-2.0";
        uint256 rate = token.getMintingRate(model);
        vm.assume(rate > 0);

        uint256 minConsumed = _minTokenConsumedForNonZeroAmount(rate);
        uint256 maxConsumed = type(uint256).max / rate;
        vm.assume(minConsumed <= maxConsumed);

        // Force tokenConsumed into the upper half of the safe range.
        uint256 lower = maxConsumed / 2;
        if (lower < minConsumed) lower = minConsumed;
        uint256 tokenConsumed = _bound(tokenConsumedSeed, lower, maxConsumed);

        uint256 beforeSupply = token.totalSupply();
        token.mintByUsage(model, tokenConsumed, provider);

        uint256 amount = (tokenConsumed * rate) / TOKENS_PER_UNIT;
        _assertEq(token.totalSupply() - beforeSupply, amount, "large mint supply delta != amount");
    }

    function testFuzz_mintByUsage_reverts_whenAmountRoundsToZero(uint256 tokenConsumedSeed, address provider)
        public
    {
        vm.assume(provider != address(0));

        // For rate=100 (gpt-3.5-turbo), tokenConsumed < 10 makes amount==0.
        uint256 tokenConsumed = _bound(tokenConsumedSeed, 1, 9);

        vm.expectRevert(_err("ShareToken: amount=0"));
        token.mintByUsage("gpt-3.5-turbo", tokenConsumed, provider);
    }

    function testFuzz_mintByUsage_overflow_tokenConsumedTimesRate_reverts(uint256 tokenConsumedSeed, address provider)
        public
    {
        vm.assume(provider != address(0));
        vm.assume(provider != treasury && provider != lp);

        // New model has no ±20% constraint on first set.
        token.updateMintingRate("overflow-model", type(uint256).max);

        // Any tokenConsumed >= 2 will overflow tokenConsumed * rate.
        uint256 tokenConsumed = _bound(tokenConsumedSeed, 2, type(uint256).max);

        // Panic(0x11) = arithmetic overflow/underflow.
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));
        token.mintByUsage("overflow-model", tokenConsumed, provider);
    }

    // ============ Governance (updateMintingRate) ============

    function testFuzz_updateMintingRate_within20Percent_succeeds(uint16 deltaBpsSeed, bool increase) public {
        string memory model = "claude-3-opus";
        uint256 oldRate = token.getMintingRate(model);
        vm.assume(oldRate > 0);

        uint256 deltaBps = _bound(uint256(deltaBpsSeed), 0, MAX_RATE_CHANGE_BPS);
        uint256 delta = (oldRate * deltaBps) / BPS_DENOMINATOR;

        uint256 newRate = increase ? (oldRate + delta) : (oldRate - delta);
        // newRate is always > 0 because delta <= 20% of oldRate.
        vm.assume(newRate > 0);

        token.updateMintingRate(model, newRate);
        _assertEq(token.getMintingRate(model), newRate, "rate not updated");
    }

    function testFuzz_updateMintingRate_outside20Percent_reverts(uint256 newRateSeed, bool tooHigh) public {
        string memory model = "claude-3-opus";
        uint256 oldRate = token.getMintingRate(model);
        vm.assume(oldRate > 0);

        uint256 maxDelta = (oldRate * MAX_RATE_CHANGE_BPS) / BPS_DENOMINATOR;
        uint256 lower = oldRate - maxDelta;
        uint256 upper = oldRate + maxDelta;

        uint256 newRate;
        if (tooHigh) {
            // Strictly greater than upper.
            uint256 minHigh = upper + 1;
            newRate = _bound(newRateSeed, minHigh, type(uint256).max);
        } else {
            // Strictly less than lower, but still > 0 to avoid the newRate=0 guard.
            vm.assume(lower > 1);
            newRate = _bound(newRateSeed, 1, lower - 1);
        }

        vm.expectRevert(_err("ShareToken: delta>20%"));
        token.updateMintingRate(model, newRate);
    }

    function testFuzz_updateMintingRate_newModel_noDeltaLimit(uint256 newRateSeed, bytes32 modelSeed) public {
        uint256 newRate = _bound(newRateSeed, 1, type(uint256).max);
        string memory model = string(abi.encodePacked("new-model-", _toHex(modelSeed)));

        token.updateMintingRate(model, newRate);
        _assertEq(token.getMintingRate(model), newRate, "new model rate not set");
    }

    // ============ Airdrop (batchAirdrop) ============

    function testFuzz_batchAirdrop_emptyArrays_noop(string memory reason) public {
        address[] memory recipients = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        uint256 beforeSupply = token.totalSupply();
        token.batchAirdrop(recipients, amounts, reason);
        _assertEq(token.totalSupply(), beforeSupply, "empty airdrop changed supply");
    }

    function testFuzz_batchAirdrop_lengthMismatch_reverts(uint256 lenASeed, uint256 lenBSeed, string memory reason)
        public
    {
        uint256 lenA = _bound(lenASeed, 0, 32);
        uint256 lenB = _bound(lenBSeed, 0, 32);
        vm.assume(lenA != lenB);

        address[] memory recipients = new address[](lenA);
        uint256[] memory amounts = new uint256[](lenB);

        vm.expectRevert(_err("ShareToken: length"));
        token.batchAirdrop(recipients, amounts, reason);
    }

    function testFuzz_batchAirdrop_reverts_onZeroRecipient(uint256 amountSeed, string memory reason) public {
        uint256 amount = _bound(amountSeed, 1, type(uint128).max);

        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = address(0);
        amounts[0] = amount;

        vm.expectRevert(_err("ShareToken: recipient=0"));
        token.batchAirdrop(recipients, amounts, reason);
    }

    function testFuzz_batchAirdrop_reverts_onZeroAmount(address recipient, string memory reason) public {
        vm.assume(recipient != address(0));

        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = recipient;
        amounts[0] = 0;

        vm.expectRevert(_err("ShareToken: amount=0"));
        token.batchAirdrop(recipients, amounts, reason);
    }

    function testFuzz_batchAirdrop_success_tracksHistoryAndSupply(
        address[] memory recipientsSeed,
        uint256[] memory amountsSeed,
        string memory reason
    ) public {
        // Build equal-length arrays with a reasonable upper bound.
        uint256 n = recipientsSeed.length;
        if (amountsSeed.length < n) n = amountsSeed.length;
        if (n > 32) n = 32;

        address[] memory recipients = new address[](n);
        uint256[] memory amounts = new uint256[](n);

        for (uint256 i = 0; i < n; i++) {
            address r = recipientsSeed[i];
            uint256 a = _bound(amountsSeed[i], 1, type(uint128).max);
            vm.assume(r != address(0));
            recipients[i] = r;
            amounts[i] = a;
        }

        // Snapshot per-index (handles duplicates via O(n^2) expected sums).
        uint256[] memory beforeBalances = new uint256[](n);
        uint256[] memory beforeHistory = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            beforeBalances[i] = token.balanceOf(recipients[i]);
            beforeHistory[i] = token.getAirdropHistory(recipients[i]);
        }

        uint256 beforeSupply = token.totalSupply();
        token.batchAirdrop(recipients, amounts, reason);

        uint256 expectedTotal;
        for (uint256 i = 0; i < n; i++) {
            expectedTotal += amounts[i];
        }
        _assertEq(token.totalSupply() - beforeSupply, expectedTotal, "airdrop supply delta != sum(amounts)");

        for (uint256 i = 0; i < n; i++) {
            uint256 expectedForRecipient;
            for (uint256 j = 0; j < n; j++) {
                if (recipients[j] == recipients[i]) expectedForRecipient += amounts[j];
            }

            _assertEq(
                token.balanceOf(recipients[i]) - beforeBalances[i],
                expectedForRecipient,
                "recipient balance delta != expected"
            );
            _assertEq(
                token.getAirdropHistory(recipients[i]) - beforeHistory[i],
                expectedForRecipient,
                "recipient history delta != expected"
            );
        }
    }

    // ============ Helpers ============

    function _modelFromIndex(uint8 i) internal pure returns (string memory) {
        uint8 idx = i % 5;
        if (idx == 0) return "claude-3-opus";
        if (idx == 1) return "claude-3-sonnet";
        if (idx == 2) return "gpt-4-turbo";
        if (idx == 3) return "gpt-3.5-turbo";
        return "seedance-2.0";
    }

    function _minTokenConsumedForNonZeroAmount(uint256 rate) internal pure returns (uint256) {
        // amount = tokenConsumed * rate / 1000 > 0  <=> tokenConsumed * rate >= 1000
        // tokenConsumed >= ceil(1000 / rate)
        return (TOKENS_PER_UNIT + rate - 1) / rate;
    }

    function _toHex(bytes32 data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            uint8 b = uint8(data[i]);
            str[i * 2] = alphabet[b >> 4];
            str[i * 2 + 1] = alphabet[b & 0x0f];
        }
        return string(str);
    }
}
