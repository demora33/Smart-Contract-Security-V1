// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract LotteryV2 is VRFV2WrapperConsumerBase, Ownable {
    using Address for address payable;

    mapping(address => uint8) public bets;
    bool public betsClosed;
    bool public prizeTaken;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256[] public randomResult;
    uint8 public winningNumber;

    uint32 callbackGasLimit = 800000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 1;

    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    // address WRAPPER - hardcoded for Goerli
    address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;

    constructor() VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) {}

    function getRandomNumber() external onlyOwner returns (uint256 requestId) {
        // require(
        //     LINK.balanceOf(address(this)) >= fee,
        //     "Not enough LINK - fill contract with faucet"
        // );
        return
            requestRandomness(callbackGasLimit, requestConfirmations, numWords);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        randomResult = _randomWords;
    }

    function placeBet(uint8 _number) external payable {
        require(bets[msg.sender] == 0, "Only 1 bet per player");
        require(msg.value == 10 ether, "Bet cost: 10 ether");
        require(betsClosed == false, "Bets are closed");
        require(
            _number > 0 && _number <= 255,
            "Must be a number from 1 to 255"
        );

        bets[msg.sender] = _number;
    }

    function endLottery() external onlyOwner {
        betsClosed = true;

        winningNumber = uint8((randomResult[0] % 254) + 1);
    }

    function withdrawPrize() external {
        require(betsClosed == true, "Bets are still open");
        require(prizeTaken == false, "Prize already taken");
        require(bets[msg.sender] == winningNumber, "You aren't the winner");

        prizeTaken = true;

        payable(msg.sender).sendValue(address(this).balance);
    }

    // function pseudoRandNumGen() private view returns (uint8) {
    //     return uint8(uint256(keccak256(abi.encode(block.timestamp))) % 254) + 1;
    // }
}
