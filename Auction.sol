//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract auction {

    address payable public auctioner;

    uint public stBlock;
    uint public edBlock;

    enum aucState {started,running,ended,cancelled}
    aucState public auctionState;

    uint public highestBid;
    uint public highestPayableBid;
    uint public incBid;

    address payable public highestBidder;

    mapping(address => uint) public bids;

    constructor() {
        auctioner = payable(msg.sender);
        stBlock= block.number;
        edBlock= stBlock + 240;
        auctionState = aucState.running;
        incBid = 1 ether; 
    }

    modifier notOwner() {
        require(msg.sender != auctioner, "owner cannot bid");
        _;
    }

    modifier Owner() {
        require(msg.sender == auctioner);
        _;
    }

    modifier started() {
        require(block.number>stBlock);
        _;
    }

    modifier beforeEnding() {
        require(block.number<edBlock);
        _;
    }

    function cancelAuc() public Owner {
        auctionState = aucState.cancelled;
    }

    function min(uint a, uint b) pure private returns (uint){
        if(a<=b){
            return a;
        }else {
            return b; 
        }
    }

    function bid() payable public notOwner started beforeEnding {
        require(auctionState == aucState.running);
        require(msg.value>=1 ether);

        uint currentBid = bids[msg.sender] + msg.value;

        require(currentBid>highestPayableBid);

        bids[msg.sender] = currentBid;

        if(currentBid<bids[highestBidder]){
            highestPayableBid = min(currentBid+incBid, bids[highestBidder]);
        }else{
            highestPayableBid= min(currentBid, bids[highestBidder]+incBid);
            highestBidder = payable(msg.sender);
        }
    }

    function finalizeAuc() public {
        require(auctionState == aucState.cancelled || block.number>edBlock);
        require(msg.sender == auctioner || bids[msg.sender]>0);

        address payable person;
        uint value;

        if(auctionState == aucState.cancelled) {
            person = payable(msg.sender);
            value = bids[msg.sender];
        }
        else{
            if(msg.sender == auctioner) {
                person = auctioner;
                value= highestPayableBid;
            }
            else{
                if(msg.sender == highestBidder){
                    person = highestBidder;
                    value = bids[highestBidder]-highestPayableBid;
                }
                else{
                    person = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        bids[msg.sender] = 0;
        person.transfer(value);
    }

}