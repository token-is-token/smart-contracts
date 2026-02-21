import { ethers, upgrades } from 'hardhat';
import * as fs from 'fs';
import * as path from 'path';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying all contracts with account:', deployer.address);

  const deployments: Record<string, any> = {};

  // 1. Deploy ShareToken
  const ShareToken = await ethers.getContractFactory('ShareToken');
  const shareToken = await upgrades.deployProxy(ShareToken, ['ShareToken', 'SHARE', deployer.address, deployer.address, deployer.address], { kind: 'transparent' });
  await shareToken.waitForDeployment();
  const stAddr = await shareToken.getAddress();
  deployments.ShareToken = { proxy: stAddr, implementation: await upgrades.erc1967.getImplementationAddress(stAddr) };
  console.log('ShareToken:', stAddr);

  // 2. Deploy core contracts
  const UsageRegistry = await ethers.getContractFactory('UsageRegistry');
  const usageRegistry = await upgrades.deployProxy(UsageRegistry, [deployer.address], { kind: 'transparent' });
  await usageRegistry.waitForDeployment();
  const urAddr = await usageRegistry.getAddress();
  deployments.UsageRegistry = { proxy: urAddr, implementation: await upgrades.erc1967.getImplementationAddress(urAddr) };

  const PaymentSettlement = await ethers.getContractFactory('PaymentSettlement');
  const paymentSettlement = await upgrades.deployProxy(PaymentSettlement, [deployer.address], { kind: 'transparent' });
  await paymentSettlement.waitForDeployment();
  const psAddr = await paymentSettlement.getAddress();
  deployments.PaymentSettlement = { proxy: psAddr, implementation: await upgrades.erc1967.getImplementationAddress(psAddr) };

  const ProviderStaking = await ethers.getContractFactory('ProviderStaking');
  const providerStaking = await upgrades.deployProxy(ProviderStaking, [deployer.address, stAddr], { kind: 'transparent' });
  await providerStaking.waitForDeployment();
  const pstAddr = await providerStaking.getAddress();
  deployments.ProviderStaking = { proxy: pstAddr, implementation: await upgrades.erc1967.getImplementationAddress(pstAddr) };
  console.log('Core contracts deployed');

  // 3. Deploy governance contracts
  const Timelock = await ethers.getContractFactory('Timelock');
  const timelock = await Timelock.deploy(deployer.address);
  await timelock.waitForDeployment();
  const tlAddr = await timelock.getAddress();
  deployments.Timelock = tlAddr;

  const Governor = await ethers.getContractFactory('ShareGovernor');
  const governor = await Governor.deploy(stAddr, tlAddr);
  await governor.waitForDeployment();
  deployments.Governor = await governor.getAddress();

  const Treasury = await ethers.getContractFactory('Treasury');
  const treasury = await upgrades.deployProxy(Treasury, [deployer.address], { kind: 'transparent' });
  await treasury.waitForDeployment();
  const trAddr = await treasury.getAddress();
  deployments.Treasury = { proxy: trAddr, implementation: await upgrades.erc1967.getImplementationAddress(trAddr) };
  console.log('Governance contracts deployed');

  // Save deployment record
  const network = (await ethers.provider.getNetwork()).name;
  const deployPath = path.join(__dirname, '../../deployments');
  if (!fs.existsSync(deployPath)) fs.mkdirSync(deployPath, { recursive: true });
  const record = { network, ...deployments, deployer: deployer.address, timestamp: new Date().toISOString() };
  fs.writeFileSync(path.join(deployPath, `${network}.json`), JSON.stringify(record, null, 2));
  console.log('All contracts deployed. Record saved to deployments/', network, '.json');
}

main().catch((error) => { console.error(error); process.exit(1); });
