import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';

describe('UsageRegistry', function () {
  let usageRegistry: any;
  let owner: any, consumer: any, provider: any;

  beforeEach(async () => {
    [owner, consumer, provider] = await ethers.getSigners();
    const UsageRegistry = await ethers.getContractFactory('UsageRegistry');
    usageRegistry = await upgrades.deployProxy(UsageRegistry, [owner.address]);
    await usageRegistry.waitForDeployment();
  });

  it('should record usage', async () => {
    const tx = await usageRegistry.recordUsage('gpt-4', 100, 200, consumer.address, provider.address);
    const receipt = await tx.wait();
    const event = receipt.logs.find((log: any) => log.fragment && log.fragment.name === 'UsageRecorded');
    const hash = event.args[0];
    const usage = await usageRegistry.getUsage(hash);
    expect(usage.model).to.equal('gpt-4');
    expect(usage.totalTokens).to.equal(300);
  });

  it('should get consumer usage', async () => {
    await usageRegistry.recordUsage('gpt-4', 100, 200, consumer.address, provider.address);
    const hashes = await usageRegistry.getConsumerUsage(consumer.address, 0, ethers.MaxUint256);
    expect(hashes.length).to.equal(1);
  });
});
