// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IOptimismMintableERC20Factory
interface IOptimismMintableERC20Factory {
    /// @notice Creates an instance of the OptimismMintableERC20 contract.
    /// @param _remoteToken Address of the token on the remote chain.
    /// @param _name        ERC20 name.
    /// @param _symbol      ERC20 symbol.
    /// @return Address of the newly created token.
    function createOptimismMintableERC20(
        address _remoteToken,
        string memory _name,
        string memory _symbol
    ) external returns (address);
}
