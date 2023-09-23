// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

struct AddressPair {
    address addr1;
    address addr2;
}

struct AddressSet {
    address[] addrs;
    AddressPair[] addressPairs;
    mapping(address => bool) saved;
    mapping(address => mapping(address => bool)) savedAllowance;
}

library LibAddressSet {
    function add(AddressSet storage s, address addr) internal {
        if (!s.saved[addr]) {
            s.addrs.push(addr);
            s.saved[addr] = true;
        }
    }

    function add(AddressSet storage s, address addr, address addr0) internal {
        if (!s.savedAllowance[addr][addr0]) {
            AddressPair memory newPair = AddressPair(addr, addr0);
            s.addressPairs.push(newPair);
            s.savedAllowance[addr][addr0] = true;
        }
    }

    function rand(
        AddressSet storage s,
        uint256 seed
    ) internal view returns (address) {
        if (s.addrs.length > 0) {
            return s.addrs[seed % s.addrs.length];
        } else {
            return address(0);
        }
    }

    function contains(
        AddressSet storage s,
        address addr
    ) internal view returns (bool) {
        return s.saved[addr];
    }

    function count(AddressSet storage s) internal view returns (uint256) {
        return s.addrs.length;
    }
}
