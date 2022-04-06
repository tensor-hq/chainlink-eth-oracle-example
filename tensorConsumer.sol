// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract BAYCPriceFetcher is ChainlinkClient, ConfirmedOwner {
  using Chainlink for Chainlink.Request;

  uint256 constant private ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY;
  uint256 public currentPrice;

  event RequestBAYCPriceFulfilled(
    bytes32 indexed requestId,
    uint256 indexed price
  );

  constructor() ConfirmedOwner(msg.sender){
    setPublicChainlinkToken();
  }

  function getBAYCPrice(address _oracle, string memory _jobId)
    public
    onlyOwner
  {
    Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), address(this), this.fulfillBAYCPrice.selector);
    req.add("get", "https://api.tensor.so/eth/collections/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d/floor");
    req.add("path", "price");
    sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
  }

  function getBAYCPriceAt(address _oracle, string memory _jobId, string memory at)
    public
    onlyOwner
  {
    Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), address(this), this.fulfillBAYCPrice.selector);
    string memory url = string(abi.encodePacked("https://api.tensor.so/eth/collections/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d/floor?at=", at));
    req.add("get", url);
    req.add("path", "price");
    sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
  }

  function fulfillBAYCPrice(bytes32 _requestId, uint256 _price)
    public
    recordChainlinkFulfillment(_requestId)
  {
    emit RequestBAYCPriceFulfilled(_requestId, _price);
    currentPrice = _price;
  }

  function stringToBytes32(string memory source) private pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly { // solhint-disable-line no-inline-assembly
      result := mload(add(source, 32))
    }
  }
}
