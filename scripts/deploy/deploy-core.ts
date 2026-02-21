import { ethers, upgrades } from 'hardhat';
import * as fs from 'fs';
import * as path from 'path';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying core contracts with account:', deployer.address);

  const deployments: Record<string, { proxy: string; implementation: string }> = {};

  // Deploy UsageRegistry
  const UsageRegistry = await ethers.getContractFactory('UsageRegistry');
  const usageRegistry = await upgrades.deployProxy(UsageRegistry, [deployer.address], { kind: 'transparent' });
  await usageRegistry.waitForDeployment();
  const urAddr = await usageRegistry.getAddress();
  deployments.UsageRegistry = { proxy: urAddr, implementation: await upgrades.erc1967.getImplementationAddress(urAddr) };
  console.log('UsageRegistry:', urAddr);

  // Deploy PaymentSettlement
  const PaymentSettlement = await ethers.getContractFactory('PaymentSettlement');
  const paymentSettlement = await upgrades.deployProxy(PaymentSettlement, [deployer.address], { kind: 'transparent' });
  await paymentSettlement.waitForDeployment();
  const psAddr = await paymentSettlement.getAddress();
  deployments.PaymentSettlement = { proxy: psAddr, implementation: await upgrades.erc1967.getImplementationAddress(psAddr) };
  console.log('PaymentSettlement:', psAddr);

  // Deploy ProviderStaking (needs SHARE token address from env)
  const shareToken = process.env.SHARE_TOKEN_ADDRESS || deployer.address;
  const ProviderStaking = await ethers.getContractFactory('ProviderStaking');
  const providerStaking = await upgrades.deployProxy(ProviderStaking, [deployer.address, shareToken], { kind: 'transparent' });
  await providerStaking.waitForDeployment();
  const pstAddr = await providerStaking.getAddress();
  deployments.ProviderStaking = { proxy: pstAddr, implementation: await upgrades.erc1967.getImplementationAddress(pstAddr) };
  console.log('ProviderStaking:', pstAddr);

  // Save deployment record
  const network = (await ethers.provider.getNetwork()).name;
  const deployPath = path.join(__dirname, '../../deployments');
  if (!fs.existsSync(deployPath)) fs.mkdirSync(deployPath, { recursive: true });
  fs.writeFileSync(path.join(deployPath, `${network}-core.json`), JSON.stringify({ network, ...deployments, deployer: deployer.address, timestamp: new Date().toISOString() }, null, 2));
}

main().catch((error) => { console.error(error); process.exit(1); });
