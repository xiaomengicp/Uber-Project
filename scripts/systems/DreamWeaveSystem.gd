# DreamWeaveSystem.gd - 梦网系统，基于玩家体验生成内容
extends Node
class_name DreamWeaveSystem

# 信号定义
signal content_liked(content_id: String, content_type: String)
signal browsing_completed(total_likes: int, attribute_changes: Dictionary)

# 梦网内容类型枚举
enum ContentType {
    SYSTEM_PROPAGANDA,     # 系统宣传
    UNDERGROUND_WHISPER,   # 地下低语
    MEMORY_FRAGMENT,       # 记忆片段
    EMOTIONAL_EXPRESSION,  # 情感表达
    DAILY_REFLECTION,      # 日常反思
    CULTURAL_HERITAGE,     # 文化传承
    RESISTANCE_SIGNAL,     # 抵抗信号
    HEALING_MESSAGE        # 治愈信息
}

# 内容数据结构
var content_template = {
    "id": "",
    "type": ContentType.DAILY_REFLECTION,
    "author": "",
    "content": "",
    "tags": [],
    "sentiment": "neutral",  # "positive", "negative", "neutral"
    "like_effects": {},      # 点赞后的属性影响
    "unlock_condition": {},  # 解锁条件
    "is_liked": false
}

# 当前会话数据
var daily_content: Array = []
var player_interactions: Dictionary = {}
var browsing_session_active: bool = false

# 内容生成权重
var content_weights: Dictionary = {
    ContentType.SYSTEM_PROPAGANDA: 0.2,
    ContentType.UNDERGROUND_WHISPER: 0.15,
    ContentType.MEMORY_FRAGMENT: 0.15,
    ContentType.EMOTIONAL_EXPRESSION: 0.2,
    ContentType.DAILY_REFLECTION: 0.15,
    ContentType.CULTURAL_HERITAGE: 0.05,
    ContentType.RESISTANCE_SIGNAL: 0.05,
    ContentType.HEALING_MESSAGE: 0.05
}

func _ready():
    print("🌐 DreamWeaveSystem初始化...")

func generate_daily_content(player_stats, current_day: int, recent_npcs: Array = [], recent_events: Array = []) -> Array:
    """生成当日梦网内容"""
    print("🌐 生成第", current_day, "天的梦网内容...")
    
    daily_content.clear()
    
    # 基于玩家状态和体验生成5-8条内容
    var content_count = randi_range(5, 8)
    
    for i in range(content_count):
        var content_type = select_content_type_by_weight(player_stats, recent_npcs, recent_events)
        var content = generate_content_by_type(content_type, player_stats, current_day, recent_npcs, recent_events)
        
        if content != null:
            daily_content.append(content)
    
    print("✅ 生成了", daily_content.size(), "条梦网内容")
    return daily_content

func select_content_type_by_weight(player_stats, recent_npcs: Array, recent_events: Array) -> ContentType:
    """基于权重和玩家状态选择内容类型"""
    var adjusted_weights = content_weights.duplicate()
    
    # 根据玩家属性调整权重
    if player_stats != null:
        # 高压力时增加治愈信息权重
        if player_stats.pressure > 70:
            adjusted_weights[ContentType.HEALING_MESSAGE] *= 2.0
            adjusted_weights[ContentType.SYSTEM_PROPAGANDA] *= 0.5
        
        # 高开放度时增加地下内容权重
        if player_stats.openness > 65:
            adjusted_weights[ContentType.UNDERGROUND_WHISPER] *= 1.5
            adjusted_weights[ContentType.RESISTANCE_SIGNAL] *= 1.5
        
        # 高自省时增加反思内容权重
        if player_stats.self_connection > 65:
            adjusted_weights[ContentType.DAILY_REFLECTION] *= 1.5
            adjusted_weights[ContentType.MEMORY_FRAGMENT] *= 1.5
        
        # 高共情时增加情感表达权重
        if player_stats.empathy > 65:
            adjusted_weights[ContentType.EMOTIONAL_EXPRESSION] *= 1.5
            adjusted_weights[ContentType.HEALING_MESSAGE] *= 1.2
    
    # 基于最近遇到的NPC调整权重
    for npc_id in recent_npcs:
        match npc_id:
            "old_wang":
                adjusted_weights[ContentType.CULTURAL_HERITAGE] *= 2.0
                adjusted_weights[ContentType.MEMORY_FRAGMENT] *= 1.5
            "jamie":
                adjusted_weights[ContentType.UNDERGROUND_WHISPER] *= 1.5
                adjusted_weights[ContentType.RESISTANCE_SIGNAL] *= 1.5
            "robin":
                adjusted_weights[ContentType.HEALING_MESSAGE] *= 1.5
                adjusted_weights[ContentType.RESISTANCE_SIGNAL] *= 1.2
            "sarah", "kevin":
                adjusted_weights[ContentType.EMOTIONAL_EXPRESSION] *= 1.3
                adjusted_weights[ContentType.DAILY_REFLECTION] *= 1.3
    
    # 权重随机选择
    return weighted_random_selection(adjusted_weights)

