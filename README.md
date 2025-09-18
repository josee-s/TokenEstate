# TokenEstate

## Overview

TokenEstate is a tokenized real estate smart contract that enables fractional ownership of properties through share-based tokenization. It supports property registration, buying and selling of shares, and distribution of rental income as dividends.

## Features

* Register properties with market value, shares, and price per share
* Buy fractional property shares with STX transfers
* Sell shares back to the property owner
* Distribute rental income proportionally as dividends
* Event logging for property registration, share transactions, and dividend distribution

## Data Structures

* **property-counter**: Tracks the number of registered properties
* **properties**: Stores property details including owner, value, shares, and price
* **investors**: Tracks investor share balances per property
* **last-event-id**: Tracks emitted event IDs for logging

## Key Functions

* `register-property`: Register a new property and tokenize into shares
* `buy-shares`: Buy fractional ownership of a property
* `sell-shares`: Sell property shares back to the owner
* `distribute-dividend`: Distribute rental income to investors

## Helper Functions

* `get-property`: Fetch property details
* `get-investor`: Fetch investor details
* `is-owner`: Check if caller is property owner

## Event Emitters

* `emit-property-registered`: Logs property registration
* `emit-shares-purchased`: Logs share purchase
* `emit-shares-sold`: Logs share sale
* `emit-dividends-distributed`: Logs dividend distribution

## Error Handling

* `u400`: Invalid input
* `u401`: Unauthorized (only owner can distribute dividends)
* `u403`: Investor not found
* `u404`: Property not found
* `u100`: Insufficient funds
* `u101`: Insufficient shares for sale
