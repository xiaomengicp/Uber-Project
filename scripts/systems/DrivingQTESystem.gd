# DrivingQTESystem.gd - 修复版本：解决属性赋值问题
extends Node
class_name DrivingQTESystem

# QTE事件类型枚举
enum QTEType {
    RED_LIGHT_BRAKE,
    HEAVY_WIND_WINDOW,
    RAIN_WIPERS,
    NOISY_AREA,
    PEDESTRIAN_BRAKE,
    TRAFFIC_JAM_MUSIC,
    URGENT_CALL,
}

# 简化的QTE事件数据结构 - 使用Dictionary而不是类
# 这样避免了GDScript内部类的属性赋值问题
var qte_event_template = {
    "type": QTEType.RED_LIGHT_BRAKE,
    "ai_prompt": "",
    "countdown_time": 0.0,
    "expected_actions": [],
    "success_feedback": "",
    "failure_feedback": "",
    "timeout_feedback": "",
    "npc_positive_reaction": "",
    "npc_negative_reaction": "",
    "economic_penalty": 0,
    "attribute_effects_success": {},
    "attribute_effects_failure": {}
}

# 信号定义
signal qte_event_started(event: Dictionary)
signal qte_event_completed(event: Dictionary, success: bool)
signal ai_assistant_speaks(message: String, urgent: bool)

# QTE状态
var current_event: Dictionary = {}
var is_qte_active: bool = false
var countdown_timer: float = 0.0
var event_resolved: bool = false

# 事件触发控制
var events_this_trip: int = 0
var max_events_per_trip: int = 2
var event_probability: float = 0.4
var min_event_interval: float = 15.0
var last_event_time: float = 0.0

# 可用的QTE事件
var available_events: Array = []

func _ready():
    setup_qte_events()
    print("✅ 驾驶QTE系统初始化完成 - 使用Dictionary事件")

func _process(delta):
    if is_qte_active and not current_event.is_empty() and not event_resolved:
        countdown_timer -= delta
        if countdown_timer <= 0.0:
            handle_qte_timeout()

func create_qte_event(data: Dictionary) -> Dictionary:
    """创建QTE事件 - 使用Dictionary模板"""
    var event = qte_event_template.duplicate(true)
    for key in data.keys():
        if key in event:
            event[key] = data[key]
    return event

