// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CLBaseHook} from "./CLBaseHook.sol";
import {CLHooks} from "pancake-v4-core/src/pool-cl/libraries/CLHooks.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "pancake-v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "pancake-v4-core/src/types/BeforeSwapDelta.sol";

contract HighestLiquidityHolderHook is CLBaseHook {
    using PoolIdLibrary for PoolKey;

    // State to keep track of liquidity and the highest liquidity holder
    struct LiquidityInfo {
        address holder;
        uint256 liquidity;
    }

    mapping(PoolId => LiquidityInfo) public highestLiquidityHolder;

    constructor(ICLPoolManager _poolManager) CLBaseHook(_poolManager) {}

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: true,
                afterAddLiquidity: true,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: true,
                beforeSwap: false,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnsDelta: false,
                afterSwapReturnsDelta: false,
                afterAddLiquidityReturnsDelta: false,
                afterRemoveLiquidityReturnsDelta: false
            })
        );
    }

    // Function to update highest liquidity holder when adding liquidity
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ICLPoolManager.ModifyPositionParams calldata params,
        bytes calldata
    ) external override returns (bytes4) {
        PoolId poolId = key.toId();
        uint256 newLiquidity = params.liquidityDelta; // Corrected to liquidityDelta

        if (newLiquidity > highestLiquidityHolder[poolId].liquidity) {
            highestLiquidityHolder[poolId] = LiquidityInfo(sender, newLiquidity);
        }

        return CLBaseHook.beforeAddLiquidity.selector;
    }

    // Function to update highest liquidity holder after removing liquidity
    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ICLPoolManager.ModifyPositionParams calldata params,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4) {
        PoolId poolId = key.toId();
        if (sender == highestLiquidityHolder[poolId].holder && params.liquidityDelta <= highestLiquidityHolder[poolId].liquidity) {
            // Find the next highest liquidity holder
            // For simplicity, we are not implementing this in this example
            // In a practical scenario, you would need logic to iterate through liquidity providers
            highestLiquidityHolder[poolId] = LiquidityInfo(address(0), 0);
        }

        return CLBaseHook.afterRemoveLiquidity.selector;
    }

   function validateHookAddress(CLBaseHook _this) internal pure {
            }
        }