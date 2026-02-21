import { ethers, run } from 'hardhat';
import * as fs from 'fs';
import * as path from 'path';

async function main() {
  const network = (await ethers.provider.getNetwork()).name;
  const deployPath = path.join(__dirname, '../../deployments');
  const filePath = path.join(deployPath, `${network}.json`);

  if (!fs.existsSync(filePath)) {
    console.log('No deployment file found:', filePath);
    return;
  }

  const deployments = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  console.log('Verifying contracts on network:', network);

  const verify = async (name: string, address: string, args: any[] = []) => {
    try {
      console.log(`Verifying ${name} at ${address}...`);
      await run('verify:verify', { address, constructorArguments: args });
      console.log(`${name} verified`);
    } catch (e: any) {
      if (e.message.includes('Already Verified')) {
        console.log(`${name} already verified`);
      } else {
        console.log(`${name} verification failed:`, e.message);
      }
    }
  };

  for (const [name, info] of Object.entries(deployments)) {
    if (typeof info === 'object' && (info as any).implementation) {
      await verify(name, (info as any).implementation);
    } else if (typeof info === 'string') {
      await verify(name, info);
    }
  }

  console.log('Verification complete');
}

main().catch((error) => { console.error(error); process.exit(1); });
