// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WETH9} from "../../src/WETH9.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {console2 as console} from "forge-std/Test.sol";
import {AddressSet, AddressPair, LibAddressSet} from "../helpers/LibAddressSet.sol";

contract Handler is CommonBase, StdCheats, StdUtils {
    using LibAddressSet for AddressSet;
    AddressSet internal _actors;

    WETH9 public weth;

    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;

    uint256 public ghost_approvedSum;
    uint256 public ghost_zeroDeposits;

    uint256 public ghost_zeroApprovals;
    uint256 public ghost_zeroTransfers;

    uint256 public ghost_UsedApprovedSum;
    uint256 public ghost_zeroWithdrawals;

    uint256 public ghost_zeroTransferFroms;

    address currentActor;

    uint256 public constant ETH_SUPPLY = 120_500_000 ether;

    mapping(bytes32 => uint256) public calls;

    constructor(WETH9 _weth) {
        weth = _weth;
        deal(address(this), ETH_SUPPLY);
    }

    modifier createActor() {
        currentActor = msg.sender;
        _actors.add(currentActor);
        _;
    }

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = _actors.rand(actorIndexSeed);
        _;
    }

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    function deposit(uint256 amount) public createActor countCall("deposit") {
        amount = bound(amount, 0, address(this).balance);
        if (amount == 0) ghost_zeroDeposits++;
        _pay(currentActor, amount);

        vm.prank(currentActor);
        weth.deposit{value: amount}();

        ghost_depositSum += amount;
    }

    function withdraw(
        uint256 amount,
        uint actorSeed
    ) public useActor(actorSeed) countCall("withdraw") {
        amount = bound(amount, 0, weth.balanceOf(currentActor));
        if (amount == 0) ghost_zeroWithdrawals++;

        vm.startPrank(currentActor);

        weth.withdraw(amount);
        _pay(address(this), amount);

        vm.stopPrank();
        ghost_withdrawSum += amount;
    }

    function sendFallback(
        uint256 amount
    ) public createActor countCall("sendFallback") {
        amount = bound(amount, 0, address(this).balance);

        if (amount == 0) ghost_zeroDeposits++;
        _pay(currentActor, amount);

        vm.startPrank(currentActor);
        (bool success, ) = address(weth).call{value: amount}("");

        require(success, "sendFallback failed");
        vm.stopPrank();
        ghost_depositSum += amount;
    }

    function approve(
        uint256 actorSeed,
        uint256 spenderSeed,
        uint256 amount
    ) public useActor(actorSeed) countCall("approve") {
        amount = bound(amount, 0, type(uint248).max - ghost_approvedSum);

        if (amount == 0) ghost_zeroApprovals++;
        address spender = _actors.rand(spenderSeed);

        if (currentActor != spender) {
            if (weth.allowance(currentActor, spender) > 0) {} else {
                vm.prank(currentActor);
                weth.approve(spender, amount);

                _actors.add(currentActor, spender);
                ghost_approvedSum += amount;
            }
        }
    }

    function transfer(
        uint256 actorSeed,
        uint256 toSeed,
        uint256 amount
    ) external useActor(actorSeed) countCall("transfer") {
        amount = bound(amount, 0, weth.balanceOf(currentActor));
        address to = _actors.rand(toSeed);

        vm.startPrank(currentActor);
        weth.transfer(to, amount);

        if (amount == 0) ghost_zeroTransfers++;
        vm.stopPrank();
    }

    function transferFrom(
        uint256 actorSeed,
        uint256 fromSeed,
        uint256 amount,
        uint256 toSeed
    ) external useActor(actorSeed) countCall("transferFrom") {
        address to = _actors.rand(toSeed);
        address from = _actors.rand(fromSeed);
        amount = bound(amount, 0, weth.balanceOf(from));

        if (from == currentActor) {
            vm.startPrank(currentActor);
            if (amount == 0) ghost_zeroTransferFroms++;

            weth.transferFrom(from, to, amount);
            vm.stopPrank();
        } else {
            vm.startPrank(from);

            if (weth.allowance(from, currentActor) > 0) {
                amount = bound(amount, 0, weth.allowance(from, currentActor));
            } else {
                amount = bound(
                    amount,
                    0,
                    type(uint248).max - ghost_approvedSum
                );

                calls["approve"]++;
                weth.approve(currentActor, amount);

                if (amount == 0) ghost_zeroApprovals++;

                _actors.add(from, currentActor);
                ghost_approvedSum += amount;
            }

            vm.stopPrank();
            vm.startPrank(currentActor);

            if (amount == 0) ghost_zeroTransferFroms++;

            weth.transferFrom(from, to, amount);
            vm.stopPrank();

            ghost_UsedApprovedSum += amount;
        }
    }

    function actors() external view returns (address[] memory) {
        return _actors.addrs;
    }

    function approvalActors() external view returns (AddressPair[] memory) {
        return _actors.addressPairs;
    }

    function _pay(address to, uint256 amount) internal {
        (bool s, ) = to.call{value: amount}("");
        require(s, "pay() failed");
    }

    function callSummary() external view {
        console.log("Call summary:");

        console.log("-------------------");
        console.log("approve", calls["approve"]);
        console.log("deposit", calls["deposit"]);
        console.log("withdraw", calls["withdraw"]);
        console.log("transfer", calls["transfer"]);
        console.log("sendFallback", calls["sendFallback"]);
        console.log("transferFrom", calls["transferFrom"]);

        console.log("-------------------");
        console.log("Zero deposits:", ghost_zeroDeposits);
        console.log("Zero approvals:", ghost_zeroApprovals);
        console.log("Zero transfers:", ghost_zeroTransfers);
        console.log("Zero withdrawals:", ghost_zeroWithdrawals);
        console.log("Zero transferFroms:", ghost_zeroTransferFroms);
    }

    receive() external payable {}
}
