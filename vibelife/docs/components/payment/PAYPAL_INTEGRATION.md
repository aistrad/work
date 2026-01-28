# PayPal Integration

## Overview

PayPal 作为 Stripe 的补充支付渠道，主要服务于：
- 偏好使用 PayPal 的海外用户
- 没有信用卡但有 PayPal 账户的用户
- 对 Stripe 支持较弱地区的用户

## 适用场景

| 场景 | 推荐渠道 | 原因 |
|-----|---------|------|
| 订阅制自动续费 | Stripe | PayPal 订阅体验较差 |
| 一次性预付购买 | PayPal / Stripe | 两者皆可 |
| 中国用户 | Stripe（支付宝/微信） | PayPal 在中国不流行 |
| 东南亚/拉美用户 | PayPal | 信用卡普及率低 |

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Frontend  │────►│  Next.js    │────►│   FastAPI   │
│  (React)    │     │  API Route  │     │   Backend   │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                          ┌───────────────────┼───────────────────┐
                          ▼                   ▼                   ▼
                    ┌───────────┐       ┌───────────┐       ┌───────────┐
                    │  Create   │       │  Capture  │       │  Webhook  │
                    │   Order   │       │  Payment  │       │  Handler  │
                    └───────────┘       └───────────┘       └───────────┘
                          │                   │                   │
                          └───────────────────┼───────────────────┘
                                              ▼
                                        ┌───────────┐
                                        │  PayPal   │
                                        │    API    │
                                        └───────────┘
```

## PayPal 支付流程

### 标准结账流程

```
1. 用户点击 PayPal 按钮
2. 前端调用后端创建 Order
3. 后端调用 PayPal API 创建 Order
4. 返回 Order ID 和 Approve URL
5. 用户跳转到 PayPal 授权页面
6. 用户在 PayPal 确认支付
7. PayPal 重定向回网站（带 token）
8. 前端调用后端 Capture 扣款
9. 后端调用 PayPal API 完成扣款
10. Webhook 通知（可选验证）
11. 更新用户权益
```

## API Endpoints

### Create Order

```
POST /api/payment/paypal/create-order
```

Request:
```json
{
  "amount": "9.99",
  "currency": "USD",
  "description": "VibeLife Pro - 1 Month",
  "metadata": {
    "package": "prepaid_1m",
    "user_id": "user_xxx"
  }
}
```

Response:
```json
{
  "order_id": "5O190127TN364715T",
  "approve_url": "https://www.paypal.com/checkoutnow?token=5O190127TN364715T",
  "status": "CREATED"
}
```

### Capture Order

```
POST /api/payment/paypal/capture-order
```

Request:
```json
{
  "order_id": "5O190127TN364715T"
}
```

Response:
```json
{
  "order_id": "5O190127TN364715T",
  "status": "COMPLETED",
  "capture_id": "3C679366HH908993F",
  "amount": "9.99",
  "currency": "USD"
}
```

### Webhook Handler

```
POST /api/payment/paypal/webhook
```

监听事件：
- `CHECKOUT.ORDER.APPROVED` - 用户授权成功
- `PAYMENT.CAPTURE.COMPLETED` - 扣款成功
- `PAYMENT.CAPTURE.DENIED` - 扣款失败
- `PAYMENT.CAPTURE.REFUNDED` - 退款完成

## Environment Variables

### Backend (`apps/api/.env`)

```env
# PayPal API (Sandbox for testing, Live for production)
PAYPAL_CLIENT_ID=AYSq3RDGsmBLJE-otTkBtM-jBRd1TCQwFf9RGfwddNXWz0uFU9ztymylOhRS
PAYPAL_CLIENT_SECRET=EGnHDxD_qRPdaLdZz8iCr8N7_MzF-YHPTkjs6NKYQvQSBngp4PTTVWkPZRbL

# PayPal Environment: sandbox | live
PAYPAL_MODE=sandbox

# PayPal Webhook ID (for signature verification)
PAYPAL_WEBHOOK_ID=WH-xxx

