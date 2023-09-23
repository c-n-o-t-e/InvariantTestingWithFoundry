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
        if (amount > 0) {
            amount = bound(amount, 0, address(this).balance);
            if (amount == 0) ghost_zeroDeposits++;
            _pay(currentActor, amount);

            vm.prank(currentActor);
            weth.deposit{value: amount}();

            ghost_depositSum += amount;
        }
    }

    function withdraw(
        uint256 amount,
        uint actorSeed
    ) public useActor(actorSeed) countCall("withdraw") {
        if (amount > 0) {
            amount = bound(amount, 0, weth.balanceOf(currentActor));
            if (amount == 0) ghost_zeroWithdrawals++;

            vm.startPrank(currentActor);

            weth.withdraw(amount);
            _pay(address(this), amount);

            vm.stopPrank();
            ghost_withdrawSum += amount;
        }
    }

    function sendFallback(
        uint256 amount
    ) public createActor countCall("sendFallback") {
        amount = bound(amount, 0, address(this).balance);
        if (amount > 0) {
            if (amount == 0) ghost_zeroDeposits++;
            _pay(currentActor, amount);

            vm.startPrank(currentActor);
            (bool success, ) = address(weth).call{value: amount}("");

            require(success, "sendFallback failed");
            vm.stopPrank();
            ghost_depositSum += amount;
        }
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
