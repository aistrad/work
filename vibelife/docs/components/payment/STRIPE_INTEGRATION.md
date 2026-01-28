# Stripe Integration

## Overview

VibeLife uses Stripe for payment processing, supporting subscriptions (overseas users) and prepaid packages (China/HK users).

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Frontend  │────►│  Next.js    │────►│   FastAPI   │
│  (React)    │     │  API Route  │     │   Backend   │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              ▼
                                        ┌─────────────┐
                                        │   Stripe    │
                                        │    API      │
                                        └─────────────┘
                                              │
                                              ▼
                                        ┌─────────────┐
                                        │  Webhook    │
                                        │  Handler    │
                                        └─────────────┘
```

## API Endpoints

### Create Checkout Session

```
POST /api/payment/create-checkout
```

Request:
```json
{
  "price_id": "price_xxx",
  "success_url": "https://vibelife.app/payment/success",
  "cancel_url": "https://vibelife.app/pricing"
}
```

Response:
```json
{
  "session_id": "cs_xxx",
  "url": "https://checkout.stripe.com/pay/cs_xxx"
}
```

### Create Payment Intent

```
POST /api/payment/create-intent
```

Request:
```json
{
  "amount": 7800,
  "currency": "hkd",
  "metadata": {
    "package": "prepaid_1m"
  }
}
```

Response:
```json
{
  "client_secret": "pi_xxx_secret_xxx",
  "payment_intent_id": "pi_xxx"
}
```

### Create Billing Portal Session

```
POST /api/payment/billing-portal
```

Response:
```json
{
  "url": "https://billing.stripe.com/session/xxx"
}
```

### Webhook Handler

```
POST /api/payment/webhook
```

Handles events:
- `checkout.session.completed`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.paid`
- `invoice.payment_failed`
- `payment_intent.succeeded`
- `payment_intent.payment_failed`

## Environment Variables

### Backend (`apps/api/.env`)

```env
# Stripe API Keys
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_PUBLISHABLE_KEY=pk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# Subscription Prices (USD)
STRIPE_PRICE_SUB_MONTHLY_USD=price_xxx
STRIPE_PRICE_SUB_QUARTERLY_USD=price_xxx
STRIPE_PRICE_SUB_YEARLY_USD=price_xxx

# Prepaid Prices (HKD)
STRIPE_PRICE_PREPAID_1M_HKD=price_xxx
STRIPE_PRICE_PREPAID_3M_HKD=price_xxx
STRIPE_PRICE_PREPAID_12M_HKD=price_xxx

# Callback URLs
PAYMENT_SUCCESS_URL=https://vibelife.app/payment/success
PAYMENT_CANCEL_URL=https://vibelife.app/pricing
BILLING_PORTAL_RETURN_URL=https://vibelife.app/account
```

## Backend Service

### StripeService Class

Location: `apps/api/services/billing/stripe_service.py`

```python
from services.billing.stripe_service import StripeService

stripe_service = StripeService()

# Create checkout session
session = await stripe_service.create_checkout_session(
    user_id="user_xxx",
    price_id="price_xxx",
    success_url="https://vibelife.app/payment/success",
    cancel_url="https://vibelife.app/pricing"
)

# Create payment intent
intent = await stripe_service.create_payment_intent(
    amount=7800,
    currency="hkd",
    metadata={"user_id": "user_xxx"}
)

# Verify webhook signature
event = stripe_service.verify_webhook_signature(
    payload=request.body,
    signature=request.headers["Stripe-Signature"]
)
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `create_checkout_session` | Create Stripe Checkout Session |
| `create_payment_intent` | Create PaymentIntent for custom flow |
| `create_billing_portal_session` | Create Customer Portal session |
| `get_subscription` | Get subscription details |
| `cancel_subscription` | Cancel subscription |
| `verify_webhook_signature` | Verify webhook payload |

## Frontend Integration

### Redirect to Checkout

```tsx
const handleCheckout = async (priceId: string) => {
  const response = await fetch("/api/payment/create-checkout", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ price_id: priceId }),
  });

  const { url } = await response.json();
  window.location.href = url;
};
```

### Payment Element (Custom UI)

```tsx
import { loadStripe } from "@stripe/stripe-js";
import { Elements, PaymentElement } from "@stripe/react-stripe-js";

const stripePromise = loadStripe(process.env.NEXT_PUBLIC_STRIPE_KEY!);

function CheckoutForm({ clientSecret }: { clientSecret: string }) {
  return (
    <Elements stripe={stripePromise} options={{ clientSecret }}>
      <PaymentElement />
      <button type="submit">Pay</button>
    </Elements>
  );
}
```

## Database Schema

```sql
-- User subscription tracking
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vibe_users(id),
    stripe_customer_id VARCHAR(255),
    stripe_subscription_id VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'inactive',
    plan VARCHAR(50),
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment history
CREATE TABLE payment_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vibe_users(id),
    stripe_payment_intent_id VARCHAR(255),
    amount INTEGER NOT NULL,
    currency VARCHAR(10) NOT NULL,
    status VARCHAR(50) NOT NULL,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Webhook Event Handling

```python
async def handle_webhook_event(event_type: str, data: dict):
    if event_type == "checkout.session.completed":
        # Create or update subscription
        user_id = data["metadata"]["user_id"]
        subscription_id = data["subscription"]
        await update_user_subscription(user_id, subscription_id)

    elif event_type == "customer.subscription.deleted":
        # Deactivate subscription
        subscription_id = data["id"]
        await deactivate_subscription(subscription_id)

    elif event_type == "invoice.payment_failed":
        # Handle failed payment
        customer_id = data["customer"]
        await handle_payment_failure(customer_id)
```

## Security Best Practices

1. **Server-side amount calculation**: Never trust client-provided amounts
2. **Webhook signature verification**: Always verify webhook signatures
3. **Idempotency**: Handle duplicate webhook events gracefully
4. **HTTPS only**: All payment endpoints must use HTTPS
5. **PCI compliance**: Use Stripe Elements or Checkout to avoid handling card data

## Testing

### Test Mode

Use test API keys (`sk_test_`, `pk_test_`) for development.

### Test Cards

| Number | Scenario |
|--------|----------|
| `4242 4242 4242 4242` | Successful payment |
| `4000 0000 0000 9995` | Card declined |
| `4000 0000 0000 3220` | Requires 3D Secure |

### Stripe CLI

```bash
# Listen to webhook events locally
stripe listen --forward-to localhost:8000/api/payment/webhook

# Trigger test events
stripe trigger checkout.session.completed
stripe trigger payment_intent.succeeded
```

## Error Handling

| Error | HTTP Status | Message |
|-------|------------|---------|
| Invalid price ID | 400 | "Invalid price ID" |
| Payment failed | 402 | "Payment failed" |
| Webhook verification failed | 400 | "Invalid signature" |
| Stripe API error | 500 | "Payment service error" |