# Callback URLs
PAYPAL_RETURN_URL=https://vibelife.app/payment/paypal/success
PAYPAL_CANCEL_URL=https://vibelife.app/payment/paypal/cancel
```

## Backend Service

### PayPalService Class

Location: `apps/api/services/billing/paypal_service.py`

```python
import os
import httpx
import base64
from typing import Optional
import logging

logger = logging.getLogger(__name__)

PAYPAL_CLIENT_ID = os.getenv("PAYPAL_CLIENT_ID", "")
PAYPAL_CLIENT_SECRET = os.getenv("PAYPAL_CLIENT_SECRET", "")
PAYPAL_MODE = os.getenv("PAYPAL_MODE", "sandbox")

PAYPAL_API_BASE = {
    "sandbox": "https://api-m.sandbox.paypal.com",
    "live": "https://api-m.paypal.com"
}


class PayPalService:
    """PayPal REST API Service"""

    def __init__(self):
        self.client_id = PAYPAL_CLIENT_ID
        self.client_secret = PAYPAL_CLIENT_SECRET
        self.base_url = PAYPAL_API_BASE.get(PAYPAL_MODE, PAYPAL_API_BASE["sandbox"])
        self._access_token = None

    @property
    def is_configured(self) -> bool:
        return bool(self.client_id and self.client_secret)

    async def _get_access_token(self) -> Optional[str]:
        """Get OAuth 2.0 access token"""
        if not self.is_configured:
            return None

        try:
            auth = base64.b64encode(
                f"{self.client_id}:{self.client_secret}".encode()
            ).decode()

            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/v1/oauth2/token",
                    headers={
                        "Authorization": f"Basic {auth}",
                        "Content-Type": "application/x-www-form-urlencoded"
                    },
                    data={"grant_type": "client_credentials"}
                )

                if response.status_code == 200:
                    data = response.json()
                    self._access_token = data["access_token"]
                    return self._access_token

        except Exception as e:
            logger.error(f"Failed to get PayPal access token: {e}")

        return None

    async def create_order(
        self,
        amount: str,
        currency: str = "USD",
        description: str = "",
        return_url: str = "",
        cancel_url: str = "",
        metadata: Optional[dict] = None
    ) -> Optional[dict]:
        """Create a PayPal order"""
        token = await self._get_access_token()
        if not token:
            return None

        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/v2/checkout/orders",
                    headers={
                        "Authorization": f"Bearer {token}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "intent": "CAPTURE",
                        "purchase_units": [{
                            "amount": {
                                "currency_code": currency,
                                "value": amount
                            },
                            "description": description,
                            "custom_id": str(metadata) if metadata else None
                        }],
                        "application_context": {
                            "return_url": return_url,
                            "cancel_url": cancel_url,
                            "brand_name": "VibeLife",
                            "landing_page": "LOGIN",
                            "user_action": "PAY_NOW"
                        }
                    }
                )

                if response.status_code in [200, 201]:
                    data = response.json()
                    approve_url = next(
                        (link["href"] for link in data.get("links", [])
                         if link["rel"] == "approve"),
                        None
                    )
                    return {
                        "order_id": data["id"],
                        "status": data["status"],
                        "approve_url": approve_url
                    }

        except Exception as e:
            logger.error(f"Failed to create PayPal order: {e}")

        return None

    async def capture_order(self, order_id: str) -> Optional[dict]:
        """Capture an approved order"""
        token = await self._get_access_token()
        if not token:
            return None

        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/v2/checkout/orders/{order_id}/capture",
                    headers={
                        "Authorization": f"Bearer {token}",
                        "Content-Type": "application/json"
                    }
                )

                if response.status_code in [200, 201]:
                    data = response.json()
                    capture = data["purchase_units"][0]["payments"]["captures"][0]
                    return {
                        "order_id": data["id"],
                        "status": data["status"],
                        "capture_id": capture["id"],
                        "amount": capture["amount"]["value"],
                        "currency": capture["amount"]["currency_code"]
                    }

        except Exception as e:
            logger.error(f"Failed to capture PayPal order: {e}")

        return None

    async def get_order(self, order_id: str) -> Optional[dict]:
        """Get order details"""
        token = await self._get_access_token()
        if not token:
            return None

        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/v2/checkout/orders/{order_id}",
                    headers={"Authorization": f"Bearer {token}"}
                )

                if response.status_code == 200:
                    return response.json()

        except Exception as e:
            logger.error(f"Failed to get PayPal order: {e}")

        return None

    def verify_webhook_signature(
        self,
        headers: dict,
        body: bytes,
        webhook_id: str
    ) -> bool:
        """Verify PayPal webhook signature"""
        # PayPal webhook verification is more complex
        # For simplicity, you can verify via API call
        # See: https://developer.paypal.com/docs/api/webhooks/v1/#verify-webhook-signature
        return True  # TODO: Implement proper verification
