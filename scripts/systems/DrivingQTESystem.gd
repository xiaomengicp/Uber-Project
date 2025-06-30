# DrivingQTESystem.gd - 驾驶QTE事件系统
# 处理红绿灯、转弯、天气等驾驶事件

extends Node
class_name DrivingQTESystem

# QTE事件类型枚举
enum QTEType {
    RED_LIGHT,
    TURN_LEFT,
    TURN_RIGHT,
    RAIN_WIPERS,
    NOISE_WINDOW,
    PEDESTRIAN_CROSSING,
    AMBULANCE_YIELDING
}

# QTE事件数据结构
class QTEEvent:
    var type: QTEType
    var prompt_text: String
    var countdown_time: float
    var correct_action: String
    var success_feedback: String
    var failure_feedback: String
    var npc_reaction_positive: String
    var npc_reaction_negative: String
    var economic_penalty: int = 0
    var attribute_effects: Dictionary = {}
    
    func _init(t: QTEType, prompt: String, time: float, action: String):
        type = t
        prompt_text = prompt
        countdown_time = time
        correct_action = action

# 信号定义
signal qte_event_started(event: QTEEvent)
signal qte_event_completed(event: QTEEvent, success: bool)
signal voice_assistant_speaks(message: String)

# 当前QTE状态
var current_event: QTEEvent = null
var is_qte_active: bool = false
var countdown_timer: float = 0.0
var qte_completed: bool = false

# QTE事件配置
var qte_events: Array[QTEEvent] = []

# 随机事件触发
var base_event_probability: float = 0.3  # 每次对话段落后30%概率触发事件
var last_event_time: float = 0.0
var min_event_interval: float = 10.0  # 最小事件间隔

func _ready():
    setup_qte_events()
    print("驾驶QTE系统初始化完成")

func _process(delta):
    if is_qte_active and current_event != null:
        countdown_timer -= delta
        if countdown_timer <= 0.0 and not qte_completed:
            # 超时失败
            complete_qte_event(false)

func setup_qte_events():
    """初始化所有QTE事件"""
    qte_events.clear()
    
    # 红绿灯事件
    var red_light = QTEEvent.new(QTEType.RED_LIGHT, "前方红灯，请减速停车", 3.0, "brake")
    red_light.success_feedback = "安全停车，遵守交规"
    red_light.failure_feedback = "闯红灯！被监控拍摄"
    red_light.npc_reaction_positive = "司机很守规矩，让人安心"
    red_light.npc_reaction_negative = "太危险了！这样开车让人害怕"
    red_light.economic_penalty = 200
    red_light.attribute_effects = {"pressure": 0.5, "empathy": -0.2}
    qte_events.append(red_light)
    
    # 左转事件
    var turn_left = QTEEvent.new(QTEType.TURN_LEFT, "前方路口，请左转", 4.0, "turn_left")
    turn_left.success_feedback = "转弯顺畅"
    turn_left.failure_feedback = "错过路口，需要重新规划路线"
    turn_left.npc_reaction_positive = "路线很熟悉呢"
    turn_left.npc_reaction_negative = "是不是走错路了？"
    turn_left.attribute_effects = {"pressure": 0.3}
    qte_events.append(turn_left)
    
    # 右转事件
    var turn_right = QTEEvent.new(QTEType.TURN_RIGHT, "前方路口，请右转", 4.0, "turn_right")
    turn_right.success_feedback = "转弯顺畅"
    turn_right.failure_feedback = "错过路口，需要重新规划路线"
    turn_right.npc_reaction_positive = "司机技术不错"
    turn_right.npc_reaction_negative = "这条路对吗？"
    turn_right.attribute_effects = {"pressure": 0.3}
    qte_events.append(turn_right)
    
    # 下雨事件
    var rain_event = QTEEvent.new(QTEType.RAIN_WIPERS, "开始下雨，建议使用雨刷", 5.0, "wipers")
    rain_event.success_feedback = "雨刷启动，视线清晰"
    rain_event.failure_feedback = "视线模糊，行驶危险度增加"
    rain_event.npc_reaction_positive = "雨夜开车确实要小心"
    rain_event.npc_reaction_negative = "这样看不清路很危险啊"
    rain_event.attribute_effects = {"pressure": 0.4, "empathy": -0.1}
    qte_events.append(rain_event)
    
    # 噪音事件
    var noise_event = QTEEvent.new(QTEType.NOISE_WINDOW, "外界噪音较大，建议关窗", 4.0, "close_window")
    noise_event.success_feedback = "车内安静，适合对话"
    noise_event.failure_feedback = "噪音干扰，对话受影响"
    noise_event.npc_reaction_positive = "这样安静多了，谢谢"
    noise_event.npc_reaction_negative = "太吵了，都听不清说话"
    noise_event.attribute_effects = {"empathy": 0.2}
    qte_events.append(noise_event)
    
    # 行人穿越事件（紧急）
    var pedestrian = QTEEvent.new(QTEType.PEDESTRIAN_CROSSING, "注意！前方有行人穿越", 2.0, "emergency_brake")
    pedestrian.success_feedback = "及时避让，安全第一"
    pedestrian.failure_feedback = "险些撞到行人，请注意安全"
    pedestrian.npc_reaction_positive = "反应真快，专业司机"
    pedestrian.npc_reaction_negative = "刚才太险了！"
    pedestrian.attribute_effects = {"pressure": 0.8, "empathy": -0.3}
    qte_events.append(pedestrian)
    
    # 救护车让道事件
    var ambulance = QTEEvent.new(QTEType.AMBULANCE_YIELDING, "后方救护车，请靠边让行", 3.0, "yield_right")
    ambulance.success_feedback = "成功让行，体现公民素质"
    ambulance.failure_feedback = "阻挡急救车辆，可能面临处罚"
    ambulance.npc_reaction_positive = "做得对，救人要紧"
    ambulance.npc_reaction_negative = "怎么能挡救护车呢？"
    ambulance.economic_penalty = 300
    ambulance.attribute_effects = {"empathy": 0.5, "pressure": 0.6}
    qte_events.append(ambulance)

