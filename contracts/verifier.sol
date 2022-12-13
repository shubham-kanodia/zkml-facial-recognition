//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.11;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            8739664812785163481269677897979524700371357336735918672526308752066527792616,
            13463698676216221853304270617674395097246173009925348011571383028953597016697
        );

        vk.beta2 = Pairing.G2Point(
            [17828527401621982156266763575266260551781783375128121626061368374991463998599,
             7161511600924159407386499824602678641330998077496046763890397141715168263430],
            [4760926959337649641602111044755056734256796669806121723975070016437253199618,
             2717950664039324362059676262993774251878651379668377323773243293991315865285]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [19610964081402048555656196017380080064874297755598138064662073621426621411285,
             3364755605091345845973814255554363817880088492134903509275595500923804164013],
            [14338047195888456377632347126161080878319010951654940381151008540281068289581,
             15828228963165962765751122775084898457451884111492697544487523482440484685341]
        );
        vk.IC = new Pairing.G1Point[](18);
        
        vk.IC[0] = Pairing.G1Point( 
            11144328325176134491693487772164542525793278861466522877582859568866696232477,
            8967302299038068694248934471821087904281384255633663757376717285616046339342
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            13708539933945965727148618961620407320485430289233097326604622236887551298438,
            9067543722839409095541356280395134757544954797871898440248948480230752409272
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            6837076446530937315537995144926098992567469988398746196554100577589958868238,
            19599508679146504773668124177626619736960541820622224807062478699984385941334
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            15980642561790473789768439311572931828340108943340486159470263035056123379982,
            24886927691691898908009515568726359512989921102770702716298831253658561119
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            4412249567103249163810697072297056608800956977911711089031965467482171745074,
            8358763684964130962713379817953869493794681144569393616152601010342679628629
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            18558233723580459826520705600708756474325564052517654309389984740056599243311,
            15257676633053929398585255152771650877947097307242396970022625764133750818784
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            20674370686599933110025664709658204657667598181668285231009537601941523995316,
            17049371432155639252689058168615185068394930169229196666159442895440359871273
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            3918014248914755307005328720540045690287997778368626228110526698023085189414,
            3937381174886765074964494515540701762895798854504120024166764290774805595696
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            15243510042960002678705215048433712241144607901823770719911243725186261369518,
            18803318319935471407296022740095192365975625099671884420278362588060272518691
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            9428215490064139349918048444787165934735509103717658532544144259743679450398,
            11858301198040368117790649606075047578264916025360410719684925101218624728950
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            7957539418774660540924780054772041695354577864154765943508933401642725662433,
            7130073214915655756395295894362941484296987241631248171213249920466442547941
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            19940076752574356775993384820223049364407707081053056615028368785818236429499,
            2176940906904874283954454434767504250197234746942902618415051219755082319621
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            20040933217249456411085105651213418960825257330081657176783435542651872014629,
            20689863526475767349283575534694401702133008469654557478373637411715380704436
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            13059408504733843006414967539374160219852221762550877829172325794822517635311,
            11106237462588913681166096799053437950289302078692432878841266170333007655695
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            13940275095927147255739987675801486665779249926420911942579232504108728326310,
            21083418097925568457649596662825876343215020143693433501951517246187785293472
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            17054815929651339598106477848335119288441202132384354402268272330651774549441,
            17231736407375022325590182897293118929364927083884035898414353924734153171304
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            932225385106691556621619913645883729942030782522426994828525398913449686362,
            16181200882957372504032851576333751719145457999144165267054811973795587392591
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            6191201065731806319094185338708003663367037368770354361696174730020733205153,
            15293677666650449118095228620560641483690850898872200923557785682719510601087
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[17] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
