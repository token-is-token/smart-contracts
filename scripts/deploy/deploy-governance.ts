import { ethers, upgrades } from 'hardhat';
import * as fs from 'fs';
import * as path from 'path';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying governance contracts with account:', deployer.address);

  const shareToken = process.env.SHARE_TOKEN_ADDRESS || deployer.address;

  // Deploy Timelock (no proxy)
  const Timelock = await ethers.getContractFactory('Timelock');
  const timelock = await Timelock.deploy(deployer.address);
  await timelock.waitForDeployment();
  const tlAddr = await timelock.getAddress();
  console.log('Timelock:', tlAddr);

  // Deploy Governor (no proxy)
  const Governor = await ethers.getContractFactory('ShareGovernor');
  const governor = await Governor.deploy(shareToken, tlAddr);
  await governor.waitForDeployment();
  const govAddr = await governor.getAddress();
  console.log('Governor:', govAddr);

  // Deploy Treasury (with proxy)
  const Treasury = await ethers.getContractFactory('Treasury');
  const treasury = await upgrades.deployProxy(Treasury, [deployer.address], { kind: 'transparent' });
  await treasury.waitForDeployment();
  const trAddr = await treasury.getAddress();
  console.log('Treasury:', trAddr);

  // Save deployment record
  const network = (await ethers.provider.getNetwork()).name;
  const deployPath = path.join(__dirname, '../../deployments');
  if (!fs.existsSync(deployPath)) fs.mkdirSync(deployPath, { recursive: true });
  const record = {
    network,
    Timelock: tlAddr,
    Governor: govAddr,
    Treasury: { proxy: trAddr, implementation: await upgrades.erc1967.getImplementationAddress(trAddr) },
    deployer: deployer.address,
    timestamp: new Date().toISOString()
  };
  fs.writeFileSync(path.join(deployPath, `${network}-governance.json`), JSON.stringify(record, null, 2));
}

main().catch((error) => { console.error(error); process.exit(1); });
