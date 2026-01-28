# Vibe ID 分享卡片设计

> Version: 7.0 | 2026-01-18

---

## 概述

分享卡片是 Vibe ID 裂变的核心载体，采用**服务端渲染**方案，确保在所有平台上的兼容性。

## 设计目标

1. **高辨识度**: 一眼就能认出是 VibeLife
2. **易传播**: 适合朋友圈、小红书、微博等平台
3. **引发好奇**: 让看到的人想测测自己的 Vibe
4. **快速加载**: 图片体积小，加载快

---

## 卡���样式

### 1. Default 样式 (默认)

```
┌─────────────────────────────────────┐
│                                     │
│     ┌──────────┐                    │
│     │   🧭     │  我是              │
│     │          │  ════════════════  │
│     │  Avatar  │  探索者 Vibe       │
│     └──────────┘                    │
│                                     │
│     "好奇心驱动，追求意义，          │
│      享受探索未知的旅程"            │
│                                     │
│     ┌─────────────────────────────┐ │
│     │ 🔍 好奇宝宝 95%              │ │
│     │ 🦅 独立自主 88%              │ │
│     │ 🧠 理性分析 82%              │ │
│     │ 🎢 爱冒险   79%              │ │
│     └─────────────────────────────┘ │
│                                     │
│     ─────────────────────────────   │
│     扫码测测你的 Vibe               │
│     [QR Code]           [VibeLife]  │
│                                     │
└─────────────────────────────────────┘

尺寸: 750 x 1334 px (适合手机屏幕)
背景: 浅米色渐变 (#FFF8F0 → #FFF0E6)
```

### 2. Dark 样式

```
┌─────────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ▓                                 ▓ │
│ ▓    ┌──────────┐                 ▓ │
│ ▓    │   🧭     │  我是           ▓ │
│ ▓    │          │  ════════════   ▓ │
│ ▓    │  Avatar  │  探索者 Vibe    ▓ │
│ ▓    └──────────┘                 ▓ │
│ ▓                                 ▓ │
│ ▓    "好奇心驱动，追求意义，       ▓ │
│ ▓     享受探索未知的旅程"         ▓ │
│ ▓                                 ▓ │
│ ▓    🔍 95%  🦅 88%  🧠 82%       ▓ │
│ ▓                                 ▓ │
│ ▓    ───────────────────────────  ▓ │
│ ▓    扫码测测你的 Vibe            ▓ │
│ ▓    [QR]              [VibeLife] ▓ │
│ ▓                                 ▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
└─────────────────────────────────────┘

背景: 深色渐变 (#1A1A2E → #16213E)
文字: 白色/浅色
```

### 3. Gradient 样式

```
┌─────────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░  ╔═══════════════════════════╗  ░ │
│ ░  ║                           ║  ░ │
│ ░  ║    🧭 探索者 Vibe         ║  ░ │
│ ░  ║                           ║  ░ │
│ ░  ║    "好奇心驱动，          ║  ░ │
│ ░  ║     追求意义"             ║  ░ │
│ ░  ║                           ║  ░ │
│ ░  ║    ▓▓▓▓▓▓▓▓▓▓ 95%        ║  ░ │
│ ░  ║    ▓▓▓▓▓▓▓▓░░ 88%        ║  ░ │
│ ░  ║    ▓▓▓▓▓▓▓░░░ 82%        ║  ░ │
│ ░  ║                           ║  ░ │
│ ░  ╚═══════════════════════════╝  ░ │
│ ░                                 ░ │
│ ░  [QR] 扫码测测你的 Vibe         ░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
└─────────────────────────────────────┘

背景: 原型对应的渐变色
边框: 毛玻璃效果
```

### 4. Minimal 样式 (小红书优化)

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│           🧭                        │
│                                     │
│        探索者 Vibe                  │
│                                     │
│    "好奇心驱动，追求意义"           │
│                                     │
│                                     │
│        VibeLife                     │
│                                     │
└─────────────────────────────────────┘

