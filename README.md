## Setup

1. Run npm install to setup circomlib

```bash
npm install
```

2. Compile circuit

```bash
circom circuits/circuit.circom --r1cs --wasm --sym -o output/
```

3. Change to `output/circuit_js/` directory

```bash
cd output/circuit_js/
```

4. To generate witness for sample input run

```bash
node generate_witness.js circuit.wasm ../../data/input.json witness.wtns
```

5. From step 6th onwards we will prove the circuit, for this step we will need `snarkjs` installed. The trusted setup is done in two parts

    1. The powers of tau, which is independent of the circuit
    2. The phase 2, which depends on the circuit

6. Start a new `powers of tau` ceremony

```bash
snarkjs powersoftau new bn128 12 pot12_0000.ptau -v
```

7. Contribute to the ceremony

```bash
snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v
```

8. Begin circuit dependent phase

```bash
snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v
```

9. Generate proving and verification keys

```bash
snarkjs groth16 setup output/circuit.r1cs pot12_final.ptau circuit_0000.zkey
```

10. Contribute to phase 2

```bash
snarkjs zkey contribute circuit_0000.zkey circuit_0001.zkey --name="1st Contributor Name" -v
```

11. Export verification key

```bash
snarkjs zkey export verificationkey circuit_0001.zkey verification_key.json
```

12. To run steps 6-11, you can use provided bash script (change directory to ptau-ceremony/)

```bash
./ptau-ceremony/ceremony.sh
```