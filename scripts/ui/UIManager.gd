# UIManager.gd - 调试版本，修复AI助手面板显示问题
class_name UIManager
extends Node

# 信号定义
signal ui_switched(ui_name: String)
signal area_selected(area_name: String)
signal button_pressed(button_id: String, data: Dictionary)

# UI节点引用
var ui_container: Control
var start_ui: Control
var area_selection_ui: Control  
var driving_ui: Control
var home_ui: Control
var shop_ui: Control

# 特殊UI组件
var ai_assistant_panel: Panel
var ai_message_label: Label  # 改为Label类型
var ai_countdown_label: Label

# 当前UI状态
var current_ui: Control
var ui_nodes: Dictionary = {}

func initialize(main_scene: Control):
    """初始化UI管理器"""
    print("🔧 UIManager初始化...")
    
    # 获取UI节点引用
    ui_container = main_scene.get_node("UIContainer")
    if ui_container == null:
        print("❌ 无法找到UIContainer")
        return
    
    start_ui = ui_container.get_node("StartUI")
    area_selection_ui = ui_container.get_node("AreaSelectionUI")
    driving_ui = ui_container.get_node("DrivingUI")
    home_ui = ui_container.get_node("HomeUI")
    shop_ui = ui_container.get_node("ShopUI")
    
    print("✅ UI节点获取完成")
    print("   driving_ui: ", driving_ui)
    
    # 存储UI节点映射
    ui_nodes = {
        "start": start_ui,
        "area_selection": area_selection_ui,
        "driving": driving_ui,
        "home": home_ui,
        "shop": shop_ui
    }
    
    # 应用字体主题
    apply_fonts()
    
    # 连接按钮信号
    connect_ui_signals()
    
    # 创建AI助手UI - 延迟到驾驶界面激活时
    # create_ai_assistant_ui()
    
    print("✅ UIManager初始化完成")

func apply_fonts():
    """应用字体主题到所有UI"""
    if has_node("/root/FontManager"):
        FontManager.apply_theme_to_node(ui_container)
        
        # 等待一帧确保节点准备好
        await get_tree().process_frame
        
        # 特殊处理对话标签字体
        var dialogue_label = get_dialogue_label()
        if dialogue_label != null:
            FontManager.force_apply_font_to_node(dialogue_label)
            dialogue_label.fit_content = true
            dialogue_label.scroll_active = false
            print("✅ 对话字体设置完成")

func connect_ui_signals():
    """连接所有UI按钮信号"""
    # StartUI 按钮
    start_ui.get_node("CenterContainer/VBoxContainer/StartButton").pressed.connect(_on_button_pressed.bind("start_game"))
    start_ui.get_node("CenterContainer/VBoxContainer/ContinueButton").pressed.connect(_on_button_pressed.bind("continue_game"))
    start_ui.get_node("CenterContainer/VBoxContainer/SettingsButton").pressed.connect(_on_button_pressed.bind("settings"))
    start_ui.get_node("CenterContainer/VBoxContainer/QuitButton").pressed.connect(_on_button_pressed.bind("quit"))
    
    # AreaSelectionUI 按钮
    area_selection_ui.get_node("VBoxContainer/BusinessButton").pressed.connect(_on_area_selected.bind("business"))
    area_selection_ui.get_node("VBoxContainer/ResidentialButton").pressed.connect(_on_area_selected.bind("residential"))
    area_selection_ui.get_node("VBoxContainer/EntertainmentButton").pressed.connect(_on_area_selected.bind("entertainment"))
    area_selection_ui.get_node("VBoxContainer/SuburbanButton").pressed.connect(_on_area_selected.bind("suburban"))
    
    # HomeUI 按钮
    home_ui.get_node("CenterContainer/VBoxContainer/DreamweaveButton").pressed.connect(_on_button_pressed.bind("browse_dreamweave"))
    home_ui.get_node("CenterContainer/VBoxContainer/ShopButton").pressed.connect(_on_button_pressed.bind("go_shopping"))
    home_ui.get_node("CenterContainer/VBoxContainer/SleepButton").pressed.connect(_on_button_pressed.bind("sleep"))
    
    # ShopUI 按钮
    shop_ui.get_node("VBoxContainer/ReturnButton").pressed.connect(_on_button_pressed.bind("return_home"))
    
    print("✅ UI信号连接完成")

func ensure_ai_assistant_created():
    """确保AI助手UI已创建"""
    if ai_assistant_panel != null:
        print("✅ AI助手面板已存在")
        return
    
    if driving_ui == null:
        print("❌ driving_ui为null，无法创建AI助手")
        return
    
    print("🔧 创建AI助手UI...")
    create_ai_assistant_ui()