尺寸: 1080 x 1080 px (正方形)
背景: 纯色 + 原型色点缀
极简设计，适合小红书
```

---

## 技术实现

### 服务端渲染方案

使用 **Pillow** (Python) 进行图片渲染。

```python
# skills/vibe_id/services/card_renderer.py

from PIL import Image, ImageDraw, ImageFont
from io import BytesIO
import qrcode
from typing import Dict, Any, Literal
import os

CardStyle = Literal["default", "dark", "gradient", "minimal"]

class CardRenderer:
    """分享卡片渲染器"""

    # 卡片尺寸
    SIZES = {
        "default": (750, 1334),
        "dark": (750, 1334),
        "gradient": (750, 1334),
        "minimal": (1080, 1080),
    }

    # 字体路径
    FONT_DIR = os.path.join(os.path.dirname(__file__), "../assets/fonts")

    def __init__(self):
        self._load_fonts()
        self._load_assets()

    def _load_fonts(self):
        """加载字体"""
        self.fonts = {
            "title": ImageFont.truetype(f"{self.FONT_DIR}/NotoSansSC-Bold.ttf", 48),
            "subtitle": ImageFont.truetype(f"{self.FONT_DIR}/NotoSansSC-Medium.ttf", 32),
            "body": ImageFont.truetype(f"{self.FONT_DIR}/NotoSansSC-Regular.ttf", 24),
            "small": ImageFont.truetype(f"{self.FONT_DIR}/NotoSansSC-Regular.ttf", 18),
            "emoji": ImageFont.truetype(f"{self.FONT_DIR}/NotoColorEmoji.ttf", 64),
        }

    def _load_assets(self):
        """加载静态资源"""
        assets_dir = os.path.join(os.path.dirname(__file__), "../assets")
        self.logo = Image.open(f"{assets_dir}/logo.png")

    def render(
        self,
        vibe_id: Dict[str, Any],
        style: CardStyle = "default",
        include_qr: bool = True
    ) -> bytes:
        """
        渲染分享卡片

        Args:
            vibe_id: Vibe ID 数据
            style: 卡片样式
            include_qr: 是否包含二维码

        Returns:
            PNG 图片二进制数据
        """
        size = self.SIZES[style]
        img = Image.new("RGBA", size, self._get_background(style, vibe_id))
        draw = ImageDraw.Draw(img)

        if style == "default":
            self._render_default(img, draw, vibe_id, include_qr)
        elif style == "dark":
            self._render_dark(img, draw, vibe_id, include_qr)
        elif style == "gradient":
            self._render_gradient(img, draw, vibe_id, include_qr)
        elif style == "minimal":
            self._render_minimal(img, draw, vibe_id, include_qr)

        # 输出为 PNG
        buffer = BytesIO()
        img.save(buffer, format="PNG", optimize=True)
        return buffer.getvalue()

    def _get_background(self, style: CardStyle, vibe_id: Dict) -> tuple:
        """获取背景色"""
        if style == "dark":
            return (26, 26, 46, 255)
        elif style == "minimal":
            return (255, 255, 255, 255)
        else:
            return (255, 248, 240, 255)

    def _render_default(self, img: Image, draw: ImageDraw, vibe_id: Dict, include_qr: bool):
        """渲染默认样式"""
        identity = vibe_id["identity"]
        tags = vibe_id["tags"]
        share = vibe_id["share"]

        width, height = img.size
        center_x = width // 2

        # 原型 Emoji (大)
        emoji = identity["primary_emoji"]
        draw.text((center_x, 150), emoji, font=self.fonts["emoji"], anchor="mm")

        # "我是" 标签
        draw.text((center_x, 250), "我是", font=self.fonts["body"], fill=(100, 100, 100), anchor="mm")

        # 原型名称
        archetype_text = f"{identity['primary_tagline']} Vibe"
        draw.text((center_x, 310), archetype_text, font=self.fonts["title"], fill=(30, 30, 30), anchor="mm")

        # 标语
        slogan = f'"{identity["primary_slogan"]}"'
        self._draw_wrapped_text(draw, slogan, center_x, 400, self.fonts["subtitle"], (80, 80, 80), width - 100)

        # 标签
        y_offset = 550
        for tag in tags[:4]:
            tag_text = f"{tag['emoji']} {tag['label']} {tag['score']}%"
            draw.text((center_x, y_offset), tag_text, font=self.fonts["body"], fill=(60, 60, 60), anchor="mm")
            y_offset += 50

        # 分隔线
        draw.line([(100, height - 300), (width - 100, height - 300)], fill=(200, 200, 200), width=1)

        # 底部文案
        draw.text((center_x, height - 220), "扫码测测你的 Vibe", font=self.fonts["body"], fill=(100, 100, 100), anchor="mm")

        # 二维码
        if include_qr:
            qr = self._generate_qr(f"https://vibelife.app/vibe-id/{share['share_code']}")
            qr = qr.resize((120, 120))
            img.paste(qr, (100, height - 180))

        # Logo
        logo = self.logo.resize((100, 30))
        img.paste(logo, (width - 150, height - 100), logo)

    def _render_dark(self, img: Image, draw: ImageDraw, vibe_id: Dict, include_qr: bool):
        """渲染深色样式"""
        # 类似 default，但使用深色背景和浅色文字
        pass

    def _render_gradient(self, img: Image, draw: ImageDraw, vibe_id: Dict, include_qr: bool):
        """渲染渐变样式"""
        # 使用原型对应的渐变色
        pass

    def _render_minimal(self, img: Image, draw: ImageDraw, vibe_id: Dict, include_qr: bool):
        """渲染极简样式"""
        identity = vibe_id["identity"]
        width, height = img.size
        center_x = width // 2
        center_y = height // 2

        # 原型 Emoji (超大)
        draw.text((center_x, center_y - 150), identity["primary_emoji"], font=self.fonts["emoji"], anchor="mm")

        # 原型名称
        draw.text((center_x, center_y + 50), f"{identity['primary_tagline']} Vibe", font=self.fonts["title"], fill=(30, 30, 30), anchor="mm")

        # 标语 (简短版)
        short_slogan = identity["primary_slogan"][:20] + "..."
        draw.text((center_x, center_y + 120), f'"{short_slogan}"', font=self.fonts["subtitle"], fill=(100, 100, 100), anchor="mm")

        # 品牌
        draw.text((center_x, height - 80), "VibeLife", font=self.fonts["body"], fill=(150, 150, 150), anchor="mm")

    def _generate_qr(self, url: str) -> Image:
        """生成二维码"""
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=2,
        )
        qr.add_data(url)
        qr.make(fit=True)
        return qr.make_image(fill_color="black", back_color="white")

    def _draw_wrapped_text(self, draw: ImageDraw, text: str, x: int, y: int, font: ImageFont, fill: tuple, max_width: int):
        """绘制自动换行文本"""
        lines = []
        current_line = ""

        for char in text:
            test_line = current_line + char
            bbox = draw.textbbox((0, 0), test_line, font=font)
            if bbox[2] - bbox[0] <= max_width:
                current_line = test_line
            else:
                lines.append(current_line)
                current_line = char

        if current_line:
            lines.append(current_line)

        line_height = font.size + 10
        total_height = len(lines) * line_height
        start_y = y - total_height // 2

        for i, line in enumerate(lines):
            draw.text((x, start_y + i * line_height), line, font=font, fill=fill, anchor="mm")


