// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WETH9} from "../src/WETH9.sol";
import {Handler} from "./handlers/Handler.sol";
import {Test, console2 as console} from "forge-std/Test.sol";

contract WETH9Invariants is Test {
    WETH9 public weth;
    Handler public handler;

    function setUp() public {
        weth = new WETH9();
        handler = new Handler(weth);

        targetContract(address(handler));
    }

    // ETH can only be wrapped into WETH, WETH can only
    // be unwrapped back into ETH. The sum of the Handler's
    // ETH balance plus the WETH totalSupply() should always
    // equal the total ETH_SUPPLY.
    function invariant_badInvariantThisShouldFail() public {
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
}