func create_ai_assistant_ui():
    """创建AI助手界面"""
    print("🔧 开始创建AI助手界面...")
    
    # 创建AI助手面板
    ai_assistant_panel = Panel.new()
    ai_assistant_panel.name = "AIAssistantPanel"
    ai_assistant_panel.visible = false  # 初始隐藏
    
    # 设置位置和大小 - 使用绝对位置确保可见
    ai_assistant_panel.position = Vector2(50, 50)  # 左上角位置，便于调试
    ai_assistant_panel.size = Vector2(400, 150)    # 稍大一些
    
    # 设置面板样式
    var panel_style = StyleBoxFlat.new()
    panel_style.bg_color = Color(0.1, 0.2, 0.4, 0.95)  # 更明显的蓝色
    panel_style.border_color = Color.CYAN             # 青色边框，便于看到
    panel_style.border_width_left = 3
    panel_style.border_width_right = 3
    panel_style.border_width_top = 3
    panel_style.border_width_bottom = 3
    panel_style.corner_radius_top_left = 8
    panel_style.corner_radius_top_right = 8
    panel_style.corner_radius_bottom_left = 8
    panel_style.corner_radius_bottom_right = 8
    ai_assistant_panel.add_theme_stylebox_override("panel", panel_style)
    
    # 创建垂直布局
    var vbox = VBoxContainer.new()
    vbox.anchors_preset = Control.PRESET_FULL_RECT
    vbox.offset_left = 15
    vbox.offset_right = -15
    vbox.offset_top = 10
    vbox.offset_bottom = -10
    ai_assistant_panel.add_child(vbox)
    
    # AI助手标题
    var ai_title = Label.new()
    ai_title.text = "🤖 ARIA 驾驶助手"
    ai_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ai_title.add_theme_font_size_override("font_size", 16)
    ai_title.add_theme_color_override("font_color", Color.WHITE)
    vbox.add_child(ai_title)
    
    # AI消息显示
    ai_message_label = Label.new()  # 改用Label而不是RichTextLabel避免问题
    ai_message_label.text = ""
    ai_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    ai_message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    ai_message_label.add_theme_font_size_override("font_size", 14)
    ai_message_label.add_theme_color_override("font_color", Color.WHITE)
    vbox.add_child(ai_message_label)
    
    # 倒计时显示
    ai_countdown_label = Label.new()
    ai_countdown_label.text = ""
    ai_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ai_countdown_label.add_theme_font_size_override("font_size", 18)
    ai_countdown_label.add_theme_color_override("font_color", Color.YELLOW)
    vbox.add_child(ai_countdown_label)
    
    # 添加到驾驶界面
    driving_ui.add_child(ai_assistant_panel)
    print("✅ AI助手面板添加到driving_ui")
    
    # 应用字体
    if has_node("/root/FontManager"):
        FontManager.force_apply_font_to_node(ai_message_label)
    
    print("✅ AI助手UI创建完成")
    print("   面板位置: ", ai_assistant_panel.position)
    print("   面板大小: ", ai_assistant_panel.size)

func switch_to_ui(ui_name: String):
    """切换到指定UI"""
    if ui_name not in ui_nodes:
        print("❌ 未知的UI名称：", ui_name)
        return
    
    var target_ui = ui_nodes[ui_name]
    if target_ui == null:
        print("❌ UI节点不存在：", ui_name)
        return
    
    # 隐藏所有UI
    hide_all_ui()
    
    # 显示目标UI
    target_ui.visible = true
    current_ui = target_ui
    
    # 如果切换到驾驶界面，确保AI助手已创建
    if ui_name == "driving":
        ensure_ai_assistant_created()
    
    print("✅ 切换到UI：", ui_name)
    ui_switched.emit(ui_name)

func hide_all_ui():
    """隐藏所有UI"""
    for ui in ui_nodes.values():
        if ui != null:
            ui.visible = false

func update_area_selection_display(current_day: int):
    """更新区域选择界面显示"""
    var day_label = area_selection_ui.get_node("VBoxContainer/DayLabel")
    if day_label != null:
        day_label.text = "第 %d 天" % current_day
    
    # 解锁逻辑
    var entertainment_button = area_selection_ui.get_node("VBoxContainer/EntertainmentButton")
    var suburban_button = area_selection_ui.get_node("VBoxContainer/SuburbanButton")
    
    if current_day >= 2 and entertainment_button != null:
        entertainment_button.disabled = false
    if current_day >= 3 and suburban_button != null:
        suburban_button.disabled = false

func update_home_display(daily_income: int, economic_status: String):
    """更新家中界面显示"""
    var stats_label = home_ui.get_node("CenterContainer/VBoxContainer/StatsLabel")
    if stats_label != null:
        stats_label.text = "今日收入: %d元\n当前状态: %s" % [daily_income, economic_status]


# ============ AI助手相关方法 ============
func show_ai_assistant(message: String, urgent: bool = false):
    """显示AI助手消息"""
    print("🤖 显示AI助手消息: ", message, " (紧急: ", urgent, ")")
    
    # 确保AI助手面板存在
    ensure_ai_assistant_created()
    
    if ai_assistant_panel == null:
        print("❌ AI助手面板仍然为null")
        return
    
    # 强制显示面板
    ai_assistant_panel.visible = true
    print("✅ AI助手面板设置为可见")
    
    if ai_message_label != null:
        ai_message_label.text = message
        print("✅ AI消息已设置:", message)
    else:
        print("❌ ai_message_label为null")
    
    # 根据紧急程度设置面板颜色
    var panel_style = ai_assistant_panel.get_theme_stylebox("panel")
    if panel_style != null:
        if urgent:
            panel_style.border_color = Color.RED
            panel_style.bg_color = Color(0.3, 0.1, 0.1, 0.95)
            print("🚨 设置为紧急样式")
        else:
            panel_style.border_color = Color.CYAN
            panel_style.bg_color = Color(0.1, 0.2, 0.4, 0.95)
            print("ℹ️ 设置为普通样式")
    
    # 强制刷新显示
    ai_assistant_panel.queue_redraw()
    
    print("🤖 ARIA显示完成: ", message, " [紧急]" if urgent else "")

