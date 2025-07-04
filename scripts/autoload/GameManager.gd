# GameManager.gd - AutoLoad脚本
# 管理游戏流程、状态切换和核心逻辑

extends Node

# 游戏状态枚举

# GameManager.gd 梦网状态扩展
# 在现有的GameManager.gd中进行以下修改：

# 1. 更新游戏状态枚举，添加DREAMWEAVE状态：
enum GameState {
    MENU,
    AREA_SELECTION,
    DRIVING,
    HOME,
    SHOP,
    DREAMWEAVE  # 新增梦网状态
}

# 2. 在_on_game_state_changed()函数中添加DREAMWEAVE状态处理：



# 信号定义
signal state_changed(new_state: GameState)
signal day_completed
signal game_completed

# 当前游戏状态
var current_state: GameState = GameState.MENU
var current_day: int = 1
var passengers_today: int = 0
var max_passengers_per_day: int = 2

# 玩家数据引用
var player_stats: PlayerStats
var daily_income: int = 0

# 配置数据
var balance_config: Dictionary
var economy_config: Dictionary
var dialogue_config: Dictionary

func _ready():
    print("GameManager初始化...")
    load_all_configs()
    initialize_player_stats()
    
func load_all_configs():
    """加载所有配置文件"""
    balance_config = load_json_config("res://data/config/balance_config.json")
    economy_config = load_json_config("res://data/config/economy_config.json")
    dialogue_config = load_json_config("res://data/config/dialogue_config.json")
    print("配置文件加载完成")

func load_json_config(path: String) -> Dictionary:
    """加载JSON配置文件"""
    print("尝试加载配置文件: ", path)
    
    # 检查文件是否存在
    if not FileAccess.file_exists(path):
        print("❌ 配置文件不存在: ", path)
        return {}
    
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        print("❌ 无法打开配置文件: ", path)
        return {}
    
    var json_string = file.get_as_text()
    file.close()
    
    # 检查文件内容是否为空
    if json_string.strip_edges() == "":
        print("❌ 配置文件为空: ", path)
        return {}
    
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    if parse_result != OK:
        print("❌ JSON解析失败: ", path)
        print("   错误信息: ", json.error_string)
        print("   错误行号: ", json.error_line)
        print("   文件内容预览: ", json_string.substr(0, 200))
        return {}
    
    print("✅ 配置文件加载成功: ", path)
    return json.data

func initialize_player_stats():
    """初始化玩家属性"""
    player_stats = PlayerStats.new()
    current_day = 1  # 重置当前天数
    passengers_today = 0
    daily_income = 0
    
    # 使用配置文件中的初始值
    if balance_config.has("initial_attributes"):
        var initial = balance_config.initial_attributes
        player_stats.empathy = initial.get("empathy", 50)
        player_stats.self_connection = initial.get("self_connection", 40)
        player_stats.openness = initial.get("openness", 45)
        player_stats.pressure = initial.get("pressure", 30)
    
    player_stats.money = economy_config.get("initial_money", 100)
    player_stats.current_day = current_day

func change_state(new_state: GameState):
    """改变游戏状态"""
    if current_state != new_state:
        current_state = new_state
        print("游戏状态改变为: ", GameState.keys()[new_state])
        state_changed.emit(new_state)

func start_new_day():
    """开始新的一天"""
    current_day += 1
    passengers_today = 0
    daily_income = 0
    player_stats.current_day = current_day
    
    # 每日固定支出
    var daily_cost = economy_config.expenses.daily_fixed_cost
    player_stats.money -= daily_cost
    
    print("第", current_day, "天开始")
    change_state(GameState.AREA_SELECTION)

func complete_passenger_trip(income: int, mood_score: float):
    """完成一次载客"""
    passengers_today += 1
    daily_income += income
    player_stats.money += income
    
    print("完成载客，收入：", income, "元，心情分数：", mood_score)
    print("今日已接乘客：", passengers_today, "/", max_passengers_per_day)
    
    if passengers_today >= max_passengers_per_day:
        # 一天的客人接完了，结束一天
        print("今日乘客已满，准备结束一天")
        end_day()
    else:
        # 还没接够客人，等待UI层面处理下一个乘客
        print("等待下一位乘客...")

func end_day():
    """结束一天"""
    print("第", current_day, "天结束")
    print("今日收入：", daily_income, "元")
    day_completed.emit()
    
    # 检查是否应该结束游戏（第7天结束后）
    if current_day >= 7:
        print("游戏达到结束条件（完成7天）")
        change_state(GameState.HOME)  # 先回到家中，然后在home界面触发结局
    else:
        change_state(GameState.HOME)

func calculate_interrupt_success_rate(interrupt_type: String, npc_preference: float = 0.0) -> float:
    """计算插话成功率"""
    var config = balance_config.interrupt_system
    var base_rate: float
    
    if interrupt_type == "basic":
        base_rate = config.basic_success_rate
    else:
        base_rate = config.deep_interrupt_base_rate
        
        # 检查属性要求
        var required_attribute = get_interrupt_required_attribute(interrupt_type)
        if required_attribute != "":
            var attr_value = player_stats.get(required_attribute)
            if attr_value < 60:
                return 0.0  # 不满足解锁条件
            
            # 属性加成
            var bonus = (attr_value - 60) * config.attribute_bonus_multiplier
            base_rate += bonus
    
    # 压力惩罚
    var pressure_penalty = player_stats.pressure * config.pressure_penalty_multiplier
    
    # 计算最终成功率
    var final_rate = base_rate - pressure_penalty + npc_preference
    return clamp(final_rate, config.success_rate_limits.min, config.success_rate_limits.max)

func get_interrupt_required_attribute(interrupt_type: String) -> String:
    """获取插话类型对应的属性要求"""
    match interrupt_type:
        "emotional":
            return "empathy"
        "self_reflection":
            return "self_connection"
        "openness":
            return "openness"
        _:
            return ""

func can_use_interrupt(interrupt_type: String) -> bool:
    """检查是否可以使用特定插话"""
    if interrupt_type == "basic":
        return true
        
    var required_attr = get_interrupt_required_attribute(interrupt_type)
    if required_attr == "":
        return false
        
    return player_stats.get(required_attr) >= 60

func update_player_attribute(attribute: String, change: float):
    """更新玩家属性"""
    player_stats.update_attribute(attribute, change)
    print("属性变化：", attribute, " ", ("+" if change >= 0 else ""), change)

# 游戏进度检查
func should_game_end() -> bool:
    """检查游戏是否应该结束"""
    return current_day >= 7  # 第7天结束后游戏结束

func get_ending_type() -> String:
    """计算结局类型"""
    var score = calculate_final_score()
    var thresholds = balance_config.ending_thresholds
    
    if score >= thresholds.find_yourself:
        return "find_yourself"
    elif score >= thresholds.connect_others:
        return "connect_others"
    elif score >= thresholds.continue_searching:
        return "continue_searching"
    else:
        return "need_rest"

func calculate_final_score() -> float:
    """计算最终分数"""
    var weights = balance_config.score_calculation
    var attr_avg = (player_stats.empathy + player_stats.self_connection + 
                    player_stats.openness - player_stats.pressure / weights.pressure_penalty_divisor) / 3
    
    # 这里可以加入其他因素，如NPC关系、经济状况等
    return attr_avg

# 3. 添加便捷方法进入梦网状态：
func enter_dreamweave_state():
    """进入梦网状态"""
    change_state(GameState.DREAMWEAVE)

func exit_dreamweave_state():
    """退出梦网状态，返回家中"""
    change_state(GameState.HOME)