func weighted_random_selection(weights: Dictionary) -> ContentType:
    """权重随机选择"""
    var total_weight = 0.0
    for weight in weights.values():
        total_weight += weight
    
    var random_value = randf() * total_weight
    var current_weight = 0.0
    
    for content_type in weights.keys():
        current_weight += weights[content_type]
        if random_value <= current_weight:
            return content_type
    
    return ContentType.DAILY_REFLECTION  # 默认值

func generate_content_by_type(content_type: ContentType, player_stats, current_day: int, recent_npcs: Array, recent_events: Array) -> Dictionary:
    """根据类型生成具体内容"""
    var content = content_template.duplicate(true)
    content.id = "content_" + str(current_day) + "_" + str(daily_content.size())
    content.type = content_type
    
    match content_type:
        ContentType.SYSTEM_PROPAGANDA:
            generate_system_propaganda(content, player_stats, current_day)
        ContentType.UNDERGROUND_WHISPER:
            generate_underground_whisper(content, player_stats, recent_npcs)
        ContentType.MEMORY_FRAGMENT:
            generate_memory_fragment(content, player_stats, recent_npcs)
        ContentType.EMOTIONAL_EXPRESSION:
            generate_emotional_expression(content, player_stats, recent_events)
        ContentType.DAILY_REFLECTION:
            generate_daily_reflection(content, player_stats, current_day)
        ContentType.CULTURAL_HERITAGE:
            generate_cultural_heritage(content, player_stats, recent_npcs)
        ContentType.RESISTANCE_SIGNAL:
            generate_resistance_signal(content, player_stats, recent_npcs)
        ContentType.HEALING_MESSAGE:
            generate_healing_message(content, player_stats)
    
    return content

func generate_system_propaganda(content: Dictionary, player_stats, current_day: int):
    """生成系统宣传内容"""
    var propaganda_messages = [
        "今日情绪评分系统升级完成，新算法将更好地维护社会和谐稳定。",
        "影子学院本月毕业率达98.7%，创历史新高！优秀整合案例持续涌现。",
        "市民情绪稳定度较上月提升15%，感谢大家的配合与支持。",
        "温馨提醒：异常情绪波动可能影响健康，请及时寻求专业调节服务。",
        "科学研究表明，情绪管控训练可有效提升工作效率和生活质量。",
        "本周情绪异常报告下降23%，证明我们的管理体系正在发挥积极作用。",
        "新一代情感平衡药物即将上市，副作用更小，效果更持久。"
    ]
    
    content.author = "官方发布"
    content.content = propaganda_messages[randi() % propaganda_messages.size()]
    content.sentiment = "positive"
    content.tags = ["官方", "政策", "健康"]
    content.like_effects = {
        "pressure": 0.3,  # 点赞系统宣传增加压力
        "self_connection": -0.2
    }