func hide_ai_assistant():
    """隐藏AI助手"""
    print("🤖 隐藏AI助手")
    if ai_assistant_panel != null:
        ai_assistant_panel.visible = false
        print("✅ AI助手已隐藏")
    else:
        print("❌ ai_assistant_panel为null，无法隐藏")

func update_ai_countdown(remaining_time: float):
    """更新AI助手倒计时显示"""
    if ai_countdown_label != null:
        if remaining_time > 0:
            ai_countdown_label.text = "⏰ %.1f 秒" % remaining_time
        else:
            ai_countdown_label.text = ""

# ============ 获取特定UI元素的方法 ============
func get_dialogue_label() -> RichTextLabel:
    """获取对话标签"""
    if driving_ui == null:
        return null
    return driving_ui.get_node("ControlArea/DialogueArea/DialogueContainer/DialogueLabel")

func get_npc_name_label() -> Label:
    """获取NPC名字标签"""
    if driving_ui == null:
        return null
    return driving_ui.get_node("ControlArea/DialogueArea/DialogueContainer/NPCNameLabel")

func get_interrupt_buttons() -> Dictionary:
    """获取插话按钮"""
    if driving_ui == null:
        return {"button1": null, "button2": null}
    var container = driving_ui.get_node("ControlArea/DialogueArea/DialogueContainer/InterruptContainer")
    return {
        "button1": container.get_node("InterruptButton1"),
        "button2": container.get_node("InterruptButton2")
    }

func get_continue_button() -> Button:
    """获取继续按钮"""
    if driving_ui == null:
        return null
    return driving_ui.get_node("ControlArea/DialogueArea/DialogueContainer/ContinueButton")

func get_attribute_labels() -> Dictionary:
    """获取属性显示标签"""
    if driving_ui == null:
        return {"empathy": null, "self": null, "openness": null, "pressure": null}
    var attributes_container = driving_ui.get_node("CarWindowView/AttributesPanel/AttributesContainer")
    return {
        "empathy": attributes_container.get_node("EmpathyLabel"),
        "self": attributes_container.get_node("SelfLabel"), 
        "openness": attributes_container.get_node("OpennessLabel"),
        "pressure": attributes_container.get_node("PressureLabel")
    }

func get_money_label() -> Label:
    """获取金钱标签"""
    if driving_ui == null:
        return null
    return driving_ui.get_node("CarWindowView/MoneyLabel")

func get_city_background() -> ColorRect:
    """获取城市背景"""
    if driving_ui == null:
        return null
    return driving_ui.get_node("CarWindowView/BackgroundCity")

func get_city_label() -> Label:
    """获取城市标签"""
    if driving_ui == null:
        return null
    return driving_ui.get_node("CarWindowView/CityLabel")

# ============ 信号处理方法 ============
func _on_button_pressed(button_id: String):
    """处理按钮点击"""
    print("UI按钮点击：", button_id)
    button_pressed.emit(button_id, {})

func _on_area_selected(area_name: String):
    """处理区域选择"""
    print("选择区域：", area_name)
    area_selected.emit(area_name)

# ============ 调试方法 ============
func debug_ai_assistant():
    """调试AI助手状态"""
    print("=== AI助手调试信息 ===")
    print("ai_assistant_panel: ", ai_assistant_panel)
    if ai_assistant_panel != null:
        print("  visible: ", ai_assistant_panel.visible)
        print("  position: ", ai_assistant_panel.position)
        print("  size: ", ai_assistant_panel.size)
        print("  parent: ", ai_assistant_panel.get_parent())
    print("ai_message_label: ", ai_message_label)
    print("ai_countdown_label: ", ai_countdown_label)
    print("driving_ui: ", driving_ui)
    print("====================")

# ============ 结局界面创建 ============
func create_ending_ui(ending_type: String, score: float, ending_description: String) -> Control:
    """创建结局界面"""
    print("创建结局界面，类型：", ending_type, "，分数：", score)
    
    # 隐藏所有现有UI
    hide_all_ui()
    
    # 创建结局界面容器
    var ending_container = CenterContainer.new()
    ending_container.name = "EndingUI"
    ending_container.anchors_preset = Control.PRESET_FULL_RECT
    
    var ending_panel = VBoxContainer.new()
    ending_panel.custom_minimum_size = Vector2(600, 400)
    ending_container.add_child(ending_panel)
    
    # 添加结局标题
    var title_label = Label.new()
    title_label.text = "游戏结束"
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 32)
    ending_panel.add_child(title_label)
    
    # 添加分隔线
    var separator = HSeparator.new()
    ending_panel.add_child(separator)
    
    # 添加结局描述
    var description_label = RichTextLabel.new()
    description_label.text = ending_description
    description_label.fit_content = true
    description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    ending_panel.add_child(description_label)
    
    # 添加分数显示
    var score_label = Label.new()
    score_label.text = "最终分数: %.1f" % score
    score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ending_panel.add_child(score_label)
    
    # 添加重新开始按钮
    var restart_button = Button.new()
    restart_button.text = "重新开始"
    restart_button.custom_minimum_size = Vector2(200, 50)
    restart_button.pressed.connect(_on_button_pressed.bind("restart_game"))
    ending_panel.add_child(restart_button)
    
    # 添加退出按钮
    var quit_button = Button.new()
    quit_button.text = "退出游戏"
    quit_button.custom_minimum_size = Vector2(200, 50)
    quit_button.pressed.connect(_on_button_pressed.bind("quit"))
    ending_panel.add_child(quit_button)
    
    # 应用字体
    if has_node("/root/FontManager"):
        FontManager.apply_theme_to_node(ending_container)
        FontManager.force_apply_font_to_node(description_label)
    
    # 添加到场景
    ui_container.get_parent().add_child(ending_container)
    current_ui = ending_container
    
    print("✅ 结局界面创建完成")
    return ending_container

