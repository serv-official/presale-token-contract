// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MyToken is ERC20, Pausable, Multicall, AccessControl {
    
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    bool public burnAllowed;

    // Upper cap of USD 4294 
    uint32 public tokenCostMilliCents;
    uint32 public referralMilliPercentage;
    uint32 public minMilliTokenContribution;
    uint32 public maxMilliTokenContribution;

    struct bonus{
        uint32 amount;
        uint32 percentage;
    }

    bonus[] public bonusValues;

    // Upper cap of 1.8446744e+16
    uint64 public maxTotalSupply;

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
            "Can't mint, total supply would exceed maxTotalSupply"
        );
        _mint(to, amount);
    }

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
        require(burnAllowed, "Burn not allowed");

        super._burn(account, amount);
    }

    function setBurnStatus(bool _burnAllowed) public onlyRole(DEFAULT_ADMIN_ROLE) {
        burnAllowed = _burnAllowed;
    }

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
        require(milliAmounts.length == milliPercentages.length);

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
