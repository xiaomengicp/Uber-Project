# NPCEventManager.gd - 修复版本，正确处理PlayerStats属性获取
extends Node

# 信号定义
signal npc_events_loaded()
signal new_npc_event_unlocked(event: NPCEvent)

# 事件存储
var all_npc_events: Array[NPCEvent] = []
var events_by_area: Dictionary = {}
var events_by_npc: Dictionary = {}
var events_by_type: Dictionary = {}

# 玩家进度跟踪
var encountered_events: Array[String] = []
var npc_encounter_counts: Dictionary = {}

# 配置路径
var npc_data_base_path: String = "res://data/npcs/"
var npc_dirs: Array[String] = [
    "business_district",
    "residential", 
    "entertainment",
    "suburban",
    "cross_area",
    "special"
]

func _ready():
    print("🎭 NPCEventManager初始化...")
    load_all_npc_events()

func get_player_attribute_value(player_stats, attr_name: String) -> float:
    """安全地获取玩家属性值"""
    if player_stats == null:
        return 0.0
    
    # 直接访问PlayerStats的属性
    match attr_name:
        "empathy":
            return player_stats.empathy
        "self_connection":
            return player_stats.self_connection
        "openness":
            return player_stats.openness
        "pressure":
            return player_stats.pressure
        _:
            print("⚠️ 未知属性名称：", attr_name)
            return 0.0

func load_all_npc_events():
    """加载所有NPC事件文件"""
    print("📖 开始加载NPC事件...")
    
    all_npc_events.clear()
    events_by_area.clear()
    events_by_npc.clear()
    events_by_type.clear()
    
    for dir_name in npc_dirs:
        var dir_path = npc_data_base_path + dir_name + "/"
        load_npc_files_from_directory(dir_path, dir_name)
    
    print("✅ NPC事件加载完成，总计: ", all_npc_events.size(), " 个事件")
    npc_events_loaded.emit()

func load_npc_files_from_directory(dir_path: String, dir_name: String):
    """从指定目录加载所有NPC文件"""
    print("📁 扫描目录: ", dir_path)
    
    # 检查目录是否存在
    if not DirAccess.dir_exists_absolute(dir_path):
        print("⚠️  目录不存在，创建示例: ", dir_path)
        create_sample_npc_files(dir_path, dir_name)
        return
    
    var dir = DirAccess.open(dir_path)
    if dir == null:
        print("❌ 无法打开目录: ", dir_path)
        return
    
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        if file_name.ends_with(".json"):
            var file_path = dir_path + file_name
            load_single_npc_file(file_path)
        file_name = dir.get_next()
    
    dir.list_dir_end()

func load_single_npc_file(file_path: String):
    """加载单个NPC文件"""
    print("📄 加载NPC文件: ", file_path)
    
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        print("❌ 无法打开文件: ", file_path)
        return
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    if parse_result != OK:
        print("❌ JSON解析失败: ", file_path)
        print("   错误: ", json.error_string, " 行号: ", json.error_line)
        return
    
    var npc_data = json.data
    
    # 解析NPC信息和事件
    var npc_info = npc_data.get("npc_info", {})
    var events_data = npc_data.get("events", [])
    
    print("  📊 NPC: ", npc_info.get("npc_name", "Unknown"), " 事件数: ", events_data.size())
    
    # 转换每个事件
    for event_data in events_data:
        # 从npc_info补充基础信息
        if not event_data.has("npc_name"):
            event_data["npc_name"] = npc_info.get("npc_name", "")
        if not event_data.has("npc_id"):
            event_data["npc_id"] = npc_info.get("npc_id", "")
        
        var npc_event = create_npc_event_from_data(event_data, npc_info)
        if npc_event != null:
            all_npc_events.append(npc_event)
            organize_event(npc_event)