func update_shop_display_with_items(current_money: int, available_items: Array):
    """更新商店界面显示完整商品列表（简化版本，适配现有tscn结构）"""
    print("🛒 UIManager: 更新商店显示")
    
    var shop_money_label = shop_ui.get_node_or_null("VBoxContainer/MoneyLabel")
    if shop_money_label != null:
        shop_money_label.text = "当前余额: %d元" % current_money
        print("✅ 更新金钱显示：%d元" % current_money)
    else:
        print("❌ 找不到 MoneyLabel")
    
    # 更新商品列表
    var item_list = shop_ui.get_node_or_null("VBoxContainer/ScrollContainer/ItemList")
    if item_list != null:
        # 清除现有的商品按钮
        for child in item_list.get_children():
            child.queue_free()
        
        print("✅ 清空商品列表，开始添加 %d 个商品" % available_items.size())
        
        # 等待一帧确保旧的子节点被清理
        await get_tree().process_frame
        
        # 按分类组织并显示商品
        var categories = organize_shop_items_by_category(available_items)
        create_shop_categories_display(item_list, categories, current_money)
        
        print("✅ 商店商品显示完成")
    else:
        print("❌ 找不到 ItemList 节点")

func organize_shop_items_by_category(items: Array) -> Dictionary:
    """按分类组织商品"""
    var categories = {}
    for item in items:
        var category = item.get("category", "other")
        if category not in categories:
            categories[category] = []
        categories[category].append(item)
    
    print("📦 商品分类结果：")
    for cat in categories.keys():
        print("   %s: %d 个商品" % [cat, categories[cat].size()])
    
    return categories

func create_shop_categories_display(parent: VBoxContainer, categories: Dictionary, player_money: int):
    """创建商品分类显示"""
    var category_order = ["basic", "exploration", "healing", "special"]
    
    for category in category_order:
        if category in categories and categories[category].size() > 0:
            create_shop_category_section(parent, category, categories[category], player_money)

func create_shop_category_section(parent: VBoxContainer, category: String, items: Array, player_money: int):
    """创建商品分类区域"""
    print("📂 创建分类：%s，包含 %d 个商品" % [category, items.size()])
    
    # 分类标题
    var category_label = Label.new()
    category_label.text = get_shop_category_display_name(category)
    category_label.add_theme_font_size_override("font_size", 18)
    category_label.add_theme_color_override("font_color", Color.YELLOW)
    parent.add_child(category_label)
    
    # 分类描述
    var desc_label = Label.new()
    desc_label.text = get_shop_category_description(category)
    desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc_label.add_theme_font_size_override("font_size", 11)
    desc_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
    parent.add_child(desc_label)
    
    # 商品列表
    for item in items:
        create_shop_item_display(parent, item, player_money)
    
    # 分隔线
    var separator = HSeparator.new()
    separator.custom_minimum_size.y = 10
    parent.add_child(separator)

func create_shop_item_display(parent: VBoxContainer, item: Dictionary, player_money: int):
    """创建单个商品显示"""
    var item_container = HBoxContainer.new()
    item_container.custom_minimum_size = Vector2(0, 80)
    
    # 商品信息容器
    var info_container = VBoxContainer.new()
    info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    # 商品名称和价格行
    var name_price_container = HBoxContainer.new()
    
    var name_label = Label.new()
    var affordable_icon = "💰" if player_money >= item.price else "❌"
    name_label.text = "%s %s" % [affordable_icon, item.name]
    name_label.add_theme_font_size_override("font_size", 16)
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    var price_label = Label.new()
    price_label.text = "%d元" % item.price
    price_label.add_theme_font_size_override("font_size", 16)
    if player_money >= item.price:
        price_label.add_theme_color_override("font_color", Color.GREEN)
    else:
        price_label.add_theme_color_override("font_color", Color.RED)
    
    name_price_container.add_child(name_label)
    name_price_container.add_child(price_label)
    
    # 商品描述
    var desc_label = Label.new()
    desc_label.text = item.description
    desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc_label.add_theme_font_size_override("font_size", 11)
    desc_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
    desc_label.custom_minimum_size.x = 300  # 确保有足够宽度
    
    # 效果显示
    var effects_label = Label.new()
    effects_label.text = format_shop_item_effects(item.get("effects", {}))
    effects_label.add_theme_font_size_override("font_size", 10)
    effects_label.add_theme_color_override("font_color", Color.CYAN)
    
    info_container.add_child(name_price_container)
    info_container.add_child(desc_label)
    info_container.add_child(effects_label)
    
    # 购买按钮
    var buy_button = Button.new()
    buy_button.text = "购买"
    buy_button.custom_minimum_size = Vector2(80, 60)
    buy_button.disabled = player_money < item.price
    
    # 连接购买信号
    buy_button.pressed.connect(_on_shop_item_purchase_requested.bind(item.id))
    
    item_container.add_child(info_container)
    item_container.add_child(buy_button)
    parent.add_child(item_container)
    
    print("✅ 创建商品显示：%s (%d元)" % [item.name, item.price])

