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

    receive() external payable {}
}
