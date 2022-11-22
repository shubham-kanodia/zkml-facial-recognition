const { buildContractCallArgs, genProof } = require("../scripts/utils");

const { expect } = require("chai");
const { ethers } = require("hardhat");
const path = require("path");
const fs = require("fs");

describe("face recognition test", () => {
  it("should predict the right class for a given sample", async () => {
    const Verifier = await ethers.getContractFactory("Verifier");
    const verifier = await Verifier.deploy();
    await verifier.deployed();

    const jsonString = fs.readFileSync("./data/input.json");
    const input = JSON.parse(jsonString);

    // Generate proof
    const { proof, publicSignals } = await genProof(
      input,
      path.resolve(__dirname, "../output/circuit_js/circuit.wasm"),
      path.resolve(__dirname, "../ptau-ceremony/circuit_0001.zkey")
    );
    const callArgs = await buildContractCallArgs(proof, publicSignals);
    const result = await verifier.verifyProof(...callArgs);
    expect(result).equals(true);
  });
});