func format_shop_item_effects(effects: Dictionary) -> String:
    """格式化物品效果显示"""
    if effects.is_empty():
        return "无特殊效果"
    
    var effect_strings = []
    for effect in effects.keys():
        var value = effects[effect]
        var effect_name = get_shop_effect_display_name(effect)
        var sign = "+" if value > 0 else ""
        effect_strings.append("%s%s %s" % [sign, value, effect_name])
    return "效果: " + ", ".join(effect_strings)

func get_shop_effect_display_name(effect: String) -> String:
    """获取效果的显示名称"""
    match effect:
        "empathy": return "共情"
        "self_connection": return "自省"
        "openness": return "开放"
        "pressure": return "压力"
        "energy": return "活力"
        _: return effect

func get_shop_category_display_name(category: String) -> String:
    """获取分类显示名称"""
    match category:
        "basic": return "🏠 生活必需品"
        "exploration": return "🔍 自我探索"
        "healing": return "💖 情感治愈"
        "special": return "⭐ 特殊物品"
        _: return "📦 其他"

func get_shop_category_description(category: String) -> String:
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

func show_purchase_result(success: bool, item_name: String, story_text: String, remaining_money: int):
    """显示购买结果（简化版本）"""
    if success:
        print("🎉 购买成功：", item_name)
        print("📖 ", story_text)
        print("💰 剩余金额：", remaining_money, "元")
        
        # 创建简单的成功提示
        create_purchase_success_popup(item_name, story_text, remaining_money)
    else:
        print("❌ 购买失败：", item_name)

func create_purchase_success_popup(item_name: String, story_text: String, remaining_money: int):
    """创建购买成功弹窗"""
    var popup_container = CenterContainer.new()
    popup_container.name = "PurchaseSuccessPopup"
    popup_container.anchors_preset = Control.PRESET_FULL_RECT
    
    # 半透明背景
    var background = ColorRect.new()
    background.anchors_preset = Control.PRESET_FULL_RECT
    background.color = Color(0, 0, 0, 0.7)
    popup_container.add_child(background)
    
    # 弹窗面板
    var popup_panel = Panel.new()
    popup_panel.custom_minimum_size = Vector2(500, 300)
    
    # 设置面板样式
    var panel_style = StyleBoxFlat.new()
    panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
    panel_style.border_color = Color.GREEN
    panel_style.border_width_left = 3
    panel_style.border_width_right = 3
    panel_style.border_width_top = 3
    panel_style.border_width_bottom = 3
    panel_style.corner_radius_top_left = 10
    panel_style.corner_radius_top_right = 10
    panel_style.corner_radius_bottom_left = 10
    panel_style.corner_radius_bottom_right = 10
    popup_panel.add_theme_stylebox_override("panel", panel_style)
    
    var vbox = VBoxContainer.new()
    vbox.anchors_preset = Control.PRESET_FULL_RECT
    vbox.offset_left = 20
    vbox.offset_right = -20
    vbox.offset_top = 15
    vbox.offset_bottom = -15
    
    # 成功标题
    var title_label = Label.new()
    title_label.text = "🎉 购买成功！"
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 24)
    title_label.add_theme_color_override("font_color", Color.GREEN)
    
    # 物品名称
    var item_label = Label.new()
    item_label.text = "获得：" + item_name
    item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    item_label.add_theme_font_size_override("font_size", 18)
    item_label.add_theme_color_override("font_color", Color.WHITE)
    
    # 故事文本
    var story_label = RichTextLabel.new()
    story_label.text = story_text
    story_label.fit_content = true
    story_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    story_label.add_theme_font_size_override("normal_font_size", 14)
    story_label.add_theme_color_override("default_color", Color.LIGHT_GRAY)
    
    # 余额显示
    var money_label = Label.new()
    money_label.text = "💰 剩余金额：%d元" % remaining_money
    money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    money_label.add_theme_font_size_override("font_size", 16)
    money_label.add_theme_color_override("font_color", Color.YELLOW)
    
    # 关闭按钮
    var close_button = Button.new()
    close_button.text = "确定"
    close_button.custom_minimum_size = Vector2(100, 40)
    close_button.pressed.connect(_on_purchase_popup_close.bind(popup_container))
    
    vbox.add_child(title_label)
    vbox.add_child(HSeparator.new())
    vbox.add_child(item_label)
    vbox.add_child(story_label)
    vbox.add_child(money_label)
    vbox.add_child(HSeparator.new())
    
    # 按钮居中容器
    var button_center = CenterContainer.new()
    button_center.add_child(close_button)
    vbox.add_child(button_center)
    
    popup_panel.add_child(vbox)
    popup_container.add_child(popup_panel)
    
    # 应用字体
    if has_node("/root/FontManager"):
        FontManager.apply_theme_to_node(popup_container)
        FontManager.force_apply_font_to_node(story_label)
    
    # 添加到主场景
    ui_container.get_parent().add_child(popup_container)
    
    # 3秒后自动关闭
    var timer = Timer.new()
    timer.wait_time = 3.0
    timer.one_shot = true
    timer.timeout.connect(_on_purchase_popup_close.bind(popup_container))
    popup_container.add_child(timer)
    timer.start()
    
    print("✅ 购买成功弹窗已创建")

