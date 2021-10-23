<img src="https://s3-eu-west-1.amazonaws.com/eventsquare.assets/ext/payconiq_logo.png" alt="Payconiq" width="300"/>

# Payconiq API client for PHP #

Accepting [Payconiq](https://www.payconiq.com/) payments with the use of the QR code.

## Requirements ##
To use the Payconiq API client, the following things are required:

+ Payconiq Merchant Id and API key
+ PHP >= 5.6
+ PHP cURL extension

## Installation ##

The best way to install the Payconiq API client is to require it with [Composer](http://getcomposer.org/doc/00-intro.md).

    $ composer require eventsquare/payconiq

You may also git checkout or [download all the files](https://github.com/EventSquare/payconiq-api-php/archive/master.zip), and include the Payconiq API client manually.



## Parameters ##

We use the following parameters in the examples below:

```php
$apiKey = 'apiKey 123456'; // Used to secure request between merchant backend and Payconiq backend.

$amount = 1000; // Transaction amount in cents
$currency = 'EUR'; // Currency
$callbackUrl = 'http://yoursite.com/postback'; // Callback where Payconiq needs to POST confirmation status
```

To learn more about how, when and what Payconiq  will POST to your callbackUrl, please refer to the developer documentation [right here](https://dev.payconiq.com/online-payments-dock).

## Usage ##


### Create a payment ###


```php
use Payconiq\Client;

$payconiq = new Client($apiKey);
	
// Create a new payment
$payment = $payconiq->createPayment($amount, $currency, $reference, $callbackUrl);
	
// Assemble QR code content
$qrcode = $payment->_links->qrcode->href;
```

### Retrieve a payment ###

```php
use Payconiq\Client;

$payconiq = new Client($apiKey);

// Retrieve a payment
$payment = $payconiq->retrievePayment($paymentId);
```
