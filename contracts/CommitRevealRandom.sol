// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CommitRevealRandom {
    bytes32 public commitHash;
    uint256 public revealedNumber;
    address public player;

    enum Phase { COMMIT, REVEAL }
    Phase public phase = Phase.COMMIT;

    /// Player sends the hash of their secret value
    function commit(bytes32 _hash) external {
        require(phase == Phase.COMMIT, "Already committed");
        commitHash = _hash;
        player = msg.sender;
        phase = Phase.REVEAL;
    }

    /// Player reveals the secret, contract verifies it and generates random output
    function reveal(uint256 secret) external {
        require(phase == Phase.REVEAL, "Not time to reveal");
        require(msg.sender == player, "Not player");
        require(keccak256(abi.encodePacked(secret)) == commitHash, "Invalid reveal");

        revealedNumber = secret % 100;
        phase = Phase.COMMIT; // ready for next round
    }

    /// Calcula el hash para un secreto
    function getHash(uint256 _secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_secret));
    }
}