func _on_purchase_popup_close(popup: Control):
    """关闭购买成功弹窗"""
    if popup.is_inside_tree():
        popup.queue_free()
        print("✅ 购买弹窗已关闭")

func _on_shop_item_purchase_requested(item_id: String):
    """处理商店物品购买请求"""
    print("🛒 UIManager: 请求购买物品：", item_id)
    button_pressed.emit("purchase_item", {"item_id": item_id})

# 重写现有的 update_shop_display 方法以避免冲突
func update_shop_display(current_money: int):
    """更新商店显示（保持向后兼容）"""
    var shop_money_label = shop_ui.get_node_or_null("VBoxContainer/MoneyLabel")
    if shop_money_label != null:
        shop_money_label.text = "当前余额: %d元" % current_money

# 调试方法
func debug_shop_ui():
    """调试商店UI状态"""
    print("=== 商店UI调试信息 ===")
    print("shop_ui: ", shop_ui)
    
    if shop_ui != null:
        print("shop_ui visible: ", shop_ui.visible)
        
        var money_label = shop_ui.get_node_or_null("VBoxContainer/MoneyLabel")
        print("MoneyLabel: ", money_label)
        
        var item_list = shop_ui.get_node_or_null("VBoxContainer/ScrollContainer/ItemList")
        print("ItemList: ", item_list)
        if item_list != null:
            print("ItemList children count: ", item_list.get_child_count())
    
    print("====================")

# 在现有的 switch_to_ui 方法中添加商店UI的特殊处理
# 如果你的 switch_to_ui 方法存在，请在其中添加：
# if ui_name == "shop":
#     debug_shop_ui()  # 调试用，正式版本可以移除
# UIManager.gd 梦网界面扩展部分
# 将这些方法添加到现有的UIManager.gd中

# ============ 梦网界面相关方法 ============



func create_dreamweave_content_item(parent: VBoxContainer, content: Dictionary, index: int):
    """创建单个梦网内容项"""
    # 内容项容器
    var item_container = Panel.new()
    item_container.custom_minimum_size = Vector2(0, 120)
    
    # 设置不同类型内容的颜色
    var item_style = StyleBoxFlat.new()
    item_style.corner_radius_top_left = 8
    item_style.corner_radius_top_right = 8
    item_style.corner_radius_bottom_left = 8
    item_style.corner_radius_bottom_right = 8
    
    # 根据内容情感设置颜色
    match content.get("sentiment", "neutral"):
        "positive":
            item_style.bg_color = Color(0.1, 0.2, 0.1, 0.8)
            item_style.border_color = Color(0.2, 0.8, 0.2, 0.5)
        "negative":
            item_style.bg_color = Color(0.2, 0.1, 0.1, 0.8)
            item_style.border_color = Color(0.8, 0.2, 0.2, 0.5)
        _:
            item_style.bg_color = Color(0.1, 0.1, 0.2, 0.8)
            item_style.border_color = Color(0.4, 0.4, 0.8, 0.5)
    
    item_style.border_width_left = 1
    item_style.border_width_right = 1
    item_style.border_width_top = 1
    item_style.border_width_bottom = 1
    item_container.add_theme_stylebox_override("panel", item_style)
    
    # 主布局
    var main_hbox = HBoxContainer.new()
    main_hbox.anchors_preset = Control.PRESET_FULL_RECT
    main_hbox.offset_left = 15
    main_hbox.offset_right = -15
    main_hbox.offset_top = 10
    main_hbox.offset_bottom = -10
    item_container.add_child(main_hbox)
    
    # 内容区域
    var content_vbox = VBoxContainer.new()
    content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    # 作者和标签行
    var header_hbox = HBoxContainer.new()
    
    # 作者标签
    var author_label = Label.new()
    author_label.text = "@" + content.get("author", "匿名")
    author_label.add_theme_font_size_override("font_size", 12)
    author_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
    
    # 标签显示
    var tags_label = Label.new()
    var tags_text = ""
    var tags = content.get("tags", [])
    for tag in tags:
        tags_text += "#" + tag + " "
    tags_label.text = tags_text
    tags_label.add_theme_font_size_override("font_size", 10)
    tags_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
    tags_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    tags_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    
    header_hbox.add_child(author_label)
    header_hbox.add_child(tags_label)
    content_vbox.add_child(header_hbox)
    
    # 内容文本
    var content_label = Label.new()
    content_label.text = content.get("content", "")
    content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content_label.add_theme_font_size_override("font_size", 14)
    content_label.add_theme_color_override("font_color", Color.WHITE)
    content_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_vbox.add_child(content_label)
    
    main_hbox.add_child(content_vbox)
    
    # 点赞区域
    var like_container = VBoxContainer.new()
    like_container.custom_minimum_size = Vector2(80, 0)
    like_container.alignment = BoxContainer.ALIGNMENT_CENTER
    
    # 点赞按钮
    var like_button = Button.new()
    var is_liked = content.get("is_liked", false)
    like_button.text = "❤️" if is_liked else "🤍"
    like_button.custom_minimum_size = Vector2(60, 40)
    like_button.disabled = is_liked
    
    # 连接点赞信号
    if not is_liked:
        like_button.pressed.connect(_on_dreamweave_like_pressed.bind(content.get("id", "")))
    
    # 点赞状态文字
    var like_status_label = Label.new()
    like_status_label.text = "已赞" if is_liked else "点赞"
    like_status_label.add_theme_font_size_override("font_size", 10)
    like_status_label.add_theme_color_override("font_color", Color.PINK if is_liked else Color.LIGHT_GRAY)
    like_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    
    like_container.add_child(like_button)
    like_container.add_child(like_status_label)
    main_hbox.add_child(like_container)
    
    parent.add_child(item_container)
    
    # 添加项目间距
    if index < parent.get_child_count() - 1:
        var spacer = Control.new()
        spacer.custom_minimum_size.y = 10
        parent.add_child(spacer)