func generate_underground_whisper(content: Dictionary, player_stats, recent_npcs: Array):
    """生成地下低语内容"""
    var whisper_messages = [
        "深夜频道：有人在传递古老的梦语密码，懂的人自然懂。",
        "今晚的星空特别亮，是因为有人在用心观看。",
        "某个废弃地下通道里，传来了久违的真实歌声。",
        "听说城东有个书店，老板会在特定时间分享'特殊'的诗集。",
        "有朋友说，月圆之夜在公园里散步，能听到心灵的呼唤。",
        "据说有个治愈师，专门帮助那些被'整合'伤害的人。",
        "匿名消息：真正的艺术从未消失，只是转入了地下。"
    ]
    
    # 基于最近遇到的NPC调整消息
    if "jamie" in recent_npcs:
        whisper_messages.append("某个音乐人正在组织秘密演出，只邀请真正懂音乐的人。")
    if "old_wang" in recent_npcs:
        whisper_messages.append("有老师愿意分享被遗忘的文化记忆，但需要找对人。")
    
    content.author = "匿名用户"
    content.content = whisper_messages[randi() % whisper_messages.size()]
    content.sentiment = "neutral"
    content.tags = ["地下", "神秘", "文化"]
    content.like_effects = {
        "openness": 0.5,
        "self_connection": 0.3,
        "pressure": -0.2
    }

func generate_memory_fragment(content: Dictionary, player_stats, recent_npcs: Array):
    """生成记忆片段内容"""
    var memory_messages = [
        "突然想起小时候和奶奶一起看星星的夜晚，那时候的月亮好像更亮。",
        "翻到一张旧照片，里面的笑容是那么真实，现在很难找到了。",
        "梦见了学校里的梧桐树，秋天的叶子黄得像诗句一样。",
        "闻到桂花香，想起了初恋时牵手的紧张和甜蜜。",
        "看到一个孩子在追蝴蝶，想起我也曾经那样无忧无虑。",
        "听到某首老歌，眼泪不自觉地流了下来，心里有种说不出的感动。",
        "下雨的时候想起妈妈的怀抱，那是世界上最安全的地方。"
    ]
    
    # 基于王老师遇见增加文化记忆
    if "old_wang" in recent_npcs:
        memory_messages.extend([
            "忽然想起小学语文课上学过的诗：'春有百花秋有月，夏有凉风冬有雪。'",
            "记起老师说过的话：'诗歌是心灵的语言，不需要翻译。'"
        ])
    
    content.author = get_random_memory_author()
    content.content = memory_messages[randi() % memory_messages.size()]
    content.sentiment = "positive"
    content.tags = ["回忆", "童年", "情感"]
    content.like_effects = {
        "self_connection": 0.8,
        "empathy": 0.4,
        "pressure": -0.3
    }

func generate_emotional_expression(content: Dictionary, player_stats, recent_events: Array):
    """生成情感表达内容"""
    var expression_messages = [
        "今天第一次在很久以后真正地哭了，原来眼泪可以这么温暖。",
        "在公园里看到一对老夫妻手牵手散步，心中涌起说不出的感动。",
        "突然想对所有爱过我的人说声谢谢，即使他们可能听不到。",
        "工作再忙，也要记得停下来感受夕阳的美好。",
        "发现自己还能被一首歌感动到起鸡皮疙瘩，这感觉真好。",
        "有时候孤独，但知道世界上还有人在真诚地生活着，就不怕了。",
        "想念那些能让我做真实自己的人，希望他们都好。"
    ]
    
    # 基于最近的情感事件调整
    if player_stats != null and player_stats.pressure > 70:
        expression_messages.extend([
            "压力很大的时候，想起还有人在乎我，就有力气继续下去。",
            "累了，但不想放弃做一个有温度的人。"
        ])
    
    content.author = get_random_emotional_author()
    content.content = expression_messages[randi() % expression_messages.size()]
    content.sentiment = "positive"
    content.tags = ["情感", "真实", "感动"]
    content.like_effects = {
        "empathy": 0.6,
        "self_connection": 0.4,
        "pressure": -0.4
    }

