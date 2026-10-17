// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// Offline mainnet runtime. Provenance and hash: mainnet-validator.json.
// Fixed-size word copies avoid the solc 0.8.26 optimizer crash on a 15KB hex literal.
contract MainnetValidatorCode {
    constructor() {
        bytes memory runtime = new bytes(15463);
        part0(runtime);
        part1(runtime);
        part2(runtime);
        part3(runtime);
        part4(runtime);
        part5(runtime);
        part6(runtime);
        part7(runtime);
        part8(runtime);
        part9(runtime);
        part10(runtime);
        part11(runtime);
        part12(runtime);
        part13(runtime);
        part14(runtime);
        part15(runtime);
        part16(runtime);
        part17(runtime);
        part18(runtime);
        part19(runtime);
        part20(runtime);
        part21(runtime);
        part22(runtime);
        part23(runtime);
        part24(runtime);
        part25(runtime);
        part26(runtime);
        part27(runtime);
        part28(runtime);
        part29(runtime);
        part30(runtime);
        assembly ("memory-safe") { return(add(runtime, 32), mload(runtime)) }
    }

    function part0(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 32), 0x608060405234801561000f575f80fd5b506004361061031e575f3560e01c8063)
            mstore(add(runtime, 64), 0x88c1d66d116101a5578063b8dcc68f116100ec578063ddae38f2116100955780)
            mstore(add(runtime, 96), 0x63e991dc301161006f578063e991dc30146108ec578063ede0fe31146108ff57)
            mstore(add(runtime, 128), 0x8063fd51f20f146109125761031e565b8063ddae38f214610615578063de02cb)
            mstore(add(runtime, 160), 0xb1146108c6578063df5fd29a146108d95761031e565b8063caee23ea116100c6)
            mstore(add(runtime, 192), 0x578063caee23ea1461088d578063da0194c0146108a0578063dda964e3146108)
            mstore(add(runtime, 224), 0xb35761031e565b8063b8dcc68f14610854578063bf7bfd7e14610867578063c3)
            mstore(add(runtime, 256), 0xd58f4d1461087a5761031e565b8063a1cc5cc11161014e578063b6e39ba11161)
            mstore(add(runtime, 288), 0x0128578063b6e39ba1146107d3578063b70510f5146107e6578063b89c4b0d14)
            mstore(add(runtime, 320), 0x6108415761031e565b8063a1cc5cc114610755578063a5ce71f5146107555780)
            mstore(add(runtime, 352), 0x63ae602f44146107685761031e565b80638b6ee8651161017f5780638b6ee865)
            mstore(add(runtime, 384), 0x146106c85780638e28800f146106db578063982d03c0146107425761031e565b)
            mstore(add(runtime, 416), 0x806388c1d66d1461068f57806389631626146106a257806389a9c855146106b5)
            mstore(add(runtime, 448), 0x5761031e565b8063317e3e8d116102695780636971082811610212578063755b)
            mstore(add(runtime, 480), 0x6fd7116101ec578063755b6fd7146106155780637bac97de146106285780637c)
            mstore(add(runtime, 512), 0x1e14b4146104e85761031e565b806369710828146105e75780636bfab91d1461)
        }
    }

    function part1(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 544), 0x05fa5780637423eb3c1461060d5761031e565b80633e5c139d11610243578063)
            mstore(add(runtime, 576), 0x3e5c139d146105ae57806343999db8146105c157806350793315146105d45761)
            mstore(add(runtime, 608), 0x031e565b8063317e3e8d146105215780633a0e3160146105345780633cda743a)
            mstore(add(runtime, 640), 0x146105475761031e565b806316a17ce0116102cb578063285fb8c8116102a557)
            mstore(add(runtime, 672), 0x8063285fb8c8146104e857806328cc1131146104fb5780632eb0b98a1461050e)
            mstore(add(runtime, 704), 0x5761031e565b806316a17ce01461043b5780631854b2411461049657806323c9)
            mstore(add(runtime, 736), 0x9262146104a95761031e565b80630ad38899116102fc5780630ad38899146103)
            mstore(add(runtime, 768), 0xf55780630b6153091461040857806310b5c6a01461041b5761031e565b806301)
            mstore(add(runtime, 800), 0x5499301461035f57806301ffc9a714610372578063057497cb1461039a575b7f)
            mstore(add(runtime, 832), 0x0000000000000000000000001fca38fd099c7701b4f28fbc3f0ba57ed4067137)
            mstore(add(runtime, 864), 0x365f80375f80365f845af43d5f803e808015610359573d5ff35b3d5ffd5b005b)
            mstore(add(runtime, 896), 0x61035d61036d36600461359c565b610925565b61038561038036600461361b56)
            mstore(add(runtime, 928), 0x5b6109d0565b60405190151581526020015b60405180910390f35b6103856103)
            mstore(add(runtime, 960), 0xa836600461367d565b6effffffffffffffffffffffffffffff82165f90815260)
            mstore(add(runtime, 992), 0x016020908152604080832073ffffffffffffffffffffffffffffffffffffffff)
            mstore(add(runtime, 1024), 0x8516845260060190915290205460ff1692915050565b61035d61040336600461)
        }
    }

    function part2(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 1056), 0x36ae565b610a93565b61035d61041636600461367d565b610b05565b61042e61)
            mstore(add(runtime, 1088), 0x04293660046136c7565b610bc4565b60405161039191906136e0565b61038561)
            mstore(add(runtime, 1120), 0x044936600461367d565b6effffffffffffffffffffffffffffff82165f908152)
            mstore(add(runtime, 1152), 0x60016020908152604080832073ffffffffffffffffffffffffffffffffffffff)
            mstore(add(runtime, 1184), 0xff8516845260090190915290205460ff1692915050565b61035d6104a4366004)
            mstore(add(runtime, 1216), 0x613739565b610bf2565b5f546104c89061010090046effffffffffffffffffff)
            mstore(add(runtime, 1248), 0xffffffffff1681565b6040516effffffffffffffffffffffffffffff90911681)
            mstore(add(runtime, 1280), 0x52602001610391565b61035d6104f636600461378a565b610bff565b61035d61)
            mstore(add(runtime, 1312), 0x05093660046137ca565b610c0f565b61035d61051c36600461359c565b610cbe)
            mstore(add(runtime, 1344), 0x565b61035d61052f366004613807565b610d63565b61035d6105423660046138)
            mstore(add(runtime, 1376), 0x77565b610dcb565b61038561055536600461389f565b73ffffffffffffffffff)
            mstore(add(runtime, 1408), 0xffffffffffffffffffffff9182165f908152600260209081526040808320546e)
            mstore(add(runtime, 1440), 0xffffffffffffffffffffffffffffff1683526001825280832093909416825260)
            mstore(add(runtime, 1472), 0x03909201909152205460ff1690565b61042e6105bc3660046136ae565b610e3a)
            mstore(add(runtime, 1504), 0x565b61035d6105cf36600461367d565b610e8b565b61035d6105e23660046138)
            mstore(add(runtime, 1536), 0x9f565b610f1e565b61035d6105f536600461359c565b610fa3565b61035d6106)
        }
    }

    function part3(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 1568), 0x0836600461367d565b611047565b61035d61112c565b61035d61062336600461)
            mstore(add(runtime, 1600), 0x359c565b611254565b61038561063636600461389f565b73ffffffffffffffff)
            mstore(add(runtime, 1632), 0xffffffffffffffffffffffff9182165f90815260026020908152604080832054)
            mstore(add(runtime, 1664), 0x6effffffffffffffffffffffffffffff16835260018252808320939094168252)
            mstore(add(runtime, 1696), 0x6009909201909152205460ff1690565b61035d61069d36600461367d565b6112)
            mstore(add(runtime, 1728), 0xf6565b61042e6106b03660046136c7565b6113af565b6103856106c336600461)
            mstore(add(runtime, 1760), 0x36ae565b6113dd565b61035d6106d63660046136c7565b61148f565b61038561)
            mstore(add(runtime, 1792), 0x06e936600461389f565b73ffffffffffffffffffffffffffffffffffffffff91)
            mstore(add(runtime, 1824), 0x82165f908152600260209081526040808320546effffffffffffffffffffffff)
            mstore(add(runtime, 1856), 0xffffff168352600182528083209390941682526006909201909152205460ff16)
            mstore(add(runtime, 1888), 0x90565b61042e6107503660046136ae565b61150c565b61035d61076336600461)
            mstore(add(runtime, 1920), 0x359c565b61155d565b6107ae6107763660046136c7565b6effffffffffffffff)
            mstore(add(runtime, 1952), 0xffffffffffffff165f9081526001602052604090205473ffffffffffffffffff)
            mstore(add(runtime, 1984), 0xffffffffffffffffffffff1690565b60405173ffffffffffffffffffffffffff)
            mstore(add(runtime, 2016), 0xffffffffffffff9091168152602001610391565b61035d6107e1366004613877)
            mstore(add(runtime, 2048), 0x565b611602565b6103856107f436600461367d565b6effffffffffffffffffff)
        }
    }

    function part4(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 2080), 0xffffffffff82165f90815260016020908152604080832073ffffffffffffffff)
            mstore(add(runtime, 2112), 0xffffffffffffffffffffffff8516845260030190915290205460ff1692915050)
            mstore(add(runtime, 2144), 0x565b61035d61084f366004613877565b611647565b6104c86108623660046138)
            mstore(add(runtime, 2176), 0xfe565b61168c565b61035d61087536600461393d565b611796565b61035d6108)
            mstore(add(runtime, 2208), 0x8836600461367d565b611881565b61035d61089b366004613965565b61191456)
            mstore(add(runtime, 2240), 0x5b61035d6108ae3660046139ad565b611920565b61042e6108c13660046136c7)
            mstore(add(runtime, 2272), 0x565b61192a565b6104c86108d43660046139e5565b611959565b61035d6108e7)
            mstore(add(runtime, 2304), 0x36600461359c565b611b26565b61042e6108fa3660046136ae565b611bc8565b)
            mstore(add(runtime, 2336), 0x61035d61090d36600461367d565b611c19565b61035d61092036600461367d56)
            mstore(add(runtime, 2368), 0x5b611cd3565b8261092f81611de1565b815f81900361096a576040517f693f36)
            mstore(add(runtime, 2400), 0x9c00000000000000000000000000000000000000000000000000000000815260)
            mstore(add(runtime, 2432), 0x040160405180910390fd5b6109c9858585808060200260200160405190810160)
            mstore(add(runtime, 2464), 0x405280939291908181526020018383602002808284375f9201829052506effff)
            mstore(add(runtime, 2496), 0xffffffffffffffffffffffffff8c168152600160205260409020600701925060)
            mstore(add(runtime, 2528), 0x029150611e4f9050565b5050505050565b5f7fffffffff000000000000000000)
            mstore(add(runtime, 2560), 0x0000000000000000000000000000000000000082161580610a4157507fffffff)
        }
    }

    function part5(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 2592), 0xff0000000000000000000000000000000000000000000000000000000082167f)
            mstore(add(runtime, 2624), 0x751a614900000000000000000000000000000000000000000000000000000000)
            mstore(add(runtime, 2656), 0x145b80610a8d57507f01ffc9a700000000000000000000000000000000000000)
            mstore(add(runtime, 2688), 0x0000000000000000007fffffffff000000000000000000000000000000000000)
            mstore(add(runtime, 2720), 0x000000000000000000008316145b92915050565b610a9c81611fa6565b610b02)
            mstore(add(runtime, 2752), 0x7f596a397a000000000000000000000000000000000000000000000000000000)
            mstore(add(runtime, 2784), 0x0073ffffffffffffffffffffffffffffffffffffffff8316175b7f0000000000)
            mstore(add(runtime, 2816), 0x00000000000000000000000000000000000000000002bb00001d9863ffffffff)
            mstore(add(runtime, 2848), 0x16565b50565b81610b0f81611de1565b6040805160018082528183019092525f)
            mstore(add(runtime, 2880), 0x916020808301908036833701905050905082815f81518110610b4357610b4361)
            mstore(add(runtime, 2912), 0x3a2c565b602002602001019073ffffffffffffffffffffffffffffffffffffff)
            mstore(add(runtime, 2944), 0xff16908173ffffffffffffffffffffffffffffffffffffffff1681525050610b)
            mstore(add(runtime, 2976), 0xbe848260015f886effffffffffffffffffffffffffffff166effffffffffffff)
            mstore(add(runtime, 3008), 0xffffffffffffffff1681526020019081526020015f206001015f61202d565b50)
            mstore(add(runtime, 3040), 0x505050565b6effffffffffffffffffffffffffffff81165f9081526001602052)
            mstore(add(runtime, 3072), 0x60409020606090610a8d9060070161211f565b6109c98585858585612132565b)
        }
    }

    function part6(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 3104), 0x610c0a83838361257d565b505050565b610c1883611fa6565b7f71836d450000)
            mstore(add(runtime, 3136), 0x00000000000000000000000000000000000000000000000000005f9081526018)
            mstore(add(runtime, 3168), 0x84905260048390526038812090610c798263ffffffff7f000000000000000000)
            mstore(add(runtime, 3200), 0x000000000000000000000000000000000002b700001d9416565b90505f610c86)
            mstore(add(runtime, 3232), 0x8483613a86565b9050610cb683827f0000000000000000000000000000000000)
            mstore(add(runtime, 3264), 0x00000000000000000002b000001d8d63ffffffff16565b505050505050565b82)
            mstore(add(runtime, 3296), 0x610cc881611de1565b815f819003610d03576040517f693f369c000000000000)
            mstore(add(runtime, 3328), 0x0000000000000000000000000000000000000000000081526004016040518091)
            mstore(add(runtime, 3360), 0x0390fd5b6109c985858580806020026020016040519081016040528093929190)
            mstore(add(runtime, 3392), 0x8181526020018383602002808284375f9201829052506effffffffffffffffff)
            mstore(add(runtime, 3424), 0xffffffffffff8c1681526001602081905260409091206004019350915061202d)
            mstore(add(runtime, 3456), 0x9050565b821580610d6e575081155b80610d765750805b15610dad576040517f)
            mstore(add(runtime, 3488), 0x7ced84b900000000000000000000000000000000000000000000000000000000)
            mstore(add(runtime, 3520), 0x815260040160405180910390fd5b6109c9858560ff166008811115610dc65761)
            mstore(add(runtime, 3552), 0x0dc6613a99565b6129a0565b610dd482611fa6565b7f7e746c61000000000000)
            mstore(add(runtime, 3584), 0x000000000000000000000000000000000000000000005f908152601883905260)
        }
    }

    function part7(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 3616), 0x0482905260389020610e369060017f0000000000000000000000000000000000)
            mstore(add(runtime, 3648), 0x00000000000000000002b000001d8d63ffffffff16565b5050565b73ffffffff)
            mstore(add(runtime, 3680), 0xffffffffffffffffffffffffffffffff81165f90815260026020908152604080)
            mstore(add(runtime, 3712), 0x8320546effffffffffffffffffffffffffffff16835260019182905290912060)
            mstore(add(runtime, 3744), 0x6091610a8d910161211f565b81610e9581611de1565b60408051600180825281)
            mstore(add(runtime, 3776), 0x83019092525f916020808301908036833701905050905082815f81518110610e)
            mstore(add(runtime, 3808), 0xc957610ec9613a2c565b73ffffffffffffffffffffffffffffffffffffffff90)
            mstore(add(runtime, 3840), 0x92166020928302919091018201526effffffffffffffffffffffffffffff8516)
            mstore(add(runtime, 3872), 0x5f908152600190915260409020610bbe90859083906007016002611e4f565b61)
            mstore(add(runtime, 3904), 0x0f2781611fa6565b610e367f596a397a00000000000000000000000000000000)
            mstore(add(runtime, 3936), 0x00000000000000000000000073ffffffffffffffffffffffffffffffffffffff)
            mstore(add(runtime, 3968), 0xff8316178373ffffffffffffffffffffffffffffffffffffffff167f00000000)
            mstore(add(runtime, 4000), 0x0000000000000000000000000000000000000000000002b000001d8d63ffffff)
            mstore(add(runtime, 4032), 0xff16565b82610fad81611de1565b815f819003610fe8576040517f693f369c00)
            mstore(add(runtime, 4064), 0x0000000000000000000000000000000000000000000000000000008152600401)
            mstore(add(runtime, 4096), 0x60405180910390fd5b6109c98585858080602002602001604051908101604052)
        }
    }

    function part8(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 4128), 0x80939291908181526020018383602002808284375f9201829052506effffffff)
            mstore(add(runtime, 4160), 0xffffffffffffffffffffff8c1681526001602052604090206007019250600291)
            mstore(add(runtime, 4192), 0x5061202d9050565b8161105181611de1565b73ffffffffffffffffffffffffff)
            mstore(add(runtime, 4224), 0xffffffffffffff821661109e576040517f2ba5f1650000000000000000000000)
            mstore(add(runtime, 4256), 0x0000000000000000000000000000000000815260040160405180910390fd5b6e)
            mstore(add(runtime, 4288), 0xffffffffffffffffffffffffffffff83165f8181526001602052604080822080)
            mstore(add(runtime, 4320), 0x547fffffffffffffffffffffffff000000000000000000000000000000000000)
            mstore(add(runtime, 4352), 0x00001673ffffffffffffffffffffffffffffffffffffffff8716908117909155)
            mstore(add(runtime, 4384), 0x90519092917f9b0894203394c3cbb23140db7a23b224d3e18e0366e9f65bd9c8)
            mstore(add(runtime, 4416), 0x402650e2736791a3505050565b333214611165576040517f2599431400000000)
            mstore(add(runtime, 4448), 0x0000000000000000000000000000000000000000000000008152600401604051)
            mstore(add(runtime, 4480), 0x80910390fd5b7f00000000000000000000000000000000000000000000000000)
            mstore(add(runtime, 4512), 0x000000000000018061119257505f5460ff165b156111c9576040517ff45b98b0)
            mstore(add(runtime, 4544), 0x0000000000000000000000000000000000000000000000000000000081526004)
            mstore(add(runtime, 4576), 0x0160405180910390fd5b6111f27f000000000000000000000000bb0bffd7f8ef)
            mstore(add(runtime, 4608), 0x12ecaa0435aef8a7bd522798251c612d08565b611228576040517f70a4078f00)
        }
    }

    function part9(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 4640), 0x0000000000000000000000000000000000000000000000000000008152600401)
            mstore(add(runtime, 4672), 0x60405180910390fd5b5f80547fffffffffffffffffffffffffffffffffffffff)
            mstore(add(runtime, 4704), 0xffffffffffffffffffffffff00166001179055565b8261125e81611de1565b81)
            mstore(add(runtime, 4736), 0x5f819003611299576040517f693f369c00000000000000000000000000000000)
            mstore(add(runtime, 4768), 0x000000000000000000000000815260040160405180910390fd5b6109c9858585)
            mstore(add(runtime, 4800), 0x8080602002602001604051908101604052809392919081815260200183836020)
            mstore(add(runtime, 4832), 0x02808284375f9201829052506effffffffffffffffffffffffffffff8c168152)
            mstore(add(runtime, 4864), 0x60016020819052604082200193509150611e4f9050565b8161130081611de156)
            mstore(add(runtime, 4896), 0x5b6040805160018082528183019092525f916020808301908036833701905050)
            mstore(add(runtime, 4928), 0x905082815f8151811061133457611334613a2c565b602002602001019073ffff)
            mstore(add(runtime, 4960), 0xffffffffffffffffffffffffffffffffffff16908173ffffffffffffffffffff)
            mstore(add(runtime, 4992), 0xffffffffffffffffffff1681525050610bbe848260015f886effffffffffffff)
            mstore(add(runtime, 5024), 0xffffffffffffffff166effffffffffffffffffffffffffffff16815260200190)
            mstore(add(runtime, 5056), 0x81526020015f206001015f611e4f565b6effffffffffffffffffffffffffffff)
            mstore(add(runtime, 5088), 0x81165f908152600160205260409020606090610a8d9060040161211f565b6040)
            mstore(add(runtime, 5120), 0x517f89a9c8550000000000000000000000000000000000000000000000000000)
        }
    }

    function part10(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 5152), 0x0000815273ffffffffffffffffffffffffffffffffffffffff82811660048301)
            mstore(add(runtime, 5184), 0x525f917f000000000000000000000000721c00182a990771244d7a71b9fa2ea7)
            mstore(add(runtime, 5216), 0x89a3b433909116906389a9c85590602401602060405180830381865afa158015)
            mstore(add(runtime, 5248), 0x61146b573d5f803e3d5ffd5b505050506040513d601f19601f82011682018060)
            mstore(add(runtime, 5280), 0x405250810190610a8d9190613ac6565b8061149981611de1565b6effffffffff)
            mstore(add(runtime, 5312), 0xffffffffffffffffffff82165f8181526001602052604080822080547fffffff)
            mstore(add(runtime, 5344), 0xffffffffffffffffff0000000000000000000000000000000000000000169055)
            mstore(add(runtime, 5376), 0x519091907f9b0894203394c3cbb23140db7a23b224d3e18e0366e9f65bd9c840)
            mstore(add(runtime, 5408), 0x2650e27367908390a35050565b73ffffffffffffffffffffffffffffffffffff)
            mstore(add(runtime, 5440), 0xffff81165f908152600260209081526040808320546effffffffffffffffffff)
            mstore(add(runtime, 5472), 0xffffffffff16835260019091529020606090610a8d9060070161211f565b8261)
            mstore(add(runtime, 5504), 0x156781611de1565b815f8190036115a2576040517f693f369c00000000000000)
            mstore(add(runtime, 5536), 0x0000000000000000000000000000000000000000008152600401604051809103)
            mstore(add(runtime, 5568), 0x90fd5b6109c98585858080602002602001604051908101604052809392919081)
            mstore(add(runtime, 5600), 0x81526020018383602002808284375f9201829052506effffffffffffffffffff)
            mstore(add(runtime, 5632), 0xffffffffff8c16815260016020819052604090912060040193509150611e4f90)
        }
    }

    function part11(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 5664), 0x50565b61160b82611fa6565b7f71836d45000000000000000000000000000000)
            mstore(add(runtime, 5696), 0x000000000000000000000000005f908152601883905260048290526038902061)
            mstore(add(runtime, 5728), 0x0e3690610ad9565b61165082611fa6565b7f7e746c6100000000000000000000)
            mstore(add(runtime, 5760), 0x0000000000000000000000000000000000005f90815260188390526004829052)
            mstore(add(runtime, 5792), 0x60389020610e3690610ad9565b5f805f600181819054906101000a90046effff)
            mstore(add(runtime, 5824), 0xffffffffffffffffffffffffff166116b690613ae1565b82546effffffffffff)
            mstore(add(runtime, 5856), 0xffffffffffffffffff8083166101009490940a84810291021990911617909255)
            mstore(add(runtime, 5888), 0x5f818152600160205260409081902080547fffffffffffffffffffffffff0000)
            mstore(add(runtime, 5920), 0x000000000000000000000000000000000000163317905551919250907f5cc365)
            mstore(add(runtime, 5952), 0xf89543268cb9f25c255f7f610e9147e733c589bc2732279575f125be14906117)
            mstore(add(runtime, 5984), 0x4a9087908790613b0e565b60405180910390a260405133906effffffffffffff)
            mstore(add(runtime, 6016), 0xffffffffffffffff8316907f9b0894203394c3cbb23140db7a23b224d3e18e03)
            mstore(add(runtime, 6048), 0x66e9f65bd9c8402650e27367905f90a39392505050565b61179f82612d73565b)
            mstore(add(runtime, 6080), 0x5f546effffffffffffffffffffffffffffff6101009091048116908216111561)
            mstore(add(runtime, 6112), 0x17f4576040517f3fbf501e000000000000000000000000000000000000000000)
            mstore(add(runtime, 6144), 0x00000000000000815260040160405180910390fd5b73ffffffffffffffffffff)
        }
    }

    function part12(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 6176), 0xffffffffffffffffffff82165f8181526002602052604080822080547fffffff)
            mstore(add(runtime, 6208), 0xffffffffffffffffffffffffffff000000000000000000000000000000166eff)
            mstore(add(runtime, 6240), 0xffffffffffffffffffffffffffff861690811790915590519092917fa66ff555)
            mstore(add(runtime, 6272), 0x7b7dc1562bb5e83306e15b513a25aa7537369bce38fc29c20847a79191a35050)
            mstore(add(runtime, 6304), 0x565b8161188b81611de1565b6040805160018082528183019092525f91602080)
            mstore(add(runtime, 6336), 0x8301908036833701905050905082815f815181106118bf576118bf613a2c565b)
            mstore(add(runtime, 6368), 0x73ffffffffffffffffffffffffffffffffffffffff9092166020928302919091)
            mstore(add(runtime, 6400), 0x018201526effffffffffffffffffffffffffffff85165f908152600190915260)
            mstore(add(runtime, 6432), 0x409020610bbe9085908390600701600261202d565b610bbe84848484612dfa56)
            mstore(add(runtime, 6464), 0x5b610e3682826129a0565b6effffffffffffffffffffffffffffff81165f9081)
            mstore(add(runtime, 6496), 0x52600160208190526040909120606091610a8d910161211f565b5f805f600181)
            mstore(add(runtime, 6528), 0x819054906101000a90046effffffffffffffffffffffffffffff166119839061)
            mstore(add(runtime, 6560), 0x3ae1565b91906101000a8154816effffffffffffffffffffffffffffff021916)
            mstore(add(runtime, 6592), 0x90836effffffffffffffffffffffffffffff16021790559050600181036effff)
            mstore(add(runtime, 6624), 0xffffffffffffffffffffffffff16836effffffffffffffffffffffffffffff16)
            mstore(add(runtime, 6656), 0x1115611a17576040517f3fbf501e000000000000000000000000000000000000)
        }
    }

    function part13(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 6688), 0x00000000000000000000815260040160405180910390fd5b6effffffffffffff)
            mstore(add(runtime, 6720), 0xffffffffffffffff8084165f9081526001602052604080822092841680835291)
            mstore(add(runtime, 6752), 0x81902080547fffffffffffffffffffffffff0000000000000000000000000000)
            mstore(add(runtime, 6784), 0x000000000000163317815590519091907f5cc365f89543268cb9f25c255f7f61)
            mstore(add(runtime, 6816), 0x0e9147e733c589bc2732279575f125be1490611a9e908a908a90613b0e565b60)
            mstore(add(runtime, 6848), 0x405180910390a260405133906effffffffffffffffffffffffffffff8516907f)
            mstore(add(runtime, 6880), 0x9b0894203394c3cbb23140db7a23b224d3e18e0366e9f65bd9c8402650e27367)
            mstore(add(runtime, 6912), 0x905f90a3611af55f848460010184600101613213565b611b0860018484600401)
            mstore(add(runtime, 6944), 0x84600401613213565b611b1b6002848460070184600701613213565b50909594)
            mstore(add(runtime, 6976), 0x5050505050565b82611b3081611de1565b815f819003611b6b576040517f693f)
            mstore(add(runtime, 7008), 0x369c000000000000000000000000000000000000000000000000000000008152)
            mstore(add(runtime, 7040), 0x60040160405180910390fd5b6109c98585858080602002602001604051908101)
            mstore(add(runtime, 7072), 0x60405280939291908181526020018383602002808284375f9201829052506eff)
            mstore(add(runtime, 7104), 0xffffffffffffffffffffffffffff8c1681526001602081905260408220019350)
            mstore(add(runtime, 7136), 0x915061202d9050565b73ffffffffffffffffffffffffffffffffffffffff8116)
            mstore(add(runtime, 7168), 0x5f908152600260209081526040808320546effffffffffffffffffffffffffff)
        }
    }

    function part14(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 7200), 0xff16835260019091529020606090610a8d9060040161211f565b81611c238161)
            mstore(add(runtime, 7232), 0x1de1565b6040805160018082528183019092525f916020808301908036833701)
            mstore(add(runtime, 7264), 0x905050905082815f81518110611c5757611c57613a2c565b6020026020010190)
            mstore(add(runtime, 7296), 0x73ffffffffffffffffffffffffffffffffffffffff16908173ffffffffffffff)
            mstore(add(runtime, 7328), 0xffffffffffffffffffffffffff1681525050610bbe848260015f886effffffff)
            mstore(add(runtime, 7360), 0xffffffffffffffffffffff166effffffffffffffffffffffffffffff16815260)
            mstore(add(runtime, 7392), 0x20019081526020015f206004016001611e4f565b81611cdd81611de1565b6040)
            mstore(add(runtime, 7424), 0x805160018082528183019092525f916020808301908036833701905050905082)
            mstore(add(runtime, 7456), 0x815f81518110611d1157611d11613a2c565b602002602001019073ffffffffff)
            mstore(add(runtime, 7488), 0xffffffffffffffffffffffffffffff16908173ffffffffffffffffffffffffff)
            mstore(add(runtime, 7520), 0xffffffffffffff1681525050610bbe848260015f886effffffffffffffffffff)
            mstore(add(runtime, 7552), 0xffffffffff166effffffffffffffffffffffffffffff16815260200190815260)
            mstore(add(runtime, 7584), 0x20015f20600401600161202d565b80825d5050565b5c90565b5f815d50565b5f)
            mstore(add(runtime, 7616), 0x5460ff1615611daf5780825d5050565b9055565b5f805460ff1615611dc35750)
            mstore(add(runtime, 7648), 0x5c90565b5080545b919050565b5f5460ff1615611ddc575f815d50565b5f9055)
            mstore(add(runtime, 7680), 0x565b6effffffffffffffffffffffffffffff81165f9081526001602052604090)
        }
    }

    function part15(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 7712), 0x205473ffffffffffffffffffffffffffffffffffffffff163314610b02576040)
            mstore(add(runtime, 7744), 0x517fd5f249290000000000000000000000000000000000000000000000000000)
            mstore(add(runtime, 7776), 0x0000815260040160405180910390fd5b5f805b8451811015610cb65784818151)
            mstore(add(runtime, 7808), 0x8110611e6d57611e6d613a2c565b602002602001015191505f73ffffffffffff)
            mstore(add(runtime, 7840), 0xffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffff)
            mstore(add(runtime, 7872), 0xffffffffff1603611edc576040517f8f6e844e00000000000000000000000000)
            mstore(add(runtime, 7904), 0x000000000000000000000000000000815260040160405180910390fd5b611ee6)
            mstore(add(runtime, 7936), 0x8483613310565b15611f9e578173ffffffffffffffffffffffffffffffffffff)
            mstore(add(runtime, 7968), 0xffff16866effffffffffffffffffffffffffffff16846002811115611f265761)
            mstore(add(runtime, 8000), 0x1f26613a99565b6040517fda8f3bd170446760f0f965a9b52bf271cb9679b5e0)
            mstore(add(runtime, 8032), 0xa70059eff2d49425229d17905f90a473ffffffffffffffffffffffffffffffff)
            mstore(add(runtime, 8064), 0xffffffff82165f908152600285016020526040902080547fffffffffffffffff)
            mstore(add(runtime, 8096), 0xffffffffffffffffffffffffffffffffffffffffffffff001660011790555b60)
            mstore(add(runtime, 8128), 0x0101611e52565b73ffffffffffffffffffffffffffffffffffffffff81165f90)
            mstore(add(runtime, 8160), 0x8152600260209081526040808320546effffffffffffffffffffffffffffff16)
            mstore(add(runtime, 8192), 0x83526001825280832033845260030190915290205460ff16610b02576040517f)
        }
    }

    function part16(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 8224), 0xeab2f2de00000000000000000000000000000000000000000000000000000000)
            mstore(add(runtime, 8256), 0x815260040160405180910390fd5b5f805b8451811015610cb657848181518110)
            mstore(add(runtime, 8288), 0x61204b5761204b613a2c565b6020908102919091010151915061206284836133)
            mstore(add(runtime, 8320), 0x31565b15612117578173ffffffffffffffffffffffffffffffffffffffff1686)
            mstore(add(runtime, 8352), 0x6effffffffffffffffffffffffffffff168460028111156120a2576120a2613a)
            mstore(add(runtime, 8384), 0x99565b6040517f503012490a650739416858609e898957b874d17415a0629451)
            mstore(add(runtime, 8416), 0x79c57357978840905f90a473ffffffffffffffffffffffffffffffffffffffff)
            mstore(add(runtime, 8448), 0x82165f908152600285016020526040902080547fffffffffffffffffffffffff)
            mstore(add(runtime, 8480), 0xffffffffffffffffffffffffffffffffffffff001690555b600101612030565b)
            mstore(add(runtime, 8512), 0x60605f61212b83613352565b9392505050565b335f9081526002602090815260)
            mstore(add(runtime, 8544), 0x4091829020825160c08101845290546effffffffffffffffffffffffffffff81)
            mstore(add(runtime, 8576), 0x16825260ff6f0100000000000000000000000000000082048116158015948401)
            mstore(add(runtime, 8608), 0x9490945270010000000000000000000000000000000082048116151594830194)
            mstore(add(runtime, 8640), 0x9094527101000000000000000000000000000000000081048416151560608301)
            mstore(add(runtime, 8672), 0x5272010000000000000000000000000000000000008104841615156080830152)
            mstore(add(runtime, 8704), 0x7301000000000000000000000000000000000000009004909216151560a08301)
        }
    }

    function part17(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 8736), 0x5261220a57506109c9565b8060800151156122635773ffffffffffffffffffff)
            mstore(add(runtime, 8768), 0xffffffffffffffffffff84163b15612263576040517f52245b98000000000000)
            mstore(add(runtime, 8800), 0x0000000000000000000000000000000000000000000081526004016040518091)
            mstore(add(runtime, 8832), 0x0390fd5b8060a0015115612351576040517f89a9c85500000000000000000000)
            mstore(add(runtime, 8864), 0x000000000000000000000000000000000000815273ffffffffffffffffffffff)
            mstore(add(runtime, 8896), 0xffffffffffffffffff85811660048301527f000000000000000000000000721c)
            mstore(add(runtime, 8928), 0x00182a990771244d7a71b9fa2ea789a3b43316906389a9c85590602401602060)
            mstore(add(runtime, 8960), 0x405180830381865afa1580156122f7573d5f803e3d5ffd5b505050506040513d)
            mstore(add(runtime, 8992), 0x601f19601f8201168201806040525081019061231b9190613ac6565b61235157)
            mstore(add(runtime, 9024), 0x6040517fa451bf2a000000000000000000000000000000000000000000000000)
            mstore(add(runtime, 9056), 0x00000000815260040160405180910390fd5b8473ffffffffffffffffffffffff)
            mstore(add(runtime, 9088), 0xffffffffffffffff168673ffffffffffffffffffffffffffffffffffffffff16)
            mstore(add(runtime, 9120), 0x036123c6578060600151156123c0576040517ff87c9614000000000000000000)
            mstore(add(runtime, 9152), 0x00000000000000000000000000000000000000815260040160405180910390fd)
            mstore(add(runtime, 9184), 0x5b506109c9565b7f71836d450000000000000000000000000000000000000000)
            mstore(add(runtime, 9216), 0x00000000000000005f90815233601852600484905260388120906124268263ff)
        }
    }

    function part18(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 9248), 0xffffff7f000000000000000000000000000000000000000000000000000002b7)
            mstore(add(runtime, 9280), 0x00001d9416565b90508381106124675761245f828583037f0000000000000000)
            mstore(add(runtime, 9312), 0x00000000000000000000000000000000000002b000001d8d63ffffffff16565b)
            mstore(add(runtime, 9344), 0x5050506109c9565b8260400151156124f55782516effffffffffffffffffffff)
            mstore(add(runtime, 9376), 0xffffffff165f90815260016020908152604080832073ffffffffffffffffffff)
            mstore(add(runtime, 9408), 0xffffffffffffffffffff8c16845260090190915290205460ff16156124f05760)
            mstore(add(runtime, 9440), 0x40517f1de5204e00000000000000000000000000000000000000000000000000)
            mstore(add(runtime, 9472), 0x000000815260040160405180910390fd5b612573565b82516effffffffffffff)
            mstore(add(runtime, 9504), 0xffffffffffffffff165f90815260016020908152604080832073ffffffffffff)
            mstore(add(runtime, 9536), 0xffffffffffffffffffffffffffff8c16845260060190915290205460ff166125)
            mstore(add(runtime, 9568), 0x73576040517f1de5204e00000000000000000000000000000000000000000000)
            mstore(add(runtime, 9600), 0x000000000000815260040160405180910390fd5b5050505050505050565b335f)
            mstore(add(runtime, 9632), 0x90815260026020908152604091829020825160c08101845290546effffffffff)
            mstore(add(runtime, 9664), 0xffffffffffffffffffff8116825260ff6f010000000000000000000000000000)
            mstore(add(runtime, 9696), 0x0082048116158015948401949094527001000000000000000000000000000000)
            mstore(add(runtime, 9728), 0x0082048116151594830194909452710100000000000000000000000000000000)
        }
    }

    function part19(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 9760), 0x0081048416151560608301527201000000000000000000000000000000000000)
            mstore(add(runtime, 9792), 0x8104841615156080830152730100000000000000000000000000000000000000)
            mstore(add(runtime, 9824), 0x9004909216151560a08301526126555750505050565b8060800151156126ae57)
            mstore(add(runtime, 9856), 0x73ffffffffffffffffffffffffffffffffffffffff82163b156126ae57604051)
            mstore(add(runtime, 9888), 0x7f52245b98000000000000000000000000000000000000000000000000000000)
            mstore(add(runtime, 9920), 0x00815260040160405180910390fd5b8060a001511561279c576040517f89a9c8)
            mstore(add(runtime, 9952), 0x5500000000000000000000000000000000000000000000000000000000815273)
            mstore(add(runtime, 9984), 0xffffffffffffffffffffffffffffffffffffffff83811660048301527f000000)
            mstore(add(runtime, 10016), 0x000000000000000000721c00182a990771244d7a71b9fa2ea789a3b433169063)
            mstore(add(runtime, 10048), 0x89a9c85590602401602060405180830381865afa158015612742573d5f803e3d)
            mstore(add(runtime, 10080), 0x5ffd5b505050506040513d601f19601f82011682018060405250810190612766)
            mstore(add(runtime, 10112), 0x9190613ac6565b61279c576040517fa451bf2a00000000000000000000000000)
            mstore(add(runtime, 10144), 0x000000000000000000000000000000815260040160405180910390fd5b8273ff)
            mstore(add(runtime, 10176), 0xffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffff)
            mstore(add(runtime, 10208), 0xffffffffffffffffffff160361280b57806060015115610bbe576040517ff87c)
            mstore(add(runtime, 10240), 0x9614000000000000000000000000000000000000000000000000000000008152)
        }
    }

    function part20(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 10272), 0x60040160405180910390fd5b337f596a397a0000000000000000000000000000)
            mstore(add(runtime, 10304), 0x00000000000000000000000000001761285b8163ffffffff7f00000000000000)
            mstore(add(runtime, 10336), 0x0000000000000000000000000000000000000002b700001d9416565b73ffffff)
            mstore(add(runtime, 10368), 0xffffffffffffffffffffffffffffffffff168573ffffffffffffffffffffffff)
            mstore(add(runtime, 10400), 0xffffffffffffffff1603612894575050505050565b8160400151156129225781)
            mstore(add(runtime, 10432), 0x516effffffffffffffffffffffffffffff165f90815260016020908152604080)
            mstore(add(runtime, 10464), 0x832073ffffffffffffffffffffffffffffffffffffffff891684526009019091)
            mstore(add(runtime, 10496), 0x5290205460ff161561291d576040517f1de5204e000000000000000000000000)
            mstore(add(runtime, 10528), 0x00000000000000000000000000000000815260040160405180910390fd5b6109)
            mstore(add(runtime, 10560), 0xc9565b81516effffffffffffffffffffffffffffff165f908152600160209081)
            mstore(add(runtime, 10592), 0x52604080832073ffffffffffffffffffffffffffffffffffffffff8916845260)
            mstore(add(runtime, 10624), 0x060190915290205460ff166109c9576040517f1de5204e000000000000000000)
            mstore(add(runtime, 10656), 0x00000000000000000000000000000000000000815260040160405180910390fd)
            mstore(add(runtime, 10688), 0x5b6129a982612d73565b5f8160088111156129bc576129bc613a99565b036129)
            mstore(add(runtime, 10720), 0xc5575060035b73ffffffffffffffffffffffffffffffffffffffff82165f9081)
            mstore(add(runtime, 10752), 0x5260026020526040902060018260088111156129fd576129fd613a99565b0361)
        }
    }

    function part21(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 10784), 0x2a3f5780547fffffffffffffffffffffffff0000000000ffffffffffffffffff)
            mstore(add(runtime, 10816), 0xffffffffffff166f01000000000000000000000000000000178155612cca565b)
            mstore(add(runtime, 10848), 0x6002826008811115612a5357612a53613a99565b03612a965780547fffffffff)
            mstore(add(runtime, 10880), 0xffffffffffffffff0000000000ffffffffffffffffffffffffffffff16700100)
            mstore(add(runtime, 10912), 0x000000000000000000000000000000178155612cca565b600382600881111561)
            mstore(add(runtime, 10944), 0x2aaa57612aaa613a99565b03612ada5780547fffffffffffffffffffffffff00)
            mstore(add(runtime, 10976), 0x00000000ffffffffffffffffffffffffffffff168155612cca565b6004826008)
            mstore(add(runtime, 11008), 0x811115612aee57612aee613a99565b03612b325780547fffffffffffffffffff)
            mstore(add(runtime, 11040), 0xffffff0000000000ffffffffffffffffffffffffffffff167101000000000000)
            mstore(add(runtime, 11072), 0x0000000000000000000000178155612cca565b6005826008811115612b465761)
            mstore(add(runtime, 11104), 0x2b46613a99565b03612b8b5780547fffffffffffffffffffffffff0000000000)
            mstore(add(runtime, 11136), 0xffffffffffffffffffffffffffffff1672010000000000000000000000000000)
            mstore(add(runtime, 11168), 0x00000000178155612cca565b6006826008811115612b9f57612b9f613a99565b)
            mstore(add(runtime, 11200), 0x03612be55780547fffffffffffffffffffffffff0000000000ffffffffffffff)
            mstore(add(runtime, 11232), 0xffffffffffffffff167301000000000000000000000000000000000000001781)
            mstore(add(runtime, 11264), 0x55612cca565b6007826008811115612bf957612bf9613a99565b03612c3e5780)
        }
    }

    function part22(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 11296), 0x547fffffffffffffffffffffffff0000000000ffffffffffffffffffffffffff)
            mstore(add(runtime, 11328), 0xffff167201010000000000000000000000000000000000178155612cca565b60)
            mstore(add(runtime, 11360), 0x08826008811115612c5257612c52613a99565b03612c985780547fffffffffff)
            mstore(add(runtime, 11392), 0xffffffffffffff0000000000ffffffffffffffffffffffffffffff1673010001)
            mstore(add(runtime, 11424), 0x0000000000000000000000000000000000178155612cca565b6040517f5ec600)
            mstore(add(runtime, 11456), 0xe300000000000000000000000000000000000000000000000000000000815260)
            mstore(add(runtime, 11488), 0x040160405180910390fd5b7fb39d8f1e6f05413a407e46fc950eb92e9f5b3d65)
            mstore(add(runtime, 11520), 0xa47c3f0bdc7a2741a6ec0f7d8383604051612cfb929190613b5a565b60405180)
            mstore(add(runtime, 11552), 0x910390a1505050565b5f8173ffffffffffffffffffffffffffffffffffffffff)
            mstore(add(runtime, 11584), 0x16600a5a612d2d9190613bb9565b6040515f8181818686fa925050503d805f81)
            mstore(add(runtime, 11616), 0x14612d65576040519150601f19603f3d011682016040523d82523d5f60208401)
            mstore(add(runtime, 11648), 0x3e612d6a565b606091505b50909392505050565b73ffffffffffffffffffffff)
            mstore(add(runtime, 11680), 0xffffffffffffffffff81163303612d935750565b612d9c816133ab565b73ffff)
            mstore(add(runtime, 11712), 0xffffffffffffffffffffffffffffffffffff163303612dbb5750565b612dc481)
            mstore(add(runtime, 11744), 0x6133d4565b610b02576040517f05b33364000000000000000000000000000000)
            mstore(add(runtime, 11776), 0x00000000000000000000000000815260040160405180910390fd5b335f908152)
        }
    }

    function part23(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 11808), 0x60026020908152604091829020825160c08101845290546effffffffffffffff)
            mstore(add(runtime, 11840), 0xffffffffffffff8116825260ff6f010000000000000000000000000000008204)
            mstore(add(runtime, 11872), 0x8116158015948401949094527001000000000000000000000000000000008204)
            mstore(add(runtime, 11904), 0x8116151594830194909452710100000000000000000000000000000000008104)
            mstore(add(runtime, 11936), 0x8416151560608301527201000000000000000000000000000000000000810484)
            mstore(add(runtime, 11968), 0x1615156080830152730100000000000000000000000000000000000000900490)
            mstore(add(runtime, 12000), 0x9216151560a0830152612ed25750610bbe565b806080015115612f2b5773ffff)
            mstore(add(runtime, 12032), 0xffffffffffffffffffffffffffffffffffff83163b15612f2b576040517f5224)
            mstore(add(runtime, 12064), 0x5b98000000000000000000000000000000000000000000000000000000008152)
            mstore(add(runtime, 12096), 0x60040160405180910390fd5b8060a0015115613019576040517f89a9c8550000)
            mstore(add(runtime, 12128), 0x0000000000000000000000000000000000000000000000000000815273ffffff)
            mstore(add(runtime, 12160), 0xffffffffffffffffffffffffffffffffff84811660048301527f000000000000)
            mstore(add(runtime, 12192), 0x000000000000721c00182a990771244d7a71b9fa2ea789a3b43316906389a9c8)
            mstore(add(runtime, 12224), 0x5590602401602060405180830381865afa158015612fbf573d5f803e3d5ffd5b)
            mstore(add(runtime, 12256), 0x505050506040513d601f19601f82011682018060405250810190612fe3919061)
            mstore(add(runtime, 12288), 0x3ac6565b613019576040517fa451bf2a00000000000000000000000000000000)
        }
    }

    function part24(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 12320), 0x000000000000000000000000815260040160405180910390fd5b8373ffffffff)
            mstore(add(runtime, 12352), 0xffffffffffffffffffffffffffffffff168573ffffffffffffffffffffffffff)
            mstore(add(runtime, 12384), 0xffffffffffffff160361308e57806060015115613088576040517ff87c961400)
            mstore(add(runtime, 12416), 0x0000000000000000000000000000000000000000000000000000008152600401)
            mstore(add(runtime, 12448), 0x60405180910390fd5b50610bbe565b7f7e746c61000000000000000000000000)
            mstore(add(runtime, 12480), 0x000000000000000000000000000000005f908152336018526004839052603881)
            mstore(add(runtime, 12512), 0x20906130ee8263ffffffff7f0000000000000000000000000000000000000000)
            mstore(add(runtime, 12544), 0x00000000000002b700001d9416565b905080156130fe57505050610bbe565b82)
            mstore(add(runtime, 12576), 0x604001511561318c5782516effffffffffffffffffffffffffffff165f908152)
            mstore(add(runtime, 12608), 0x60016020908152604080832073ffffffffffffffffffffffffffffffffffffff)
            mstore(add(runtime, 12640), 0xff8b16845260090190915290205460ff1615613187576040517f1de5204e0000)
            mstore(add(runtime, 12672), 0x0000000000000000000000000000000000000000000000000000815260040160)
            mstore(add(runtime, 12704), 0x405180910390fd5b61320a565b82516effffffffffffffffffffffffffffff16)
            mstore(add(runtime, 12736), 0x5f90815260016020908152604080832073ffffffffffffffffffffffffffffff)
            mstore(add(runtime, 12768), 0xffffffffff8b16845260060190915290205460ff1661320a576040517f1de520)
            mstore(add(runtime, 12800), 0x4e00000000000000000000000000000000000000000000000000000000815260)
        }
    }

    function part25(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 12832), 0x040160405180910390fd5b50505050505050565b8181600281015f6132238461)
            mstore(add(runtime, 12864), 0x3415565b90505f805b828110156133045761323a868261341e565b9150613246)
            mstore(add(runtime, 12896), 0x8583613310565b156132fc578173ffffffffffffffffffffffffffffffffffff)
            mstore(add(runtime, 12928), 0xffff16896effffffffffffffffffffffffffffff168b60028111156132865761)
            mstore(add(runtime, 12960), 0x3286613a99565b6040517fda8f3bd170446760f0f965a9b52bf271cb9679b5e0)
            mstore(add(runtime, 12992), 0xa70059eff2d49425229d17905f90a473ffffffffffffffffffffffffffffffff)
            mstore(add(runtime, 13024), 0xffffffff82165f90815260208590526040902080547fffffffffffffffffffff)
            mstore(add(runtime, 13056), 0xffffffffffffffffffffffffffffffffffffffffff001660011790555b600101)
            mstore(add(runtime, 13088), 0x613228565b50505050505050505050565b5f61212b8373ffffffffffffffffff)
            mstore(add(runtime, 13120), 0xffffffffffffffffffffff8416613429565b5f61212b8373ffffffffffffffff)
            mstore(add(runtime, 13152), 0xffffffffffffffffffffffff8416613475565b6060815f018054806020026020)
            mstore(add(runtime, 13184), 0x0160405190810160405280929190818152602001828054801561339f57602002)
            mstore(add(runtime, 13216), 0x820191905f5260205f20905b81548152602001906001019080831161338b575b)
            mstore(add(runtime, 13248), 0x50505050509050919050565b5f638da5cb5b5f5260205f6004601c855afa8060)
            mstore(add(runtime, 13280), 0x203d101516156133ce575f5191505b50919050565b5f60405160608101604052)
            mstore(add(runtime, 13312), 0x6391d1485481525f816020015233816040015260205f6044601c8401865afa90)
        }
    }

    function part26(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 13344), 0x508060203d101516156133ce5750505f51919050565b5f610a8d825490565b5f)
            mstore(add(runtime, 13376), 0x61212b8383613558565b5f81815260018301602052604081205461346e575081)
            mstore(add(runtime, 13408), 0x54600181810184555f8481526020808220909301849055845484825282860190)
            mstore(add(runtime, 13440), 0x93526040902091909155610a8d565b505f610a8d565b5f818152600183016020)
            mstore(add(runtime, 13472), 0x526040812054801561354f575f613497600183613bf1565b85549091505f9061)
            mstore(add(runtime, 13504), 0x34aa90600190613bf1565b9050818114613509575f865f0182815481106134c8)
            mstore(add(runtime, 13536), 0x576134c8613a2c565b905f5260205f200154905080875f0184815481106134e8)
            mstore(add(runtime, 13568), 0x576134e8613a2c565b5f91825260208083209091019290925591825260018801)
            mstore(add(runtime, 13600), 0x9052604090208390555b855486908061351a5761351a613c04565b6001900381)
            mstore(add(runtime, 13632), 0x81905f5260205f20015f90559055856001015f8681526020019081526020015f)
            mstore(add(runtime, 13664), 0x205f905560019350505050610a8d565b5f915050610a8d565b5f825f01828154)
            mstore(add(runtime, 13696), 0x811061356d5761356d613a2c565b905f5260205f200154905092915050565b80)
            mstore(add(runtime, 13728), 0x356effffffffffffffffffffffffffffff81168114611dc7575f80fd5b5f805f)
            mstore(add(runtime, 13760), 0x604084860312156135ae575f80fd5b6135b78461357e565b9250602084013567)
            mstore(add(runtime, 13792), 0xffffffffffffffff808211156135d3575f80fd5b818601915086601f83011261)
            mstore(add(runtime, 13824), 0x35e6575f80fd5b8135818111156135f4575f80fd5b8760208260051b85010111)
        }
    }

    function part27(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 13856), 0x15613608575f80fd5b6020830194508093505050509250925092565b5f602082)
            mstore(add(runtime, 13888), 0x8403121561362b575f80fd5b81357fffffffff00000000000000000000000000)
            mstore(add(runtime, 13920), 0x0000000000000000000000000000008116811461212b575f80fd5b803573ffff)
            mstore(add(runtime, 13952), 0xffffffffffffffffffffffffffffffffffff81168114611dc7575f80fd5b5f80)
            mstore(add(runtime, 13984), 0x6040838503121561368e575f80fd5b6136978361357e565b91506136a5602084)
            mstore(add(runtime, 14016), 0x0161365a565b90509250929050565b5f602082840312156136be575f80fd5b61)
            mstore(add(runtime, 14048), 0x212b8261365a565b5f602082840312156136d7575f80fd5b61212b8261357e56)
            mstore(add(runtime, 14080), 0x5b602080825282518282018190525f9190848201906040850190845b81811015)
            mstore(add(runtime, 14112), 0x61372d57835173ffffffffffffffffffffffffffffffffffffffff1683529284)
            mstore(add(runtime, 14144), 0x0192918401916001016136fb565b50909695505050505050565b5f805f805f60)
            mstore(add(runtime, 14176), 0xa0868803121561374d575f80fd5b6137568661365a565b945061376460208701)
            mstore(add(runtime, 14208), 0x61365a565b93506137726040870161365a565b94979396509394606081013594)
            mstore(add(runtime, 14240), 0x506080013592915050565b5f805f6060848603121561379c575f80fd5b6137a5)
            mstore(add(runtime, 14272), 0x8461365a565b92506137b36020850161365a565b91506137c16040850161365a)
            mstore(add(runtime, 14304), 0x565b90509250925092565b5f805f606084860312156137dc575f80fd5b6137e5)
            mstore(add(runtime, 14336), 0x8461365a565b95602085013595506040909401359392505050565b8015158114)
        }
    }

    function part28(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 14368), 0x610b02575f80fd5b5f805f805f60a0868803121561381b575f80fd5b61382486)
            mstore(add(runtime, 14400), 0x61365a565b9450602086013560ff81168114613839575f80fd5b935060408601)
            mstore(add(runtime, 14432), 0x35613849816137fa565b92506060860135613859816137fa565b915060808601)
            mstore(add(runtime, 14464), 0x35613869816137fa565b809150509295509295909350565b5f80604083850312)
            mstore(add(runtime, 14496), 0x15613888575f80fd5b6138918361365a565b946020939093013593505050565b)
            mstore(add(runtime, 14528), 0x5f80604083850312156138b0575f80fd5b6136978361365a565b5f8083601f84)
            mstore(add(runtime, 14560), 0x01126138c9575f80fd5b50813567ffffffffffffffff8111156138e0575f80fd)
            mstore(add(runtime, 14592), 0x5b6020830191508360208285010111156138f7575f80fd5b9250929050565b5f)
            mstore(add(runtime, 14624), 0x806020838503121561390f575f80fd5b823567ffffffffffffffff8111156139)
            mstore(add(runtime, 14656), 0x25575f80fd5b613931858286016138b9565b90969095509350505050565b5f80)
            mstore(add(runtime, 14688), 0x6040838503121561394e575f80fd5b6139578361365a565b91506136a5602084)
            mstore(add(runtime, 14720), 0x0161357e565b5f805f8060808587031215613978575f80fd5b6139818561365a)
            mstore(add(runtime, 14752), 0x565b935061398f6020860161365a565b925061399d6040860161365a565b9396)
            mstore(add(runtime, 14784), 0x929550929360600135925050565b5f80604083850312156139be575f80fd5b61)
            mstore(add(runtime, 14816), 0x39c78361365a565b91506020830135600981106139da575f80fd5b8091505092)
            mstore(add(runtime, 14848), 0x50929050565b5f805f604084860312156139f7575f80fd5b833567ffffffffff)
        }
    }

    function part29(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 14880), 0xffffff811115613a0d575f80fd5b613a19868287016138b9565b909450925061)
            mstore(add(runtime, 14912), 0x37c190506020850161357e565b7f4e487b710000000000000000000000000000)
            mstore(add(runtime, 14944), 0x00000000000000000000000000005f52603260045260245ffd5b7f4e487b7100)
            mstore(add(runtime, 14976), 0x0000000000000000000000000000000000000000000000000000005f52601160)
            mstore(add(runtime, 15008), 0x045260245ffd5b80820180821115610a8d57610a8d613a59565b7f4e487b7100)
            mstore(add(runtime, 15040), 0x0000000000000000000000000000000000000000000000000000005f52602160)
            mstore(add(runtime, 15072), 0x045260245ffd5b5f60208284031215613ad6575f80fd5b815161212b816137fa)
            mstore(add(runtime, 15104), 0x565b5f6effffffffffffffffffffffffffffff808316818103613b0457613b04)
            mstore(add(runtime, 15136), 0x613a59565b6001019392505050565b6020815281602082015281836040830137)
            mstore(add(runtime, 15168), 0x5f818301604090810191909152601f9092017fffffffffffffffffffffffffff)
            mstore(add(runtime, 15200), 0xffffffffffffffffffffffffffffffffffffe0160101919050565b73ffffffff)
            mstore(add(runtime, 15232), 0xffffffffffffffffffffffffffffffff831681526040810160098310613bac57)
            mstore(add(runtime, 15264), 0x7f4e487b71000000000000000000000000000000000000000000000000000000)
            mstore(add(runtime, 15296), 0x005f52602160045260245ffd5b8260208301529392505050565b5f82613bec57)
            mstore(add(runtime, 15328), 0x7f4e487b71000000000000000000000000000000000000000000000000000000)
            mstore(add(runtime, 15360), 0x005f52601260045260245ffd5b500490565b81810381811115610a8d57610a8d)
        }
    }

    function part30(bytes memory runtime) private pure {
        assembly ("memory-safe") {
            mstore(add(runtime, 15392), 0x613a59565b7f4e487b7100000000000000000000000000000000000000000000)
            mstore(add(runtime, 15424), 0x0000000000005f52603160045260245ffdfea2646970667358221220160996c9)
            mstore(add(runtime, 15456), 0x4b1d698a40469e3f97911dd81a027efec7d78941305ede91222dd7d864736f6c)
            mstore(add(runtime, 15488), 0x6343000818003300000000000000000000000000000000000000000000000000)
        }
    }
}
