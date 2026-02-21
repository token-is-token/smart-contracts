import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { ShareToken, ShareTokenV2 } from "../../typechain-types";

describe("ShareToken Upgrade", function () {
  let shareToken: ShareToken;
  let admin: SignerWithAddress;
  let treasury: SignerWithAddress;
  let lp: SignerWithAddress;
  let user: SignerWithAddress;
  let otherAccount: SignerWithAddress;

  const NAME = "ShareToken";
  const SYMBOL = "SHARE";

  beforeEach(async function () {
    [admin, treasury, lp, user, otherAccount] = await ethers.getSigners();

    const ShareTokenFactory = await ethers.getContractFactory("ShareToken");
    shareToken = (await upgrades.deployProxy(
      ShareTokenFactory,
      [NAME, SYMBOL, admin.address, treasury.address, lp.address],
      { initializer: "initialize" }
    )) as unknown as ShareToken;
  });

  it("should deploy as a transparent proxy", async function () {
    expect(await shareToken.name()).to.equal(NAME);
    expect(await shareToken.symbol()).to.equal(SYMBOL);
    expect(await shareToken.treasury()).to.equal(treasury.address);
    expect(await shareToken.liquidityPool()).to.equal(lp.address);
  });

  it("should preserve state after upgrade", async function () {
    // 1. Set some state in V1
    const model = "claude-3-opus";
    const initialRate = await shareToken.getMintingRate(model);
    expect(initialRate).to.be.gt(0);

    await shareToken.connect(admin).mintByUsage(model, 1000, user.address);
    const userBalanceBefore = await shareToken.balanceOf(user.address);
    expect(userBalanceBefore).to.be.gt(0);

    // 2. Upgrade to V2
    const ShareTokenV2Factory = await ethers.getContractFactory("ShareTokenV2");
    const shareTokenV2 = (await upgrades.upgradeProxy(
      await shareToken.getAddress(),
      ShareTokenV2Factory
    )) as unknown as ShareTokenV2;

    // 3. Verify state is preserved
    expect(await shareTokenV2.name()).to.equal(NAME);
    expect(await shareTokenV2.balanceOf(user.address)).to.equal(userBalanceBefore);
    expect(await shareTokenV2.getMintingRate(model)).to.equal(initialRate);
    expect(await shareTokenV2.treasury()).to.equal(treasury.address);
    expect(await shareTokenV2.liquidityPool()).to.equal(lp.address);

    // 4. Verify new functionality works
    await shareTokenV2.connect(admin).setVersion(2);
    expect(await shareTokenV2.getVersion()).to.equal(2);
  });

  it("should reject unauthorized upgrade", async function () {
    const ShareTokenV2Factory = await ethers.getContractFactory("ShareTokenV2", otherAccount);
    
    await expect(
        upgrades.upgradeProxy(
            await shareToken.getAddress(),
            ShareTokenV2Factory
        )
    ).to.be.rejected;
  });

  it("should preserve roles after upgrade", async function () {
    const MINTER_ROLE = await shareToken.MINTER_ROLE();
    const GOVERNANCE_ROLE = await shareToken.GOVERNANCE_ROLE();

    expect(await shareToken.hasRole(MINTER_ROLE, admin.address)).to.be.true;
    expect(await shareToken.hasRole(GOVERNANCE_ROLE, admin.address)).to.be.true;

    const ShareTokenV2Factory = await ethers.getContractFactory("ShareTokenV2");
    const shareTokenV2 = (await upgrades.upgradeProxy(
      await shareToken.getAddress(),
      ShareTokenV2Factory
    )) as unknown as ShareTokenV2;

    expect(await shareTokenV2.hasRole(MINTER_ROLE, admin.address)).to.be.true;
    expect(await shareTokenV2.hasRole(GOVERNANCE_ROLE, admin.address)).to.be.true;
  });
});