func show_dreamweave_like_feedback(content_id: String, effects: Dictionary):
    """显示点赞反馈"""
    print("💖 点赞反馈：", content_id, " 效果：", effects)
    
    # 创建简单的反馈提示
    var dreamweave_ui = get_node_or_null("../DreamWeaveUI")
    if dreamweave_ui == null:
        return
    
    # 创建反馈标签
    var feedback_label = Label.new()
    var feedback_text = "✨ "
    for attr in effects.keys():
        var change = effects[attr]
        var attr_name = get_attribute_display_name(attr)
        var sign = "+" if change > 0 else ""
        feedback_text += "%s%s %s " % [sign, change, attr_name]
    
    feedback_label.text = feedback_text
    feedback_label.add_theme_font_size_override("font_size", 12)
    feedback_label.add_theme_color_override("font_color", Color.YELLOW)
    feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    feedback_label.position = Vector2(dreamweave_ui.size.x / 2 - 100, 100)
    feedback_label.size = Vector2(200, 30)
    
    dreamweave_ui.add_child(feedback_label)
    
    # 2秒后自动消失
    var timer = Timer.new()
    timer.wait_time = 2.0
    timer.one_shot = true
    timer.timeout.connect(feedback_label.queue_free)
    dreamweave_ui.add_child(timer)
    timer.start()

func get_attribute_display_name(attr: String) -> String:
    """获取属性显示名称"""
    match attr:
        "empathy": return "共情"
        "self_connection": return "自省"
        "openness": return "开放"
        "pressure": return "压力"
        _: return attr

# ============ 梦网界面信号处理 ============

func _on_dreamweave_like_pressed(content_id: String):
    """处理梦网点赞"""
    print("👍 梦网点赞：", content_id)
    button_pressed.emit("dreamweave_like", {"content_id": content_id})

func _on_dreamweave_refresh_pressed():
    """处理梦网刷新"""
    print("🔄 梦网刷新请求")
    button_pressed.emit("dreamweave_refresh", {})

func _on_dreamweave_return_pressed():
    """处理梦网返回"""
    print("🏠 梦网返回")
    button_pressed.emit("dreamweave_return", {})
    
    # UIManager.gd 修复的梦网UI方法
# 替换现有的相关方法

func update_dreamweave_content(content_list: Array):
    """更新梦网内容显示 - 修复版本"""
    # 修复节点路径查找
    var dreamweave_ui = get_node_or_null("../DreamWeaveUI")
    if dreamweave_ui == null:
        print("❌ 梦网界面不存在，尝试直接查找...")
        # 尝试从当前UI容器的父节点查找
        var parent = ui_container.get_parent()
        if parent != null:
            dreamweave_ui = parent.get_node_or_null("DreamWeaveUI")
        
        if dreamweave_ui == null:
            print("❌ 无法找到梦网界面")
            return
    
    # 修复内容容器路径
    var content_container = dreamweave_ui.get_node_or_null("Panel/VBoxContainer/ScrollContainer/ContentList")
    if content_container == null:
        print("❌ 梦网内容容器不存在，尝试查找所有可能路径...")
        # 调试：打印界面结构
        print("🔍 梦网界面结构：")
        debug_node_structure(dreamweave_ui, 0)
        
        # 尝试其他可能的路径
        var possible_paths = [
            "VBoxContainer/ScrollContainer/ContentList",
            "MainPanel/VBoxContainer/ScrollContainer/ContentList", 
            "Panel/VBox/ScrollContainer/ContentList"
        ]
        
        for path in possible_paths:
            content_container = dreamweave_ui.get_node_or_null(path)
            if content_container != null:
                print("✅ 找到内容容器，路径：", path)
                break
        
        if content_container == null:
            print("❌ 无法找到内容容器，请检查create_dreamweave_ui()的节点结构")
            return
    
    # 清空现有内容
    for child in content_container.get_children():
        child.queue_free()
    
    await get_tree().process_frame
    
    print("🌐 更新梦网内容，共", content_list.size(), "条")
    
    # 创建内容项
    for i in range(content_list.size()):
        var content = content_list[i]
        create_dreamweave_content_item(content_container, content, i)

func debug_node_structure(node: Node, indent: int = 0):
    """调试节点结构"""
    var indent_str = "  ".repeat(indent)
    print(indent_str + "- " + node.name + " (" + node.get_class() + ")")
    
    for child in node.get_children():
        if indent < 3:  # 限制深度避免输出过多
            debug_node_structure(child, indent + 1)

