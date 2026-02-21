import { expect } from 'chai';
import { ethers } from 'hardhat';
import { execSync } from 'child_process';

describe('Deployment Scripts', function () {
  it('should run deploy-token.ts', async () => {
    const output = execSync('npx hardhat run scripts/deploy/deploy-token.ts --network hardhat', { encoding: 'utf8' });
    expect(output).to.include('ShareToken proxy:');
    expect(output).to.include('ShareToken impl:');
  });

  it('should run deploy-core.ts', async () => {
    const output = execSync('npx hardhat run scripts/deploy/deploy-core.ts --network hardhat', { encoding: 'utf8' });
    expect(output).to.include('UsageRegistry:');
    expect(output).to.include('PaymentSettlement:');
    expect(output).to.include('ProviderStaking:');
  });

  it('should run deploy-governance.ts', async () => {
    const output = execSync('npx hardhat run scripts/deploy/deploy-governance.ts --network hardhat', { encoding: 'utf8' });
    expect(output).to.include('Timelock:');
    expect(output).to.include('Governor:');
    expect(output).to.include('Treasury:');
  });

  it('should run deploy-all.ts', async () => {
    const output = execSync('npx hardhat run scripts/deploy/deploy-all.ts --network hardhat', { encoding: 'utf8' });
    expect(output).to.include('All contracts deployed');
  });
});
