// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract time{
    function onesecond() public view returns(uint){
        return block.timestamp;
    }

    function second() public view returns(uint){
        return 
        block.timestamp + 60 seconds;
    }

    function FourMin() public view returns(uint){
        return block.timestamp + 4 minutes;
    }
    function day() public view returns(uint){
        return block.timestamp + 5 days;
    }
    function hour() public view returns(uint){
        return block.timestamp + 3 hours;
    }
}