func create_dreamweave_ui() -> Control:
    """创建梦网界面 - 修复版本"""
    print("🌐 创建梦网界面...")
    
    # 隐藏所有现有UI
    hide_all_ui()
    
    # 创建梦网界面容器
    var dreamweave_container = Control.new()
    dreamweave_container.name = "DreamWeaveUI"
    dreamweave_container.anchors_preset = Control.PRESET_FULL_RECT
    
    # 主面板 - 确保名称一致
    var main_panel = Panel.new()
    main_panel.name = "Panel"  # 确保名称是"Panel"
    main_panel.anchors_preset = Control.PRESET_FULL_RECT
    main_panel.offset_left = 50
    main_panel.offset_right = -50
    main_panel.offset_top = 50
    main_panel.offset_bottom = -50
    
    # 设置面板样式
    var panel_style = StyleBoxFlat.new()
    panel_style.bg_color = Color(0.05, 0.1, 0.15, 0.95)
    panel_style.border_color = Color(0.2, 0.4, 0.6)
    panel_style.border_width_left = 2
    panel_style.border_width_right = 2
    panel_style.border_width_top = 2
    panel_style.border_width_bottom = 2
    panel_style.corner_radius_top_left = 10
    panel_style.corner_radius_top_right = 10
    panel_style.corner_radius_bottom_left = 10
    panel_style.corner_radius_bottom_right = 10
    main_panel.add_theme_stylebox_override("panel", panel_style)
    
    dreamweave_container.add_child(main_panel)
    
    # 主布局 - 确保名称一致
    var vbox = VBoxContainer.new()
    vbox.name = "VBoxContainer"  # 确保名称是"VBoxContainer"
    vbox.anchors_preset = Control.PRESET_FULL_RECT
    vbox.offset_left = 20
    vbox.offset_right = -20
    vbox.offset_top = 15
    vbox.offset_bottom = -15
    main_panel.add_child(vbox)
    
    # 标题
    var title_label = Label.new()
    title_label.text = "🌐 梦网 DreamWeave"
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 24)
    title_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
    vbox.add_child(title_label)
    
    # 副标题
    var subtitle_label = Label.new()
    subtitle_label.text = "今日推荐内容 - 点击❤️表达共鸣"
    subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle_label.add_theme_font_size_override("font_size", 14)
    subtitle_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
    vbox.add_child(subtitle_label)
    
    # 分隔线
    var separator = HSeparator.new()
    separator.custom_minimum_size.y = 10
    vbox.add_child(separator)
    
    # 内容滚动区域 - 确保名称一致
    var scroll_container = ScrollContainer.new()
    scroll_container.name = "ScrollContainer"  # 确保名称是"ScrollContainer"
    scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll_container.custom_minimum_size = Vector2(0, 400)
    vbox.add_child(scroll_container)
    
    # 内容列表容器 - 确保名称一致
    var content_list = VBoxContainer.new()
    content_list.name = "ContentList"  # 确保名称是"ContentList"
    content_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll_container.add_child(content_list)
    
    # 底部按钮区域
    var button_container = HBoxContainer.new()
    button_container.name = "HBoxContainer"  # 确保名称一致
    button_container.alignment = BoxContainer.ALIGNMENT_CENTER
    
    # 刷新按钮
    var refresh_button = Button.new()
    refresh_button.text = "🔄 刷新内容"
    refresh_button.custom_minimum_size = Vector2(120, 40)
    refresh_button.pressed.connect(_on_dreamweave_refresh_pressed)
    
    # 统计标签
    var stats_label = Label.new()
    stats_label.name = "StatsLabel"
    stats_label.text = "今日互动: 0次"
    stats_label.add_theme_font_size_override("font_size", 12)
    stats_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
    
    # 返回按钮
    var return_button = Button.new()
    return_button.text = "🏠 返回"
    return_button.custom_minimum_size = Vector2(100, 40)
    return_button.pressed.connect(_on_dreamweave_return_pressed)
    
    button_container.add_child(refresh_button)
    button_container.add_child(stats_label)
    button_container.add_child(return_button)
    vbox.add_child(button_container)
    
    # 应用字体
    if has_node("/root/FontManager"):
        FontManager.apply_theme_to_node(dreamweave_container)
    
    # 添加到主场景
    ui_container.get_parent().add_child(dreamweave_container)
    current_ui = dreamweave_container
    
    print("✅ 梦网界面创建完成")
    print("   节点路径: Panel/VBoxContainer/ScrollContainer/ContentList")
    return dreamweave_container

func update_dreamweave_stats(interactions_count: int, total_content: int):
    """更新梦网统计信息 - 修复版本"""
    var dreamweave_ui = get_node_or_null("../DreamWeaveUI")
    if dreamweave_ui == null:
        # 尝试从父节点查找
        var parent = ui_container.get_parent()
        if parent != null:
            dreamweave_ui = parent.get_node_or_null("DreamWeaveUI")
    
    if dreamweave_ui == null:
        print("❌ 无法找到梦网界面来更新统计")
        return
    
    var stats_label = dreamweave_ui.get_node_or_null("Panel/VBoxContainer/HBoxContainer/StatsLabel")
    if stats_label != null:
        stats_label.text = "今日互动: %d/%d" % [interactions_count, total_content]
        print("✅ 更新统计: %d/%d" % [interactions_count, total_content])
    else:
        print("❌ 无法找到统计标签")