func generate_daily_reflection(content: Dictionary, player_stats, current_day: int):
    """生成日常反思内容"""
    var reflection_messages = [
        "今天试着对镜子里的自己微笑，发现原来我还记得怎么笑。",
        "走路的时候没有看手机，发现街上有很多被忽略的美好。",
        "主动和陌生人说了'谢谢'，看到对方眼中的惊喜，心情很好。",
        "深夜的时候问自己：什么时候开始，我不再为小事感到快乐了？",
        "整理房间的时候找到一些旧物，想起曾经的梦想，还没有完全消失。",
        "发现自己很久没有仰望过星空了，今晚要试试。",
        "思考什么是真正的成功，也许不是别人定义的那样。"
    ]
    
    # 基于游戏天数调整反思深度
    if current_day >= 5:
        reflection_messages.extend([
            "这几天的经历让我重新思考什么是真正重要的。",
            "开始学会倾听内心的声音，而不是外界的评判。"
        ])
    
    content.author = "夜行思考者"
    content.content = reflection_messages[randi() % reflection_messages.size()]
    content.sentiment = "neutral"
    content.tags = ["反思", "成长", "自省"]
    content.like_effects = {
        "self_connection": 0.7,
        "openness": 0.3,
        "pressure": -0.2
    }

func generate_cultural_heritage(content: Dictionary, player_stats, recent_npcs: Array):
    """生成文化传承内容"""
    var heritage_messages = [
        "『山重水复疑无路，柳暗花明又一村。』—— 古人的智慧在今天依然闪光。",
        "听老人讲过去的故事，那时候的人们用诗歌表达复杂的情感。",
        "找到一本旧书，里面有手写的批注，感受到前人的温度。",
        "学会了一个传统手工艺，手工的温度是机器无法替代的。",
        "『落红不是无情物，化作春泥更护花。』—— 每次读到都有不同的感悟。",
        "祖母的摇篮曲，是世界上最古老也最温暖的音乐。",
        "传统节日不只是假期，更是文化记忆的载体。"
    ]
    
    # 王老师相关内容
    if "old_wang" in recent_npcs:
        heritage_messages.extend([
            "感谢那些默默保存文化记忆的人，他们是真正的守护者。",
            "『春有百花秋有月，夏有凉风冬有雪』—— 简单的诗句包含深刻的生活智慧。"
        ])
    
    content.author = "文化守护者"
    content.content = heritage_messages[randi() % heritage_messages.size()]
    content.sentiment = "positive"
    content.tags = ["文化", "传统", "智慧"]
    content.like_effects = {
        "openness": 0.8,
        "self_connection": 0.5,
        "empathy": 0.3
    }

func generate_resistance_signal(content: Dictionary, player_stats, recent_npcs: Array):
    """生成抵抗信号内容"""
    var resistance_messages = [
        "真正的治愈不是让人变得麻木，而是让人重新感受到活着的意义。",
        "坚持做真实的自己，即使这个世界试图让你变成别人。",
        "艺术的力量在于唤醒，而不是安抚。",
        "每一次真诚的对话，都是对冷漠世界的小小抵抗。",
        "保持疑问的勇气，不要让标准答案替代独立思考。",
        "真正的教育是点燃火焰，而不是填满木桶。",
        "选择性家庭的意义：血缘不是唯一的连接方式。"
    ]
    
    # 基于特定NPC增加相关内容
    if "jamie" in recent_npcs:
        resistance_messages.append("音乐是他们还没学会完全控制的语言。")
    if "robin" in recent_npcs:
        resistance_messages.append("真正的医疗是治愈人，而不是管理数据。")
    
    content.author = "自由思考者"
    content.content = resistance_messages[randi() % resistance_messages.size()]
    content.sentiment = "neutral"
    content.tags = ["抵抗", "自由", "思考"]
    content.like_effects = {
        "openness": 1.0,
        "self_connection": 0.8,
        "pressure": -0.5
    }

