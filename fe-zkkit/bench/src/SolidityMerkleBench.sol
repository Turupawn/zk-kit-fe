// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @dev Solidity reference implementation matching `zkkit_merkle`'s Keccak-based helpers.
contract SolidityMerkleBench {
    error InvalidSiblingsLen();
    error RootMismatch();

    function _hash2(uint256 left, uint256 right) internal pure returns (uint256 digest) {
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            digest := keccak256(0x00, 0x40)
        }
    }

    function _computeLeanIMTRoot(uint256 leaf, uint256 index, uint256 siblingsLen, uint256[32] calldata siblings)
        internal
        pure
        returns (uint256 node)
    {
        if (siblingsLen > 32) revert InvalidSiblingsLen();

        node = leaf;
        uint256 idx = index;
        for (uint256 i = 0; i < siblingsLen; i++) {
            uint256 sibling = siblings[i];
            bool isRightChild = (idx & 1) == 1;
            idx >>= 1;
            if (isRightChild) {
                node = _hash2(sibling, node);
            } else {
                node = _hash2(node, sibling);
            }
        }
    }

    function computeLeanIMTRoot(uint256 leaf, uint256 index, uint256 siblingsLen, uint256[32] calldata siblings)
        external
        pure
        returns (uint256)
    {
        return _computeLeanIMTRoot(leaf, index, siblingsLen, siblings);
    }

    function verifyLeanIMT(
        uint256 root,
        uint256 leaf,
        uint256 index,
        uint256 siblingsLen,
        uint256[32] calldata siblings
    ) external pure returns (bool) {
        return _computeLeanIMTRoot(leaf, index, siblingsLen, siblings) == root;
    }

    function updateLeanIMTRoot(
        uint256 currentRoot,
        uint256 oldLeaf,
        uint256 newLeaf,
        uint256 index,
        uint256 siblingsLen,
        uint256[32] calldata siblings
    ) external pure returns (uint256) {
        uint256 oldRoot = _computeLeanIMTRoot(oldLeaf, index, siblingsLen, siblings);
        if (oldRoot != currentRoot) revert RootMismatch();
        return _computeLeanIMTRoot(newLeaf, index, siblingsLen, siblings);
    }

    function _computeSMTRoot(uint256 leaf, uint256 index, uint256 enables, uint256[32] calldata siblings)
        internal
        pure
        returns (uint256 node)
    {
        node = leaf;
        uint256 idx = index;

        // Fast path: if all siblings are enabled, we never need the default `zero` nodes.
        if (enables == type(uint32).max) {
            for (uint256 i = 0; i < 32; i++) {
                uint256 sibling = siblings[i];
                bool isRightChild = (idx & 1) == 1;
                idx >>= 1;
                node = isRightChild ? _hash2(sibling, node) : _hash2(node, sibling);
            }
            return node;
        }

        uint256 zero = 0;
        uint256 cursor = 0;

        for (uint256 i = 0; i < 32; i++) {
            uint256 sibling = (enables & 1) == 1 ? siblings[cursor++] : zero;
            enables >>= 1;

            bool isRightChild = (idx & 1) == 1;
            idx >>= 1;
            if (isRightChild) {
                node = _hash2(sibling, node);
            } else {
                node = _hash2(node, sibling);
            }

            zero = _hash2(zero, zero);
        }
    }

    function computeSMTRoot(uint256 leaf, uint256 index, uint256 enables, uint256[32] calldata siblings)
        external
        pure
        returns (uint256)
    {
        return _computeSMTRoot(leaf, index, enables, siblings);
    }

    function verifySMT(uint256 root, uint256 leaf, uint256 index, uint256 enables, uint256[32] calldata siblings)
        external
        pure
        returns (bool)
    {
        return _computeSMTRoot(leaf, index, enables, siblings) == root;
    }

    function updateSMTRoot(
        uint256 currentRoot,
        uint256 oldLeaf,
        uint256 newLeaf,
        uint256 index,
        uint256 enables,
        uint256[32] calldata siblings
    ) external pure returns (uint256) {
        uint256 oldRoot = _computeSMTRoot(oldLeaf, index, enables, siblings);
        if (oldRoot != currentRoot) revert RootMismatch();
        return _computeSMTRoot(newLeaf, index, enables, siblings);
    }
}
