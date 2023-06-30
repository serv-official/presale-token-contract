// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
* @title Presale token which will be used to get allocated SNCA tokens.
* @dev A custom ERC20 token with additional round configuration functionality. 
* @notice Regular users can not transfer their presale tokens, they can (eventually) burn
          them to get their SNCA tokens.
*/
contract SenecaPresaleToken is ERC20, Pausable, Multicall, AccessControl {
    
    /**
    * @dev Only address with Distributor Role can tranfer tokens and approve allowance. 
    */
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    
    /**
    * @dev All addresses can burn when this flag is set true. 
    */
    bool public burnAllowed;

    /**
    * @title pSNCA Token cost in milli Cents.
    * @dev Upper limit of USD 4294.
    */
    uint32 public tokenCostMilliCents;

    /**
    * @title Extra milli percentage paid to both Referrer and Referee in the case of a referral.
    */
    uint32 public referralMilliPercentage;

    /**
    * @title Minimum and Maximum token allowed to be distributed per address.
    */
    uint32 public minMilliTokenContribution;
    uint32 public maxMilliTokenContribution;

    struct bonus{
        uint32 amount;
        uint32 percentage;
    }

    /**
    * @notice Bonus percentages based on the initial USD amount bought.
    */
    bonus[] public bonusValues;

    /**
    * @dev Upper limit for tokens. Max value after adjusting for decimal: 1.8446744e+16.
    */
    uint64 public maxTotalSupply;

    // @param distributor Token Sale's Distributor Address.
    // @param _maxTotalSupply Upper Cap on Token Supply.
    constructor(address distributor, uint64 _maxTotalSupply) ERC20("SenecaPresale", "pSNCA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DISTRIBUTOR_ROLE, msg.sender);        
        _grantRole(DISTRIBUTOR_ROLE, distributor);

        maxTotalSupply = _maxTotalSupply;
        burnAllowed = false;
    }

    function decimals() public view virtual override returns (uint8) {
        return 3;
    }

    function mint(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        
        require(
            totalSupply() + amount <= maxTotalSupply, 
            "Can't mint, total supply would exceed maxTotalSupply."
        );
        _mint(to, amount);
    }

    /**
    * @notice Only address with Admin Role can pause or unpause.
    */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override onlyRole(DISTRIBUTOR_ROLE) {
        super._transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override whenNotPaused onlyRole(DISTRIBUTOR_ROLE) {
        super._approve(owner, spender, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override {
        require(burnAllowed, "Burn not allowed.");

        super._burn(account, amount);
    }

    /**
    * @dev Set burnAllowed which is required to be true for allowing burning.
    * @notice Only address with Admin Role can call.
    */
    function setBurnStatus(bool _burnAllowed) public onlyRole(DEFAULT_ADMIN_ROLE) {
        burnAllowed = _burnAllowed;
    }


    /**
    * @title Start a round of the Token Sale with updated configuration values.
    * @dev `amount` gets minted to `distributor` address.
    * @notice Only address with Admin Role can call.
    */
    function setRound( 
        address distributor,
        uint256 amount,
        uint32 _tokenCostMilliCents,
        uint32 _referralMilliPercentage,
        uint32 _minMilliTokenContribution,
        uint32 _maxMilliTokenContribution,
        uint32[] memory milliAmounts,
        uint32[] memory milliPercentages
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            milliAmounts.length == milliPercentages.length,
            "Length of arrays milliAmounts and milliPercentages must be same"
        );

        _mint(distributor, amount);
        tokenCostMilliCents = _tokenCostMilliCents;
        referralMilliPercentage = _referralMilliPercentage;
        minMilliTokenContribution = _minMilliTokenContribution;
        maxMilliTokenContribution = _maxMilliTokenContribution;

        for(uint i = 0; i< milliAmounts.length; i++){
            bonusValues.push(bonus({amount : milliAmounts[i], percentage : milliPercentages[i]}));
        }
    }
}
