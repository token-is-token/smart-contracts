import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';

describe('Core Contracts Upgrade', function () {
  it('should upgrade PaymentSettlement', async () => {
    const [owner] = await ethers.getSigners();
    const PaymentSettlement = await ethers.getContractFactory('PaymentSettlement');
    const proxy = await upgrades.deployProxy(PaymentSettlement, [owner.address]);
    await proxy.waitForDeployment();
    const impl1 = await upgrades.erc1967.getImplementationAddress(await proxy.getAddress());
    
    const PaymentSettlementV2 = await ethers.getContractFactory('PaymentSettlement');
    const upgraded = await upgrades.upgradeProxy(await proxy.getAddress(), PaymentSettlementV2);
    const impl2 = await upgrades.erc1967.getImplementationAddress(await upgraded.getAddress());
    
    expect(await upgraded.getAddress()).to.equal(await proxy.getAddress());
  });

  it('should upgrade UsageRegistry', async () => {
    const [owner] = await ethers.getSigners();
    const UsageRegistry = await ethers.getContractFactory('UsageRegistry');
    const proxy = await upgrades.deployProxy(UsageRegistry, [owner.address]);
    await proxy.waitForDeployment();
    
    const UsageRegistryV2 = await ethers.getContractFactory('UsageRegistry');
    const upgraded = await upgrades.upgradeProxy(await proxy.getAddress(), UsageRegistryV2);
    expect(await upgraded.getAddress()).to.equal(await proxy.getAddress());
  });

  it('should upgrade ProviderStaking', async () => {
    const [owner] = await ethers.getSigners();
    const ShareToken = await ethers.getContractFactory('ShareToken');
    const shareToken = await upgrades.deployProxy(ShareToken, ['ShareToken', 'SHARE', owner.address, owner.address, owner.address]);
    
    const ProviderStaking = await ethers.getContractFactory('ProviderStaking');
    const proxy = await upgrades.deployProxy(ProviderStaking, [owner.address, await shareToken.getAddress()]);
    await proxy.waitForDeployment();
    
    const ProviderStakingV2 = await ethers.getContractFactory('ProviderStaking');
    const upgraded = await upgrades.upgradeProxy(await proxy.getAddress(), ProviderStakingV2);
    expect(await upgraded.getAddress()).to.equal(await proxy.getAddress());
  });
});
