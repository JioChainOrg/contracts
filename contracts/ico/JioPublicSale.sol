// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract JioPublicSale  is Ownable, Pausable {
   
    using SafeERC20 for IERC20;
    IERC20 immutable public buyingToken; 
    IERC20 immutable public jioToken; 
    uint256 public jioPrice;

    uint256 public maxJioToSell;
    uint256 public totalRaised;
    uint256 public totalJioSold;

    uint256 public salesEndTime;

    bool public isInitialized;

    uint256 public totalJioWithdrawnByUsers;
    // set time

    uint256 public constant MAX_LOCK_PERIOD = 365;


    struct Purchase{
        uint256 purchaseAmount;
        uint256 jioAmount;
        uint256 purchaseTime;
        bool isWithdrawn;

    }


    mapping(address=>Purchase[]) public purchases;

    event onParticipate(uint256 buyingTokenAmount,uint256 jioAmount);
    event onClaim(uint256 jioAmount);
    constructor(IERC20 _jioToken,IERC20 _buyingToken, uint256 _jioPrice)  {
        buyingToken = _buyingToken;
        jioToken = _jioToken;
        updateJioPrice(_jioPrice);
    }

    function initialize(uint256 _maxJioToSell,uint256 _salesEndTime) public onlyOwner {
        require(!isInitialized,"already initialized");
        maxJioToSell = _maxJioToSell;
        jioToken.safeTransferFrom(msg.sender,address(this),maxJioToSell);
        updateSalesEndTime(_salesEndTime);
        isInitialized = true;
    }



    function updateSalesEndTime( uint256 _salesEndTime) public onlyOwner{
        require(_salesEndTime> block.timestamp,"invalid sales end time");
        salesEndTime = _salesEndTime;
    }

    function updateJioPrice( uint256 newPrice) public onlyOwner{
        jioPrice = newPrice;
    }

    function withdrawBuyingTokens() public onlyOwner {
        buyingToken.safeTransfer(msg.sender,buyingToken.balanceOf(address(this)));
    }


    function buyingTokenAmountToJioAmount(uint256 buyingTokenAmount) public view returns(uint256) {
        return buyingTokenAmount*1e18/jioPrice;
    }

    function participate(uint256 buyingTokenAmount) public  whenNotPaused{
        require(buyingTokenAmount>0,"invalid amount");
        uint256 buyingAmountToJioAmount = buyingTokenAmountToJioAmount(buyingTokenAmount);
        require(totalJioSold+buyingAmountToJioAmount<= maxJioToSell,"sold out!");

        buyingToken.safeTransferFrom(msg.sender,address(this),buyingTokenAmount);

        purchases[msg.sender].push(Purchase({
            purchaseAmount:buyingTokenAmount,
            jioAmount:buyingAmountToJioAmount,
            purchaseTime:block.timestamp,
            isWithdrawn:false
        }));

  

        totalRaised +=buyingTokenAmount;
        totalJioSold +=buyingAmountToJioAmount;
        
        emit onParticipate(buyingTokenAmount,buyingAmountToJioAmount);
    }
   

   function claim(uint256 purchaseId) public  {
        Purchase storage purchase = purchases[msg.sender][purchaseId];
        require(purchase.jioAmount>0,"invalid purchase");
        require(purchase.purchaseTime+MAX_LOCK_PERIOD< block.timestamp,"cant withdraw early");
        require(!purchase.isWithdrawn,"Already withdrawn");

        uint256 withdrawAmount= purchase.jioAmount;
        totalJioWithdrawnByUsers +=withdrawAmount;
        purchase.isWithdrawn = true;
        jioToken.safeTransfer(msg.sender,withdrawAmount);
        emit onClaim(withdrawAmount);

   }

   function totalPurchases(address user) public view returns(uint256) {
        return purchases[user].length; 
   }

   function withdrawRemainingJio()  public onlyOwner {
        require(salesEndTime< block.timestamp,"wait till presale end");
        uint256 remainingJio = maxJioToSell -totalJioSold;
        jioToken.safeTransfer(msg.sender,remainingJio);
   }
}
