// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.4.22 <0.8.0;
/**
 * @title NameReg
 * @dev Name Registration contract to place a name against address for nameFee * numBlocks fee reservation.
 */
contract NameReg {
    struct NameRegStruct {
        uint expiry_block_number;
        address account;
    }
    mapping(bytes32 => NameRegStruct) public names;
    event NameRegistered(address voter, bytes32 name, uint expiry_block_number);
    event NameRenewed(address voter, bytes32 name, uint expiry_block_number);
    uint nameFeePerBlock;
    constructor() public {
        // Set the fee per block as 10
        nameFeePerBlock = 10;
    }
    /**
     * @dev Register name for numBlocks with a nameFee * numBlocks fee.
     * @param _name name to attach to address.
     * @param _numBlocks Number of blocks for which name should be freezed.
     */
    function register(bytes32 _name, uint _numBlocks) public {
         // Add a check to see if name is available.
         // Solidity has no concept of null.
         // every integer starts as 0, every string starts a "", every array starts as []
         require(names[_name].expiry_block_number == 0 || names[_name].expiry_block_number < block.number);
         uint expiry_block_number = block.number + _numBlocks;
         NameRegStruct storage new_name = names[_name];
         new_name.expiry_block_number = expiry_block_number;
         new_name.account = msg.sender;
         emit NameRegistered(msg.sender, _name, expiry_block_number);
    }
    /**
     * @dev Renew/Extend name for numBlocks with a nameFee * numBlocks fee for the sender.
     * @param _name name to attach to address.
     * @param _numBlocks Number of blocks for which name should be freezed.
     */
    function renew(bytes32 _name, uint _numBlocks) public  {
        // Check if name belongs to sender
        require(names[_name].account == msg.sender);
        uint expiry_block_number = block.number + _numBlocks;
        NameRegStruct storage new_name = names[_name];
        new_name.expiry_block_number = expiry_block_number;
        new_name.account = msg.sender;
        emit NameRegistered(msg.sender, _name, expiry_block_number);
    }
    /**
     * @dev Cancel the ownership of name.
     * @param _name name which needs to be canceled
     */
    function cancel(bytes32 _name) public {
        require(names[_name].account == msg.sender);
        NameRegStruct storage new_name = names[_name];
        new_name.expiry_block_number = 0;
        new_name.account = msg.sender;
    }
    function getData(bytes32 _name) view public returns (uint, address) {
        return (names[_name].expiry_block_number, names[_name].account);
    }
}