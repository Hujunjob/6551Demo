// This is a script for deploying your contracts. You can adapt it to deploy
const { BigNumber } = require("ethers");
const { network, ethers } = require("hardhat");

let {
  contract_version,
  SAVE_FILE_ADDRESS,
} = require("../contract.config")

// yours, or create new ones.
let admin = "0x89693ae82BB93f0f7a0DDB686a5Ee07c97943cD8"
let deployer;
let addrs;
let erc6551Account
let register
let nft

async function main() {
  // This is just a convenience check
  console.log("net work name=" + network.name)
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
      "gets automatically created and destroyed every time. Use the Hardhat" +
      " option '--network localhost'"
    );
  }

  // ethers is avaialble in the global scope
  [deployer, ...addrs] = await ethers.getSigners();

  // console.log("Account balance:", (await deployer.getBalance()).toString());

  //发送交易，获得收据
  if (network.name == "localhost") {
    // 创建交易请求，参数：to为接收地址，value为ETH数额
    const tx = {
      to: admin,
      value: ethers.utils.parseEther("10")
    }
    const receipt = await deployer.sendTransaction(tx)
    await receipt.wait() // 等待链上确认交易
  }

  // console.log(receipt) // 打印交易详情

  // await loadContract()

  await deployAccount()
  await deployRegister()
  await deployNFT()
}

async function deployAccount() {
  if (erc6551Account != null) {
    return;
  }
  console.log("deployAccount start")
  const Factory = await ethers.getContractFactory("Account");
  erc6551Account = await Factory.deploy();
  await erc6551Account.deployed();
  console.log("deployAccount finish "+erc6551Account.address)
  // saveFrontendFiles(gold, "GameGold");
}

async function deployRegister() {
  if (register != null) {
    return;
  }
  console.log("deployRegister start")
  const Factory = await ethers.getContractFactory("ERC6551Registry");
  // RoyaltyReceiver = deployer.address;
  register = await Factory.deploy();
  await register.deployed();
  console.log("deployRegister finish "+register.address)
  // saveFrontendFiles(gold, "GameGold");
}

async function deployNFT() {
  if (nft != null) {
    return;
  }
  console.log("deployNFT start")
  const Factory = await ethers.getContractFactory("NFT");
  nft = await upgrades.deployProxy(Factory,["NFT","NFT"]);
  await nft.deployed();
  // saveFrontendFiles(inviteShop, "InviteShop");
}

function saveFrontendFiles(token, tokenname) {
  const fs = require("fs");
  const contractsDir = SAVE_FILE_ADDRESS + "/" + network.name + "/" + contract_version;
  console.log("contract name " + tokenname + " deployed,address:" + token.address + ",contractsDir:" + contractsDir);
  var json = {};
  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  if (fs.existsSync(contractsDir + "/contract-address.json")) {
    var data = fs.readFileSync(contractsDir + "/contract-address.json").toString();
    json = JSON.parse(data);
  }

  json[tokenname] = token.address;
  var jsonStr = JSON.stringify(json, undefined, 2);
  fs.writeFileSync(
    contractsDir + "/contract-address.json",
    jsonStr
  );

  const TokenArtifact = artifacts.readArtifactSync(tokenname);

  fs.writeFileSync(
    contractsDir + "/" + tokenname + ".json",
    JSON.stringify(TokenArtifact.abi, null, 2)
  );
}


function getContractInstance(theInstance, address, name) {
  if (!theInstance) {
    console.log("getContractInstance " + name)
    // The Contract interface
    const TokenArtifact = artifacts.readArtifactSync(name);

    let abi = TokenArtifact.abi;
    let contractAddress = address;

    // 使用Provider 连接合约，将只有对合约的可读权限
    theInstance = new ethers.Contract(contractAddress, abi, deployer);
  }
  return theInstance;
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
