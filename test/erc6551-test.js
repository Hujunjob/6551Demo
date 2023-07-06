const { expect } = require("chai");
const { ethers, network } = require("hardhat");

describe("Greeter", function () {
    it("Should return the new greeting once it's changed", async function () {

        // ethers is avaialble in the global scope
        [deployer, ...addrs] = await ethers.getSigners();
        const Account = await ethers.getContractFactory("Account");
        let erc6551Account = await Account.deploy();
        await erc6551Account.deployed();

        // const AccountProxy = await ethers.getContractFactory("AccountProxy");
        // let accountProxy = await AccountProxy.deploy(erc6551Account.address);
        // await accountProxy.deployed();

        const ERC6551Registry = await ethers.getContractFactory("ERC6551Registry");
        // RoyaltyReceiver = deployer.address;
        let register = await ERC6551Registry.deploy();
        await register.deployed();

        const NFT = await ethers.getContractFactory("NFT");
        let nft = await upgrades.deployProxy(NFT, ["NFT", "NFT",register.address,erc6551Account.address]);
        await nft.deployed();

        // function createAccount(
        //     address implementation,
        //     uint256 chainId,
        //     address tokenContract,
        //     uint256 tokenId,
        //     uint256 salt,
        //     bytes calldata initData
        // )

        await nft.mint()

        let tokenId = await nft.tokenOfOwnerByIndex(deployer.address,0)
        console.log("tokenid="+ (tokenId));
        let nftAccount = await nft.erc6551Account(tokenId)
        console.log("nftAccount="+nftAccount);

        // let implementation = erc6551Account.address
        // let chainId = network.config.chainId
        // let tokenContract = nft.address
        // console.log("implementation="+implementation+",chainId="+chainId+",tokenContract="+tokenContract);
        // await register.createAccount(implementation,chainId,tokenContract,tokenId,0,[])

        // let nftAccount = await register.account(implementation,chainId,tokenContract,tokenId,0)


        // await nft.transferFrom(deployer.address,nftAccount,tokenId)

        let balanceOf= await nft.balanceOf(nftAccount)
        console.log("balanceOf="+balanceOf);

        // provider.getCode(address)
        // let code =await ethers.provider.getCode(nftAccount)
        // console.log("code="+code+",length="+code.length);

        // function executeCall(
        //     address to,
        //     uint256 value,
        //     bytes calldata data
        // )


        const TokenArtifact = artifacts.readArtifactSync("Account");

        let abi = TokenArtifact.abi;
        // let contractAddress = address;

        // 使用Provider 连接合约，将只有对合约的可读权限
        let theInstance = new ethers.Contract(nftAccount, abi, deployer);
        let owner = await theInstance.owner()
        console.log("owner="+owner+",deployer="+deployer.address);

        const NFT2 = await ethers.getContractFactory("NFT2");
        let nft2 = await upgrades.deployProxy(NFT2, ["NFT2", "NFT2"]);
        await nft2.deployed();
        await nft2.mint()
        let tokenId2 = await nft.tokenOfOwnerByIndex(deployer.address,0)
        await nft2.transferFrom(deployer.address,nftAccount,tokenId2)

        let balanceOf2= await nft2.balanceOf(nftAccount)
        console.log("balanceOf2="+balanceOf2);
        // setApprovalForAll(address operator, bool approved)

        // const approveData = nft2.interface.encodeFunctionData("setApprovalForAll",[deployer.address,true])
        // await theInstance.executeCall(nft2.address,0,data)

        const data = nft2.interface.encodeFunctionData("transferFrom", [nftAccount,deployer.address , 1]); 
        await theInstance.executeCall(nft2.address,0,data)
        balanceOf2= await nft2.balanceOf(nftAccount)
        console.log("balanceOf2="+balanceOf2);
    });
});
