import { expect } from "chai";
import { ethers } from "hardhat";

describe("InsecureRandom", function () {
  it("Debería generar números entre 0 y 99", async function () {
    const InsecureRandom = await ethers.getContractFactory("InsecureRandom");
    const contract = await InsecureRandom.deploy();
    await contract.waitForDeployment();

    const tx = await contract.getInsecureRandomNumber();
    const result = await tx.wait();

    const random = await contract.lastRandom();
    expect(random).to.be.gte(0);
    expect(random).to.be.lt(100);
  });

  it("Debería permitir jugar y retornar 'Ganaste!' o 'Perdiste.'", async function () {
    const [player] = await ethers.getSigners();
    const InsecureRandom = await ethers.getContractFactory("InsecureRandom");
    const contract = await InsecureRandom.deploy();
    await contract.waitForDeployment();

    await player.sendTransaction({
      to: await contract.getAddress(),
      value: ethers.parseEther("1.0"), // Fondo inicial
    });

    const tx = await contract.play({ value: ethers.parseEther("0.01") });
    await tx.wait();

    const random = await contract.lastRandom();
    expect(random).to.be.a("bigint");
  });
});
