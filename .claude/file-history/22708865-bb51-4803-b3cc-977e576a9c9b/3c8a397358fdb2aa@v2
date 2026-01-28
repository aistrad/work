# WeChat Authentication System

## Overview

WeChat QR code login for web applications, implementing the "Website Application" (网站应用) OAuth flow.

## Features

- QR code generation for WeChat scan login
- Status polling until user confirms
- Automatic account creation for new users
- Support for onboarding data (birth datetime, etc.)

## Login Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Generate QR │────►│ Display QR  │────►│ User Scans  │
│   Code      │     │   Code      │     │  with App   │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Return    │◄────│  Callback   │◄────│ User Auth   │
│    JWT      │     │   Handler   │     │  Confirms   │
└─────────────┘     └─────────────┘     └─────────────┘
```

## API Endpoints

### Generate QR Code

```
POST /api/auth/wechat/qrcode
```

Response:
```json
{
  "scene_id": "unique-session-id",
  "qrcode_url": "https://open.weixin.qq.com/connect/qrconnect?...",
  "expires_at": "2026-01-25T12:05:00Z"
}
```

### Poll Status

```
GET /api/auth/wechat/status?scene_id={scene_id}
```

Response (pending):
```json
{
  "status": "pending"
}
```

Response (scanned):
```json
{
  "status": "scanned",
  "message": "User scanned, waiting for confirmation"
}
```

Response (confirmed):
```json
{
  "status": "confirmed",
  "tokens": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "token_type": "bearer",
    "expires_in": 3600
  },
  "user": {
    "user_id": "uuid",
    "vibe_id": "VB-XXXXXXXX",
    "display_name": "微信用户"
  }
}
```

Response (expired):
```json
{
  "status": "expired",
  "message": "QR code expired"
}
```

### OAuth Callback (Internal)

```
GET /api/auth/wechat/callback?code={code}&state={scene_id}
```

This endpoint is called by WeChat after user authorization.

## Environment Variables

### Backend (`apps/api/.env`)

```env
# WeChat Open Platform
WECHAT_APP_ID=wxXXXXXXXXXXXX
WECHAT_APP_SECRET=your_app_secret
```

## Components

### WechatLoginButton

```tsx
import { WechatLoginButton } from "@/components/auth/WechatLoginButton";

<WechatLoginButton
  onSuccess={() => router.push("/chat")}
  onError={(error) => toast.error(error)}
/>
```

Props:
- `onSuccess?: () => void` - Called after successful login
- `onError?: (error: string) => void` - Called on error
- `onboarding?: OnboardingData` - Optional onboarding data for new users
- `disabled?: boolean` - Disable button

### WechatQRModal

Internal component that displays the QR code and handles polling.

## Database Schema

```sql
CREATE TABLE wechat_login_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scene_id VARCHAR(64) UNIQUE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    openid VARCHAR(64),
    unionid VARCHAR(64),
    user_info JSONB,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_wechat_sessions_scene ON wechat_login_sessions(scene_id);
CREATE INDEX idx_wechat_sessions_expires ON wechat_login_sessions(expires_at);
```

## Security Features

1. **Session Expiry**: QR codes expire after 5 minutes
2. **One-time Use**: Each scene_id can only be used once
3. **UnionID Support**: Uses unionid for cross-app identification when available
4. **Account Linking**: Prevents duplicate accounts via unionid/openid

## Setup Guide

### 1. Register at WeChat Open Platform

1. Go to [WeChat Open Platform](https://open.weixin.qq.com/)
2. Register and complete developer verification (requires business credentials)
3. Annual fee: 300 RMB

### 2. Create Website Application

1. Navigate to **Management Center** > **Website Application** > **Create**
2. Fill in application info and submit for review (1-3 business days)

### 3. Configure Callback Domain

1. After approval, go to application details
2. Under **Development Info**, set:
   - **Callback Domain**: `vibelife.app` (without https://)

### 4. Get Credentials

- **AppID**: Found in application details
- **AppSecret**: Shown only once when created (save it!)

## Error Handling

| Error | HTTP Status | Message |
|-------|------------|---------|
| WeChat not configured | 500 | "WeChat credentials not configured" |
| Session not found | 404 | "Session not found" |
| QR code expired | 400 | "QR code expired" |
| OAuth failed | 500 | "WeChat authorization failed" |

## Polling Best Practices

Frontend should poll the status endpoint:
- Interval: 1-2 seconds
- Timeout: 5 minutes (matches QR code expiry)
- Stop on: `confirmed`, `expired`, or user cancels

```typescript
const pollStatus = async (sceneId: string) => {
  const startTime = Date.now();
  const timeout = 5 * 60 * 1000; // 5 minutes

  while (Date.now() - startTime < timeout) {
    const res = await fetch(`/api/auth/wechat/status?scene_id=${sceneId}`);
    const data = await res.json();

    if (data.status === "confirmed") {
      // Store tokens and redirect
      return data;
    }

    if (data.status === "expired") {
      throw new Error("QR code expired");
    }

    await new Promise(r => setTimeout(r, 1500));
  }

  throw new Error("Polling timeout");
};
```
