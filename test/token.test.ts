import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

describe("Token", function () {
  it("Should return name Token", async function () {
    const Token = await ethers.getContractFactory("GovToken");

    const token = await upgrades.deployProxy(Token, [
      "Orbiter",
      "Orb",
      "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
    ]);
    await token.waitForDeployment();

    expect(await token.name()).to.equal("Orbiter");
  });
});
