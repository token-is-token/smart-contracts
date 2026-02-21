import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { ShareToken } from "../../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("ShareToken Unit Tests", function () {
  let shareToken: ShareToken;
  let admin: SignerWithAddress;
  let treasury: SignerWithAddress;
  let lp: SignerWithAddress;
  let provider: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let otherAccount: SignerWithAddress;

  const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
  const GOVERNANCE_ROLE = ethers.keccak256(ethers.toUtf8Bytes("GOVERNANCE_ROLE"));
  const AIRDROP_ROLE = ethers.keccak256(ethers.toUtf8Bytes("AIRDROP_ROLE"));

  beforeEach(async function () {
    [admin, treasury, lp, provider, user1, user2, otherAccount] = await ethers.getSigners();

    const ShareTokenFactory = await ethers.getContractFactory("ShareToken");
    shareToken = (await upgrades.deployProxy(
      ShareTokenFactory,
      ["ShareToken", "SHARE", admin.address, treasury.address, lp.address],
      { initializer: "initialize" }
    )) as unknown as ShareToken;
  });

  describe("Deployment & Initialization", function () {
    it("Should set the correct name and symbol", async function () {
      expect(await shareToken.name()).to.equal("ShareToken");
      expect(await shareToken.symbol()).to.equal("SHARE");
    });

    it("Should set the correct treasury and liquidity pool addresses", async function () {
      expect(await shareToken.treasury()).to.equal(treasury.address);
      expect(await shareToken.liquidityPool()).to.equal(lp.address);
    });

    it("Should grant roles to the admin", async function () {
      expect(await shareToken.hasRole(await shareToken.DEFAULT_ADMIN_ROLE(), admin.address)).to.be.true;
      expect(await shareToken.hasRole(MINTER_ROLE, admin.address)).to.be.true;
      expect(await shareToken.hasRole(GOVERNANCE_ROLE, admin.address)).to.be.true;
      expect(await shareToken.hasRole(AIRDROP_ROLE, admin.address)).to.be.true;
    });

    it("Should initialize with default minting rates", async function () {
      expect(await shareToken.getMintingRate("claude-3-opus")).to.equal(1000);
      expect(await shareToken.getMintingRate("claude-3-sonnet")).to.equal(500);
      expect(await shareToken.getMintingRate("gpt-4-turbo")).to.equal(800);
      expect(await shareToken.getMintingRate("gpt-3.5-turbo")).to.equal(100);
      expect(await shareToken.getMintingRate("seedance-2.0")).to.equal(10000);
    });

    it("Should fail if initialized twice", async function () {
      await expect(
        shareToken.initialize("NewName", "NEW", admin.address, treasury.address, lp.address)
      ).to.be.revertedWithCustomError(shareToken, "InvalidInitialization");
    });
  });

  describe("Minting (mintByUsage)", function () {
    const model = "claude-3-opus";
    const rate = 1000;
    const tokensConsumed = 10000;

    it("Should mint tokens and distribute them 85/10/5", async function () {
      const amount = (BigInt(tokensConsumed) * BigInt(rate)) / 1000n;
      const expectedTreasury = (amount * 1000n) / 10000n;
      const expectedLP = (amount * 500n) / 10000n;
      const expectedProvider = amount - expectedTreasury - expectedLP;

      await expect(shareToken.connect(admin).mintByUsage(model, tokensConsumed, provider.address))
        .to.emit(shareToken, "TokensMinted")
        .withArgs(model, tokensConsumed, amount, provider.address, anyValue);

      expect(await shareToken.balanceOf(provider.address)).to.equal(expectedProvider);
      expect(await shareToken.balanceOf(treasury.address)).to.equal(expectedTreasury);
      expect(await shareToken.balanceOf(lp.address)).to.equal(expectedLP);
    });

    it("Should fail if caller does not have MINTER_ROLE", async function () {
      await expect(
        shareToken.connect(otherAccount).mintByUsage(model, tokensConsumed, provider.address)
      ).to.be.revertedWithCustomError(shareToken, "AccessControlUnauthorizedAccount");
    });

    it("Should fail if provider is zero address", async function () {
      await expect(
        shareToken.connect(admin).mintByUsage(model, tokensConsumed, ethers.ZeroAddress)
      ).to.be.revertedWith("ShareToken: provider=0");
    });

    it("Should fail if model rate is zero", async function () {
      await expect(
        shareToken.connect(admin).mintByUsage("unknown-model", tokensConsumed, provider.address)
      ).to.be.revertedWith("ShareToken: rate=0");
    });

    it("Should fail if tokensConsumed is zero", async function () {
      await expect(
        shareToken.connect(admin).mintByUsage(model, 0, provider.address)
      ).to.be.revertedWith("ShareToken: consumed=0");
    });
  });

  describe("Airdrop (batchAirdrop)", function () {
    let recipients: string[];
    let amounts: bigint[];
    const reason = "Community Reward";

    beforeEach(async function () {
      recipients = [user1.address, user2.address];
      amounts = [ethers.parseEther("100"), ethers.parseEther("200")];
    });

    it("Should distribute airdrops correctly", async function () {
      await expect(shareToken.connect(admin).batchAirdrop(recipients, amounts, reason))
        .to.emit(shareToken, "AirdropDistributed")
        .withArgs(user1.address, amounts[0], reason)
        .and.to.emit(shareToken, "AirdropDistributed")
        .withArgs(user2.address, amounts[1], reason);

      expect(await shareToken.balanceOf(user1.address)).to.equal(amounts[0]);
      expect(await shareToken.balanceOf(user2.address)).to.equal(amounts[1]);
      expect(await shareToken.getAirdropHistory(user1.address)).to.equal(amounts[0]);
      expect(await shareToken.getAirdropHistory(user2.address)).to.equal(amounts[1]);
    });

    it("Should fail if caller does not have AIRDROP_ROLE", async function () {
      await expect(
        shareToken.connect(otherAccount).batchAirdrop(recipients, amounts, reason)
      ).to.be.revertedWithCustomError(shareToken, "AccessControlUnauthorizedAccount");
    });

    it("Should fail if array lengths mismatch", async function () {
      await expect(
        shareToken.connect(admin).batchAirdrop([user1.address], amounts, reason)
      ).to.be.revertedWith("ShareToken: length");
    });
  });

  describe("Governance & Rate Updates", function () {
    it("Should update minting rate within 20% limit", async function () {
      const model = "claude-3-opus";
      const oldRate = 1000;
      const newRate = 1100;

      await expect(shareToken.connect(admin).updateMintingRate(model, newRate))
        .to.emit(shareToken, "MintingRateUpdated")
        .withArgs(model, oldRate, newRate);

      expect(await shareToken.getMintingRate(model)).to.equal(newRate);
    });

    it("Should allow setting rate for new model without limit", async function () {
      const model = "new-model";
      const newRate = 5000;

      await expect(shareToken.connect(admin).updateMintingRate(model, newRate))
        .to.emit(shareToken, "MintingRateUpdated")
        .withArgs(model, 0, newRate);

      expect(await shareToken.getMintingRate(model)).to.equal(newRate);
    });

    it("Should fail if rate update exceeds 20%", async function () {
      const model = "claude-3-opus";
      const newRate = 1201;

      await expect(
        shareToken.connect(admin).updateMintingRate(model, newRate)
      ).to.be.revertedWith("ShareToken: delta>20%");
    });

    it("Should fail if rate update is below 20%", async function () {
      const model = "claude-3-opus";
      const newRate = 799;

      await expect(
        shareToken.connect(admin).updateMintingRate(model, newRate)
      ).to.be.revertedWith("ShareToken: delta>20%");
    });

    it("Should update treasury address", async function () {
      await shareToken.connect(admin).updateTreasury(otherAccount.address);
      expect(await shareToken.treasury()).to.equal(otherAccount.address);
    });

    it("Should update liquidity pool address", async function () {
      await shareToken.connect(admin).updateLiquidityPool(otherAccount.address);
      expect(await shareToken.liquidityPool()).to.equal(otherAccount.address);
    });

    it("Should fail governance updates if not GOVERNANCE_ROLE", async function () {
      await expect(
        shareToken.connect(otherAccount).updateMintingRate("claude-3-opus", 1100)
      ).to.be.revertedWithCustomError(shareToken, "AccessControlUnauthorizedAccount");

      await expect(
        shareToken.connect(otherAccount).updateTreasury(otherAccount.address)
      ).to.be.revertedWithCustomError(shareToken, "AccessControlUnauthorizedAccount");
    });
  });

  describe("Permissions", function () {
    it("Should allow admin to grant and revoke roles", async function () {
      await shareToken.connect(admin).grantRole(MINTER_ROLE, otherAccount.address);
      expect(await shareToken.hasRole(MINTER_ROLE, otherAccount.address)).to.be.true;

      await shareToken.connect(admin).revokeRole(MINTER_ROLE, otherAccount.address);
      expect(await shareToken.hasRole(MINTER_ROLE, otherAccount.address)).to.be.false;
    });
  });
});

const anyValue = (val: any) => true;
