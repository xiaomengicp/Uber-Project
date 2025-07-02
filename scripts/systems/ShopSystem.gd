# ShopSystem.gd - 完整的商店系统
extends Node
class_name ShopSystem

# 信号定义
signal item_purchased(item_id: String, item_data: Dictionary)
signal purchase_failed(reason: String)
signal shop_updated()

# 商品数据结构
var shop_items: Array[Dictionary] = []
var purchased_items: Array[String] = []

# 商店配置
var shop_config: Dictionary = {}

func _ready():
    load_shop_config()
    setup_shop_items()
    print("✅ 商店系统初始化完成")

func load_shop_config():
    """加载商店配置"""
    # 从配置文件加载，如果没有则使用默认值
    shop_config = {
        "daily_refresh": false,
        "discount_events": {},
        "category_unlocks": {
            "basic": 0,        # 第0天解锁基础物品
            "exploration": 1,   # 第1天解锁自我探索
            "healing": 2,      # 第2天解锁情感治愈
            "special": 3       # 第3天解锁特殊物品
        }
    }
    print("✅ 商店配置加载完成")

func setup_shop_items():
    """设置所有商店物品"""
    shop_items.clear()
    
    # ============ 生活必需品类 ============
    add_shop_item({
        "id": "coffee",
        "name": "咖啡",
        "price": 15,
        "category": "basic",
        "description": "提神醒脑，缓解疲劳。在这个高压的世界里，咖啡因是最后的朋友。",
        "effects": {
            "pressure": -2,
            "energy": 1
        },
        "unlock_condition": {},
        "can_buy_multiple": true,
        "story_text": "热气腾腾的咖啡让你暂时忘记了系统的监控。"
    })
    
    add_shop_item({
        "id": "simple_meal",
        "name": "简餐",
        "price": 25,
        "category": "basic",
        "description": "填饱肚子，保持体力。简单的食物，简单的满足。",
        "effects": {
            "pressure": -1,
            "empathy": 0.5
        },
        "unlock_condition": {},
        "can_buy_multiple": true,
        "story_text": "温暖的食物提醒你，身体的需求仍然是真实的。"
    })
    
    add_shop_item({
        "id": "good_sleep",
        "name": "优质睡眠",
        "price": 30,
        "category": "basic",
        "description": "升级住宿条件，获得更好的休息。睡眠是逃离监控的最后避难所。",
        "effects": {
            "pressure": -3,
            "self_connection": 0.5
        },
        "unlock_condition": {},
        "can_buy_multiple": false,
        "story_text": "在柔软的床褥中，你暂时逃离了系统的触手。"
    })
    
    # ============ 自我探索类 ============
    add_shop_item({
        "id": "psychology_book",
        "name": "心理学书籍",
        "price": 40,
        "category": "exploration",
        "description": "深入了解自己和他人。被禁书目之外的知识，珍贵而危险。",
        "effects": {
            "self_connection": 2,
            "empathy": 1,
            "openness": 0.5
        },
        "unlock_condition": {"day": 1},
        "can_buy_multiple": true,
        "story_text": "字里行间，你看到了被系统隐藏的人性真相。"
    })
    
    add_shop_item({
        "id": "meditation_guide",
        "name": "冥想指导",
        "price": 35,
        "category": "exploration",
        "description": "学习古老的内观技巧。在喧嚣中寻找内心的宁静。",
        "effects": {
            "self_connection": 2.5,
            "pressure": -2,
            "openness": 0.3
        },
        "unlock_condition": {"day": 1},
        "can_buy_multiple": false,
        "story_text": "呼吸间，你触摸到了未被系统污染的内在空间。"
    })
    
    add_shop_item({
        "id": "art_supplies",
        "name": "艺术用品",
        "price": 45,
        "category": "exploration",
        "description": "颜料、画笔、纸张。创作是表达真实自我的最后方式。",
        "effects": {
            "openness": 2,
            "self_connection": 1,
            "pressure": -1
        },
        "unlock_condition": {"day": 1, "openness": 40},
        "can_buy_multiple": true,
        "story_text": "色彩在纸上流淌，你画出了内心无法言喻的风景。"
    })
    
    # ============ 情感治愈类 ============
    add_shop_item({
        "id": "music_album",
        "name": "独立音乐专辑",
        "price": 30,
        "category": "healing",
        "description": "地下音乐人的作品。这些旋律没有经过系统审查，保持着原始的情感力量。",
        "effects": {
            "openness": 1.5,
            "pressure": -1,
            "empathy": 0.5
        },
        "unlock_condition": {"day": 2},
        "can_buy_multiple": true,
        "story_text": "旋律在耳边响起，唤醒了你以为已经死去的感受。"
    })
    
    add_shop_item({
        "id": "skincare",
        "name": "护肤套装",
        "price": 50,
        "category": "healing",
        "description": "关爱自己的身体，从细节开始。自我关爱是对系统忽视的最好回应。",
        "effects": {
            "pressure": -3,
            "self_connection": 1,
            "empathy": 0.3
        },
        "unlock_condition": {"day": 2},
        "can_buy_multiple": false,
        "story_text": "镜子里的自己变得柔和，你记起了自我关爱的感觉。"
    })
    
    add_shop_item({
        "id": "memory_box",
        "name": "记忆盒子",
        "price": 60,
        "category": "healing",
        "description": "收集珍贵回忆的小盒子。有些东西，系统永远无法删除。",
        "effects": {
            "self_connection": 1.5,
            "pressure": -2,
            "empathy": 0.8
        },
        "unlock_condition": {"day": 2, "self_connection": 50},
        "can_buy_multiple": false,
        "story_text": "盒子里装着碎片化的美好，提醒你曾经拥有完整的自己。"
    })
    
    # ============ 特殊物品 (条件触发) ============
    add_shop_item({
        "id": "therapy_session",
        "name": "非正式心理咨询",
        "price": 100,
        "category": "special",
        "description": "与系统外的治愈师对话。危险但可能改变一切的体验。",
        "effects": {
            "self_connection": 3,
            "pressure": -5,
            "empathy": 1.5,
            "openness": 1
        },
        "unlock_condition": {"pressure": 70},
        "can_buy_multiple": false,
        "story_text": "在安全屋的深处，你第一次向另一个人袒露了真实的内心。"
    })
    
    add_shop_item({
        "id": "academy_consultation",
        "name": "前学院生咨询",
        "price": 120,
        "category": "special",
        "description": "与成功逃离学院的人交流。了解另一种可能的人生。",
        "effects": {
            "self_connection": 4,
            "pressure": -3,
            "openness": 2
        },
        "unlock_condition": {"day": 3, "self_connection": 60},
        "can_buy_multiple": false,
        "story_text": "他的眼中有你从未见过的平静，仿佛找到了自己的影子。"
    })
    
    add_shop_item({
        "id": "family_contact",
        "name": "选择性家庭联系",
        "price": 150,
        "category": "special",
        "description": "接触地下support网络。血缘之外的真正家庭。",
        "effects": {
            "empathy": 3,
            "self_connection": 2,
            "openness": 2,
            "pressure": -4
        },
        "unlock_condition": {"day": 4, "empathy": 70, "openness": 60},
        "can_buy_multiple": false,
        "story_text": "陌生人的拥抱比血亲更温暖，你明白了什么是真正的家。"
    })
    
    add_shop_item({
        "id": "shadow_integration",
        "name": "真正的影子整合",
        "price": 200,
        "category": "special",
        "description": "非学院版本的影子工作。危险，但可能让你找回完整的自己。",
        "effects": {
            "self_connection": 5,
            "empathy": 2,
            "openness": 1,
            "pressure": -6
        },
        "unlock_condition": {"day": 5, "self_connection": 80},
        "can_buy_multiple": false,
        "story_text": "在黑暗中，你终于拥抱了被学院厌恶的那部分自己。"
    })
    
    print("✅ 设置了", shop_items.size(), "个商店物品")

