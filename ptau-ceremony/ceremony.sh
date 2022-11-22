#!/bin/bash

set -e

snarkjs powersoftau new bn128 12 pot12_0000.ptau -v

snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v -e="$(head -n 4096 /dev/urandom | openssl sha1)"

snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v

snarkjs groth16 setup ../output/circuit.r1cs pot12_final.ptau circuit_0000.zkey

snarkjs zkey contribute circuit_0000.zkey circuit_0001.zkey --name="1st Contributor Name" -v -e="$(head -n 4096 /dev/urandom | openssl sha1)"

snarkjs zkey export verificationkey circuit_0001.zkey verification_key.json

snarkjs zkey export solidityverifier circuit_0001.zkey ../contracts/verifier.sol
