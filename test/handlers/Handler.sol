// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WETH9} from "../../src/WETH9.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {AddressSet, LibAddressSet} from "../helpers/LibAddressSet.sol";

contract Handler is CommonBase, StdCheats, StdUtils {
    using LibAddressSet for AddressSet;
    AddressSet internal _actors;

    WETH9 public weth;

    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;

    address currentActor;

    uint256 public constant ETH_SUPPLY = 120_500_000 ether;

    constructor(WETH9 _weth) {
        weth = _weth;
        deal(address(this), ETH_SUPPLY);
    }

    modifier createActor() {
        currentActor = msg.sender;
        _actors.add(currentActor);
        _;
    }

    function deposit(uint256 amount) public createActor {
        amount = bound(amount, 0, address(this).balance);
        _pay(currentActor, amount);

        vm.prank(currentActor);
        weth.deposit{value: amount}();

        ghost_depositSum += amount;
    }

    function withdraw(uint256 amount) public createActor {
        amount = bound(amount, 0, weth.balanceOf(currentActor));
        vm.startPrank(currentActor);

        weth.withdraw(amount);
        _pay(address(this), amount);

        vm.stopPrank();
        ghost_withdrawSum += amount;
    }

    function sendFallback(uint256 amount) public createActor {
        amount = bound(amount, 0, address(this).balance);
        _pay(currentActor, amount);

        vm.prank(currentActor);
        (bool success, ) = address(weth).call{value: amount}("");

        require(success, "sendFallback failed");
        ghost_depositSum += amount;
    }

    function actors() external view returns (address[] memory) {
        return _actors.addrs;
    }

    function _pay(address to, uint256 amount) internal {
        (bool s, ) = to.call{value: amount}("");
        require(s, "pay() failed");
    }

    receive() external payable {}
}
