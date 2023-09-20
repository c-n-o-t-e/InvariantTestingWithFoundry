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
}
