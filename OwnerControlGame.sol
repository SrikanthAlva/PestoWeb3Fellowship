// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract OwnerControlGame{
    address owner;
    uint256 contractValue;
    uint256 public previousOwnerDeposits;
    uint256 public minThresholdETH = 1 ether;
    
    struct User{
        address userAddress;
        bool isRegistered;
        uint balance;
    }

    mapping(address => User) public userRecords;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner, uint256 indexed timestamp);
    event NewUserRegistered(address indexed _user, uint256 indexed _userId, uint256 indexed timestamp);

    modifier checkUser(address _userAddress){
        require(_userAddress == msg.sender, "Impersonating user - Bad call");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Caller is not Owner");
        _;
    }

    modifier notOwner(){
        require(msg.sender != owner, "Caller is Owner");
        _;
    }

    modifier isRegisteredUser(){
        require(userRecords[msg.sender].isRegistered, "Not a Registered User");
        _;
    }

    constructor() payable{
        // Want to check if ETHER provided is 1 or more than - If not, revert
        require(msg.value >= minThresholdETH, "Invalid Amount Passed");
        // If success - make the deployer as the owner.
        owner = msg.sender;
        // If success - initialize contract's value as whatever value is passed by deployer
        contractValue = msg.value;
        previousOwnerDeposits = msg.value;
        userRecords[msg.sender].balance = msg.value;
        userRecords[msg.sender].isRegistered = true;
        userRecords[msg.sender].userAddress = msg.sender;
    }

    function getOwner() external view returns(address){
        return owner;
    }

    function getContractValue() external view returns(uint256){
        return contractValue;
    }

    function setContractValue() external onlyOwner() payable{
        require(msg.value > previousOwnerDeposits, "Invalid amount");
        contractValue += msg.value;
    }

    function register(address _userAddress, uint256 _id) external checkUser(_userAddress){
        User memory newUser;
        newUser.userAddress = _userAddress;
        newUser.isRegistered = true;
        userRecords[msg.sender] = newUser;
        emit NewUserRegistered(msg.sender, _id, block.timestamp);
    }

    function makeMeAdmin() external payable {  
        User memory user = userRecords[msg.sender];
        userRecords[msg.sender].balance = msg.value;
        require(user.isRegistered, "User is not registered");
        require(msg.value > previousOwnerDeposits,"Less deposit than prev owner");
        address oldOwner = owner;
        owner = msg.sender;
        previousOwnerDeposits = msg.value;
        contractValue += msg.value;

        emit OwnerChanged(oldOwner, msg.sender, block.timestamp);
    }

    function withdrawEth() public notOwner isRegisteredUser { 
        uint256 balance = userRecords[msg.sender].balance;
        require(balance > 0, "No Ethers Deposited");
        contractValue = contractValue - balance; 
        userRecords[msg.sender].isRegistered = false;
        userRecords[msg.sender].balance = 0;
        payable(msg.sender).transfer(balance);

        // *************Transfer ETH Using SEND Function************************
        // bool success = payable(msg.sender).send(balance);
        // if(!success){
        //     revert("Transfer Unsuccessfull");
        // }

        // *************Transfer ETH Using CALL Function************************
        // (bool success, bytes memory data) = payable(msg.sender).call{value: balance}("");
        // if(!success){
        //     revert("Transfer Unsuccessfull");
        // }
    }

}

            
        
        