func add_shop_item(item_data: Dictionary):
    """添加商店物品"""
    shop_items.append(item_data)

func get_available_items(current_day: int, player_stats) -> Array[Dictionary]:
    """获取当前可购买的物品"""
    var available_items: Array[Dictionary] = []
    
    for item in shop_items:
        if is_item_available(item, current_day, player_stats):
            available_items.append(item)
    
    return available_items

func is_item_available(item: Dictionary, current_day: int, player_stats) -> bool:
    """检查物品是否可用"""
    var unlock_condition = item.get("unlock_condition", {})
    
    # 检查天数要求
    if unlock_condition.has("day") and current_day < unlock_condition.day:
        return false
    
    # 检查属性要求
    if player_stats != null:
        for attr in ["empathy", "self_connection", "openness", "pressure"]:
            if unlock_condition.has(attr):
                var required_value = unlock_condition[attr]
                var current_value = player_stats.get(attr)
                if current_value < required_value:
                    return false
    
    # 检查是否已购买且不能多次购买
    if not item.get("can_buy_multiple", true):
        if item.id in purchased_items:
            return false
    
    return true

func purchase_item(item_id: String, player_stats) -> Dictionary:
    """购买物品"""
    var item = find_item_by_id(item_id)
    if item.is_empty():
        var error = {"success": false, "reason": "物品不存在"}
        purchase_failed.emit(error.reason)
        return error
    
    # 检查金钱
    if player_stats.money < item.price:
        var error = {"success": false, "reason": "金钱不足"}
        purchase_failed.emit(error.reason)
        return error
    
    # 检查是否可以购买
    if not item.get("can_buy_multiple", true) and item.id in purchased_items:
        var error = {"success": false, "reason": "该物品只能购买一次"}
        purchase_failed.emit(error.reason)
        return error
    
    # 扣除金钱
    player_stats.money -= item.price
    player_stats.total_expenses += item.price
    
    # 应用效果
    apply_item_effects(item, player_stats)
    
    # 记录购买
    if not item.get("can_buy_multiple", true):
        purchased_items.append(item.id)
    
    # 记录到玩家数据
    if item.id not in player_stats.purchased_items:
        player_stats.purchased_items.append(item.id)
    
    print("✅ 购买成功：", item.name, " (-", item.price, "元)")
    
    # 发送信号
    item_purchased.emit(item.id, item)
    shop_updated.emit()
    
    return {
        "success": true,
        "item": item,
        "story_text": item.get("story_text", ""),
        "remaining_money": player_stats.money
    }