func generate_healing_message(content: Dictionary, player_stats):
    """生成治愈信息内容"""
    var healing_messages = [
        "你已经很努力了，给自己一些时间和耐心。",
        "每个人都值得被温柔对待，包括你自己。",
        "治愈不是忘记痛苦，而是学会与它和解。",
        "你的存在本身就有意义，不需要证明什么。",
        "今天也要记得好好吃饭，好好休息，好好爱自己。",
        "世界很大，总有人会理解你的不同。",
        "慢一点没关系，重要的是朝着正确的方向。"
    ]
    
    # 基于压力状态调整治愈消息
    if player_stats != null and player_stats.pressure > 80:
        healing_messages.extend([
            "累的时候可以停下来，休息不是放弃。",
            "你不需要变得完美，只需要保持真实。"
        ])
    
    content.author = "温暖的陌生人"
    content.content = healing_messages[randi() % healing_messages.size()]
    content.sentiment = "positive"
    content.tags = ["治愈", "温暖", "支持"]
    content.like_effects = {
        "pressure": -0.8,
        "empathy": 0.4,
        "self_connection": 0.3
    }

func get_random_memory_author() -> String:
    """获取随机的记忆作者名"""
    var authors = ["回忆者", "怀旧的人", "记忆收集者", "时光旅人", "往昔追寻者"]
    return authors[randi() % authors.size()]

func get_random_emotional_author() -> String:
    """获取随机的情感表达作者名"""
    var authors = ["感性的人", "情感表达者", "真实的声音", "心灵书写者", "情感探索者"]
    return authors[randi() % authors.size()]

func start_browsing_session() -> Array:
    """开始浏览会话"""
    print("🌐 开始梦网浏览会话")
    browsing_session_active = true
    player_interactions.clear()
    
    # 随机打乱内容顺序
    daily_content.shuffle()
    
    return daily_content

func like_content(content_id: String) -> Dictionary:
    """点赞内容"""
    print("👍 点赞内容：", content_id)
    
    var content = find_content_by_id(content_id)
    if content == null:
        print("❌ 未找到内容：", content_id)
        return {}
    
    if content.is_liked:
        print("⚠️ 内容已经点赞过：", content_id)
        return {}
    
    content.is_liked = true
    player_interactions[content_id] = "liked"
    
    # 应用属性影响
    var effects = content.like_effects
    content_liked.emit(content_id, ContentType.keys()[content.type])
    
    print("✅ 点赞成功，属性效果：", effects)
    return effects

func find_content_by_id(content_id: String) -> Dictionary:
    """根据ID查找内容"""
    for content in daily_content:
        if content.id == content_id:
            return content
    return {}

func complete_browsing_session() -> Dictionary:
    """完成浏览会话"""
    print("🌐 完成梦网浏览会话")
    browsing_session_active = false
    
    var total_likes = 0
    var total_attribute_changes = {}
    
    # 计算总的属性变化
    for content in daily_content:
        if content.is_liked:
            total_likes += 1
            for attr in content.like_effects.keys():
                var change = content.like_effects[attr]
                if attr in total_attribute_changes:
                    total_attribute_changes[attr] += change
                else:
                    total_attribute_changes[attr] = change
    
    # 添加浏览本身的轻微压力（信息过载）
    if total_likes == 0:
        total_attribute_changes["pressure"] = total_attribute_changes.get("pressure", 0.0) + 0.2
    
    var session_result = {
        "total_likes": total_likes,
        "attribute_changes": total_attribute_changes,
        "content_count": daily_content.size()
    }
    
    browsing_completed.emit(total_likes, total_attribute_changes)
    
    print("📊 浏览结果：", total_likes, "个赞，属性变化：", total_attribute_changes)
    return session_result

func get_session_status() -> Dictionary:
    """获取会话状态"""
    return {
        "is_active": browsing_session_active,
        "content_count": daily_content.size(),
        "interactions_count": player_interactions.size()
    }

func get_content_preview(max_content: int = 5) -> Array:
    """获取内容预览（用于UI显示）"""
    var preview = []
    var count = min(max_content, daily_content.size())
    
    for i in range(count):
        var content = daily_content[i]
        preview.append({
            "id": content.id,
            "author": content.author,
            "content": content.content,
            "tags": content.tags,
            "is_liked": content.is_liked,
            "sentiment": content.sentiment
        })
    
    return preview

func reset_daily_content():
    """重置每日内容（新游戏时调用）"""
    daily_content.clear()
    player_interactions.clear()
    browsing_session_active = false
    print("🔄 梦网内容已重置")
