import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';

describe('Governance', function () {
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

  it('should deploy timelock with correct delay', async () => {
    expect(await timelock.getMinDelay()).to.equal(2n * 24n * 60n * 60n);
  });

  it('should deploy governor with correct settings', async () => {
    expect(await governor.votingDelay()).to.equal(1n * 24n * 60n * 60n);
    expect(await governor.votingPeriod()).to.equal(7n * 24n * 60n * 60n);
    expect(await governor.proposalThreshold()).to.equal(ethers.parseEther('10000'));
  });

  it('should deposit to treasury', async () => {
    await shareToken.batchAirdrop([owner.address], [ethers.parseEther('1000')], 'test');
    await shareToken.approve(await treasury.getAddress(), ethers.parseEther('100'));
    await treasury.deposit(await shareToken.getAddress(), ethers.parseEther('100'));
    expect(await treasury.getBalance(await shareToken.getAddress())).to.equal(ethers.parseEther('100'));
  });
});
