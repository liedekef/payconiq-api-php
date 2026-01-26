# Payconiq API client for PHP #

Accepting [Payconiq](https://www.payconiq.be/) payments with the use of the QR code.  
API documentation can be found [here](https://docs.payconiq.be/apis/merchant-payment.openapi).

## Requirements ##
To use the Payconiq API client, the following things are required:

+ Payconiq Merchant Id and API key
+ PHP >= 8.3
+ PHP cURL extension

## Installation ##

The best way to install the Payconiq API client is to require it with [Composer](http://getcomposer.org/doc/00-intro.md).

    $ composer require liedekef/payconiq-api-php

You may also git checkout or [download all the files](https://github.com/EventSquare/payconiq-api-php/archive/master.zip), and include the Payconiq API client manually.


## Parameters ##

We use the following parameters in the examples below:

```php
$apiKey = 'apiKey 123456'; // Used to secure request between merchant backend and Payconiq backend.
$merchantId = 'merchantid'; // payconiq merchantid (not really used, unless to verify more in notification callback)
$amount = 1000; // Transaction amount in cents
$currency = 'EUR'; // Currency
$reference = "my internal payment reference"; // an internal reference (e.g. a booking id)
      // the reference is given in the callback, allowing you to know what local payment is being handled
$callbackUrl = 'http://yoursite.com/postback'; // Callback where Payconiq needs to POST confirmation status
$returnUrl = 'http://yoursite.com/returnpage'; // Optional. the page a buyer is returned to after payment. You'll need to check
     // the payment status there
```

To learn more about how, when and what Payconiq  will POST to your callbackUrl, please refer to the developer documentation [right here](https://dev.payconiq.com/online-payments-dock).


## Installation

```php
// Include the Client.php file
require_once '/path/to/Payconiq/Client.php';

use Payconiq\Client;
```

## Initialization

### Basic Setup

```php
// Production environment (default)
$client = new Client('your-api-key-here');

// Test environment
$client = new Client('your-test-api-key', Client::ENVIRONMENT_TEST);

// Or configure after instantiation
$client = new Client();
$client->setApiKey('your-api-key-here')
       ->setEndpointTest(); // Switch to test environment
```

### Custom Endpoints

```php
$client->setEndpoints(
    'https://custom.api.endpoint/v3',
    'https://custom.jwks.endpoint/'
);
```

## Core Methods

### 1. Create a Payment

```php
/**
 * @param float $amount Payment amount in cents (e.g., 1000 = €10.00)
 * @param string $currency Currency code (default: 'EUR')
 * @param string $description Payment description (optional, max 140 chars)
 * @param string $reference External reference (optional, max 35 chars)
 * @param string $bulkId Bulk ID for payouts (optional)
 * @param string $callbackUrl Webhook callback URL (optional)
 * @param string $returnUrl Return URL after payment (optional)
 * @return object Payment object with paymentId
 * @throws CreatePaymentFailedException
 */
$payment = $client->createPayment(
    1000,                   // €10.00
    'EUR',                  // Currency
    'Order #12345',         // Description
    'REF-12345',            // Your reference
    '',                     // Bulk ID
    'https://your-site.com/webhook',
    'https://your-site.com/return'
);

// Response contains:
// - $payment->paymentId
// - $payment->_links->checkout->href (payment URL for customer)
```

### 2. Retrieve Payment Details

```php
/**
 * @param string $paymentId Payconiq payment ID
 * @return object Payment details
 * @throws RetrievePaymentFailedException
 */
$payment = $client->retrievePayment('PAYMENT_ID_HERE');

// Response contains:
// - $payment->paymentId
// - $payment->amount
// - $payment->currency
// - $payment->status (e.g., 'SUCCEEDED', 'PENDING')
// - $payment->_links->refund->href (if refundable)
```

### 3. Get Payments by Reference

```php
/**
 * @param string $reference Your external reference
 * @return array List of payments with matching reference
 * @throws GetPaymentsListFailedException
 */
$payments = $client->getPaymentsListByReference('REF-12345');

// Returns array of payment objects
```

### 4. Get Payments by Date Range

```php
/**
 * @param string $fromDate Start date (format: YYYY-MM-ddTHH:mm:ss.SSSZ)
 * @param string $toDate End date (format: YYYY-MM-ddTHH:mm:ss.SSSZ)
 * @param int $size Page size (default: 50)
 * @return array List of successful payments in date range
 * @throws GetPaymentsListFailedException
 */
$payments = $client->getPaymentsListByDateRange(
    '2024-01-01T00:00:00.000Z',
    '2024-01-31T23:59:59.999Z',
    100
);
```

### 5. Refund a Payment

```php
/**
 * @param string $paymentId Payconiq payment ID
 * @param float $amount Refund amount in cents
 * @param string $currency Currency (default: 'EUR')
 * @param string $description Refund description (optional)
 * @param string $idempotencyKey Optional idempotency key (UUIDv4)
 * @param string $refundUrl Optional custom refund URL
 * @return object Refund response
 * @throws RefundFailedException
 */
$refund = $client->refundPayment(
    'PAYMENT_ID_HERE',
    500,                    // Refund €5.00
    'EUR',
    'Partial refund for order #12345',
    null,                   // Auto-generated UUID if null
    null                    // Auto-detected from payment
);
```

### 6. Get Refund IBAN

```php
/**
 * @param string $paymentId Payconiq payment ID
 * @return string IBAN for refunds
 * @throws GetRefundIbanFailedException
 */
$iban = $client->getRefundIban('PAYMENT_ID_HERE');
```

## Webhook Signature Verification

### 1. Verify Webhook Signature

```php
/**
 * @param string $payload Raw request body (php://input)
 * @param array $headers HTTP headers (getallheaders())
 * @return bool True if signature is valid
 * @throws \Exception on verification failure
 */
$isValid = $client->verifyWebhookSignature(
    file_get_contents('php://input'),
    getallheaders()
);

if ($isValid) {
    // Process webhook
    $data = json_decode(file_get_contents('php://input'), true);
    // Handle payment events
}
```

### 2. Webhook Handling Example

```php
// Complete webhook handler example
try {
    $payload = file_get_contents('php://input');
    $headers = getallheaders();
    
    if ($client->verifyWebhookSignature($payload, $headers)) {
        $data = json_decode($payload, true);
        
        switch ($data['status']) {
            case 'SUCCEEDED':
                // Update order as paid
                break;
            case 'FAILED':
                // Handle failed payment
                break;
            case 'REFUNDED':
                // Handle refund
                break;
        }
        
        http_response_code(200);
        echo 'OK';
    } else {
        http_response_code(401);
        echo 'Invalid signature';
    }
} catch (\Exception $e) {
    error_log('Webhook error: ' . $e->getMessage());
    http_response_code(400);
}
```

## Error Handling

### Exception Types

- `CreatePaymentFailedException`
- `RetrievePaymentFailedException`
- `GetPaymentsListFailedException`
- `RefundFailedException`
- `GetRefundIbanFailedException`

### Exception Example

```php
try {
    $payment = $client->createPayment(1000, 'EUR');
} catch (CreatePaymentFailedException $e) {
    echo 'Payment creation failed: ' . $e->getMessage();
} catch (\Exception $e) {
    echo 'General error: ' . $e->getMessage();
}
```

## Common Error Responses

```php
// Check response for details
$response = $client->createPayment(1000, 'EUR');
if (isset($response->message)) {
    // API returned an error message
    echo 'Error: ' . $response->message;
}
```

## Utility Methods

### Get Environment

```php
$environment = $client->getEnvironment(); // 'prod' or 'test'
```

### Set Cache Directory for JWKS Keys

```php
// If not set, the system tmp dir is used
$client->setCacheDir('/my/own/dir');
```

## SEPA String Conversion

All strings (descriptions, references) are automatically converted to SEPA-compliant format:

- Removes diacritics/accents
- Filters to allowed characters only
- Truncates to maximum lengths

## Best Practices

### 1. Idempotency for Refunds

```php
// Always use idempotency keys for refunds
$idempotencyKey = 'unique-refund-key-' . time();
$client->refundPayment($paymentId, $amount, 'EUR', '', $idempotencyKey);
```

### 2. Error Logging

```php
// Enable logging for debugging
$client->setLogger(function($message, $level) {
    error_log("[Payconiq $level] $message");
});
```

### 3. Webhook Security

- Always verify webhook signatures
- Never process unverified webhooks
- Implement replay attack protection

### 4. Cache Management

- JWKS keys are cached automatically
- Cache is refreshed on verification failures
- Manual cache clearing may be needed in edge cases

---

**Note:** This client automatically handles SEPA compliance, JWKS caching, and signature verification according to Payconiq specifications.
