// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLBaseHook} from "./CLBaseHook.sol";
import {CLHooks} from "pancake-v4-core/src/pool-cl/libraries/CLHooks.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "pancake-v4-core/src/types/BeforeSwapDelta.sol";

/**
 * @title An interface for checking whether an address has a valid kycNFT token
 */
interface IKycValidity {
    /// @dev Check whether a given address has a valid kycNFT token
    /// @param _addr Address to check for tokens
    /// @return valid Whether the address has a valid token
    function hasValidToken(address _addr) external view returns (bool valid);
}

/**
 * Only KYC'ed people can trade on the V4 hook'ed pool.
 * Caveat: Relies on external oracle for info on an address's KYC status.
 */
contract KYCSwaps is CLBaseHook, Ownable {
    IKycValidity public kycValidity;
    address private _preKycValidity;
    uint256 private _setKycValidityReqTimestamp;

    constructor(
        ICLPoolManager _poolManager,
        address _kycValidity
    ) CLBaseHook(_poolManager) Ownable(msg.sender){
        kycValidity = IKycValidity(_kycValidity);
    }

    modifier onlyPermitKYC() {
        require(
            kycValidity.hasValidToken(tx.origin),
            "Swaps available for valid KYC token holders"
        );
        _;
    }

    /// Sorta timelock
    function setKycValidity(address _kycValidity) external onlyOwner {
        if (
            block.timestamp - _setKycValidityReqTimestamp >= 7 days &&
            _kycValidity == _preKycValidity
        ) {
            kycValidity = IKycValidity(_kycValidity);
        } else {
            _preKycValidity = _kycValidity;
            _setKycValidityReqTimestamp = block.timestamp;
        }
    }

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
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

    function beforeSwap(
        address,
        PoolKey calldata,
        ICLPoolManager.SwapParams calldata,
        bytes calldata
    ) external view override onlyPermitKYC returns (bytes4, BeforeSwapDelta, uint24) {
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
}