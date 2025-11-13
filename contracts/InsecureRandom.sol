// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract InsecureRandom {
    address public owner;
    uint256 public lastRandom;
    uint256 public lastBlock;

    event Played(address indexed player, uint256 random, bool won);

    constructor() {
        owner = msg.sender;
    }

    function getInsecureRandomNumber() public returns (uint256) {
        uint256 random = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao))
        ) % 100;

        lastRandom = random;
        lastBlock = block.number;
        return random;
    }

    function play() public payable returns (string memory) {
        require(msg.value == 0.01 ether, "Debes enviar 0.01 ETH para jugar");

        uint256 random = getInsecureRandomNumber();
        bool won = false;
        if (random % 2 == 0) {
            payable(msg.sender).transfer(0.02 ether);
            won = true;
        }
        emit Played(msg.sender, random, won);
        return won ? "Ganaste!" : "Perdiste.";
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public {
        require(msg.sender == owner, "Solo el owner puede retirar");
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}
