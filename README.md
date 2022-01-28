<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/github_username/repo_name">
    <img src="assets/abacus.jpg" alt="Logo" width="600" height="800">
  </a>
  <h1 align="center">AbacusV0</h1>
  <p align="center">

 
<br />


## Overview

Description

## Notes

Uni v2 links:
- https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol

- https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol

- https://github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router02.sol
<br />

## Functions

### swapAndTransferUnwrappedNatoWithV2LP
Swap tokens and send unwrapped nato to the msg.sender with a Uni V2 LP interface.

```js
function swapAndTransferUnwrappedNatoWithV2LP (address _lp) external {

}
```

### swapAndTransferUnwrappedNatoSupportingFeesOnTransferWithV2LP
Swap tokens and send unwrapped nato to the msg.sender supporting fee on transfer with a Uni V2 LP interface.

```js

function swapAndTransferUnwrappedNatoSupportingFeesOnTransferWithV2LP (address _lp) external {

}
```

### swapAndTransferUnwrappedNatoWithV3LP
Swap tokens and send unwrapped nato to the msg.sender with a Uni V3 LP interface.

```js

function swapAndTransferUnwrappedNatoWithV3LP (address _lp) external {

}
```
### swapAndTransferUnwrappedNatoSupportingFeesOnTransferWithV3LP
Swap tokens and send unwrapped nato to the msg.sender supporting fee on transfer with a Uni V3 LP interface.

```js

function swapAndTransferUnwrappedNatoSupportingFeesOnTransferWithV3LP (address _lp) external {

}
```

<br />


## AbacusV1 Plans

A running list of functionality add ons for the AbacusV1. This list will be expanded upon through ideation and conversations around usecases. Gas optimizations are also going to be included in the next version and maybe even a rewrite in Yul.


### swapAndTransferDAI

Swaps to DAI to enable amount out in a stable coin.

```js
function swapAndTransferDAI(address _lp)
```

<br />


### swapAndTransferDAISupportingFeesOnTransfer

Swaps to DAI to enable amount out in a stable coin supporting fees on transfer.

```js
function swapAndTransferDAISupportingFeesOnTransfer(address _lp)
```


### WithdrawReferralRewards
Enable a user to withdraw their own referral rewards. 

```js
function WithdrawReferralRewards(address referrerAddress)
```


### SwapAndDistribute
A function that a swap can happen and you can split amounts out to various wallets

### SwapAndDistributePercentages
A function that a swap can happen and you can split amounts out to various wallets with percentage out for each wallet (ex. 5 wallets and wallet 1 gets 30%, wallet 2 gets 15%, the remaining wallets split the rest evently)

### SwapWithManualRoutingPath
A function where you can specify the routing path 