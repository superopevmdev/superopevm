// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MultiSigWallet as MultiSigWallet} from "@superopevm/contracts/multisig/MultiSigWallet.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";

/**
 * @title MultiSigFactory
 * @dev Factory contract to deploy MultiSigWallet instances
 */
contract MultiSigFactory is Ownable {
    // Events
    event MultiSigCreated(
        address indexed multiSigAddress,
        address[] owners,
        uint256 required,
        uint256 timestamp
    );

    /**
     * @dev Deploy a new MultiSigWallet
     * @param _owners List of initial owners
     * @param _required Number of required confirmations
     * @return Address of the deployed contract
     */
    function createMultiSigWallet(
        address[] memory _owners,
        uint256 _required
    ) external returns (address) {
        MultiSigWallet multiSig = new MultiSigWallet(_owners, _required);
        emit MultiSigCreated(
            address(multiSig),
            _owners,
            _required,
            block.timestamp
        );
        return address(multiSig);
    }

    /**
     * @dev Predict the address of a MultiSigWallet before deployment
     * @param _owners List of initial owners
     * @param _required Number of required confirmations
     * @return Predicted address
     */
    function predictMultiSigAddress(
        address[] memory _owners,
        uint256 _required
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            type(MultiSigWallet).creationCode
        );
        bytes32 salt = keccak256(abi.encodePacked(_owners, _required));
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            bytecodeHash
                        )
                    )
                )
            )
        );
    }
}