func create_npc_event_from_data(event_data: Dictionary, npc_info: Dictionary = {}) -> NPCEvent:
    """从Dictionary数据创建NPCEvent对象"""
    var event = NPCEvent.new()
    
    # 基础信息
    event.id = event_data.get("id", "")
    event.npc_name = event_data.get("npc_name", npc_info.get("npc_name", ""))
    event.npc_id = event_data.get("npc_id", npc_info.get("npc_id", ""))
    event.encounter_type = event_data.get("encounter_type", "first")
    
    # 触发条件
    event.area = event_data.get("area", npc_info.get("primary_area", ""))
    event.unlock_day = event_data.get("unlock_day", 1)
    
    var trigger_conditions = event_data.get("trigger_conditions", {})
    event.time_range = trigger_conditions.get("time_range", ["20:00", "06:00"])
    event.weather_conditions = trigger_conditions.get("weather", ["any"])
    event.required_attributes = trigger_conditions.get("required_attributes", {})
    event.forbidden_attributes = trigger_conditions.get("forbidden_attributes", {})
    event.previous_encounters = trigger_conditions.get("previous_encounters", [])
    
    # 对话内容
    event.dialogue_segments = event_data.get("dialogue", [])
    event.interrupt_responses = event_data.get("interrupt_responses", {})
    
    # 游戏效果
    var game_effects = event_data.get("game_effects", {})
    event.driving_preferences = game_effects.get("driving_preferences", {})
    event.economic_impact = game_effects.get("economic", {})
    event.attribute_effects = game_effects.get("attributes", {})
    
    # 元数据
    event.story_significance = npc_info.get("story_role", "")
    event.character_background = npc_info.get("background", "")
    event.unlock_hints = event_data.get("unlock_hints", [])
    
    if event.id != "":
        print("  ✅ 创建事件: ", event.id, " (", event.npc_name, ")")
    else:
        print("  ❌ 事件缺少ID，跳过")
        return null
    
    return event

func organize_event(event: NPCEvent):
    """组织事件到不同的索引中"""
    
    # 按区域组织
    if event.area != "":
        if event.area not in events_by_area:
            events_by_area[event.area] = []
        events_by_area[event.area].append(event)
    
    # 按NPC组织
    if event.npc_id not in events_by_npc:
        events_by_npc[event.npc_id] = []
    events_by_npc[event.npc_id].append(event)
    
    # 按类型组织
    if event.encounter_type not in events_by_type:
        events_by_type[event.encounter_type] = []
    events_by_type[event.encounter_type].append(event)

func get_available_events_for_area(area: String, current_day: int, player_stats, weather: String = "clear") -> Array[NPCEvent]:
    """获取指定区域的可用事件"""
    var available_events: Array[NPCEvent] = []
    
    var area_events = events_by_area.get(area, [])
    print("🔍 检查区域 ", area, " 的事件，共 ", area_events.size(), " 个")
    
    for event in area_events:
        if can_event_trigger(event, current_day, area, player_stats, weather):
            available_events.append(event)
            print("  ✅ 可用事件: ", event.id)
        else:
            print("  ❌ 不可用事件: ", event.id, " 原因: ", get_trigger_failure_reason(event, current_day, area, player_stats, weather))
    
    return available_events

func can_event_trigger(event: NPCEvent, current_day: int, current_area: String, player_stats, weather: String) -> bool:
    """检查事件是否可以触发 - 修正版逻辑"""
    
    # 使用NPCEvent自己的基础检查方法（天数、区域、属性等）
    if not event.can_trigger(current_day, current_area, player_stats, weather):
        return false
    
    # 检查这个具体事件是否已经完成
    if event.id in encountered_events:
        return false  # 这个具体事件已经遇见过，不能再触发
    
    # 检查前置事件（这是关键！）
    for prerequisite_id in event.previous_encounters:
        if prerequisite_id not in encountered_events:
            return false  # 前置事件未完成，不能触发
    
    return true
    
func get_trigger_failure_reason(event: NPCEvent, current_day: int, current_area: String, player_stats, weather: String) -> String:
    """获取事件无法触发的原因（调试用） - 修正版"""
    if current_day < event.unlock_day:
        return "天数不足(%d < %d)" % [current_day, event.unlock_day]
    
    if event.area != "" and current_area != event.area:
        return "区域不匹配(%s != %s)" % [current_area, event.area]
    
    # 检查具体事件是否已完成
    if event.id in encountered_events:
        return "该事件已完成: " + event.id
    
    # 检查前置事件
    for prerequisite_id in event.previous_encounters:
        if prerequisite_id not in encountered_events:
            return "前置事件未完成: " + prerequisite_id
    
    # 检查属性要求
    if player_stats != null:
        for attr in event.required_attributes.keys():
            var required = event.required_attributes[attr]
            var current = get_player_attribute_value(player_stats, attr)
            if current < required:
                return "属性不足: %s(%.1f < %d)" % [attr, current, required]
    
    return "未知原因"
    
    
'''func get_encounter_limit(encounter_type: String) -> int:
    """获取遇见类型的次数限制"""
    match encounter_type:
        "first":
            return 1
        "second": 
            return 2
        "third":
            return 3
        "hidden":
            return 1
        "special":
            return 1
        _:
            return 1'''

