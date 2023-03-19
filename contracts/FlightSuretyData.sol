pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational;                                           // Blocks all state changes throughout the contract if false
    uint256 contractFunds;                                              // Ammount of ether in the contract
    uint256 registeredAirlineCount;                                     // Number of registered 
    uint16 insuranceMultiplier                                          // Insurance credit multiplier 

    struct Airline {
        bool isRegistered;
        bool isFunded;
        address airlineID;
        string airlineName;
        uint256 voteCount;
    }

    struct Flight {
        address airlineID;
        uint8 statusCode;
        string flightCode;
        bytes32 flightKey;
        uint256 timeStamp;
    }

    struct Insurance {
        address passengerID;
        uint256 ammountInsured;
    }

    mapping(address => Airline) private airlines;
    mapping(address => Airline) private waitingAirlines;
    mapping(bytes32 => Flight) public flights;
    mapping(bytes32 => Insurance[]) public flightInsurance;
    mapping (address => uint256) passengerCredit;


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        operational = true;
        contractFunds = 0;
        registeredAirlineCount = 0;
        insuranceMultiplier = 1.5;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireIsRegistered(address airlineID)
    {
        require(airlines[airlineID].isRegistered, "Airline is not registered.");
        _;
    }

    modifier requireIsFunded(address airlineID)
    {
        require(airlines[airlineID].isFunded, "Airline is not Funded.");
        _;
    }



    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    /**
    * @dev Check if airline is registered
    */
    function isAirlineRegistered
                                (
                                    address airline
                                ) 
                                public 
                                view
                                requireIsOperational
                                returns(bool) 
    {
        return airlines[airline].isRegistered;
    }

    /**
    * @dev Check if airline is funded
    */
    function isAirlineFunded
                            (
                                address airline
                            ) 
                            public 
                            view 
                            returns(bool) 
    {
        return airlines[airline].isFunded;
    }

    /**
    * @dev Check if the airline is in the waiting list for voting
    */

    function isAirlineForVoting
                                (
                                    address airline
                                )
                                public
                                view
                                returns(bool)
    {
        return waitingAirlines[airline] != false;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (
                                string _airlineName,
                                address _airlineID
                            )
                            external
                            pure
                            requireIsOperational

    {
       airlines[_airlineID] = Airline({
            airlineID: _airlineID,
            airlineName: _airlineName,
            isRegistered: true,
            isFunded : false,
            voteCount: 0
        });

        registeredAirlineCount++; 
    }

    function registerFlight
                            (
                                address _airlineID,
                                string _flightCode,
                                uint256 _timestamp
                            )
                            external
                            payable
                            requireIsOperational
                            requireIsFunded
    {
        flights[_flightCode] Flight({
            airlineID: _airlineID,
            flightCode: _flightCode,
            statusCode: 10,
            timeStamp: _timeStamp
            flightKey: getFlightKey(_airlineID, _flightCode, _timestamp)
        });
    }

    function fundAirline 
                        (
                            address _airlineID
                            uint256 _amount
                        )
                        external
                        pure
                        requireIsOperational
                        requireIsRegistered
    {
        airlines[_airlineID].isFunded = true;
        contractFunds = contractFunds.add(_amount);
    }

    function addToWaitingAirlines
                                (
                                    string _airlineName,
                                    address _airlineID
                                )
                                external
                                pure
                                requireIsOperational
                                requireIsRegistered
    {
       airlines[_airlineID] = Airline({
            airlineID: _airlineID,
            airlineName: _airlineName,
            isRegistered: true,
            isFunded : false,
            voteCount: 0
        });
                                

                                

    function voteForAirline 
                            (
                                address _airlineID
                            )
                            external
                            pure
                            requireIsOperational
                            requireIsRegistered
    {
        waitingAirlines[_airlineID].voteCount = waitingAirlines[_airlineID].voteCount.add(1);
        if (waitingAirlines[_airlineID].voteCount >= registeredAirlineCount.div(2)) {
            registerAirline(waitingAirlines[_airlineID].airlineName, _airlineID);
            delete waitingAirline[_airlineID];
        }

    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (     
                                bytes32 flightKey,
                                address passengerID,
                                uint256 ammountInsured                        
                            )
                            external
                            payable
                            requireIsOperational
    {
        flightInsurance[flightKey].push(Insurance(
            passengerID,
            amountInsured,
        ));
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                ( 
                                    bytes32 flightKey
                                )
                                external
                                pure
    {
        for (uint256 i = 0; i < flightInsurance[flightKey].lenght; i++) {
            Insurance memory insurance = flightInsurance[flightKey][i];
            uint256 ammount = insurance.ammountInsured.mul(insuranceMultiplier).div(100);
            passengerCredit[insurance.passengerID] = passengerCredit[insurance.passengerID].add(amount);
        }
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            payable
                            requireIsOperational
    {
        uint amount = passengerCredit[msg.sender];
        require( contractFunds >= amount, "Contract has insufficient funds.");
        require(amount > 0, "There are no credit available");
        passengerCredit[msg.sender] = 0;
        msg.sender.transfer(amount);

    }


    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