# 单例
_renderer: CardRenderer = None

def get_card_renderer() -> CardRenderer:
    global _renderer
    if _renderer is None:
        _renderer = CardRenderer()
    return _renderer
```

### API 端点实现

```python
# routes/vibe_id.py

from fastapi import APIRouter, Response
from fastapi.responses import StreamingResponse
from skills.vibe_id.services.card_renderer import get_card_renderer, CardStyle

router = APIRouter(prefix="/vibe-id", tags=["vibe-id"])

@router.get("/card/{share_code}.png")
async def get_share_card(
    share_code: str,
    style: CardStyle = "default",
    size: str = "medium"
):
    """获取分享卡片图片"""
    # 1. 通过 share_code 查找 vibe_id
    vibe_id = await find_vibe_id_by_share_code(share_code)
    if not vibe_id:
        # 返回默认占位图
        return Response(content=get_placeholder_image(), media_type="image/png")

    # 2. 渲染卡片
    renderer = get_card_renderer()
    image_bytes = renderer.render(vibe_id, style=style)

    # 3. 返回图片
    return Response(
        content=image_bytes,
        media_type="image/png",
        headers={
            "Cache-Control": "public, max-age=3600",  # 缓存1小时
            "Content-Disposition": f"inline; filename=vibe-id-{share_code}.png"
        }
    )