func select_random_event_for_area(area: String, current_day: int, player_stats, weather: String = "clear") -> NPCEvent:
    """为指定区域随机选择一个可用事件 - 修正版权重逻辑"""
    var available_events = get_available_events_for_area(area, current_day, player_stats, weather)
    
    if available_events.is_empty():
        print("❌ 区域 ", area, " 没有可用的NPC事件")
        return null
    
    # 修正的权重逻辑：优先first事件，然后是可解锁的后续事件
    var weighted_events = []
    for event in available_events:
        var weight = 1
        
        # 根据事件类型给不同权重
        match event.encounter_type:
            "first":
                weight = 4  # first事件高权重，优先遇见
            "second":
                weight = 3  # second事件中等权重
            "third":
                weight = 2  # third事件较低权重，因为更珍贵
            "hidden", "special":
                weight = 5  # 特殊事件最高权重，因为稀有
        
        # 将事件按权重加入池子
        for i in range(weight):
            weighted_events.append(event)
    
    if weighted_events.is_empty():
        return available_events[0]
    
    var selected_event = weighted_events[randi() % weighted_events.size()]
    print("🎭 选中NPC事件: ", selected_event.id, " (", selected_event.npc_name, ", ", selected_event.encounter_type, ")")
    
    return selected_event
    
func mark_event_encountered(event: NPCEvent, current_day: int):
    """标记事件已遇见 - 简化版逻辑"""
    if event == null:
        return
    
    # 更新事件状态
    event.mark_encountered(current_day)
    
    # 将具体事件ID加入已完成列表
    if event.id not in encountered_events:
        encountered_events.append(event.id)
    
    # 简单记录NPC遇见次数（用于统计，不影响解锁逻辑）
    var current_count = npc_encounter_counts.get(event.npc_id, 0)
    npc_encounter_counts[event.npc_id] = current_count + 1
    
    print("📝 标记事件已遇见: ", event.id, " (第", npc_encounter_counts[event.npc_id], "次遇见", event.npc_name, ")")
    
    # 检查是否解锁了新事件
    check_for_newly_unlocked_events()
    
func check_for_newly_unlocked_events():
    """检查是否有新解锁的事件"""
    for event in all_npc_events:
        if not event.is_available:
            continue
        
        if event.id in encountered_events:
            continue
        
        # 检查前置条件是否满足
        var prerequisites_met = true
        for prerequisite_id in event.previous_encounters:
            if prerequisite_id not in encountered_events:
                prerequisites_met = false
                break
        
        if prerequisites_met and event.previous_encounters.size() > 0:
            print("🆕 解锁新事件: ", event.id)
            new_npc_event_unlocked.emit(event)

func get_npc_progress(npc_id: String) -> Dictionary:
    """获取特定NPC的进度信息 - 基于具体事件完成情况"""
    var npc_events = events_by_npc.get(npc_id, [])
    
    var completed_events = []
    var available_events = []
    var locked_events = []
    
    for event in npc_events:
        if event.id in encountered_events:
            completed_events.append(event.id)
        else:
            # 检查是否可以触发（不考虑天数和区域，只看前置条件）
            var can_unlock = true
            for prerequisite_id in event.previous_encounters:
                if prerequisite_id not in encountered_events:
                    can_unlock = false
                    break
            
            if can_unlock:
                available_events.append(event.id)
            else:
                locked_events.append(event.id)
    
    return {
        "npc_id": npc_id,
        "total_events": npc_events.size(),
        "completed_events": completed_events,
        "available_events": available_events,
        "locked_events": locked_events,
        "completion_rate": float(completed_events.size()) / float(npc_events.size()) if npc_events.size() > 0 else 0.0
    }
    
func get_max_encounters_for_npc(npc_id: String) -> int:
    """获取NPC的最大遇见次数 - 改为基于具体事件数量"""
    var npc_events = events_by_npc.get(npc_id, [])
    return npc_events.size()  # 直接返回该NPC的事件总数
    
func reset_progress():
    """重置所有进度（新游戏时调用）"""
    encountered_events.clear()
    npc_encounter_counts.clear()
    
    for event in all_npc_events:
        event.times_encountered = 0
        event.last_encounter_day = -1
        event.current_mood_score = 50.0
        event.is_available = true
    
    print("🔄 NPC进度已重置")

func get_debug_info() -> Dictionary:
    """获取调试信息"""
    return {
        "total_events": all_npc_events.size(),
        "events_by_area": get_area_event_counts(),
        "events_by_npc": get_npc_event_counts(),
        "encountered_events": encountered_events.size(),
        "npc_encounter_counts": npc_encounter_counts,
        "loaded_directories": npc_dirs
    }

