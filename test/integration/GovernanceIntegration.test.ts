import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';

describe('Governance Integration', function () {
  let shareToken: any, timelock: any, governor: any, treasury: any;
  let owner: any;

  beforeEach(async () => {
    [owner] = await ethers.getSigners();
    const ShareToken = await ethers.getContractFactory('ShareToken');
    shareToken = await upgrades.deployProxy(ShareToken, ['ShareToken', 'SHARE', owner.address, owner.address, owner.address]);
    await shareToken.waitForDeployment();
    const Timelock = await ethers.getContractFactory('Timelock');
    timelock = await Timelock.deploy(owner.address);
    await timelock.waitForDeployment();
    const Governor = await ethers.getContractFactory('ShareGovernor');
    governor = await Governor.deploy(await shareToken.getAddress(), await timelock.getAddress());
    await governor.waitForDeployment();
    const Treasury = await ethers.getContractFactory('Treasury');
    treasury = await upgrades.deployProxy(Treasury, [owner.address]);
    await treasury.waitForDeployment();
  });

  it('should have correct governance setup', async () => {
    expect(await governor.name()).to.equal('ShareGovernor');
  });

  it('should fund treasury', async () => {
    await shareToken.batchAirdrop([await treasury.getAddress()], [ethers.parseEther('1000')], 'funding');
    expect(await shareToken.balanceOf(await treasury.getAddress())).to.equal(ethers.parseEther('1000'));
  });
});