@router.post("/card/generate")
async def generate_share_card(
    style: CardStyle = "default",
    include_qr: bool = True,
    current_user: dict = Depends(get_current_user)
):
    """生成分享卡片"""
    user_id = UUID(current_user["id"])

    # 1. 获取用户的 vibe_id
    vibe_id = await get_vibe_id(user_id)
    if not vibe_id:
        raise HTTPException(status_code=404, detail="Vibe ID not found")

    # 2. 渲染卡片
    renderer = get_card_renderer()
    image_bytes = renderer.render(vibe_id, style=style, include_qr=include_qr)

    # 3. 保存到存储 (可选)
    card_url = await save_card_to_storage(user_id, image_bytes)

    # 4. 更新 vibe_id 中的 card_url
    await update_vibe_id_card_url(user_id, card_url)

    return {
        "status": "success",
        "data": {
            "card_url": card_url,
            "share_code": vibe_id["share"]["share_code"],
            "generated_at": datetime.utcnow().isoformat()
        }
    }
```

---

## 资源文件

### 字体文件

```
skills/vibe_id/assets/fonts/
├── NotoSansSC-Bold.ttf
├── NotoSansSC-Medium.ttf
├── NotoSansSC-Regular.ttf
└── NotoColorEmoji.ttf
```

### 静态资源

```
skills/vibe_id/assets/
├── logo.png                    # VibeLife Logo
├── logo-white.png              # 白色 Logo (深色背景用)
├── backgrounds/
│   ├── default.png
│   ├── dark.png
│   └── gradient-*.png          # 各原型渐变背景
└── icons/
    └── qr-placeholder.png
```

---

## 分享码生成

```python
# skills/vibe_id/services/share_code.py

import random
import string
from typing import Optional

# 分享码字符集 (排除易混淆字符)
CHARSET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

def generate_share_code(length: int = 6) -> str:
    """生成分享码"""
    return "".join(random.choices(CHARSET, k=length))

async def get_unique_share_code(max_attempts: int = 10) -> str:
    """获取唯一分享码"""
    for _ in range(max_attempts):
        code = generate_share_code()
        if not await share_code_exists(code):
            return code
    raise Exception("Failed to generate unique share code")

async def share_code_exists(code: str) -> bool:
    """检查分享码是否已存在"""
    result = await fetchval(
        """SELECT 1 FROM unified_profiles
           WHERE profile->'skill_data'->'vibe_id'->'share'->>'share_code' = $1""",
        code
    )
    return result is not None
```

---

## 缓存策略

```python
# 卡片缓存配置

CARD_CACHE_CONFIG = {
    # CDN 缓存
    "cdn_ttl": 3600,              # 1小时

    # 本地缓存
    "local_ttl": 300,             # 5分钟

    # 缓存 key 格式
    "key_format": "vibe_card:{share_code}:{style}",

    # 缓存失效条件
    "invalidate_on": [
        "vibe_id_recalculated",
        "card_style_changed",
    ]
}
```

---

## 性能优化

1. **图片压缩**: 使用 PNG 优化，控制在 200KB 以内
2. **CDN 缓存**: 卡片图片通过 CDN 分发
3. **预生成**: 用户创建 Vibe ID 时预生成默认样式卡片
4. **懒加载**: 其他样式按需生成
