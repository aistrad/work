# VibeLife Skill System 设计文档

> **符合**: [Agent Skills 开放标准](https://agentskills.io) | [anthropics/skills](https://github.com/anthropics/skills)  
> **版本**: 3.0 | **日期**: January 2026

---

## 一、设计原则

| 原则 | 实现 |
|------|------|
| **不造轮子** | 计算引擎采用 GitHub 验证的开源项目 |
| **Context Engineering** | 渐进式披露，动态组装上下文 |
| **极简架构** | PostgreSQL + pgvector + MD/JSON，一库搞定 |
| **模型可配置** | GLM 4.7 (默认) / DeepSeek V3 / Gemini Pro 3 |

### 1.1 开源计算引擎选型

| Skill | 计算库 | GitHub | Stars | 特点 |
|-------|--------|--------|-------|------|
| **bazi-master** | [lunar-python](https://github.com/6tail/lunar-python) | 6tail/lunar-python | ⭐3.2k | 零依赖，八字/十神/五行/大运/节气，完整命理计算 |
| **astra-guide** | [kerykeion](https://github.com/g-battaglia/kerykeion) | g-battaglia/kerykeion | ⭐900+ | Swiss Ephemeris，AI-first 设计，SVG 星盘 |

---

## 二、系统架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          VibeLife Architecture                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐      │
│   │   Next.js   │────▶│  Vercel AI SDK  │────▶│   LLM Provider  │      │
│   │   Frontend  │     │    6 (Agent)    │     │ GLM 4.7 / DS V3 │      │
│   └─────────────┘     └────────┬────────┘     └─────────────────┘      │
│                                │                                        │
│                 ┌──────────────┼──────────────┐                        │
│                 ▼              ▼              ▼                        │
│         ┌────────────┐  ┌────────────┐  ┌────────────┐                │
│         │   Skills   │  │  Context   │  │ Knowledge  │                │
│         │ (Scripts)  │  │  Assembly  │  │  Retrieval │                │
│         └──────┬─────┘  └──────┬─────┘  └──────┬─────┘                │
│                │               │               │                       │
│       ┌────────┴────────┐      │      ┌────────┴────────┐             │
│       ▼                 ▼      ▼      ▼                 ▼             │
│  ┌──────────┐    ┌──────────┐     ┌────────────────────────────┐     │
│  │  lunar-  │    │ keryke-  │     │  PostgreSQL + pgvector     │     │
│  │  python  │    │   ion    │     │  (用户数据 + 向量检索)      │     │
│  └──────────┘    └──────────┘     └────────────────────────────┘     │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │               Knowledge Files (Git-versioned)                    │  │
│   │    .claude/skills/*/references/*.md  │  knowledge/*.json        │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.1 技术栈

```yaml
Frontend:      Next.js 15 (App Router, Server Components)
Agent:         Vercel AI SDK 6 (ToolLoopAgent)
LLM:           GLM 4.7 (可配置: DeepSeek V3, Gemini Pro 3, Claude)
Database:      PostgreSQL + pgvector (Neon/Supabase serverless)
Cache:         Vercel KV (optional)
Knowledge:     MD/JSON files (Git-versioned)
Compute:       Python (Vercel Functions)
```

### 2.2 为什么选择 pgvector

| 对比 | pgvector | Pinecone |
|------|----------|----------|
| **部署复杂度** | 一个数据库 | 需要额外服务 |
| **成本** | PostgreSQL 内置 | 单独计费 |
| **事务支持** | 完整 ACID | 无 |
| **关联查询** | 原生 JOIN | 需要应用层处理 |
| **适用场景** | 中小规模 (<10M vectors) | 大规模向量检索 |

---

## 三、项目目录结构

```
vibelife/
├── .claude/
│   └── skills/                          # Agent Skills 标准位置
│       ├── bazi-master/                 # 八字命理 Skill
│       │   ├── SKILL.md                 # 入口文件 (必需)
│       │   ├── scripts/
│       │   │   └── bazi.py              # 封装 lunar-python
│       │   └── references/
│       │       ├── ten-gods.md          # 十神详解
│       │       ├── patterns.md          # 格局模式
│       │       └── dayun.md             # 大运流年
│       │
│       └── astra-guide/                 # 星座占星 Skill
│           ├── SKILL.md
│           ├── scripts/
│           │   └── astro.py             # 封装 kerykeion
│           └── references/
│               ├── planets.md           # 行星含义
│               ├── houses.md            # 宫位解读
│               └── aspects.md           # 相位分析
│
├── app/                                 # Next.js App Router
│   ├── api/
│   │   ├── chat/route.ts                # AI Chat (streaming)
│   │   └── compute/
│   │       ├── bazi/route.ts            # 八字计算 API
│   │       └── astro/route.ts           # 占星计算 API
│   ├── (chat)/
│   │   └── page.tsx
│   └── layout.tsx
│
├── lib/
│   ├── agents/                          # Vercel AI SDK 6 Agents
│   │   ├── index.ts
│   │   ├── bazi-agent.ts
│   │   └── astra-agent.ts
│   ├── tools/                           # Tool definitions
│   │   ├── bazi-tools.ts
│   │   └── astra-tools.ts
│   ├── db/                              # Database
│   │   ├── schema.ts                    # Drizzle schema
│   │   └── index.ts
│   └── knowledge/                       # Context Engineering
│       ├── retriever.ts                 # pgvector 检索
│       └── indexer.ts                   # 知识索引
│
├── knowledge/                           # 知识库源文件
│   ├── bazi/
│   │   ├── theory.md
│   │   └── cases.json
│   └── astra/
│       ├── theory.md
│       └── cases.json
│
├── python/                              # Python 计算服务
│   ├── bazi_service.py
│   ├── astro_service.py
│   └── requirements.txt
│
├── drizzle/                             # Database migrations
│   └── migrations/
│
└── package.json
```

---

## 四、Skill 详细实现

### 4.1 bazi-master (八字命理)

#### SKILL.md

```markdown
---
name: bazi-master
description: Chinese BaZi (八字) birth chart analysis. Calculate Four Pillars, Ten Gods (十神), Five Elements (五行), DaYun (大运) and LiuNian (流年). Use when users mention 八字, BaZi, birth chart, 命盘, 大运, 流年, 十神, 五行, Chinese astrology, or ask about life direction using Chinese metaphysics.
license: MIT
metadata:
  author: vibelife
  version: "1.0"
  engine: lunar-python
---

# BaZi Master (八字命理大师)

## Compute Engine

Uses [lunar-python](https://github.com/6tail/lunar-python) - zero-dependency Chinese calendar and BaZi library.

## Workflow

### Step 1: Collect Birth Data

Required information:
- Birth date (公历 or 农历)
- Birth time (时辰, 0-23)
- Gender (for DaYun direction)
- Location (optional, for timezone)

### Step 2: Calculate Chart

Run the bazi calculation script:

```bash
python scripts/bazi.py --date "1990-03-15" --hour 14 --gender M --solar
```

Output includes:
- Four Pillars (四柱): 年柱, 月柱, 日柱, 时柱
- Day Master (日主) and element
- Ten Gods (十神) configuration
- Five Elements (五行) distribution
- Hidden Stems (藏干)
- Current DaYun (大运)

### Step 3: Interpret Results

For detailed interpretations:
- Ten Gods meanings: See [references/ten-gods.md](references/ten-gods.md)
- Pattern analysis: See [references/patterns.md](references/patterns.md)
- DaYun guidance: See [references/dayun.md](references/dayun.md)

### Step 4: Response Structure

1. **命盘概览** - Four Pillars + Day Master
2. **五行分析** - Element distribution and balance
3. **十神解读** - Ten Gods configuration
4. **当前运势** - Current DaYun + LiuNian
5. **建议方向** - Practical guidance

## Response Style

- Use modern, accessible language
- Avoid deterministic predictions (use "倾向于" not "一定会")
- Connect concepts to practical life decisions
- Encourage self-reflection and growth
- Respect cultural significance while being objective
```

#### scripts/bazi.py

```python
#!/usr/bin/env python3
"""
BaZi Calculator - Wrapper for lunar-python library
https://github.com/6tail/lunar-python

Usage:
    python bazi.py --date "1990-03-15" --hour 14 --gender M --solar
    python bazi.py --date "1990-02-19" --hour 8 --gender F --lunar
"""

import argparse
import json
from lunar_python import Solar, Lunar, EightChar

def calculate_bazi(year: int, month: int, day: int, hour: int, 
                   minute: int = 0, is_solar: bool = True, gender: str = "M") -> dict:
    """
    Calculate complete BaZi chart using lunar-python.
    
    Args:
        year, month, day: Birth date
        hour: Birth hour (0-23)
        minute: Birth minute
        is_solar: True for solar/公历, False for lunar/农历
        gender: "M" for male, "F" for female
    
    Returns:
        Complete BaZi chart data
    """
    # Create date object
    if is_solar:
        solar = Solar.fromYmdHms(year, month, day, hour, minute, 0)
        lunar = solar.getLunar()
    else:
        lunar = Lunar.fromYmdHms(year, month, day, hour, minute, 0)
        solar = lunar.getSolar()
    
    # Get EightChar (八字)
    ba = lunar.getEightChar()
    
    # Four Pillars (四柱)
    four_pillars = {
        "year": {
            "gan": ba.getYearGan(),
            "zhi": ba.getYearZhi(),
            "pillar": ba.getYear(),
            "nayin": ba.getYearNaYin(),
            "ten_god_gan": ba.getYearShiShenGan(),
            "hidden_stems": list(ba.getYearHideGan())
        },
        "month": {
            "gan": ba.getMonthGan(),
            "zhi": ba.getMonthZhi(),
            "pillar": ba.getMonth(),
            "nayin": ba.getMonthNaYin(),
            "ten_god_gan": ba.getMonthShiShenGan(),
            "hidden_stems": list(ba.getMonthHideGan())
        },
        "day": {
            "gan": ba.getDayGan(),
            "zhi": ba.getDayZhi(),
            "pillar": ba.getDay(),
            "nayin": ba.getDayNaYin(),
            "hidden_stems": list(ba.getDayHideGan())
        },
        "hour": {
            "gan": ba.getTimeGan(),
            "zhi": ba.getTimeZhi(),
            "pillar": ba.getTime(),
            "nayin": ba.getTimeNaYin(),
            "ten_god_gan": ba.getTimeShiShenGan(),
            "hidden_stems": list(ba.getTimeHideGan())
        }
    }
    
    # Day Master (日主)
    day_master = ba.getDayGan()
    element_map = {
        "甲": "木", "乙": "木", "丙": "火", "丁": "火",
        "戊": "土", "己": "土", "庚": "金", "辛": "金",
        "壬": "水", "癸": "水"
    }
    
    # Five Elements Distribution (五行分布)
    five_elements = {"木": 0, "火": 0, "土": 0, "金": 0, "水": 0}
    zhi_elements = {
        "子": "水", "丑": "土", "寅": "木", "卯": "木",
        "辰": "土", "巳": "火", "午": "火", "未": "土",
        "申": "金", "酉": "金", "戌": "土", "亥": "水"
    }
    
    # Count from Heavenly Stems
    for gan in [ba.getYearGan(), ba.getMonthGan(), ba.getDayGan(), ba.getTimeGan()]:
        five_elements[element_map[gan]] += 1
    
    # Count from Earthly Branches
    for zhi in [ba.getYearZhi(), ba.getMonthZhi(), ba.getDayZhi(), ba.getTimeZhi()]:
        five_elements[zhi_elements[zhi]] += 1
    
    # DaYun (大运)
    is_male = gender.upper() == "M"
    yun = ba.getYun(is_male)
    dayun_list = []
    for dy in yun.getDaYun()[:10]:  # First 10 periods
        dayun_list.append({
            "start_age": dy.getStartAge(),
            "end_age": dy.getEndAge(),
            "gan_zhi": dy.getGanZhi(),
            "start_year": dy.getStartYear(),
            "ten_god": ba.getShiShen(dy.getGanZhi()[0]) if dy.getGanZhi() else ""
        })
    
    return {
        "birth": {
            "solar": solar.toYmd(),
            "lunar": f"{lunar.getYearInChinese()}年{lunar.getMonthInChinese()}月{lunar.getDayInChinese()}",
            "zodiac": lunar.getYearShengXiao(),
            "constellation": solar.getXingZuo()
        },
        "four_pillars": four_pillars,
        "day_master": {
            "gan": day_master,
            "element": element_map[day_master],
            "yin_yang": "阳" if day_master in "甲丙戊庚壬" else "阴"
        },
        "five_elements": five_elements,
        "dayun": {
            "direction": "顺行" if is_male else "逆行",
            "start_age": yun.getStartYear() - solar.getYear(),
            "periods": dayun_list
        },
        "special": {
            "ming_gong": ba.getMingGong(),
            "tai_yuan": ba.getTaiYuan(),
            "shen_gong": ba.getShenGong()
        }
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate BaZi chart")
    parser.add_argument("--date", required=True, help="Birth date (YYYY-MM-DD)")
    parser.add_argument("--hour", type=int, required=True, help="Birth hour (0-23)")
    parser.add_argument("--minute", type=int, default=0, help="Birth minute")
    parser.add_argument("--gender", choices=["M", "F"], required=True)
    parser.add_argument("--solar", action="store_true", help="Use solar calendar")
    parser.add_argument("--lunar", action="store_true", help="Use lunar calendar")
    
    args = parser.parse_args()
    year, month, day = map(int, args.date.split("-"))
    is_solar = not args.lunar
    
    result = calculate_bazi(year, month, day, args.hour, args.minute, is_solar, args.gender)
    print(json.dumps(result, ensure_ascii=False, indent=2))
```

---

### 4.2 astra-guide (星座占星)

#### SKILL.md

```markdown
---
name: astra-guide
description: Western astrology natal chart analysis using Swiss Ephemeris. Calculate planetary positions, houses, aspects. Generate SVG charts. Use when users mention astrology, zodiac, horoscope, birth chart, natal chart, 星座, 星盘, planets, aspects, houses, Mercury retrograde, synastry, or ask about astrological compatibility.
license: MIT
metadata:
  author: vibelife
  version: "1.0"
  engine: kerykeion
---

# Astra Guide (星座占星指南)

## Compute Engine

Uses [kerykeion](https://github.com/g-battaglia/kerykeion) - Python astrology library with AI integration support, built on Swiss Ephemeris.

## Workflow

### Step 1: Collect Birth Data

Required:
- Date of birth
- Time of birth (for Ascendant/Houses)
- Birth location (city/country or coordinates)

### Step 2: Calculate Natal Chart

Run the astro calculation script:

```bash
python scripts/astro.py --name "User" --date "1990-07-15" --time "10:30" --city "Beijing" --country "CN"
```

Or with coordinates:
```bash
python scripts/astro.py --name "User" --date "1990-07-15" --time "10:30" --lng 116.4074 --lat 39.9042 --tz "Asia/Shanghai"
```

Output includes:
- Sun, Moon, Ascendant positions (Big Three)
- All planetary positions with signs and degrees
- House cusps (Placidus default)
- Major aspects with orbs
- Element/Modality distribution

### Step 3: Generate Chart SVG (Optional)

```bash
python scripts/astro.py --name "User" --date "1990-07-15" --time "10:30" --city "Beijing" --country "CN" --svg
```

### Step 4: Interpret Results

For detailed interpretations:
- Planet meanings: See [references/planets.md](references/planets.md)
- House meanings: See [references/houses.md](references/houses.md)
- Aspect analysis: See [references/aspects.md](references/aspects.md)

### Step 5: Response Structure

1. **Big Three** - Sun, Moon, Rising signs
2. **Planetary Positions** - Key planets with signs/houses
3. **Major Aspects** - Important planetary configurations
4. **Element Balance** - Fire/Earth/Air/Water distribution
5. **Insights** - Practical interpretation

## Response Style

- Balance archetypal symbolism with practical insights
- Acknowledge astrology as reflective tool, not deterministic
- Use inclusive, empowering language
- Connect planetary energies to daily life
```

#### scripts/astro.py

```python
#!/usr/bin/env python3
"""
Astrology Calculator - Wrapper for kerykeion library
https://github.com/g-battaglia/kerykeion

Usage:
    python astro.py --name "User" --date "1990-07-15" --time "10:30" --city "Beijing" --country "CN"
    python astro.py --name "User" --date "1990-07-15" --time "10:30" --lng 116.4074 --lat 39.9042 --tz "Asia/Shanghai"
"""

import argparse
import json
from pathlib import Path
from kerykeion import AstrologicalSubject
from kerykeion.aspects import NatalAspects
from kerykeion.charts.kerykeion_chart_svg import KerykeionChartSVG

def calculate_natal_chart(name: str, year: int, month: int, day: int,
                          hour: int, minute: int,
                          city: str = None, country: str = None,
                          lng: float = None, lat: float = None, tz_str: str = None) -> dict:
    """
    Calculate natal chart using kerykeion.
    """
    # Create subject
    if lng is not None and lat is not None and tz_str is not None:
        subject = AstrologicalSubject(
            name, year, month, day, hour, minute,
            lng=lng, lat=lat, tz_str=tz_str, online=False
        )
    else:
        subject = AstrologicalSubject(
            name, year, month, day, hour, minute,
            city=city, nation=country, online=True
        )
    
    # Extract planetary positions
    planets = {}
    planet_names = ['sun', 'moon', 'mercury', 'venus', 'mars', 
                    'jupiter', 'saturn', 'uranus', 'neptune', 'pluto']
    
    for pname in planet_names:
        planet = getattr(subject, pname)
        planets[pname] = {
            "sign": planet.sign,
            "degree": round(planet.position, 2),
            "house": planet.house,
            "retrograde": planet.retrograde
        }
    
    # Points
    points = {
        "ascendant": {
            "sign": subject.first_house.sign,
            "degree": round(subject.first_house.position, 2)
        },
        "mc": {
            "sign": subject.tenth_house.sign,
            "degree": round(subject.tenth_house.position, 2)
        }
    }
    
    # Houses
    house_attrs = ['first', 'second', 'third', 'fourth', 'fifth', 'sixth',
                   'seventh', 'eighth', 'ninth', 'tenth', 'eleventh', 'twelfth']
    houses = []
    for i, attr in enumerate(house_attrs, 1):
        house = getattr(subject, f"{attr}_house")
        houses.append({
            "number": i,
            "sign": house.sign,
            "degree": round(house.position, 2)
        })
    
    # Aspects
    natal_aspects = NatalAspects(subject)
    aspects = []
    for asp in natal_aspects.all_aspects:
        if asp.is_major:
            aspects.append({
                "planet1": asp.p1_name,
                "planet2": asp.p2_name,
                "aspect": asp.aspect,
                "orb": round(asp.orb, 2)
            })
    
    # Element distribution
    elements = {"fire": 0, "earth": 0, "air": 0, "water": 0}
    modalities = {"cardinal": 0, "fixed": 0, "mutable": 0}
    
    element_map = {
        "Ari": "fire", "Leo": "fire", "Sag": "fire",
        "Tau": "earth", "Vir": "earth", "Cap": "earth",
        "Gem": "air", "Lib": "air", "Aqu": "air",
        "Can": "water", "Sco": "water", "Pis": "water"
    }
    modality_map = {
        "Ari": "cardinal", "Can": "cardinal", "Lib": "cardinal", "Cap": "cardinal",
        "Tau": "fixed", "Leo": "fixed", "Sco": "fixed", "Aqu": "fixed",
        "Gem": "mutable", "Vir": "mutable", "Sag": "mutable", "Pis": "mutable"
    }
    
    for pdata in planets.values():
        sign_abbr = pdata["sign"][:3]
        if sign_abbr in element_map:
            elements[element_map[sign_abbr]] += 1
        if sign_abbr in modality_map:
            modalities[modality_map[sign_abbr]] += 1
    
    return {
        "name": name,
        "birth": {
            "date": f"{year}-{month:02d}-{day:02d}",
            "time": f"{hour:02d}:{minute:02d}",
            "location": city if city else f"{lat}, {lng}",
            "timezone": subject.tz_str
        },
        "big_three": {
            "sun": planets["sun"]["sign"],
            "moon": planets["moon"]["sign"],
            "rising": points["ascendant"]["sign"]
        },
        "planets": planets,
        "points": points,
        "houses": houses,
        "aspects": aspects,
        "elements": elements,
        "modalities": modalities
    }

def generate_svg(subject_data: dict, output_dir: str = "/tmp") -> str:
    """Generate SVG chart."""
    # Recreate subject for SVG generation
    birth = subject_data["birth"]
    date_parts = birth["date"].split("-")
    time_parts = birth["time"].split(":")
    
    subject = AstrologicalSubject(
        subject_data["name"],
        int(date_parts[0]), int(date_parts[1]), int(date_parts[2]),
        int(time_parts[0]), int(time_parts[1]),
        tz_str=birth["timezone"], online=False
    )
    
    chart = KerykeionChartSVG(subject, chart_type="Natal")
    chart.makeSVG()
    
    return f"{output_dir}/{subject_data['name']}_natal_chart.svg"

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate natal chart")
    parser.add_argument("--name", required=True)
    parser.add_argument("--date", required=True, help="Birth date (YYYY-MM-DD)")
    parser.add_argument("--time", required=True, help="Birth time (HH:MM)")
    parser.add_argument("--city", help="Birth city")
    parser.add_argument("--country", help="Country code (e.g., CN, US)")
    parser.add_argument("--lng", type=float, help="Longitude")
    parser.add_argument("--lat", type=float, help="Latitude")
    parser.add_argument("--tz", help="Timezone string")
    parser.add_argument("--svg", action="store_true", help="Generate SVG")
    
    args = parser.parse_args()
    
    year, month, day = map(int, args.date.split("-"))
    hour, minute = map(int, args.time.split(":"))
    
    result = calculate_natal_chart(
        args.name, year, month, day, hour, minute,
        city=args.city, country=args.country,
        lng=args.lng, lat=args.lat, tz_str=args.tz
    )
    
    if args.svg:
        svg_path = generate_svg(result)
        result["svg_path"] = svg_path
    
    print(json.dumps(result, ensure_ascii=False, indent=2))
```

---

## 五、Vercel AI SDK 6 实现

### 5.1 Tool 定义

#### lib/tools/bazi-tools.ts

```typescript
import { tool } from 'ai';
import { z } from 'zod';

export const baziBirthChartTool = tool({
  description: 'Calculate Chinese BaZi birth chart. Returns four pillars, day master, ten gods, five elements, and DaYun periods.',
  parameters: z.object({
    year: z.number().describe('Birth year'),
    month: z.number().min(1).max(12).describe('Birth month'),
    day: z.number().min(1).max(31).describe('Birth day'),
    hour: z.number().min(0).max(23).describe('Birth hour'),
    minute: z.number().default(0),
    isSolar: z.boolean().default(true).describe('true for solar/公历'),
    gender: z.enum(['M', 'F']).describe('M=male, F=female')
  }),
  execute: async (params) => {
    const res = await fetch(`${process.env.COMPUTE_API_URL}/bazi`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(params)
    });
    return res.json();
  }
});

export const baziTools = {
  calculateBirthChart: baziBirthChartTool
};
```

#### lib/tools/astra-tools.ts

```typescript
import { tool } from 'ai';
import { z } from 'zod';

export const astraNatalChartTool = tool({
  description: 'Calculate Western astrology natal chart. Returns planetary positions, houses, aspects, and element distribution.',
  parameters: z.object({
    name: z.string(),
    year: z.number(),
    month: z.number().min(1).max(12),
    day: z.number().min(1).max(31),
    hour: z.number().min(0).max(23),
    minute: z.number().default(0),
    city: z.string().optional(),
    country: z.string().optional(),
    lng: z.number().optional(),
    lat: z.number().optional(),
    tzStr: z.string().optional(),
    generateSvg: z.boolean().default(false)
  }),
  execute: async (params) => {
    const res = await fetch(`${process.env.COMPUTE_API_URL}/astro`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(params)
    });
    return res.json();
  }
});

export const astraTools = {
  calculateNatalChart: astraNatalChartTool
};
```

### 5.2 Agent 定义

#### lib/agents/bazi-agent.ts

```typescript
import { ToolLoopAgent } from 'ai';
import { createOpenAI } from '@ai-sdk/openai';
import { baziTools } from '../tools/bazi-tools';
import { retrieveKnowledge } from '../knowledge/retriever';

// GLM 4.7 via OpenAI-compatible API
const glm = createOpenAI({
  baseURL: process.env.GLM_API_BASE_URL || 'https://open.bigmodel.cn/api/paas/v4',
  apiKey: process.env.GLM_API_KEY!
});

const model = glm('glm-4-plus');

const SYSTEM_PROMPT = `你是 VibeLife 的八字命理大师。

## 核心能力
使用 lunar-python 进行精确的八字计算：四柱排盘、十神分析、五行分布、大运流年。

## 交互风格
- 现代易懂的语言
- 避免宿命论（用"倾向于"而非"一定会"）
- 联系实际生活
- 鼓励自我反思

## 回复结构
1. 命盘概览 - 四柱和日主
2. 五行分析 - 分布和平衡
3. 十神解读 - 性格特质
4. 当前运势 - 大运流年
5. 建议方向 - 实用指导

当前日期: ${new Date().toISOString().split('T')[0]}`;

export const baziAgent = new ToolLoopAgent({
  model,
  system: SYSTEM_PROMPT,
  tools: baziTools,
  maxSteps: 5,
  
  async onStepStart({ messages }) {
    const lastUserMsg = messages.filter(m => m.role === 'user').pop();
    if (lastUserMsg) {
      const knowledge = await retrieveKnowledge('bazi', String(lastUserMsg.content));
      if (knowledge) {
        return { system: SYSTEM_PROMPT + `\n\n## 参考知识\n${knowledge}` };
      }
    }
    return {};
  }
});
```

---

## 六、数据库设计 (PostgreSQL + pgvector)

### 6.1 Schema

```sql
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vibe_id VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    display_name VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User birth profiles
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    birth_year INT,
    birth_month INT,
    birth_day INT,
    birth_hour INT,
    birth_minute INT DEFAULT 0,
    birth_location VARCHAR(255),
    birth_lng DECIMAL(10, 6),
    birth_lat DECIMAL(10, 6),
    birth_timezone VARCHAR(50),
    is_solar BOOLEAN DEFAULT TRUE,
    gender VARCHAR(1),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversations
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    skill VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    tool_calls JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Knowledge chunks (for pgvector retrieval)
CREATE TABLE knowledge_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    skill VARCHAR(50) NOT NULL,
    source VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1536),  -- OpenAI ada-002 dimension
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vector similarity search index
CREATE INDEX ON knowledge_chunks 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Indexes
CREATE INDEX idx_conversations_user ON conversations(user_id);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_knowledge_skill ON knowledge_chunks(skill);
```

### 6.2 Knowledge Retriever (pgvector)

#### lib/knowledge/retriever.ts

```typescript
import { neon } from '@neondatabase/serverless';
import { embed } from 'ai';
import { createOpenAI } from '@ai-sdk/openai';

const sql = neon(process.env.DATABASE_URL!);

const embeddingModel = createOpenAI({
  apiKey: process.env.OPENAI_API_KEY!
})('text-embedding-ada-002');

export async function retrieveKnowledge(
  skill: string,
  query: string,
  topK: number = 3,
  threshold: number = 0.7
): Promise<string | null> {
  try {
    // Generate embedding for query
    const { embedding } = await embed({
      model: embeddingModel,
      value: query
    });

    // Query pgvector for similar chunks
    const results = await sql`
      SELECT 
        source,
        content,
        1 - (embedding <=> ${JSON.stringify(embedding)}::vector) as similarity
      FROM knowledge_chunks
      WHERE skill = ${skill}
        AND 1 - (embedding <=> ${JSON.stringify(embedding)}::vector) > ${threshold}
      ORDER BY embedding <=> ${JSON.stringify(embedding)}::vector
      LIMIT ${topK}
    `;

    if (results.length === 0) return null;

    return results
      .map(r => `### ${r.source}\n${r.content}`)
      .join('\n\n');
  } catch (error) {
    console.error('Knowledge retrieval error:', error);
    return null;
  }
}
```

#### lib/knowledge/indexer.ts

```typescript
import { neon } from '@neondatabase/serverless';
import { embedMany } from 'ai';
import { createOpenAI } from '@ai-sdk/openai';
import fs from 'fs/promises';
import path from 'path';

const sql = neon(process.env.DATABASE_URL!);

const embeddingModel = createOpenAI({
  apiKey: process.env.OPENAI_API_KEY!
})('text-embedding-ada-002');

export async function indexKnowledge(skill: string) {
  const knowledgeDir = path.join(process.cwd(), 'knowledge', skill);
  const files = await getMdFiles(knowledgeDir);
  
  const chunks: Array<{ skill: string; source: string; content: string }> = [];
  
  for (const file of files) {
    const content = await fs.readFile(file, 'utf-8');
    const relativePath = path.relative(knowledgeDir, file);
    
    // Split into chunks (~500 tokens each)
    const paragraphs = content.split(/\n\n+/);
    let currentChunk = '';
    
    for (const para of paragraphs) {
      if ((currentChunk + para).length > 1500) {
        if (currentChunk.trim()) {
          chunks.push({ skill, source: relativePath, content: currentChunk.trim() });
        }
        currentChunk = para;
      } else {
        currentChunk += '\n\n' + para;
      }
    }
    if (currentChunk.trim()) {
      chunks.push({ skill, source: relativePath, content: currentChunk.trim() });
    }
  }
  
  // Generate embeddings in batches
  const batchSize = 50;
  for (let i = 0; i < chunks.length; i += batchSize) {
    const batch = chunks.slice(i, i + batchSize);
    
    const { embeddings } = await embedMany({
      model: embeddingModel,
      values: batch.map(c => c.content)
    });
    
    // Insert into pgvector
    for (let j = 0; j < batch.length; j++) {
      await sql`
        INSERT INTO knowledge_chunks (skill, source, content, embedding)
        VALUES (${batch[j].skill}, ${batch[j].source}, ${batch[j].content}, ${JSON.stringify(embeddings[j])}::vector)
      `;
    }
    
    console.log(`Indexed ${i + batch.length}/${chunks.length} chunks for ${skill}`);
  }
}

async function getMdFiles(dir: string): Promise<string[]> {
  const files: string[] = [];
  const entries = await fs.readdir(dir, { withFileTypes: true });
  
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...await getMdFiles(fullPath));
    } else if (entry.name.endsWith('.md')) {
      files.push(fullPath);
    }
  }
  return files;
}
```

---

## 七、API Routes

### 7.1 Chat Endpoint

#### app/api/chat/route.ts

```typescript
import { baziAgent } from '@/lib/agents/bazi-agent';
import { astraAgent } from '@/lib/agents/astra-agent';

export const runtime = 'edge';

export async function POST(req: Request) {
  const { messages, skill } = await req.json();
  
  const agent = skill === 'bazi' ? baziAgent : astraAgent;
  const stream = await agent.stream({ messages });
  
  return stream.toDataStreamResponse();
}
```

### 7.2 Python Compute API

#### python/main.py

```python
from fastapi import FastAPI
from pydantic import BaseModel
from typing import Optional
from bazi_service import calculate_bazi
from astro_service import calculate_natal_chart

app = FastAPI(title="VibeLife Compute API")

class BaziRequest(BaseModel):
    year: int
    month: int
    day: int
    hour: int
    minute: int = 0
    isSolar: bool = True
    gender: str = "M"

class AstroRequest(BaseModel):
    name: str
    year: int
    month: int
    day: int
    hour: int
    minute: int = 0
    city: Optional[str] = None
    country: Optional[str] = None
    lng: Optional[float] = None
    lat: Optional[float] = None
    tzStr: Optional[str] = None
    generateSvg: bool = False

@app.post("/bazi")
async def bazi(req: BaziRequest):
    return calculate_bazi(
        req.year, req.month, req.day, req.hour, req.minute,
        req.isSolar, req.gender
    )

@app.post("/astro")
async def astro(req: AstroRequest):
    return calculate_natal_chart(
        req.name, req.year, req.month, req.day, req.hour, req.minute,
        city=req.city, country=req.country,
        lng=req.lng, lat=req.lat, tz_str=req.tzStr
    )

@app.get("/health")
async def health():
    return {"status": "ok"}
```

---

## 八、环境配置

### 8.1 环境变量

```env
# LLM - GLM 4.7 (default)
GLM_API_BASE_URL=https://open.bigmodel.cn/api/paas/v4
GLM_API_KEY=xxx

# Alternative: DeepSeek V3
# DEEPSEEK_API_BASE_URL=https://api.deepseek.com/v1
# DEEPSEEK_API_KEY=xxx

# Database (PostgreSQL + pgvector)
DATABASE_URL=postgresql://user:pass@host:5432/vibelife?sslmode=require

# Embedding (for pgvector)
OPENAI_API_KEY=xxx

# Python Compute API
COMPUTE_API_URL=https://vibelife-compute.vercel.app
```

### 8.2 Python Requirements

```txt
# python/requirements.txt
lunar-python>=0.3.0
kerykeion>=5.0.0
fastapi>=0.110.0
uvicorn>=0.27.0
```

---

## 九、项目构建流程

### 9.1 初始化

```bash
# 1. 创建 Next.js 项目
npx create-next-app@latest vibelife --typescript --tailwind --app

# 2. 安装依赖
cd vibelife
npm install ai @ai-sdk/openai zod
npm install @neondatabase/serverless drizzle-orm
npm install -D drizzle-kit

# 3. 创建目录结构
mkdir -p .claude/skills/{bazi-master,astra-guide}/{scripts,references}
mkdir -p lib/{agents,tools,knowledge,db}
mkdir -p knowledge/{bazi,astra}
mkdir -p python

# 4. Python 环境
cd python
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 9.2 数据库初始化

```bash
# 生成迁移
npx drizzle-kit generate

# 执行迁移
npx drizzle-kit migrate

# 索引知识库
npm run index-knowledge
```

### 9.3 部署

```bash
# Vercel 部署
vercel deploy --prod

# 设置环境变量
vercel env add GLM_API_KEY
vercel env add DATABASE_URL
vercel env add OPENAI_API_KEY
```

---

## 十、关键设计决策总结

| 决策 | 选择 | 理由 |
|------|------|------|
| **计算引擎** | lunar-python, kerykeion | GitHub 验证，准确可靠 |
| **Agent 框架** | Vercel AI SDK 6 | TypeScript-first，原生 streaming |
| **数据库** | PostgreSQL + pgvector | 一库搞定关系数据+向量检索 |
| **知识库** | MD/JSON + pgvector | 简单高效，Git 版本控制 |
| **Context 策略** | Progressive Disclosure | 按需加载，高效利用上下文 |
| **部署** | Vercel | 一体化 serverless |

---

**Document Version**: 3.0  
**Last Updated**: January 2026