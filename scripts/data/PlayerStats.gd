# PlayerStats.gd - 玩家属性和状态管理
# 这是一个Resource类，用于保存玩家的所有数据

class_name PlayerStats
extends Resource

# 核心属性
@export var empathy: float = 50.0
@export var self_connection: float = 40.0  
@export var openness: float = 45.0
@export var pressure: float = 30.0

# 经济状态
@export var money: int = 100
@export var total_income: int = 0
@export var total_expenses: int = 0

# 游戏进度
@export var current_day: int = 1
@export var areas_unlocked: Array[String] = ["business_district", "residential"]

# 统计数据
@export var total_passengers: int = 0
@export var successful_interrupts: int = 0
@export var failed_interrupts: int = 0
@export var total_mood_score: float = 0.0

# NPC关系记录
@export var npc_relationships: Dictionary = {}

# 购买记录
@export var purchased_items: Array[String] = []

func _init():
    """初始化函数"""
    pass

func update_attribute(attribute: String, change: float):
    """更新属性值，自动应用限制"""
    match attribute:
        "empathy":
            empathy = clamp(empathy + change, 0, 100)
        "self_connection":
            self_connection = clamp(self_connection + change, 0, 100)
        "openness":
            openness = clamp(openness + change, 0, 100)
        "pressure":
            pressure = clamp(pressure + change, 0, 100)

func can_interrupt(interrupt_type: String) -> bool:
    """检查是否可以使用特定插话类型"""
    match interrupt_type:
        "basic":
            return true
        "emotional":
            return empathy >= 60
        "self_reflection": 
            return self_connection >= 60
        "openness":
            return openness >= 60
        _:
            return false

func get_attribute_display() -> Dictionary:
    """获取属性的显示信息"""
    return {
        "empathy": {
            "value": empathy,
            "display": "共情能力",
            "color": Color.PINK if empathy >= 60 else Color.GRAY
        },
        "self_connection": {
            "value": self_connection, 
            "display": "自我连接",
            "color": Color.BLUE if self_connection >= 60 else Color.GRAY
        },
        "openness": {
            "value": openness,
            "display": "开放度", 
            "color": Color.GREEN if openness >= 60 else Color.GRAY
        },
        "pressure": {
            "value": pressure,
            "display": "压力值",
            "color": Color.RED if pressure >= 60 else Color.ORANGE
        }
    }

func unlock_area(area_id: String):
    """解锁新区域"""
    if area_id not in areas_unlocked:
        areas_unlocked.append(area_id)
        print("解锁新区域：", area_id)

func add_npc_encounter(npc_id: String, mood_score: float):
    """记录NPC遭遇"""
    if npc_id not in npc_relationships:
        npc_relationships[npc_id] = {
            "encounter_count": 0,
            "total_mood": 0.0,
            "average_mood": 0.0
        }
    
    var relation = npc_relationships[npc_id]
    relation.encounter_count += 1
    relation.total_mood += mood_score
    relation.average_mood = relation.total_mood / relation.encounter_count
    
    total_passengers += 1
    total_mood_score += mood_score

func record_interrupt_result(success: bool):
    """记录插话结果"""
    if success:
        successful_interrupts += 1
    else:
        failed_interrupts += 1

func get_interrupt_success_rate() -> float:
    """获取插话成功率"""
    var total = successful_interrupts + failed_interrupts
    if total == 0:
        return 0.0
    return float(successful_interrupts) / float(total)

func spend_money(amount: int) -> bool:
    """花费金钱，返回是否成功"""
    if money >= amount:
        money -= amount
        total_expenses += amount
        return true
    return false

func earn_money(amount: int):
    """赚取金钱"""
    money += amount
    total_income += amount

func get_economic_status() -> String:
    """获取经济状况描述"""
    if money < 0:
        return "债务缠身"
    elif money < 50:
        return "经济紧张"
    elif money < 150:
        return "勉强维持"
    elif money < 300:
        return "小有积蓄"
    else:
        return "经济宽裕"

func get_pressure_status() -> String:
    """获取压力状况描述"""
    if pressure < 30:
        return "心情平静"
    elif pressure < 50:
        return "略有压力"
    elif pressure < 70:
        return "压力较大"
    elif pressure < 85:
        return "高度紧张"
    else:
        return "濒临崩溃"

func calculate_daily_performance() -> Dictionary:
    """计算每日表现"""
    var performance = {
        "income": 0,
        "mood_average": 0.0,
        "interrupt_rate": get_interrupt_success_rate(),
        "pressure_change": 0.0
    }
    
    # 这里可以添加更复杂的计算逻辑
    return performance

func save_to_file(path: String):
    """保存到文件"""
    var result = ResourceSaver.save(self, path)
    if result == OK:
        print("存档保存成功：", path)
    else:
        print("存档保存失败：", path)

static func load_from_file(path: String) -> PlayerStats:
    """从文件加载"""
    if ResourceLoader.exists(path):
        var stats = ResourceLoader.load(path) as PlayerStats
        if stats != null:
            print("存档加载成功：", path)
            return stats
    
    print("存档加载失败，创建新档案")
    return PlayerStats.new()
