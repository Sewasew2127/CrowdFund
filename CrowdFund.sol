// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ICrowdFund.sol";

contract CrownFund {
 
    /*
    to inform other parties that something has happened or
    acilitate communication between smart contracts and their user interfaces we use events
    We can't just rely on the transaction status
    so here we are declaring events for each functions of the campaign
    */
    event Launch(uint256 id,address indexed creator,uint256 goal,uint32 startAt,uint32 endAt);
    event Cancel(uint256 id);
    event Pledge(uint256 indexed id, address indexed caller, uint256 amount);
    event Unpledge(uint256 indexed id, address indexed caller, uint256 amount);
    event Claim(uint256 id);
    event Refund(uint256 id, address indexed caller, uint256 amount);

    struct Campaign {
        address creator; // the campaign creator
        uint256 goal; // the amount of token 
        uint256 pledged; // the amount of token that is pledged by the user
        uint32 startAt;//the time of starting the campaign
        uint32 endAt;//the time the campaing have to end
        bool claimed;//whether it is claimed or not, if sussful, the owner will cliam the token, it is like a flag
    }

    IERC20 public immutable token;

    uint256 public count; //Number of campaigns created

    mapping(uint256 => Campaign) public campaigns; //declaring a key-value pair for the Campaign struct as campaigns

    mapping(uint256 => mapping(address => uint256)) public pledgedAmount; //declaring a double mapping/nested mapping id to the address to the amount

    constructor(address _token) {
        token = IERC20(_token);
    } //initializing the state variable token to IERC20(which is which is imported from icro.sol 


    /*
    Launching/creating a campaign
    */
    function launch(uint256 _goal,uint32 _startAt,uint32 _endAt) external { //accepts the goal, the starting time and the end time
        require(_startAt >= block.timestamp, "startAt < now");// make sure the inputed start time is greateer than or equal to the time of the contract deployment
        require(_endAt >= _startAt, "endAt < starAt");//make syre the end time is not less than the start time
        require(_endAt <= block.timestamp + 90 days, "endAt > max duration");//we are setting the maximum duration to be 90 days after the contract is deployed here make sure the end time is 
         /*if the above 3 requirment are satisfyed then increment the count value by one
            that means now that a campaing is created the count should be incremented
        **/
        count += 1; 

        /*
        setting campaigns (the mapping that we created above) using the uint count as its index? with the value
        creator = the owner of the contract(msg.sender, goal = the inputed goal, and the other, and setting the claimed to be false for now
        **/
        campaigns[count] = Campaign(msg.sender, _goal,0,_startAt,_endAt,false);

        /*
        emmitting the event that we declared obove, letting the UI that the state of the contract is changed
        **/

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

    /*
    The campaign creator can cancel the campaign if the campaing has not started yet.
    used if the campaing is created accedentally
    */

    function cancel(uint256 _id) external {
        //since we want the campaing to be deleted , we are saving it in a temporary location memory
        //1 advantage is gas consumption and the other is we don't need the campaign var outside of this function so...
        Campaign memory campaign = campaigns[_id];//campaigns is the mapping that we created, now campaing is a single campaing 
        require(campaign.creator == msg.sender, "You are not the creator"); //making sure that the canceler is the creator
        require(block.timestamp < campaign.startAt, "The campaign has started");//making sure that the campaign is started

        //if the 2 requirements are satisfyed then delete the campaign with the specifyed id by using the key word delete
        delete campaigns[_id];

        //emmitting the event that is declared above
        emit Cancel(_id);
    }

    /*
    After a campaign is started users can pledge to the campaign by specifiying the amount of 
    tokens that they want to pledge
    The token will be transsfered to this account
    if the campain is successful - token will be claimed
    if not - token can be refund to the pledger
    */

    function pledge(uint256 _id, uint256 _amount) external {
        Campaign storage campaign = campaigns[_id]; //here we are saving the campain in persistent storage since we need it in another functions
        require(
            block.timestamp >= campaign.startAt,
            "Campaign has not started"
        ); //making sure the campaing is stated
        require(block.timestamp <= campaign.endAt, "Campaign has ended"); //making sure that the campaign is not ended yet
        //if the above 2 requirements are fullfilled
        campaign.pledged += _amount; // add the specfied amount of token to the total pledged mount of the campign - struct property of Campaign 
        pledgedAmount[_id][msg.sender] += _amount;//add the pledged token amount to  the pledged amount of the current campaign 
        token.transferFrom(msg.sender, address(this), _amount);//transfer the token from the address of the pledger to the  owner 
        
        //finally emit the status
        emit Pledge(_id, msg.sender, _amount);
    }

    /*
    If the user changes thire mind on the pledge amount they can unpledge
    */

    function unpledge(uint256 _id, uint256 _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "Campaign has ended");//making sure that the campaign is not ended yet
        campaign.pledged -= _amount;//deducting the amount from the total pledged
        pledgedAmount[_id][msg.sender] -= _amount;//dedcting from the amount from the owner
        token.transfer(msg.sender, _amount);//transfer the amount from the owner to the 

        //emit to the UI

        emit Unpledge(_id, msg.sender, _amount);
    }

    /*
    After the campaing ended the and the pelegdeg amount is greater than or equal to the goal
    he can claim it
    */

    function claim(uint256 _id) external {
        //take the id of the campaing
        Campaign storage campaign = campaigns[_id];

        //requirements before claiming
        require(campaign.creator == msg.sender, "you are not the owner");
        require(block.timestamp > campaign.endAt, "Campaign Not ended- wait till it end");
        require(campaign.pledged >= campaign.goal, "pledge less than goal");
        require(!campaign.claimed, "Campaign has been claimed"); //not claimed before

        //if all of the requirments are met then set claimed true then transfer
        campaign.claimed = true; //setting the flag to true
        token.transfer(campaign.creator, campaign.pledged);
        emit Claim(_id);
    }

    /*
    If the campain is unsuccessful i.e if the goal is not reached user can ask for refund
    */

    function refund(uint256 _id) external {//accepts the side of the campaign
        Campaign memory campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "IT has not ended");//make sure if the campaign is ended
        require(campaign.pledged < campaign.goal, "pledged >= goal");//make sure th pledged token is less than the goal

        uint256 balance = pledgedAmount[_id][msg.sender];//set the pledged amount of the owner to the var balance
        pledgedAmount[_id][msg.sender] = 0;//set the pledgedamount of the owner to 0 - empty it out
        token.transfer(msg.sender, balance);//transfer the balance to the pldger
        emit Refund(_id, msg.sender, balance);
    }
}
