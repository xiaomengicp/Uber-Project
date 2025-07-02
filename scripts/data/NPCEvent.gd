# NPCEvent.gd - NPC事件数据类  
# 这是一个Resource类，用于存储单个NPC事件的所有数据
# 放在 scripts/data/NPCEvent.gd

class_name NPCEvent
extends Resource

# 基础信息
@export var id: String = ""
@export var npc_name: String = ""
@export var npc_id: String = ""
@export var encounter_type: String = "first"  # "first", "second", "third", "hidden", "special"

# 触发条件
@export var area: String = ""
@export var unlock_day: int = 1
@export var time_range: Array = ["20:00", "06:00"]  # 默认夜班时间
@export var weather_conditions: Array = ["any"]
@export var required_attributes: Dictionary = {}  # 例如 {"empathy": 60}
@export var forbidden_attributes: Dictionary = {}  # 例如 {"pressure": 80}
@export var previous_encounters: Array = []  # 需要先遇见的事件ID

# 对话内容
@export var dialogue_segments: Array = []
@export var interrupt_responses: Dictionary = {
    "empathy": "",
    "self_reflection": "", 
    "openness": "",
    "basic": ""
}

# NPC特征
@export var driving_preferences: Dictionary = {
    "smooth_driving": 0.5,
    "fast_driving": 0.5,
    "music_soothing": 0.5,
    "music_energetic": 0.5,
    "music_off": 0.5,
    "open_window": 0.5,
    "close_window": 0.5
}

# 经济影响
@export var economic_impact: Dictionary = {
    "base_fee": 50,
    "tip_range": [0, 10],
    "tip_probability": 0.3
}

# 属性影响
@export var attribute_effects: Dictionary = {
    "successful_interaction": {},  # 成功互动的属性奖励
    "failed_interaction": {},     # 失败互动的属性惩罚
    "completion_bonus": {}        # 完成事件的额外奖励
}

# 元数据
@export var story_significance: String = ""  # 这个事件的故事意义
@export var character_background: String = ""  # 角色背景
@export var unlock_hints: Array = []  # 解锁条件提示

# 运行时状态（不导出）
var times_encountered: int = 0
var last_encounter_day: int = -1
var current_mood_score: float = 50.0
var is_available: bool = true

func _init():
    """初始化NPC事件"""
    pass

func can_trigger(current_day: int, current_area: String, player_stats, weather: String = "clear") -> bool:
    """检查事件是否可以触发"""
    
    # 基础条件检查
    if current_day < unlock_day:
        return false
    
    if area != "" and current_area != area:
        return false
    
    if weather != "any" and weather not in weather_conditions and "any" not in weather_conditions:
        return false
    
    # 属性要求检查
    if player_stats != null:
        for attr in required_attributes.keys():
            var required_value = required_attributes[attr]
            var current_value = player_stats.get(attr, 0)
            if current_value < required_value:
                return false
        
        for attr in forbidden_attributes.keys():
            var forbidden_value = forbidden_attributes[attr]
            var current_value = player_stats.get(attr, 0)
            if current_value >= forbidden_value:
                return false
    
    # 前置事件检查
    if previous_encounters.size() > 0:
        # 这里需要检查玩家是否已经遇见了所有前置事件
        # 具体实现取决于你的进度跟踪系统
        pass
    
    return true

func get_dialogue_segment(index: int) -> String:
    """获取指定索引的对话段落"""
    if index >= 0 and index < dialogue_segments.size():
        return dialogue_segments[index]
    return ""

func get_interrupt_response(interrupt_type: String) -> String:
    """获取插话回应"""
    return interrupt_responses.get(interrupt_type, interrupt_responses.get("basic", ""))

func get_driving_preference(action: String) -> float:
    """获取对特定驾驶行为的偏好值 (0.0-1.0)"""
    return driving_preferences.get(action, 0.5)

func calculate_tip_amount() -> int:
    """根据心情分数计算小费金额"""
    var tip_range_array = economic_impact.get("tip_range", [0, 5])
    var min_tip = tip_range_array[0] if tip_range_array.size() > 0 else 0
    var max_tip = tip_range_array[1] if tip_range_array.size() > 1 else 5
    
    # 根据心情分数调整小费
    var mood_multiplier = clamp(current_mood_score / 50.0, 0.0, 2.0)
    var base_tip = randi_range(min_tip, max_tip)
    
    return int(base_tip * mood_multiplier)

func update_mood_score(change: float):
    """更新心情分数"""
    current_mood_score = clamp(current_mood_score + change, 0.0, 100.0)

func mark_encountered(day: int):
    """标记已遇见"""
    times_encountered += 1
    last_encounter_day = day

func get_encounter_info() -> Dictionary:
    """获取遇见信息"""
    return {
        "times_encountered": times_encountered,
        "last_encounter_day": last_encounter_day,
        "current_mood_score": current_mood_score,
        "encounter_type": encounter_type
    }

func get_debug_info() -> Dictionary:
    """获取调试信息"""
    return {
        "id": id,
        "npc_name": npc_name,
        "area": area,
        "encounter_type": encounter_type,
        "unlock_day": unlock_day,
        "dialogue_count": dialogue_segments.size(),
        "times_encountered": times_encountered,
        "is_available": is_available
    }
