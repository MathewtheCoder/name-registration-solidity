// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;
/**
 * @title NameReg
 * @dev Name Registration contract to place a name against address for nameFee * numBlocks fee reservation.
 */
contract NameReg {
    struct NameRegStruct {
        uint expiry_block_number;
        address account;
        bytes32 name;
    }
    mapping(bytes32 => NameRegStruct) names;
    mapping(address => uint256) balance;
    bytes32[] nameArray;
    uint nameFeePerBlock;
    event NameRegistered(address voter, bytes32 name, uint expiry_block_number);
    event NameRenewed(address voter, bytes32 name, uint expiry_block_number);
    event NameCanceled(bytes32 name);
    constructor() public {
        // Make the deployer of the contract the administrator
        nameFeePerBlock = 10;
    }
    /**
     * @dev Register name for numBlocks with a nameFee * numBlocks fee.
     * @param _name name to attach to address.
     * @param _numBlocks Number of blocks for which name should be freezed.
     */
    function register(bytes32 _name, uint _numBlocks) public payable {
         // Add a check to see if name is available.
         // Solidity has no concept of null.
         // every integer starts as 0, every string starts a "", every array starts as []
         require(names[_name].expiry_block_number == 0 || names[_name].expiry_block_number < block.number);
         require(msg.value >= _numBlocks * nameFeePerBlock);
         uint expiry_block_number = block.number + _numBlocks;
         NameRegStruct storage new_name = names[_name];
         new_name.expiry_block_number = expiry_block_number;
         new_name.account = msg.sender;
         new_name.name = _name;
         // TO help in getting entire name list.
         nameArray.push(_name);
         balance[msg.sender] = msg.value;
         emit NameRegistered(msg.sender, _name, expiry_block_number);
    }
    /**
     * @dev Renew/Extend name for numBlocks with a nameFee * numBlocks fee for the sender.
     * @param _name name to attach to address.
     * @param _numBlocks Number of blocks for which name should be freezed.
     */
    function renew(bytes32 _name, uint _numBlocks) public payable {
        // Check if name belongs to sender
        require(names[_name].account == msg.sender);
        require(msg.value >= _numBlocks * nameFeePerBlock);
        uint expiry_block_number = block.number + _numBlocks;
        if (block.number < expiry_block_number) {
            expiry_block_number = names[_name].expiry_block_number + _numBlocks;
        }
        NameRegStruct storage new_name = names[_name];
        new_name.expiry_block_number = expiry_block_number;
        new_name.account = msg.sender;
        new_name.name = _name;
        balance[msg.sender] += msg.value;
        emit NameRenewed(msg.sender, _name, expiry_block_number);
    }
    /**
     * @dev Cancel the ownership of name.
     * @param _name name which needs to be canceled
     */
    function cancel(bytes32 _name) public {
        require(names[_name].account == msg.sender);
        uint remaining_blocks = names[_name].expiry_block_number - block.number;
        int index = getNameIndex(_name);
        require(index > -1, 'Name not found in array');
        removeInOrder(uint(index));
        delete names[_name];
        if (remaining_blocks > 0) {
            // Refund the remaing blocks fee to the user
            // Microether 1000000000000 is used to make sure the change is visible.
            msg.sender.transfer(remaining_blocks * nameFeePerBlock * 1000000000000);
        }
        emit NameCanceled(_name);
    }
    /**
     * @dev Returns array of name details.
     */
    function getAllNames() public view returns (NameRegStruct[] memory){
        NameRegStruct[] memory ret = new NameRegStruct[](nameArray.length);
        for (uint i = 0; i < nameArray.length; i++) {
            if(names[nameArray[i]].expiry_block_number > 0) {
                ret[i] = names[nameArray[i]];
            }
        }
        return ret;
    }
    
    function getReservationFee(uint _numBlocks) public view returns (uint){
        return nameFeePerBlock * _numBlocks;
    } 
    function getNameIndex(bytes32 data) view internal returns (int){
        for (uint i = 0; i < nameArray.length; i++) {
            if(nameArray[i] == data) {
                return int(i);
            }
        }
        return -1;
    }
    function removeInOrder(uint index) internal returns(bytes32[] storage) {
        if (index >= nameArray.length) return nameArray;

        for (uint i = index; i<nameArray.length-1; i++){
            nameArray[i] = nameArray[i+1];
        }
        delete nameArray[nameArray.length-1];
        nameArray.pop();
        return nameArray;
    }
}