import { ethers, upgrades } from 'hardhat';
import * as fs from 'fs';
import * as path from 'path';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying ShareToken with account:', deployer.address);

  const treasury = process.env.TREASURY_ADDRESS || deployer.address;
  const liquidityPool = process.env.LP_ADDRESS || deployer.address;

  const ShareToken = await ethers.getContractFactory('ShareToken');
  const shareToken = await upgrades.deployProxy(
    ShareToken,
    ['ShareToken', 'SHARE', deployer.address, treasury, liquidityPool],
    { initializer: 'initialize', kind: 'transparent' }
  );
  await shareToken.waitForDeployment();

  const address = await shareToken.getAddress();
  const impl = await upgrades.erc1967.getImplementationAddress(address);

  console.log('ShareToken proxy:', address);
  console.log('ShareToken impl:', impl);

  // Save deployment record
  const network = (await ethers.provider.getNetwork()).name;
  const deployPath = path.join(__dirname, '../../deployments');
  if (!fs.existsSync(deployPath)) fs.mkdirSync(deployPath, { recursive: true });
  const record = { network, shareToken: { proxy: address, implementation: impl }, deployer: deployer.address, timestamp: new Date().toISOString() };
  fs.writeFileSync(path.join(deployPath, `${network}-token.json`), JSON.stringify(record, null, 2));
}

main().catch((error) => { console.error(error); process.exit(1); });
