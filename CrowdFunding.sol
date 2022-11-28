//SPDX-License-Identifier: UNLICENSED
// problem that i have seen
// 1. if you raised more than target value, what to do with the rest of the money;
pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding {

    address public manager;
    mapping(address=>uint) public contributers;
    uint public minContribution;
    uint public noOfContributers;
    uint public target;
    uint public deadline;
    uint public raisedAmount;

    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }

    mapping(uint=>Request) public requests;
    uint public numRequests;

    constructor(uint _target, uint _deadline) {
        target = _target;
        deadline = block.timestamp + _deadline;
        manager = msg.sender;
        minContribution = 100 wei;
    }

    function sendEth() payable public {
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value >= minContribution, "Minimum contribution has not met");

        if(contributers[msg.sender] == 0){
            noOfContributers++;
        }

        contributers[msg.sender]+=msg.value;    
        raisedAmount+=msg.value;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function refund() public {
        require(block.timestamp > deadline && raisedAmount < target, "You are not eligible for refund");
        require(contributers[msg.sender] > 0);

        address payable user = payable(msg.sender);
        user.transfer(contributers[msg.sender]);
        contributers[msg.sender] =0;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "only manager can call this function");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }


    function voteRequest(uint _requestNo) public {
        require(contributers[msg.sender] >0, "you must be contributer ");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] == false, "you have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManager {
        require(raisedAmount >= target);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == true,"this request is alreadty completed");
        require(thisRequest.noOfVoters > noOfContributers/2,"majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
}