func setup_qte_events():
    
    # 强制设置触发参数
    event_probability = 0.8  # 80%概率
    min_event_interval = 3.0  # 3秒间隔
    max_events_per_trip = 3   # 每次行程最多3个事件
    
    print("🎯 QTE触发参数设置:")
    print("   event_probability: ", event_probability)
    print("   min_event_interval: ", min_event_interval)
    print("   max_events_per_trip: ", max_events_per_trip)


    """设置所有QTE事件 - 使用Dictionary方式"""
    available_events.clear()
    
    # 红绿灯刹车事件
    var red_light = create_qte_event({
        "type": QTEType.RED_LIGHT_BRAKE,
        "ai_prompt": "前方红灯，请减速",
        "countdown_time": 4.0,
        "expected_actions": ["smooth_driving"],
        "success_feedback": "好的，安全停车",
        "failure_feedback": "闯红灯了！注意安全",
        "timeout_feedback": "反应太慢，差点闯红灯",
        "npc_positive_reaction": "司机很守规矩呢",
        "npc_negative_reaction": "刚才好危险！",
        "economic_penalty": 200,
        "attribute_effects_success": {"pressure": -0.2, "empathy": 0.1},
        "attribute_effects_failure": {"pressure": 0.8, "empathy": -0.3}
    })
    available_events.append(red_light)
    
    # 大风关窗事件
    var heavy_wind = create_qte_event({
        "type": QTEType.HEAVY_WIND_WINDOW,
        "ai_prompt": "外面风很大，建议关窗",
        "countdown_time": 5.0,
        "expected_actions": ["close_window"],
        "success_feedback": "车内安静多了",
        "failure_feedback": "风声影响对话",
        "timeout_feedback": "没有关窗，车内有点吵",
        "npc_positive_reaction": "这样舒服多了，谢谢",
        "npc_negative_reaction": "有点吵，能关下窗吗？",
        "attribute_effects_success": {"empathy": 0.3, "self_connection": 0.1},
        "attribute_effects_failure": {"pressure": 0.2}
    })
    available_events.append(heavy_wind)
    
    # 下雨事件
    var rain_event = create_qte_event({
        "type": QTEType.RAIN_WIPERS,
        "ai_prompt": "开始下雨了，注意安全",
        "countdown_time": 4.0,
        "expected_actions": ["smooth_driving", "close_window"],
        "success_feedback": "雨天驾驶很稳当",
        "failure_feedback": "雨天路滑，要小心",
        "timeout_feedback": "雨天没有调整驾驶方式",
        "npc_positive_reaction": "雨天开车确实要小心",
        "npc_negative_reaction": "这个天气有点担心安全",
        "attribute_effects_success": {"pressure": -0.3, "empathy": 0.2},
        "attribute_effects_failure": {"pressure": 0.5}
    })
    available_events.append(rain_event)
    
    # 噪音区域事件
    var noisy_area = create_qte_event({
        "type": QTEType.NOISY_AREA,
        "ai_prompt": "经过施工区域，比较嘈杂",
        "countdown_time": 4.0,
        "expected_actions": ["close_window", "music_soothing"],
        "success_feedback": "处理得当，环境安静了",
        "failure_feedback": "外界噪音比较干扰",
        "timeout_feedback": "施工噪音有点影响交流",
        "npc_positive_reaction": "这样好多了",
        "npc_negative_reaction": "太吵了，有点难受",
        "attribute_effects_success": {"empathy": 0.3},
        "attribute_effects_failure": {"pressure": 0.2}
    })
    available_events.append(noisy_area)
    
    # 行人穿马路紧急事件
    var pedestrian = create_qte_event({
        "type": QTEType.PEDESTRIAN_BRAKE,
        "ai_prompt": "注意！前方有行人",
        "countdown_time": 2.5,
        "expected_actions": ["smooth_driving"],
        "success_feedback": "及时避让，安全第一",
        "failure_feedback": "险些撞到行人！",
        "timeout_feedback": "反应太慢，很危险",
        "npc_positive_reaction": "反应真快！专业",
        "npc_negative_reaction": "刚才太险了！",
        "attribute_effects_success": {"empathy": 0.4, "pressure": -0.1},
        "attribute_effects_failure": {"pressure": 1.0, "empathy": -0.5}
    })
    available_events.append(pedestrian)
    
    # 堵车音乐事件
    var traffic_jam = create_qte_event({
        "type": QTEType.TRAFFIC_JAM_MUSIC,
        "ai_prompt": "前方道路拥堵，可能需要等待",
        "countdown_time": 6.0,
        "expected_actions": ["music_soothing", "music_energetic", "music_off"],
        "success_feedback": "音乐缓解了等待的烦躁",
        "failure_feedback": "安静等待也不错",
        "timeout_feedback": "在安静中等待通行",
        "npc_positive_reaction": "这个音乐不错",
        "npc_negative_reaction": "堵车真烦人",
        "attribute_effects_success": {"pressure": -0.3, "openness": 0.2},
        "attribute_effects_failure": {"pressure": 0.1}
    })
    available_events.append(traffic_jam)
    
    # 紧急加速事件
    var urgent_call = create_qte_event({
        "type": QTEType.URGENT_CALL,
        "ai_prompt": "乘客需要尽快到达，建议提速",
        "countdown_time": 4.0,
        "expected_actions": ["fast_driving"],
        "success_feedback": "适当提速，注意安全",
        "failure_feedback": "继续保持安全车速",
        "timeout_feedback": "维持当前车速",
        "npc_positive_reaction": "谢谢，这样快一点",
        "npc_negative_reaction": "时间有点紧张",
        "attribute_effects_success": {"openness": 0.3, "pressure": 0.1},
        "attribute_effects_failure": {"self_connection": 0.2}
    })
    available_events.append(urgent_call)
    
    print("✅ 设置了", available_events.size(), "个QTE事件")

func should_trigger_event() -> bool:
    """判断是否应该触发QTE事件"""
    print("🎯 检查QTE触发条件:")
    print("   is_qte_active: ", is_qte_active)
    print("   events_this_trip: ", events_this_trip, "/", max_events_per_trip)
    
    # 基本条件检查
    if is_qte_active:
        print("   ❌ QTE已激活，跳过")
        return false
        
    if events_this_trip >= max_events_per_trip:
        print("   ❌ 本次行程事件已达上限")
        return false
    
    # 时间间隔检查 - 放宽限制
    var current_time = Time.get_time_dict_from_system().get("second", 0)
    var time_since_last = current_time - last_event_time
    print("   时间间隔: ", time_since_last, "秒 (最小:", min_event_interval, ")")
    
    if time_since_last < min_event_interval:
        print("   ❌ 时间间隔不足")
        return false
    
    # 概率检查
    var random_value = randf()
    var will_trigger = random_value < event_probability
    print("   概率检查: ", random_value, " < ", event_probability, " = ", will_trigger)
    
    if will_trigger:
        print("   ✅ 满足所有条件，将触发QTE事件")
    else:
        print("   ❌ 概率检查未通过")
    
    return will_trigger

