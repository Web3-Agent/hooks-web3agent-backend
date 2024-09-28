// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLHooks} from "pancake-v4-core/src/pool-cl/libraries/CLHooks.sol";
import {CLBaseHook} from "./CLBaseHook.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "pancake-v4-core/src/types/BeforeSwapDelta.sol";

contract WhitelistHook is CLBaseHook, Ownable {

    mapping(address => bool) public whitelisted;

    event AddedToWhitelist(address indexed addr);
    event RemovedFromWhitelist(address indexed addr);

    constructor(ICLPoolManager _poolManager) CLBaseHook(_poolManager) Ownable(msg.sender){}

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: true,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
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

    function addToWhitelist(address _address) external onlyOwner {
        whitelisted[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelisted[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function beforeAddLiquidity(
        address sender,
        PoolKey calldata,
        ICLPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override view returns (bytes4) {
        require(whitelisted[sender], "WhitelistHook: Not whitelisted");
        return CLBaseHook.beforeAddLiquidity.selector;
    }

    function beforeSwap(address sender, PoolKey calldata, ICLPoolManager.SwapParams calldata, bytes calldata)
        external
        override
        view
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        require(whitelisted[sender], "WhitelistHook: Not whitelisted");
        return (CLBaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

}