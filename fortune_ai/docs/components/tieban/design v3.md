西方占星（胜出）： 这是一个连续时间系统。

理由： 地球自转导致星盘的四个轴点（上升ASC、中天MC）每 4分钟 移动 1度。

机制： 我们只需要计算：“在哪一个精确时刻，太阳弧推运的木星（代表扩张/喜事）精确到了0.00度合相了中天（代表事业），从而对应了用户2018年5月12日的升职？”

这本质上是一个纯粹的几何逆运算数学问题，非常适合计算机求解，且具备“秒级”的理论精度。

2. 用户输入数据标准定义
为了实现自动化反推，系统需要用户提供两类核心数据。输入格式必须标准化，以减少“模糊语言”带来的计算噪声。

A. 基础锚点信息（Base Anchors）
出生日期： YYYY-MM-DD

出生地点： City, Country (系统将自动转换为经纬度)

模糊时间窗口： Start Time - End Time (例如：14:00 - 16:00)

说明： 窗口越小，计算越快，准确率越高。如果完全不知道时间，建议先通过定性问题（如外貌、性格）锁定大致区间（但这超出了纯数学校准的范畴）。

B. 生命周期事件集（Life Events Dataset）
这是校准的核心燃料。我们需要用户回忆过去发生的、改变人生轨迹的重大事件。

输入格式要求： 一个标准的 JSON 对象列表，包含 Date (日期), Type (事件类型), Impact (主观影响).

必须输入的事件 (High Priority),输入格式,精度要求,为什么需要它？
结婚 / 确立伴侣关系,YYYY-MM-DD,精确到日,强力校准 下降点 (DSC) 和 中天 (MC)。婚姻往往伴随轴点被金星、木星或太阳弧触发。
子女出生 (第一胎最关键),YYYY-MM-DD,精确到日,强力校准 第5宫 和 中天/天底轴线。
近亲亡故 (父母/兄弟/伴侣),YYYY-MM-DD,精确到日,强力校准 天底 (IC) 和 中天 (MC)。土星、冥王星的硬相位通常非常准时。
重大搬家 / 移民,YYYY-MM,精确到月,校准 天底 (IC) (代表家庭/根基)。
职业剧变 (升职/失业/创业),YYYY-MM,精确到月,校准 中天 (MC) (代表社会地位)。
重大意外 / 手术 / 受伤,YYYY-MM-DD,精确到日,校准 上升点 (ASC) (代表肉体)。火星/天王星的行运通常精确到度。

3. 系统架构设计：反向几何搜索引擎该系统的核心逻辑不是“预测”，而是“拟合”（Fitting）。我们寻找一个 $t$ (出生时间)，使得该时间生成的星盘 $Chart(t)$ 对所有历史事件 $E$ 的解释误差 $Error$ 最小。技术栈推荐核心计算库： pyswisseph (C级精度，处理星体位置)逻辑层： Python优化算法： 暴力扫描 (Brute Force) + 局部爬山算法 (Hill Climbing)核心算法流程图第一步：生成时间切片在用户提供的 14:00 - 16:00 窗口内，以 30秒 为步长，生成 240 个假设出生时间点：$T_{1}, T_{2},..., T_{240}$。第二步：事件征象映射 (Significator Mapping)建立一个规则库，定义什么星体运动对应什么人类事件。这是系统的知识库核心。规则示例：IF Event = "Marriage" THEN Check: Solar Arc Venus/Jupiter/Sun to ASC/DSC/MC/IC (Conjunction/Square/Opposition).IF Event = "Child Birth" THEN Check: Solar Arc Jupiter/Moon to 5th House Cusp/Ruler.IF Event = "Accident" THEN Check: Transit Mars/Uranus to ASC.第三步：逆向计算循环对于每一个假设时间 $T_{i}$：计算该时刻的基础星盘（特别是 ASC, MC, IC, DSC 四个轴点的度数）。遍历用户输入的每一个事件 $E_{j}$：计算事件发生日期的 太阳弧 (Solar Arc) 增量。将全盘星体向前推进该弧度。检测：推进后的星体是否与 $T_{i}$ 时刻的轴点形成 硬相位 (0°, 90°, 180°)。检测：事件发生当天的 外行星行运 (Transits) 是否合相了 $T_{i}$ 时刻的轴点。评分 (Scoring)：如果发生精确相位 (误差 < 0.5度)，$Score += 10$。如果发生宽相位 (误差 < 1.0度)，$Score += 5$。如果没有相位，$Score += 0$。第四步：寻找峰值绘制所有 240 个时间点的得分曲线。得分最高的时间点 $T_{best}$ 即为校准后的出生时间。如果出现双峰（两个时间点得分接近），输出这两个时间点供用户确认（例如：“你是长脸型(A)还是圆脸型(B)？”）。4. 最小可行产品 (MVP) 代码逻辑伪代码

# 伪代码：极简精确校准系统核心逻辑

def rectify_birth_time(user_profile, life_events):
    # 1. 设定搜索范围：例如 1990-05-01 14:00 到 16:00
    search_range = generate_time_steps(user_profile['start_time'], user_profile['end_time'], step_seconds=30)
    
    results =

    # 2. 遍历每一个可能的出生时间
    for hypothetical_birth_time in search_range:
        total_score = 0
        
        # 计算该假设时间的本命轴点 (ASC, MC)
        natal_angles = calculate_angles(hypothetical_birth_time, user_profile['lat'], user_profile['lon'])
        
        # 3. 遍历每一个生命事件
        for event in life_events:
            event_date = event['date']
            event_type = event['type']
            
            # --- 算法 A: 太阳弧推运 (Solar Arc) ---
            # 计算从出生到事件日的太阳弧度数 (约 1度/年)
            arc_degrees = get_solar_arc(hypothetical_birth_time, event_date)
            
            # 检查关键星体推进后是否击中轴点
            # 结婚查金星(Venus)，工作查木星(Jupiter)/土星(Saturn)
            target_planets = get_significators(event_type) 
            
            for planet in target_planets:
                natal_planet_pos = get_planet_pos(hypothetical_birth_time, planet)
                directed_pos = natal_planet_pos + arc_degrees
                
                # 计算与轴点的相位误差 (仅考虑合相、刑、冲)
                error = calculate_aspect_error(directed_pos, natal_angles)
                
                if error < 1.0: # 容许度 1 度以内
                    # 误差越小，得分越高 (高斯函数)
                    score = 10 * (1 - error) 
                    total_score += score

            # --- 算法 B: 外行星行运 (Transits) ---
            # 检查事件发生当天，天上的土星/天王星/冥王星是否正好压在轴点上
            transit_planets =
            current_sky_pos = get_planetary_positions(event_date)
            
            for t_planet in transit_planets:
                error = calculate_conjunction_error(current_sky_pos[t_planet], natal_angles)
                if error < 1.0:
                    total_score += 5 * (1 - error) # 行运权重略低于太阳弧

        results.append({
            'time': hypothetical_birth_time,
            'score': total_score
        })

    # 4. 返回得分最高的时间
    best_match = max(results, key=lambda x: x['score'])
    return best_match