func trigger_random_event():
    """触发随机QTE事件"""
    if available_events.is_empty() or is_qte_active:
        return
    
    var event = available_events[randi() % available_events.size()]
    start_qte_event(event)

func start_qte_event(event: Dictionary):
    """开始QTE事件"""
    if is_qte_active:
        return
    
    current_event = event
    is_qte_active = true
    event_resolved = false
    countdown_timer = event.countdown_time
    events_this_trip += 1
    last_event_time = Time.get_time_dict_from_system().get("second", 0)
    
    print("🚗 QTE事件开始：", event.ai_prompt)
    print("   期望操作：", event.expected_actions)
    print("   倒计时：%.1f秒" % event.countdown_time)
    
    # AI助手发出提示
    var is_urgent = event.countdown_time < 3.0
    ai_assistant_speaks.emit(event.ai_prompt, is_urgent)
    
    # 发送事件开始信号
    qte_event_started.emit(event)

func handle_driving_action(action: String) -> bool:
    """处理驾驶控制板的操作"""
    if not is_qte_active or current_event.is_empty() or event_resolved:
        return false
    
    print("🎮 驾驶操作：", action)
    
    # 检查是否是期望的操作
    var expected_actions = current_event.expected_actions as Array
    var is_correct_action = action in expected_actions
    complete_qte_event(is_correct_action, "action")
    return is_correct_action

func handle_qte_timeout():
    """处理QTE超时"""
    if event_resolved:
        return
    
    print("⏰ QTE事件超时")
    complete_qte_event(false, "timeout")

func complete_qte_event(success: bool, completion_type: String):
    """完成QTE事件"""
    if event_resolved or current_event.is_empty():
        return
    
    event_resolved = true
    print("🏁 QTE事件完成：", "成功" if success else "失败", " (", completion_type, ")")
    
    var feedback_message: String
    var npc_reaction: String
    var attribute_effects: Dictionary
    
    if success:
        feedback_message = current_event.success_feedback
        npc_reaction = current_event.npc_positive_reaction
        attribute_effects = current_event.attribute_effects_success
    else:
        if completion_type == "timeout":
            feedback_message = current_event.timeout_feedback
        else:
            feedback_message = current_event.failure_feedback
        
        npc_reaction = current_event.npc_negative_reaction
        attribute_effects = current_event.attribute_effects_failure
        
        # 应用失败惩罚
        var penalty = current_event.economic_penalty as int
        if penalty > 0:
            apply_economic_penalty(penalty)
    
    # AI助手反馈
    ai_assistant_speaks.emit(feedback_message, false)
    
    # 应用属性影响
    apply_attribute_effects(attribute_effects)
    
    # 发送完成信号
    qte_event_completed.emit(current_event, success)
    
    # 清理状态
    is_qte_active = false
    current_event = {}

func apply_economic_penalty(penalty: int):
    """应用经济惩罚"""
    if GameManager.player_stats != null:
        GameManager.player_stats.money -= penalty
        print("💸 经济惩罚：-", penalty, "元")

func apply_attribute_effects(effects: Dictionary):
    """应用属性影响"""
    for attribute in effects.keys():
        var change = effects[attribute]
        GameManager.update_player_attribute(attribute, change)

func reset_trip_events():
    """重置行程事件计数和状态"""
    events_this_trip = 0
    is_qte_active = false
    event_resolved = false
    current_event = {}
    countdown_timer = 0.0
    
    # 重置时间限制
    last_event_time = 0.0
    
    print("🔄 完全重置行程事件状态")
    print("   events_this_trip: ", events_this_trip)
    print("   is_qte_active: ", is_qte_active)
    print("   last_event_time: ", last_event_time)

func get_qte_status() -> Dictionary:
    """获取QTE状态信息"""
    return {
        "is_active": is_qte_active,
        "events_this_trip": events_this_trip,
        "countdown_remaining": countdown_timer if is_qte_active else 0.0,
        "expected_actions": current_event.get("expected_actions", []) if not current_event.is_empty() else []
    }
