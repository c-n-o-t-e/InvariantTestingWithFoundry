// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WETH9} from "../src/WETH9.sol";
import {Handler} from "./handlers/Handler.sol";
import {AddressPair} from "./helpers/LibAddressSet.sol";
import {Test, console2 as console} from "forge-std/Test.sol";

contract WETH9Invariants is Test {
    WETH9 public weth;
    Handler public handler;

    function setUp() public {
        weth = new WETH9();
        handler = new Handler(weth);

        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.withdraw.selector;
        selectors[2] = Handler.sendFallback.selector;
        selectors[3] = Handler.approve.selector;
        selectors[4] = Handler.transfer.selector;
        selectors[5] = Handler.transferFrom.selector;

        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );

        targetContract(address(handler));
    }

    // ETH can only be wrapped into WETH, WETH can only
    // be unwrapped back into ETH. The sum of the Handler's
    // ETH balance plus the WETH totalSupply() should always
    // equal the total ETH_SUPPLY.
    function invariant_ensureEthSupplyIsCorrect() public {
        assertEq(
            handler.ETH_SUPPLY(),
            address(handler).balance + weth.totalSupply()
        );
    }

    // The WETH contract's Ether balance should always
    // equal the sum of all the individual deposits
    // minus all the individual withdrawals
    function invariant_solvencyDeposits() public {
        assertEq(
            address(weth).balance,
            handler.ghost_depositSum() - handler.ghost_withdrawSum()
        );
    }

    // The WETH contract's Ether balance should always be
    // at least as much as the sum of individual balances
    function invariant_solvencyBalances() public {
        uint256 sumOfBalances;
        address[] memory actors = handler.actors();
        for (uint256 i; i < actors.length; ++i) {
            sumOfBalances += weth.balanceOf(actors[i]);
        }
        assertEq(address(weth).balance, sumOfBalances);
    }

    // Ensures all WETH allowance balance should always be
    // at least as much as the sum of individual approved balances.
    function invariant_solvencyApprovals() public {
        uint256 sumOfApprovedBalances;
        AddressPair[] memory actors = handler.approvalActors();

        for (uint256 i; i < actors.length; ++i) {
            sumOfApprovedBalances += weth.allowance(
                actors[i].addr1,
                actors[i].addr2
            );
        }

        assertEq(
            handler.ghost_approvedSum() - handler.ghost_UsedApprovedSum(),
            sumOfApprovedBalances
        );
    }

    function invariant_callSummary() public view {
        handler.callSummary();
    }
}
