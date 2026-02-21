import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';

describe('PaymentSettlement', function () {
  let paymentSettlement: any;
  let owner: any, consumer: any, provider: any, settler: any;

  beforeEach(async () => {
    [owner, consumer, provider, settler] = await ethers.getSigners();
    const PaymentSettlement = await ethers.getContractFactory('PaymentSettlement');
    paymentSettlement = await upgrades.deployProxy(PaymentSettlement, [owner.address]);
    await paymentSettlement.waitForDeployment();
  });

  it('should settle usage', async () => {
    const hash = ethers.keccak256(ethers.toUtf8Bytes('test'));
    await paymentSettlement.settleUsage(hash, consumer.address, provider.address, 1000);
    const settlement = await paymentSettlement.getSettlement(hash);
    expect(settlement.amount).to.equal(1000);
  });

  it('should dispute settlement', async () => {
    const hash = ethers.keccak256(ethers.toUtf8Bytes('test'));
    await paymentSettlement.settleUsage(hash, consumer.address, provider.address, 1000);
    await paymentSettlement.connect(consumer).disputeSettlement(hash, 'test reason');
    const settlement = await paymentSettlement.getSettlement(hash);
    expect(settlement.status).to.equal(2n); // Disputed (Enum value 2)
  });

  it('should resolve dispute', async () => {
    const hash = ethers.keccak256(ethers.toUtf8Bytes('test'));
    await paymentSettlement.settleUsage(hash, consumer.address, provider.address, 1000);
    await paymentSettlement.connect(consumer).disputeSettlement(hash, 'test');
    await paymentSettlement.resolveDispute(hash, 1); // Confirmed (Enum value 1)
    const settlement = await paymentSettlement.getSettlement(hash);
    expect(settlement.status).to.equal(1n);
  });
});