func should_trigger_event() -> bool:
    """判断是否应该触发QTE事件"""
    if is_qte_active:
        return false
    
    var current_time = Time.get_time_dict_from_system()
    var time_since_last = current_time.get("second", 0) - last_event_time
    
    if time_since_last < min_event_interval:
        return false
    
    return randf() < base_event_probability

func trigger_random_event():
    """触发随机QTE事件"""
    if qte_events.is_empty() or is_qte_active:
        return
    
    var event = qte_events[randi() % qte_events.size()]
    start_qte_event(event)

func start_qte_event(event: QTEEvent):
    """开始QTE事件"""
    if is_qte_active:
        print("QTE事件已经在进行中")
        return
    
    current_event = event
    is_qte_active = true
    qte_completed = false
    countdown_timer = event.countdown_time
    last_event_time = Time.get_time_dict_from_system().get("second", 0)
    
    print("QTE事件开始：", event.prompt_text)
    
    # 语音助手提示
    voice_assistant_speaks.emit(event.prompt_text)
    
    # 发送事件开始信号
    qte_event_started.emit(event)

func handle_qte_action(action: String) -> bool:
    """处理QTE动作输入"""
    if not is_qte_active or current_event == null or qte_completed:
        print("没有活动的QTE事件，忽略输入：", action)
        return false
    
    var success = (action == current_event.correct_action)
    complete_qte_event(success)
    return success

func complete_qte_event(success: bool):
    """完成QTE事件"""
    if current_event == null or qte_completed:
        return
    
    qte_completed = true
    print("QTE事件完成，结果：", "成功" if success else "失败")
    
    var feedback_message: String
    var npc_reaction: String
    
    if success:
        feedback_message = current_event.success_feedback
        npc_reaction = current_event.npc_reaction_positive
        voice_assistant_speaks.emit(feedback_message)
    else:
        feedback_message = current_event.failure_feedback
        npc_reaction = current_event.npc_reaction_negative
        voice_assistant_speaks.emit(feedback_message)
        
        # 应用失败惩罚
        if current_event.economic_penalty > 0:
            apply_economic_penalty(current_event.economic_penalty)
        
        apply_attribute_effects(current_event.attribute_effects)
    
    # 发送完成信号
    qte_event_completed.emit(current_event, success)
    
    # 清理状态
    is_qte_active = false
    current_event = null

func apply_economic_penalty(penalty: int):
    """应用经济惩罚"""
    if GameManager.player_stats != null:
        GameManager.player_stats.money -= penalty
        print("经济惩罚：-", penalty, "元")

func apply_attribute_effects(effects: Dictionary):
    """应用属性影响"""
    for attribute in effects.keys():
        var change = effects[attribute]
        GameManager.update_player_attribute(attribute, change)
        print("属性变化：", attribute, " ", ("+" if change >= 0 else ""), change)

func get_voice_assistant_character() -> Dictionary:
    """获取语音助手角色信息"""
    return {
        "name": "ARIA",
        "full_name": "Automated Routing & Intelligence Assistant",
        "personality": "机械化但友好，偶尔显露人性化特征",
        "hidden_function": "可能在监控司机的行为和情绪状态"
    }

func get_qte_status() -> Dictionary:
    """获取当前QTE状态信息"""
    return {
        "is_active": is_qte_active,
        "current_event_type": current_event.type if current_event != null else null,
        "countdown_remaining": countdown_timer if is_qte_active else 0.0,
        "last_event_time": last_event_time
    }

# 特殊QTE事件触发器
func trigger_weather_event():
    """触发天气相关事件"""
    var weather_events = qte_events.filter(func(event): return event.type == QTEType.RAIN_WIPERS)
    if not weather_events.is_empty():
        start_qte_event(weather_events[0])

func trigger_traffic_event():
    """触发交通相关事件"""
    var traffic_events = qte_events.filter(func(event): return event.type in [QTEType.RED_LIGHT, QTEType.TURN_LEFT, QTEType.TURN_RIGHT])
    if not traffic_events.is_empty():
        var event = traffic_events[randi() % traffic_events.size()]
        start_qte_event(event)

func trigger_emergency_event():
    """触发紧急事件"""
    var emergency_events = qte_events.filter(func(event): return event.type in [QTEType.PEDESTRIAN_CROSSING, QTEType.AMBULANCE_YIELDING])
    if not emergency_events.is_empty():
        var event = emergency_events[randi() % emergency_events.size()]
        start_qte_event(event)
