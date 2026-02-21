import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';

describe('ProviderStaking', function () {
  let shareToken: any, providerStaking: any;
  let owner: any, provider: any;

  beforeEach(async () => {
    [owner, provider] = await ethers.getSigners();
    // Deploy ShareToken
    const ShareToken = await ethers.getContractFactory('ShareToken');
    shareToken = await upgrades.deployProxy(ShareToken, ['ShareToken', 'SHARE', owner.address, owner.address, owner.address]);
    await shareToken.waitForDeployment();

    const ProviderStaking = await ethers.getContractFactory('ProviderStaking');
    providerStaking = await upgrades.deployProxy(ProviderStaking, [owner.address, await shareToken.getAddress()]);
    await providerStaking.waitForDeployment();

    await shareToken.batchAirdrop([provider.address], [ethers.parseEther('100000')], 'test');
  });

  it('should stake tokens', async () => {
    const amount = ethers.parseEther('10000');
    await shareToken.connect(provider).approve(await providerStaking.getAddress(), amount);
    await providerStaking.connect(provider).stake(amount);
    const info = await providerStaking.getStakeInfo(provider.address);
    expect(info.amount).to.equal(amount);
  });

  it('should update tier', async () => {
    const amount = ethers.parseEther('10000');
    await shareToken.connect(provider).approve(await providerStaking.getAddress(), amount);
    await providerStaking.connect(provider).stake(amount);
    const tier = await providerStaking.getProviderTier(provider.address);
    expect(tier).to.equal(1);
  });
});
