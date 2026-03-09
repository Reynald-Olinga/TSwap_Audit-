/**
 * /-\|/-\|/-\|/-\|/-\|/-\|/-\|/-\|/-\|/-\
 * |                                     |
 * \ _____    ____                       /
 * -|_   _|  / ___|_      ____ _ _ __    -
 * /  | |____\___ \ \ /\ / / _` | '_ \   \
 * |  | |_____|__) \ V  V / (_| | |_) |  |
 * \  |_|    |____/ \_/\_/ \__,_| .__/   /
 * -                            |_|      -
 * /                                     \
 * |                                     |
 * \-/|\-/|\-/|\-/|\-/|\-/|\-/|\-/|\-/|\-/
 */
// SPDX-License-Identifier: GNU General Public License v3.0
// @written-info  Use a specific version of Solidity in contracts instead of a wide version.  Be sure to select the appropriate EVM version in case you intend to deploy on a chain other than mainnet like L2 chains that may not support PUSH0
pragma solidity ^0.8.20;

import {TSwapPool} from "./TSwapPool.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract PoolFactory {
    error PoolFactory__PoolAlreadyExists(address tokenAddress);
    // @written-info Consider using or removing the unused error.
    error PoolFactory__PoolDoesNotExist(address tokenAddress);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    mapping(address token => address pool) private s_pools; // e probably the poolToken -> pool
    mapping(address pool => address token) private s_tokens; // e mapping back

    address private immutable i_wethToken;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event PoolCreated(address tokenAddress, address poolAddress);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(address wethToken) {
        i_wethToken = wethToken;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    // e tokenAddress -> weth for a token/weth pool
    function createPool(address tokenAddress) external returns (address) {
        if (s_pools[tokenAddress] != address(0)) {
            revert PoolFactory__PoolAlreadyExists(tokenAddress);
        }

        // @written - high Changing state after an external call can lead to re-entrancy attacks
        // q "weird ERC20" what if the name function revert or return an empty string ?
        string memory liquidityTokenName = string.concat(
            "T-Swap ",
            IERC20(tokenAddress).name()
        );

        // @written - high Changing state after an external call can lead to re-entrancy attacks
        // @written - info This should be "IERC20(tokenAddress).symbol()" instead of "IERC20(tokenAddress).name()".  This is a minor issue but it can lead to confusion for users who expect the symbol to be used in the liquidity token symbol.  Additionally, if the name function returns an empty string or reverts, it could cause issues with the liquidity token symbol.
        string memory liquidityTokenSymbol = string.concat(
            "ts",
            IERC20(tokenAddress).name()
        );
        TSwapPool tPool = new TSwapPool(
            tokenAddress,
            i_wethToken,
            liquidityTokenName,
            liquidityTokenSymbol
        );
        s_pools[tokenAddress] = address(tPool);
        s_tokens[address(tPool)] = tokenAddress;
        emit PoolCreated(tokenAddress, address(tPool));
        return address(tPool);
    }

    /*//////////////////////////////////////////////////////////////
                   EXTERNAL AND PUBLIC VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    function getPool(address tokenAddress) external view returns (address) {
        return s_pools[tokenAddress];
    }

    function getToken(address pool) external view returns (address) {
        return s_tokens[pool];
    }

    function getWethToken() external view returns (address) {
        return i_wethToken;
    }
}