func get_area_event_counts() -> Dictionary:
    """获取各区域的事件数量"""
    var counts = {}
    for area in events_by_area.keys():
        counts[area] = events_by_area[area].size()
    return counts

func get_npc_event_counts() -> Dictionary:
    """获取各NPC的事件数量"""
    var counts = {}
    for npc_id in events_by_npc.keys():
        counts[npc_id] = events_by_npc[npc_id].size()
    return counts

func create_sample_npc_files(dir_path: String, dir_name: String):
    """创建示例NPC文件"""
    print("🔧 创建示例NPC文件: ", dir_name)
    
    # 创建目录
    if not DirAccess.dir_exists_absolute(dir_path):
        DirAccess.open("res://").make_dir_recursive(dir_path.replace("res://", ""))
    
    match dir_name:
        "business_district":
            create_sarah_sample_file(dir_path)
        "residential":
            create_old_wang_sample_file(dir_path)
        _:
            print("  ⚠️  暂无", dir_name, "的示例文件")

func create_sarah_sample_file(dir_path: String):
    """创建Sarah示例文件"""
    var sarah_data = {
        "npc_info": {
            "npc_id": "sarah",
            "npc_name": "Sarah",
            "archetype": "伪装白领",
            "primary_area": "business_district",
            "background": "影子学院3年前的优秀毕业生，被作为宣传样本，实际内心极度空虚"
        },
        "events": [
            {
                "id": "sarah_business_1",
                "encounter_type": "first",
                "area": "business_district",
                "unlock_day": 1,
                "trigger_conditions": {
                    "time_range": ["22:00", "02:00"],
                    "weather": ["any"]
                },
                "dialogue": [
                    "又是一个加班到深夜的日子...我得到了想要的一切，为什么还是觉得空虚？",
                    "有时候我觉得自己像个机器人，每天重复着同样的动作和表情。",
                    "你说，我还能找回真正的自己吗？那个在影子学院之前的我？"
                ],
                "interrupt_responses": {
                    "empathy": "谢谢你理解...很少有人愿意听我说这些",
                    "self_reflection": "你也有过这种感受吗？",
                    "openness": "也许我真的需要改变什么",
                    "basic": "嗯...也许这就是成年人的生活吧"
                },
                "game_effects": {
                    "driving_preferences": {
                        "smooth_driving": 0.9,
                        "music_soothing": 0.8,
                        "close_window": 0.7
                    },
                    "economic": {
                        "base_fee": 75,
                        "tip_range": [10, 25]
                    },
                    "attributes": {
                        "successful_interaction": {"empathy": 1.0, "self_connection": 0.5}
                    }
                }
            }
        ]
    }
    
    var file = FileAccess.open(dir_path + "sarah.json", FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(sarah_data, "\t"))
        file.close()
        print("✅ Sarah示例文件已创建")

func create_old_wang_sample_file(dir_path: String):
    """创建老王示例文件"""
    var wang_data = {
        "npc_info": {
            "npc_id": "old_wang",
            "npc_name": "老王",
            "archetype": "记忆守护者",
            "primary_area": "residential",
            "background": "经历过'模糊时期'的退休教师，暗中保存古老的情感表达方式"
        },
        "events": [
            {
                "id": "wang_residential_1",
                "encounter_type": "first",
                "area": "residential",
                "unlock_day": 1,
                "trigger_conditions": {
                    "time_range": ["20:00", "23:00"],
                    "weather": ["any"]
                },
                "dialogue": [
                    "年轻人，我经历过'模糊时期'前的日子...那时候人们会用诗歌表达复杂的情感。",
                    "有些美好的东西，只存在于记忆中了。但我想把这些留给还记得如何感受的人。",
                    "这个城市变化太快，但人心中对真实的渴望从未改变。"
                ],
                "interrupt_responses": {
                    "empathy": "你有一颗善良的心，这在现在很珍贵",
                    "openness": "愿意学习古老智慧的年轻人不多了",
                    "basic": "是啊，时代不同了"
                },
                "game_effects": {
                    "driving_preferences": {
                        "smooth_driving": 1.0,
                        "music_off": 0.8
                    },
                    "economic": {
                        "base_fee": 45,
                        "tip_range": [5, 15]
                    },
                    "attributes": {
                        "successful_interaction": {"openness": 1.0, "self_connection": 0.5}
                    }
                }
            }
        ]
    }
    
    var file = FileAccess.open(dir_path + "old_wang.json", FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(wang_data, "\t"))
        file.close()
        print("✅ 老王示例文件已创建")
