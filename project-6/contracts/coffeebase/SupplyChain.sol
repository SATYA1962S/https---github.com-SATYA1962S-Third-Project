pragma solidity ^0.4.24;

import "../coffeecore/Ownable.sol";
import "../coffeeaccesscontrol/FarmerRole.sol";
import "../coffeeaccesscontrol/DistributorRole.sol";
import "../coffeeaccesscontrol/RetailerRole.sol";
import "../coffeeaccesscontrol/ConsumerRole.sol";

// Define a contract 'Supplychain'
contract SupplyChain is
    Ownable,
    FarmerRole,
    DistributorRole,
    RetailerRole,
    ConsumerRole
{
    // Define 'owner'
    // address owner;

    // Define a variable called 'upc' for Universal Product Code (UPC)
    uint256 upc;

    // Define a variable called 'sku' for Stock Keeping Unit (SKU)
    uint256 sku;

    // Define a public mapping 'items' that maps the UPC to an Item.
    mapping(uint256 => Item) items;

    // Define a public mapping 'itemsHistory' that maps the UPC to an array of TxHash,
    // that track its journey through the supply chain -- to be sent from DApp.
    mapping(uint256 => string[]) itemsHistory;

    // Define enum 'State' with the following values (from 0 to 7):
    enum State {
        Harvested,
        Processed,
        Packed,
        ForSale,
        Sold,
        Shipped,
        Received,
        Purchased
    }

    State constant defaultState = State.Harvested;

    // Define a struct 'Item' with the following fields:
    struct Item {
        uint256 sku; // Stock Keeping Unit (SKU)
        uint256 upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
        address ownerID; // Metamask-Ethereum address of the current owner as the product moves through 8 stages
        address originFarmerID; // Metamask-Ethereum address of the Farmer
        string originFarmName; // Farmer Name
        string originFarmInformation; // Farmer Information
        string originFarmLatitude; // Farm Latitude
        string originFarmLongitude; // Farm Longitude
        uint256 productID; // Product ID potentially a combination of upc + sku
        string productNotes; // Product Notes
        uint256 productPrice; // Product Price
        State itemState; // Product State as represented in the enum above
        address distributorID; // Metamask-Ethereum address of the Distributor
        address retailerID; // Metamask-Ethereum address of the Retailer
        address consumerID; // Metamask-Ethereum address of the Consumer
    }

    // Define 8 events with the same 8 state values and accept 'upc' as input argument
    event Harvested(uint256 upc);
    event Processed(uint256 upc);
    event Packed(uint256 upc);
    event ForSale(uint256 upc);
    event Sold(uint256 upc);
    event Shipped(uint256 upc);
    event Received(uint256 upc);
    event Purchased(uint256 upc);

    // Define a modifer that checks to see if msg.sender == owner of the contract
    modifier onlyOwner() {
        require(isOwner(), "Sender is not the owner of the contract.");
        _;
    }

    // Define a modifer that verifies the Caller
    modifier verifyCaller(address _address) {
        require(
            msg.sender == _address,
            "Sender is not the caller of the contract."
        );
        _;
    }

    // Define a modifier that checks if the paid amount is sufficient to cover the price
    modifier paidEnough(uint256 _price) {
        require(
            msg.value >= _price,
            "Paid amount is insufficient for the price."
        );
        _;
    }

    // Define a modifier that checks the price and refunds the remaining balance
    modifier checkValue(uint256 _upc) {
        _;
        uint256 _price = items[_upc].productPrice;
        uint256 amountToReturn = msg.value - _price;
        items[_upc].consumerID.transfer(amountToReturn);
    }

    // Define a modifier that checks if an item.state of a upc is Harvested
    modifier harvested(uint256 _upc) {
        require(
            items[_upc].itemState == State.Harvested,
            "Product hasn't been harvested."
        );
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Processed
    modifier processed(uint256 _upc) {
        require(
            items[_upc].itemState == State.Processed,
            "Product hasn't been processed."
        );
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Packed
    modifier packed(uint256 _upc) {
        require(
            items[_upc].itemState == State.Packed,
            "Product hasn't been packed."
        );
        _;
    }

    // Define a modifier that checks if an item.state of a upc is ForSale
    modifier forSale(uint256 _upc) {
        require(
            items[_upc].itemState == State.ForSale,
            "Product isn't for sale yet."
        );
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Sold
    modifier sold(uint256 _upc) {
        require(
            items[_upc].itemState == State.Sold,
            "Product hasn't been sold."
        );
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Shipped
    modifier shipped(uint256 _upc) {
        require(
            items[_upc].itemState == State.Shipped,
            "Product hasn't been shipped."
        );
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Received
    modifier received(uint256 _upc) {
        require(
            items[_upc].itemState == State.Received,
            "Product hasn't been received."
        );
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Purchased
    modifier purchased(uint256 _upc) {
        require(
            items[_upc].itemState == State.Purchased,
            "Product hasn't been purchased."
        );
        _;
    }

    // In the constructor set 'owner' to the address that instantiated the contract
    // and set 'sku' to 1
    // and set 'upc' to 1
    constructor() public payable {
        sku = 1;
        upc = 1;
    }

    // Define a function 'kill' if required
    function kill() public {
        if (isOwner()) {
            selfdestruct(msg.sender);
        }
    }

    // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
    function harvestItem(
        uint256 _upc,
        address _originFarmerID,
        string _originFarmName,
        string _originFarmInformation,
        string _originFarmLatitude,
        string _originFarmLongitude,
        string _productNotes
    ) public onlyFarmer {
        // Add the new item as part of Harvest
        items[_upc] = Item({
            sku: sku,
            upc: _upc,
            ownerID: _originFarmerID,
            originFarmerID: _originFarmerID,
            originFarmName: _originFarmName,
            originFarmInformation: _originFarmInformation,
            originFarmLatitude: _originFarmLatitude,
            originFarmLongitude: _originFarmLongitude,
            productID: _upc + sku,
            productNotes: _productNotes,
            productPrice: 0,
            itemState: State.Harvested,
            distributorID: 0,
            retailerID: 0,
            consumerID: 0
        });

        // Increment sku
        sku = sku + 1;

        // Emit the appropriate event
        emit Harvested(_upc);
    }

    // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
    // Call modifier to check if upc has passed previous supply chain stage
    // Call modifier to verify caller of this function
    function processItem(uint256 _upc)
        public
        harvested(_upc)
        verifyCaller(msg.sender)
        onlyFarmer
    {
        // Update the appropriate fields
        items[_upc].itemState = State.Processed;

        // Emit the appropriate event
        emit Processed(_upc);
    }

    // Define a function 'packItem' that allows a farmer to mark an item 'Packed'
    // Call modifier to check if upc has passed previous supply chain stage
    // Call modifier to verify caller of this function
    function packItem(uint256 _upc)
        public
        processed(_upc)
        verifyCaller(msg.sender)
        onlyFarmer
    {
        // Update the appropriate fields
        items[_upc].itemState = State.Packed;

        // Emit the appropriate event
        emit Packed(_upc);
    }

    // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
    // Call modifier to check if upc has passed previous supply chain stage
    // Call modifier to verify caller of this function
    function sellItem(uint256 _upc, uint256 _price)
        public
        packed(_upc)
        verifyCaller(msg.sender)
        onlyFarmer
    {
        // Update the appropriate fields
        items[_upc].itemState = State.ForSale;
        items[_upc].productPrice = _price;

        // Emit the appropriate event
        emit ForSale(_upc);
    }

    // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
    // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough,
    // and any excess ether sent is refunded back to the buyer
    // Call modifier to check if upc has passed previous supply chain stage
    // Call modifer to check if buyer has paid enough
    // Call modifer to send any excess ether back to buyer
    function buyItem(uint256 _upc)
        public
        payable
        forSale(_upc)
        paidEnough(items[_upc].productPrice)
        checkValue(_upc)
        onlyDistributor
    {
        // Update the appropriate fields - ownerID, distributorID, itemState
        items[_upc].ownerID = msg.sender;
        items[_upc].itemState = State.Sold;
        items[_upc].distributorID = msg.sender;

        // Transfer money to farmer
        uint256 price = items[_upc].productPrice;
        items[_upc].originFarmerID.transfer(price);

        // emit the appropriate event
        emit Sold(_upc);
    }

    // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
    // Use the above modifers to check if the item is sold
    // Call modifier to check if upc has passed previous supply chain stage
    // Call modifier to verify caller of this function
    function shipItem(uint256 _upc)
        public
        sold(_upc)
        verifyCaller(msg.sender)
        onlyDistributor
    {
        // Update the appropriate fields
        items[_upc].itemState = State.Shipped;

        // Emit the appropriate event
        emit Shipped(_upc);
    }

    // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
    // Use the above modifiers to check if the item is shipped
    // Call modifier to check if upc has passed previous supply chain stage
    // Access Control List enforced by calling Smart Contract / DApp
    function receiveItem(uint256 _upc) public shipped(_upc) onlyRetailer {
        // Update the appropriate fields - ownerID, retailerID, itemState
        items[_upc].ownerID = msg.sender;
        items[_upc].itemState = State.Received;
        items[_upc].retailerID = msg.sender;

        // Emit the appropriate event
        emit Received(_upc);
    }

    // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
    // Use the above modifiers to check if the item is received
    // Call modifier to check if upc has passed previous supply chain stage
    // Access Control List enforced by calling Smart Contract / DApp
    function purchaseItem(uint256 _upc) public received(_upc) onlyConsumer {
        // Update the appropriate fields - ownerID, consumerID, itemState
        items[_upc].ownerID = msg.sender;
        items[_upc].itemState = State.Purchased;
        items[_upc].consumerID = msg.sender;

        // Emit the appropriate event
        emit Purchased(_upc);
    }

    // Define a function 'fetchItemBufferOne' that fetches the data
    function fetchItemBufferOne(uint256 _upc)
        public
        view
        returns (
            uint256 itemSKU,
            uint256 itemUPC,
            address ownerID,
            address originFarmerID,
            string originFarmName,
            string originFarmInformation,
            string originFarmLatitude,
            string originFarmLongitude
        )
    {
        // Assign values to the 8 parameters
        itemSKU = items[_upc].sku;
        itemUPC = items[_upc].upc;
        ownerID = items[_upc].ownerID;
        originFarmerID = items[_upc].originFarmerID;
        originFarmName = items[_upc].originFarmName;
        originFarmInformation = items[_upc].originFarmInformation;
        originFarmLatitude = items[_upc].originFarmLatitude;
        originFarmLongitude = items[_upc].originFarmLongitude;

        return (
            itemSKU,
            itemUPC,
            ownerID,
            originFarmerID,
            originFarmName,
            originFarmInformation,
            originFarmLatitude,
            originFarmLongitude
        );
    }

    // Define a function 'fetchItemBufferTwo' that fetches the data
    function fetchItemBufferTwo(uint256 _upc)
        public
        view
        returns (
            uint256 itemSKU,
            uint256 itemUPC,
            uint256 productID,
            string productNotes,
            uint256 productPrice,
            uint256 itemState,
            address distributorID,
            address retailerID,
            address consumerID
        )
    {
        // Assign values to the 9 parameters
        itemSKU = items[_upc].sku;
        itemUPC = items[_upc].upc;
        productID = items[_upc].productID;
        productNotes = items[_upc].productNotes;
        productPrice = items[_upc].productPrice;
        itemState = uint256(items[_upc].itemState);
        distributorID = items[_upc].distributorID;
        retailerID = items[_upc].retailerID;
        consumerID = items[_upc].consumerID;

        return (
            itemSKU,
            itemUPC,
            productID,
            productNotes,
            productPrice,
            itemState,
            distributorID,
            retailerID,
            consumerID
        );
    }
}
