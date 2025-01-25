// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IBEP20 {
   function totalSupply() external view returns (uint256);
   function balanceOf(address account) external view returns (uint256);
   function transfer(address recipient, uint256 amount) external returns (bool);
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract PirogiesStaking is ReentrancyGuard, Ownable {
   IBEP20 public immutable stakingToken;
   address public radomSigner;
   uint256 public constant WITHDRAW_TIME = 1708819200; 
   uint256 public constant POOL_LIMIT = 100_000_000_000 * 10**18;
   uint256 public totalStaked;
   
   bytes32 public constant BUY_ONLY = keccak256("BUY_ONLY");
   bytes32 public constant BUY_AND_STAKE = keccak256("BUY_AND_STAKE");
   
   struct Stake {
       uint256 amount;
       uint256 timestamp;
       uint256 lastRewardCalculation;
   }
   
   struct Tier {
       uint256 poolUsagePercentage;
       uint256 apy;
   }

   struct Purchase {
       address buyer;
       uint256 amount;
       bytes32 purchaseType;
       bool processed;
   }
   
   mapping(address => Stake) public stakes;
   mapping(bytes32 => Purchase) public purchases;
   mapping(string => bool) public usedReferenceIds;
   Tier[] public tiers;
   
   event Staked(address indexed user, uint256 amount);
   event Withdrawn(address indexed user, uint256 amount);
   event RewardClaimed(address indexed user, uint256 amount);
   event PurchaseProcessed(
       address indexed buyer,
       uint256 amount,
       bytes32 purchaseType,
       string referenceId
   );
   
   constructor(address _stakingToken, address _radomSigner) Ownable(msg.sender) {
       stakingToken = IBEP20(_stakingToken);
       radomSigner = _radomSigner;
       _initializeTiers();
   }
   
   function _initializeTiers() private {
       tiers.push(Tier(2, 17500));
       tiers.push(Tier(4, 16000));
       tiers.push(Tier(6, 15000));
       tiers.push(Tier(8, 14000));
       tiers.push(Tier(10, 13000));
       tiers.push(Tier(15, 12000));
       tiers.push(Tier(20, 11000));
       tiers.push(Tier(25, 10000));
       tiers.push(Tier(30, 9000));
       tiers.push(Tier(35, 8000));
       tiers.push(Tier(40, 7000));
       tiers.push(Tier(45, 6000));
       tiers.push(Tier(50, 5000));
       tiers.push(Tier(55, 4000));
       tiers.push(Tier(60, 3500));
       tiers.push(Tier(65, 3000));
       tiers.push(Tier(70, 2500));
       tiers.push(Tier(75, 2000));
       tiers.push(Tier(80, 1500));
       tiers.push(Tier(85, 1000));
       tiers.push(Tier(90, 750));
       tiers.push(Tier(95, 500));
       tiers.push(Tier(98, 250));
       tiers.push(Tier(100, 0));
   }

   function toEthSignedMessageHash(bytes32 message) internal pure returns (bytes32) {
       return keccak256(abi.encodePacked(
           "\x19Ethereum Signed Message:\n32",
           message
       ));
   }

   function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
       require(signature.length == 65, "Invalid signature length");
       
       bytes32 r;
       bytes32 s;
       uint8 v;
       
       assembly {
           r := mload(add(signature, 32))
           s := mload(add(signature, 64))
           v := byte(0, mload(add(signature, 96)))
       }
       
       if (v < 27) {
           v += 27;
       }
       
       require(v == 27 || v == 28, "Invalid signature v value");
       return ecrecover(hash, v, r, s);
   }

   function processPurchase(
       address buyer,
       uint256 amount,
       bytes32 purchaseType,
       string memory referenceId,
       bytes memory signature
   ) external {
       require(!usedReferenceIds[referenceId], "Reference ID already used");
       
       bytes32 message = keccak256(abi.encodePacked(
           buyer,
           amount,
           purchaseType,
           referenceId
       ));
       bytes32 hash = toEthSignedMessageHash(message);
       address signer = recoverSigner(hash, signature);
       require(signer == radomSigner, "Invalid signature");

       usedReferenceIds[referenceId] = true;
       
       if (purchaseType == BUY_AND_STAKE) {
           _stake(buyer, amount);
       }
       
       emit PurchaseProcessed(buyer, amount, purchaseType, referenceId);
   }

   function setRadomSigner(address _signer) external onlyOwner {
       require(_signer != address(0), "Invalid signer");
       radomSigner = _signer;
   }
   
   function getCurrentAPY() public view returns (uint256) {
       uint256 poolUsagePercent = (totalStaked * 100) / POOL_LIMIT;
       
       for (uint i = 0; i < tiers.length - 1; i++) {
           if (poolUsagePercent < tiers[i].poolUsagePercentage) {
               return tiers[i].apy;
           }
       }
       return 0;
   }
   
   function calculateRewards(address user) public view returns (uint256) {
       Stake memory userStake = stakes[user];
       if (userStake.amount == 0) return 0;
       
       uint256 timeElapsed = block.timestamp - userStake.lastRewardCalculation;
       uint256 apy = getCurrentAPY();
       
       return (userStake.amount * apy * timeElapsed) / (365 days * 100);
   }

   function stake(uint256 amount) external nonReentrant {
       _stake(msg.sender, amount);
   }
   
   function _stake(address user, uint256 amount) private {
       require(amount > 0, "Cannot stake 0");
       require(totalStaked + amount <= POOL_LIMIT, "Pool limit exceeded");
       
       if (user != msg.sender) {
           require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
       } else {
           _claimRewards();
           require(stakingToken.transferFrom(user, address(this), amount), "Transfer failed");
       }
       
       if (stakes[user].amount == 0) {
           stakes[user] = Stake({
               amount: amount,
               timestamp: block.timestamp,
               lastRewardCalculation: block.timestamp
           });
       } else {
           stakes[user].amount += amount;
           stakes[user].lastRewardCalculation = block.timestamp;
       }
       
       totalStaked += amount;
       emit Staked(user, amount);
   }
   
   function withdraw(uint256 amount) external nonReentrant {
       require(block.timestamp >= WITHDRAW_TIME, "Withdrawal not allowed yet");
       require(stakes[msg.sender].amount >= amount, "Insufficient staked amount");
       
       _claimRewards();
       
       stakes[msg.sender].amount -= amount;
       totalStaked -= amount;
       stakes[msg.sender].lastRewardCalculation = block.timestamp;
       
       require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
       emit Withdrawn(msg.sender, amount);
   }
   
   function _claimRewards() private {
       uint256 rewards = calculateRewards(msg.sender);
       if (rewards > 0) {
           stakes[msg.sender].lastRewardCalculation = block.timestamp;
           require(stakingToken.transfer(msg.sender, rewards), "Reward transfer failed");
           emit RewardClaimed(msg.sender, rewards);
       }
   }
   
   function claimRewards() external nonReentrant {
       _claimRewards();
   }
   
   function emergencyWithdraw() external nonReentrant {
       require(block.timestamp >= WITHDRAW_TIME, "Withdrawal not allowed yet");
       uint256 amount = stakes[msg.sender].amount;
       require(amount > 0, "No stake to withdraw");
       
       delete stakes[msg.sender];
       totalStaked -= amount;
       
       require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
       emit Withdrawn(msg.sender, amount);
   }
   
   function getWithdrawalAvailability() public view returns (
       bool isAvailable,
       uint256 remainingTime
   ) {
       if (block.timestamp >= WITHDRAW_TIME) {
           return (true, 0);
       }
       return (false, WITHDRAW_TIME - block.timestamp);
   }
}
