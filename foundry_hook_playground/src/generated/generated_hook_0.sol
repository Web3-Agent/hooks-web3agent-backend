// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CLBaseHook} from "./CLBaseHook.sol";
import {CLHooks} from "pancake-v4-core/src/pool-cl/libraries/CLHooks.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "pancake-v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "pancake-v4-core/src/types/BeforeSwapDelta.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract WhitelistHook is CLBaseHook, Ownable {
    // Mapping to store whitelisted addresses
    mapping(address => bool) public whitelisted;

    // Events for whitelist management
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    constructor(ICLPoolManager _poolManager) CLBaseHook(_poolManager) Ownable(msg.sender) {}

    // Function to add an address to the whitelist
    function addToWhitelist(address _address) external onlyOwner {
        whitelisted[_address] = true;
        emit AddedToWhitelist(_address);
    }

    // Function to remove an address from the whitelist
    function removeFromWhitelist(address _address) external onlyOwner {
        whitelisted[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    // Hook registration bitmap
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

    // Hook functions
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata,
        ICLPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override view returns (bytes4) {
        require(whitelisted[sender], "WhitelistHook: Sender not whitelisted");
        return CLBaseHook.beforeAddLiquidity.selector;
    }

    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata,
        ICLPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override view returns (bytes4) {
        require(whitelisted[sender], "WhitelistHook: Sender not whitelisted");
        return CLBaseHook.beforeRemoveLiquidity.selector;
    }

    function beforeSwap(
        address sender,
        PoolKey calldata,
        ICLPoolManager.SwapParams calldata,
        bytes calldata
    ) external override view returns (bytes4, BeforeSwapDelta, uint24) {
        require(whitelisted[sender], "WhitelistHook: Sender not whitelisted");
        return (CLBaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
   function validateHookAddress(CLBaseHook _this) internal pure {
            }
        }