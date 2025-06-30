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

func update_shop_display(current_money: int):
    """更新商店界面显示"""
    var shop_money_label = shop_ui.get_node("VBoxContainer/MoneyLabel")
    if shop_money_label != null:
        shop_money_label.text = "当前余额: %d元" % current_money

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
