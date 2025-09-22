// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Create2
 * @dev Helper to compute CREATE2 addresses and deploy contracts with CREATE2
 */
library Create2 {
    /**
     * @dev Computes the address of a contract deployed using CREATE2
     * @param deployer The address that will deploy the contract
     * @param salt A salt to influence the contract address
     * @param bytecodeHash The hash of the contract bytecode
     * @return The computed address
     */
    function computeAddress(
        address deployer,
        bytes32 salt,
        bytes32 bytecodeHash
    ) internal pure returns (address) {
        return computeAddress(salt, bytecodeHash, deployer);
    }

    /**
     * @dev Computes the address of a contract deployed using CREATE2
     * @param salt A salt to influence the contract address
     * @param bytecodeHash The hash of the contract bytecode
     * @param deployer The address that will deploy the contract
     * @return The computed address
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                deployer,
                                salt,
                                bytecodeHash
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Deploys a contract using CREATE2
     * @param salt A salt to influence the contract address
     * @param bytecode The contract bytecode
     * @return The address of the deployed contract
     */
    function deploy(
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        assembly {
            addr := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )
        }
        return addr;
    }

    /**
     * @dev Deploys a contract using CREATE2 with constructor arguments
     * @param salt A salt to influence the contract address
     * @param bytecode The contract bytecode
     * @param args The constructor arguments
     * @return The address of the deployed contract
     */
    function deploy(
        bytes32 salt,
        bytes memory bytecode,
        bytes memory args
    ) internal returns (address) {
        bytes memory bytecodeWithArgs = abi.encodePacked(bytecode, args);
        return deploy(salt, bytecodeWithArgs);
    }
}
