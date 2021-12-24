// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./libraries/FlashLoanReceiverBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./libraries/DexLibrary.sol";

contract Run is FlashLoanReceiverBase, Ownable {
    address pair1A;
    address pair2A;
    address from;
    address to;
    uint256 MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 playAmount;

    constructor(ILendingPoolAddressesProvider _provider)
        FlashLoanReceiverBase(_provider)
    {}

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        //
        // This contract now has the funds requested.
        // Your logic goes here.
        //

        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountOwing = amounts[i] + premiums[i];
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        IUniswapV2Pair pair1 = IUniswapV2Pair(pair1A);
        IUniswapV2Pair pair2 = IUniswapV2Pair(pair2A);
        uint256 swappedAmount = DexLibrary.swap(playAmount, from, to, pair1);
        uint256 lastAmount = DexLibrary.swap(swappedAmount, to, from, pair2);
        to = address(0);
        from = address(0);
        pair1A = address(0);
        pair2A = address(0);
        playAmount = 0;
        return true;
    }

    function _flashloan(address[] memory assets, uint256[] memory amounts)
        internal
    {
        address receiverAddress = address(this);

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        uint256[] memory modes = new uint256[](assets.length);

        // 0 = no debt (flash), 1 = stable, 2 = variable
        for (uint256 i = 0; i < assets.length; i++) {
            modes[i] = 0;
        }

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    /*
     *  Flash multiple assets
     */
    function flashloan(address[] memory assets, uint256[] memory amounts)
        public
        onlyOwner
    {
        _flashloan(assets, amounts);
    }

    /*
     *  Flash loan 1000000000000000000 wei (1 ether) worth of `_asset`
     */
    function flashloan(address _asset, uint256 _amount) public onlyOwner {
        bytes memory data = "";

        address[] memory assets = new address[](1);
        assets[0] = _asset;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        _flashloan(assets, amounts);
    }

    function sikis(
        address _from,
        address _to,
        address _pair1,
        address _pair2,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_from).approve(address(_pair1), MAX_INT);
        IERC20(_to).approve(address(_pair2), MAX_INT);
        pair1A = _pair1;
        pair2A = _pair2;
        to = _to;
        from = _from;
        playAmount = _amount;
        flashloan(_from, _amount);
    }
}
