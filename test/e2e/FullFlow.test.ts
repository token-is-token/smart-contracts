import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';

describe('Full Flow E2E', function () {
  let shareToken: any, usageRegistry: any, paymentSettlement: any, providerStaking: any, treasury: any;
  let owner: any, consumer: any, provider: any;

  beforeEach(async () => {
    [owner, consumer, provider] = await ethers.getSigners();
    const ShareToken = await ethers.getContractFactory('ShareToken');
    shareToken = await upgrades.deployProxy(ShareToken, ['ShareToken', 'SHARE', owner.address, owner.address, owner.address]);
    const UsageRegistry = await ethers.getContractFactory('UsageRegistry');
    usageRegistry = await upgrades.deployProxy(UsageRegistry, [owner.address]);
    const PaymentSettlement = await ethers.getContractFactory('PaymentSettlement');
    paymentSettlement = await upgrades.deployProxy(PaymentSettlement, [owner.address]);
    const ProviderStaking = await ethers.getContractFactory('ProviderStaking');
    providerStaking = await upgrades.deployProxy(ProviderStaking, [owner.address, await shareToken.getAddress()]);
    const Treasury = await ethers.getContractFactory('Treasury');
    treasury = await upgrades.deployProxy(Treasury, [owner.address]);
  });

  it('should complete full user journey', async () => {
    await shareToken.batchAirdrop([provider.address], [ethers.parseEther('100000')], 'initial');
    const stakeAmount = ethers.parseEther('50000');
    await shareToken.connect(provider).approve(await providerStaking.getAddress(), stakeAmount);
    await providerStaking.connect(provider).stake(stakeAmount);
    expect(await providerStaking.getProviderTier(provider.address)).to.equal(1);
  });
});