func apply_item_effects(item: Dictionary, player_stats):
    """应用物品效果"""
    var effects = item.get("effects", {})
    
    for attribute in effects.keys():
        var change = effects[attribute]
        if attribute in ["empathy", "self_connection", "openness", "pressure"]:
            # 使用GameManager来更新属性，保持一致性
            GameManager.update_player_attribute(attribute, change)
            print("  属性效果：", attribute, " ", ("+" if change >= 0 else ""), change)

func find_item_by_id(item_id: String) -> Dictionary:
    """根据ID查找物品"""
    for item in shop_items:
        if item.id == item_id:
            return item
    return {}

func get_item_category_name(category: String) -> String:
    """获取物品分类名称"""
    match category:
        "basic":
            return "生活必需品"
        "exploration":
            return "自我探索"
        "healing":
            return "情感治愈"
        "special":
            return "特殊物品"
        _:
            return "其他"

func get_category_description(category: String) -> String:
    """获取分类描述"""
    match category:
        "basic":
            return "维持基本生活需求的物品"
        "exploration":
            return "帮助自我认知和成长的工具"
        "healing":
            return "治愈心灵创伤的温暖物品"
        "special":
            return "改变人生轨迹的稀有体验"
        _:
            return ""

func get_shop_status(current_day: int, player_stats) -> Dictionary:
    """获取商店状态信息"""
    var available_items = get_available_items(current_day, player_stats)
    var categories = {}
    
    # 按分类组织物品
    for item in available_items:
        var category = item.get("category", "other")
        if category not in categories:
            categories[category] = []
        categories[category].append(item)
    
    return {
        "total_items": available_items.size(),
        "categories": categories,
        "player_money": player_stats.money if player_stats != null else 0,
        "purchased_count": purchased_items.size()
    }

func reset_shop():
    """重置商店状态（新游戏时调用）"""
    purchased_items.clear()
    print("🔄 商店状态已重置")