```

## Frontend Integration

### PayPal Button (React)

```tsx
import { PayPalScriptProvider, PayPalButtons } from "@paypal/react-paypal-js";

const PAYPAL_CLIENT_ID = process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID!;

interface PayPalCheckoutProps {
  amount: string;
  currency?: string;
  onSuccess: (orderId: string) => void;
  onError: (error: string) => void;
}

export function PayPalCheckout({
  amount,
  currency = "USD",
  onSuccess,
  onError
}: PayPalCheckoutProps) {
  return (
    <PayPalScriptProvider options={{ clientId: PAYPAL_CLIENT_ID, currency }}>
      <PayPalButtons
        style={{ layout: "vertical", label: "pay" }}
        createOrder={async () => {
          const response = await fetch("/api/payment/paypal/create-order", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ amount, currency })
          });
          const data = await response.json();
          return data.order_id;
        }}
        onApprove={async (data) => {
          const response = await fetch("/api/payment/paypal/capture-order", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ order_id: data.orderID })
          });
          const result = await response.json();
          if (result.status === "COMPLETED") {
            onSuccess(result.order_id);
          } else {
            onError("Payment not completed");
          }
        }}
        onError={(err) => {
          onError(String(err));
        }}
        onCancel={() => {
          onError("Payment cancelled");
        }}
      />
    </PayPalScriptProvider>
  );
}
```

### 安装依赖

```bash
# Frontend
npm install @paypal/react-paypal-js

# Backend (Python)
# httpx 已经在项目中，无需额外安装
```

## 手续费对比

| 渠道 | 国内收款 | 跨境收款 |
|-----|---------|---------|
| Stripe | 2.9% + $0.30 | 3.9% + $0.30 |
| PayPal | 2.99% + 固定费用 | 4.4% + 固定费用 |

> PayPal 手续费略高，但覆盖更多地区和支付方式

## Testing

### PayPal Sandbox

1. 登录 [PayPal Developer](https://developer.paypal.com/)
2. 创建 Sandbox 测试账户（Buyer 和 Seller）
3. 使用 Sandbox 凭据测试

### 测试账户

在 PayPal Developer Dashboard 创建：
- **Business Account** (Seller): 用于收款
- **Personal Account** (Buyer): 用于测试支付

### 测试信用卡号

| 卡类型 | 卡号 |
|-------|-----|
| Visa | 4111111111111111 |
| Mastercard | 5555555555554444 |
| Amex | 378282246310005 |

## Error Handling

| 错误 | HTTP Status | 处理 |
|-----|------------|------|
| INSTRUMENT_DECLINED | 400 | 支付方式被拒，提示换卡 |
| PAYER_ACTION_REQUIRED | 400 | 需要用户操作（3DS等） |
| ORDER_NOT_APPROVED | 400 | 用户未授权，重新发起 |
| PERMISSION_DENIED | 403 | API 权限问题 |

## Security

1. **服务端创建订单**：金额由后端计算，防止篡改
2. **Webhook 签名验证**：验证 PayPal 回调真实性
3. **HTTPS Only**：所有 API 调用必须使用 HTTPS
4. **订单状态检查**：Capture 前验证订单状态

## 与 Stripe 的选择建议

| 用户需求 | 推荐 |
|---------|-----|
| 自动续费订阅 | Stripe |
| 支付宝/微信 | Stripe |
| PayPal 余额支付 | PayPal |
| 无信用卡用户 | PayPal |
| 东南亚/拉美用户 | PayPal |
| Apple Pay/Google Pay | Stripe |
