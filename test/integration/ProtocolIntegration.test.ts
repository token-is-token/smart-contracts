import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';

describe('Protocol Integration', function () {
  let shareToken: any, usageRegistry: any, paymentSettlement: any, providerStaking: any;
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
  });

  it('should record usage and settle', async () => {
    const tx = await usageRegistry.recordUsage('gpt-4', 100, 200, consumer.address, provider.address);
    const receipt = await tx.wait();
    const event = receipt.logs.find((l: any) => l.fragment?.name === 'UsageRecorded');
    const usageHash = event.args[0];
    await paymentSettlement.settleUsage(usageHash, consumer.address, provider.address, 1000);
    const settlement = await paymentSettlement.getSettlement(usageHash);
    expect(settlement.amount).to.equal(1000);
  });

  it('should stake and get tier', async () => {
    await shareToken.batchAirdrop([provider.address], [ethers.parseEther('50000')], 'test');
    const stakeAmount = ethers.parseEther('10000');
    await shareToken.connect(provider).approve(await providerStaking.getAddress(), stakeAmount);
    await providerStaking.connect(provider).stake(stakeAmount);
    const tier = await providerStaking.getProviderTier(provider.address);
    expect(tier).to.equal(1);
  });

  it('should mint by usage', async () => {
    await shareToken.mintByUsage('claude-3-opus', 1000, provider.address);
    const balance = await shareToken.balanceOf(provider.address);
    expect(balance).to.be.greaterThan(0);
  });
});
