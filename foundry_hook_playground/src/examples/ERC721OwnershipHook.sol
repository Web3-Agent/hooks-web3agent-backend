// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CLHooks} from "pancake-v4-core/src/pool-cl/libraries/CLHooks.sol";
import {CLBaseHook} from "./CLBaseHook.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "pancake-v4-core/src/types/BeforeSwapDelta.sol";

/// @title ERC721OwnershipHook
contract ERC721OwnershipHook is CLBaseHook {
    /// @notice NFT contract
    IERC721 public immutable nftContract;

    error NotNftOwner();

    constructor(
        ICLPoolManager _poolManager,
        IERC721 _nftContract
    ) CLBaseHook(_poolManager) {
        nftContract = _nftContract;
    }

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: true,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: true,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnsDelta: false,
                afterSwapReturnsDelta: false,
                afterAddLiquidityReturnsDelta: false,
                afterRemoveLiquidityReturnsDelta: false
            })
        );
    }


    function beforeSwap(address sender, PoolKey calldata, ICLPoolManager.SwapParams calldata, bytes calldata)
        external
        override
        view
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        if (nftContract.balanceOf(sender) == 0) {
            revert NotNftOwner();
        }

        return (CLBaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
}