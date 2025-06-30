# Main.gd - 集成QTE系统的主脚本
extends Control

# UI界面节点引用
@onready var start_ui = $UIContainer/StartUI
@onready var area_selection_ui = $UIContainer/AreaSelectionUI  
@onready var driving_ui = $UIContainer/DrivingUI
@onready var home_ui = $UIContainer/HomeUI
@onready var shop_ui = $UIContainer/ShopUI

# 区域按钮引用
@onready var business_button = $UIContainer/AreaSelectionUI/VBoxContainer/BusinessButton
@onready var residential_button = $UIContainer/AreaSelectionUI/VBoxContainer/ResidentialButton
@onready var entertainment_button = $UIContainer/AreaSelectionUI/VBoxContainer/EntertainmentButton
@onready var suburban_button = $UIContainer/AreaSelectionUI/VBoxContainer/SuburbanButton

# 属性显示
@onready var empathy_label = $UIContainer/DrivingUI/CarWindowView/AttributesPanel/AttributesContainer/EmpathyLabel
@onready var self_label = $UIContainer/DrivingUI/CarWindowView/AttributesPanel/AttributesContainer/SelfLabel
@onready var openness_label = $UIContainer/DrivingUI/CarWindowView/AttributesPanel/AttributesContainer/OpennessLabel
@onready var pressure_label = $UIContainer/DrivingUI/CarWindowView/AttributesPanel/AttributesContainer/PressureLabel
@onready var money_label = $UIContainer/DrivingUI/CarWindowView/MoneyLabel

# 对话界面
@onready var npc_name_label = $UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/NPCNameLabel
@onready var dialogue_label = $UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/DialogueLabel
@onready var interrupt_button1 = $UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/InterruptContainer/InterruptButton1
@onready var interrupt_button2 = $UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/InterruptContainer/InterruptButton2
@onready var continue_button = $UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/ContinueButton

# 背景和其他
@onready var city_background = $UIContainer/DrivingUI/CarWindowView/BackgroundCity
@onready var city_label = $UIContainer/DrivingUI/CarWindowView/CityLabel

# 其他界面元素
@onready var day_label = $UIContainer/AreaSelectionUI/VBoxContainer/DayLabel
@onready var stats_label = $UIContainer/HomeUI/CenterContainer/VBoxContainer/StatsLabel
@onready var shop_money_label = $UIContainer/ShopUI/VBoxContainer/MoneyLabel

# QTE系统
var qte_system: DrivingQTESystem
var qte_ui_container: Control
var qte_voice_label: Label
var qte_countdown_label: Label
var qte_action_buttons: Dictionary = {}

# 当前状态
var current_ui: Control
var current_area: String = ""
var last_visited_area: String = ""

# 对话状态管理
enum DialogueState {
    WAITING_FOR_PASSENGER,
    IN_DIALOGUE,
    DIALOGUE_FINISHED,
    TRIP_COMPLETED
}

var dialogue_state: DialogueState = DialogueState.WAITING_FOR_PASSENGER

# 测试用的简单NPC数据
var test_npcs = [
    {
        "name": "Sarah",
        "dialogues": ["我今天加班到很晚...", "有时候觉得生活就是个循环", "你觉得这样的生活有意义吗？"],
        "interrupt_responses": ["是啊，工作压力很大", "生活确实需要思考"],
        "driving_preferences": {
            "smooth_driving": 1.0,
            "music_classical": 0.8,
            "window_closed": 0.9
        }
    },
    {
        "name": "老王", 
        "dialogues": ["年轻人，现在的世界变化太快了", "我记得以前的日子更简单", "你觉得简单的生活好吗？"],
        "interrupt_responses": ["确实，科技发展很快", "简单也有简单的美好"],
        "driving_preferences": {
            "smooth_driving": 1.0,
            "music_off": 0.7,
            "window_open": 0.6
        }
    }
]
var current_npc_index = 0
var current_dialogue_index = 0

func _ready():
    print("=== 主场景初始化 ===")
    
    # 初始化QTE系统
    setup_qte_system()
    
    # 检查并应用字体到对话标签
    setup_dialogue_fonts()
    
    # 应用字体主题
    if has_node("/root/FontManager"):
        FontManager.apply_theme_to_node(self)
        await get_tree().process_frame
    
    # 连接GameManager信号
    GameManager.state_changed.connect(_on_game_state_changed)
    GameManager.day_completed.connect(_on_day_completed)
    
    # 初始显示开始界面
    show_ui(start_ui)
    hide_all_ui_except(start_ui)
    update_all_displays()
    
    print("=== 初始化完成 ===\n")

func setup_qte_system():
    """初始化QTE系统"""
    qte_system = DrivingQTESystem.new()
    add_child(qte_system)
    
    # 连接QTE信号
    qte_system.qte_event_started.connect(_on_qte_event_started)
    qte_system.qte_event_completed.connect(_on_qte_event_completed)
    qte_system.voice_assistant_speaks.connect(_on_voice_assistant_speaks)
    
    # 创建QTE UI
    create_qte_ui()
    
    print("QTE系统初始化完成")

func create_qte_ui():
    """创建QTE事件的UI界面"""
    # 创建QTE UI容器
    qte_ui_container = Panel.new()
    qte_ui_container.name = "QTEContainer"
    qte_ui_container.visible = false
    qte_ui_container.anchors_preset = Control.PRESET_CENTER
    qte_ui_container.position = Vector2(300, 50)
    qte_ui_container.size = Vector2(400, 200)
    
    # 设置面板样式
    var panel_style = StyleBoxFlat.new()
    panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.9)
    panel_style.border_color = Color(1.0, 0.3, 0.3)
    panel_style.border_width_left = 2
    panel_style.border_width_right = 2
    panel_style.border_width_top = 2
    panel_style.border_width_bottom = 2
    panel_style.corner_radius_top_left = 8
    panel_style.corner_radius_top_right = 8
    panel_style.corner_radius_bottom_left = 8
    panel_style.corner_radius_bottom_right = 8
    qte_ui_container.add_theme_stylebox_override("panel", panel_style)
    
    # 创建垂直布局
    var vbox = VBoxContainer.new()
    vbox.anchors_preset = Control.PRESET_FULL_RECT
    vbox.offset_left = 10
    vbox.offset_right = -10
    vbox.offset_top = 10
    vbox.offset_bottom = -10
    qte_ui_container.add_child(vbox)
    
    # 语音助手标题
    var voice_title = Label.new()
    voice_title.text = "🤖 ARIA 助手"
    voice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    voice_title.add_theme_font_size_override("font_size", 14)
    vbox.add_child(voice_title)
    
    # 语音助手提示
    qte_voice_label = Label.new()
    qte_voice_label.text = ""
    qte_voice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    qte_voice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    qte_voice_label.add_theme_font_size_override("font_size", 16)
    vbox.add_child(qte_voice_label)
    
    # 倒计时显示
    qte_countdown_label = Label.new()
    qte_countdown_label.text = ""
    qte_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    qte_countdown_label.add_theme_font_size_override("font_size", 20)
    qte_countdown_label.add_theme_color_override("font_color", Color.RED)
    vbox.add_child(qte_countdown_label)
    
    # 动作按钮容器
    var button_container = HBoxContainer.new()
    button_container.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_child(button_container)
    
    # 创建各种QTE动作按钮
    create_qte_action_button(button_container, "brake", "🛑 刹车")
    create_qte_action_button(button_container, "turn_left", "⬅️ 左转")
    create_qte_action_button(button_container, "turn_right", "➡️ 右转")
    create_qte_action_button(button_container, "wipers", "🌧️ 雨刷")
    create_qte_action_button(button_container, "close_window", "🔇 关窗")
    create_qte_action_button(button_container, "emergency_brake", "🚨 紧急刹车")
    create_qte_action_button(button_container, "yield_right", "🚑 靠边")
    
    # 添加到驾驶界面
    driving_ui.add_child(qte_ui_container)
    
    print("QTE UI创建完成")

func create_qte_action_button(container: Container, action: String, text: String):
    """创建QTE动作按钮"""
    var button = Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(80, 40)
    button.visible = false
    button.pressed.connect(_on_qte_action_pressed.bind(action))
    
    container.add_child(button)
    qte_action_buttons[action] = button

func setup_dialogue_fonts():
    """专门设置对话字体，解决乱码问题"""
    print("设置对话字体...")
    
    # 等待节点准备好
    await get_tree().process_frame
    
    if dialogue_label != null and has_node("/root/FontManager"):
        # 强制应用字体到RichTextLabel
        FontManager.force_apply_font_to_node(dialogue_label)
        
        # 额外设置，确保中文显示正常
        dialogue_label.fit_content = true
        dialogue_label.scroll_active = false
        
        print("✅ 对话字体设置完成")

func _process(delta):
    """更新QTE倒计时显示"""
    if qte_system != null and qte_system.is_qte_active:
        var remaining = qte_system.countdown_timer
        if qte_countdown_label != null:
            qte_countdown_label.text = "⏰ %.1f 秒" % remaining

func _on_qte_event_started(event):
    """QTE事件开始"""
    print("QTE事件UI启动：", event.prompt_text)
    
    if qte_ui_container != null:
        qte_ui_container.visible = true
        
        # 隐藏所有按钮
        for button in qte_action_buttons.values():
            button.visible = false
        
        # 显示正确的按钮
        if event.correct_action in qte_action_buttons:
            qte_action_buttons[event.correct_action].visible = true
            print("显示QTE按钮：", event.correct_action)

func _on_qte_event_completed(event, success: bool):
    """QTE事件完成"""
    print("QTE事件UI完成：", "成功" if success else "失败")
    
    if qte_ui_container != null:
        qte_ui_container.visible = false
    
    # 更新显示
    update_all_displays()
    
    # 给NPC添加反应
    add_npc_reaction_to_driving(event, success)

func _on_voice_assistant_speaks(message: String):
    """语音助手说话"""
    print("ARIA: ", message)
    
    if qte_voice_label != null:
        qte_voice_label.text = message

func _on_qte_action_pressed(action: String):
    """QTE动作按钮被按下"""
    print("QTE按钮按下：", action)
    qte_system.handle_qte_action(action)

func add_npc_reaction_to_driving(event, success: bool):
    """根据QTE结果添加NPC反应"""
    if dialogue_label == null:
        return
    
    var reaction_text = ""
    if success:
        reaction_text = event.npc_reaction_positive
    else:
        reaction_text = event.npc_reaction_negative
    
    # 添加NPC对驾驶的反应
    if reaction_text != "":
        dialogue_label.text += "\n\n「" + reaction_text + "」"

# ============ 随机QTE触发 ============
func maybe_trigger_qte_event():
    """在对话间隙可能触发QTE事件"""
    if qte_system != null and qte_system.should_trigger_event():
        print("触发随机QTE事件")
        qte_system.trigger_random_event()

# ============ 原有的游戏逻辑保持不变 ============
func _on_game_state_changed(new_state: GameManager.GameState):
    """响应游戏状态变化"""
    print("UI响应状态变化：", GameManager.GameState.keys()[new_state])
    
    match new_state:
        GameManager.GameState.MENU:
            show_ui(start_ui)
        GameManager.GameState.AREA_SELECTION:
            show_ui(area_selection_ui)
            update_area_selection_display()
        GameManager.GameState.DRIVING:
            show_ui(driving_ui)
            print("切换到驾驶界面，准备开始驾驶会话")
            if GameManager.passengers_today == 0:
                start_driving_session()
        GameManager.GameState.HOME:
            show_ui(home_ui)
            update_home_display()
        GameManager.GameState.SHOP:
            show_ui(shop_ui)
            update_shop_display()

func show_ui(ui: Control):
    """显示指定UI，隐藏其他"""
    hide_all_ui_except(ui)
    
    if ui != null:
        ui.visible = true
        current_ui = ui
        print("✅ 成功切换到UI：", ui.name)

func hide_all_ui_except(except_ui: Control):
    """隐藏所有UI除了指定的"""
    var ui_container = $UIContainer
    for child in ui_container.get_children():
        if child != except_ui:
            child.visible = false

func update_all_displays():
    """更新所有显示信息"""
    update_attributes_display()
    update_money_display()
    update_city_background()

func update_attributes_display():
    """更新属性显示"""
    if GameManager.player_stats == null or empathy_label == null:
        return
        
    var stats = GameManager.player_stats
    empathy_label.text = "共情: %.0f" % stats.empathy
    self_label.text = "自省: %.0f" % stats.self_connection
    openness_label.text = "开放: %.0f" % stats.openness
    pressure_label.text = "压力: %.0f" % stats.pressure

func update_money_display():
    """更新金钱显示"""
    if GameManager.player_stats == null or money_label == null:
        return
        
    money_label.text = "💰 %d元" % GameManager.player_stats.money
    
    if shop_money_label != null:
        shop_money_label.text = "当前余额: %d元" % GameManager.player_stats.money

func update_city_background():
    """根据当前区域更新城市背景"""
    if city_background == null:
        return
        
    match current_area:
        "business":
            city_background.color = Color(0.3, 0.4, 0.6)
            if city_label != null:
                city_label.text = "商业区夜景"
        "residential":
            city_background.color = Color(0.4, 0.3, 0.4)
            if city_label != null:
                city_label.text = "居住区夜景"
        "entertainment":
            city_background.color = Color(0.5, 0.2, 0.4)
            if city_label != null:
                city_label.text = "娱乐区夜景"
        "suburban":
            city_background.color = Color(0.2, 0.4, 0.3)
            if city_label != null:
                city_label.text = "郊外夜景"
        _:
            city_background.color = Color(0.2, 0.3, 0.5)
            if city_label != null:
                city_label.text = "城市夜景"

func update_area_selection_display():
    """更新区域选择界面"""
    if day_label != null:
        day_label.text = "第 %d 天" % GameManager.current_day
    
    # 解锁逻辑
    if GameManager.current_day >= 2:
        entertainment_button.disabled = false
    if GameManager.current_day >= 3:
        suburban_button.disabled = false

func start_driving_session():
    """开始驾驶会话"""
    print("=== 开始驾驶会话 ===")
    
    update_all_displays()
    dialogue_state = DialogueState.WAITING_FOR_PASSENGER
    
    print("开始接第", GameManager.passengers_today + 1, "个乘客")
    
    # 显示等待状态
    show_waiting_for_passenger()
    
    # 等待2秒模拟乘客上车
    await get_tree().create_timer(2.0).timeout
    
    # 开始对话
    start_npc_dialogue()

func show_waiting_for_passenger():
    """显示等待乘客状态"""
    print("显示等待乘客状态")
    
    if npc_name_label != null:
        npc_name_label.text = "等待乘客中..."
    if dialogue_label != null:
        dialogue_label.text = "正在等待乘客上车..."
    
    # 隐藏所有按钮
    if interrupt_button1 != null:
        interrupt_button1.visible = false
    if interrupt_button2 != null:
        interrupt_button2.visible = false
    if continue_button != null:
        continue_button.visible = false

func start_npc_dialogue():
    """开始NPC对话"""
    print("=== 开始NPC对话 ===")
    
    dialogue_state = DialogueState.IN_DIALOGUE
    
    # 重置对话状态
    current_npc_index = randi() % test_npcs.size()
    current_dialogue_index = 0
    
    print("选择NPC：", test_npcs[current_npc_index].name)
    
    # 等待一帧确保UI更新
    await get_tree().process_frame
    show_next_dialogue()

func show_next_dialogue():
    """显示下一段对话"""
    print("=== 显示对话 ===")
    
    if dialogue_state != DialogueState.IN_DIALOGUE:
        print("❌ 对话状态不正确，跳过显示")
        return
    
    if npc_name_label == null or dialogue_label == null:
        print("❌ 对话节点未找到")
        return
        
    var npc = test_npcs[current_npc_index]
    npc_name_label.text = "%s (第%d位乘客)" % [npc.name, GameManager.passengers_today + 1]
    
    if current_dialogue_index < npc.dialogues.size():
        # 显示当前对话
        dialogue_label.text = npc.dialogues[current_dialogue_index]
        print("✅ 显示对话：", npc.dialogues[current_dialogue_index])
        
        # 显示插话选项
        if interrupt_button1 != null:
            interrupt_button1.visible = true
            interrupt_button1.text = "嗯嗯"
            interrupt_button1.disabled = false
        
        if continue_button != null:
            continue_button.visible = false
        
        # 随机触发QTE事件
        maybe_trigger_qte_event()
        
    else:
        # 对话结束
        dialogue_state = DialogueState.DIALOGUE_FINISHED
        dialogue_label.text = "谢谢你的陪伴，这次旅程很愉快。"
        
        if interrupt_button1 != null:
            interrupt_button1.visible = false
        if continue_button != null:
            continue_button.text = "结束行程"
            continue_button.visible = true
            continue_button.disabled = false

# ============ StartUI 事件处理 ============
func _on_start_game_pressed():
    print("开始新游戏")
    GameManager.initialize_player_stats()
    GameManager.current_day = 0
    GameManager.start_new_day()

func _on_continue_game_pressed():
    print("继续游戏")
    GameManager.change_state(GameManager.GameState.AREA_SELECTION)

func _on_settings_pressed():
    print("打开设置")

func _on_quit_pressed():
    get_tree().quit()

# ============ AreaSelectionUI 事件处理 ============
func _on_business_area_pressed():
    current_area = "business"
    GameManager.change_state(GameManager.GameState.DRIVING)

func _on_residential_area_pressed():
    current_area = "residential"
    GameManager.change_state(GameManager.GameState.DRIVING)

func _on_entertainment_area_pressed():
    current_area = "entertainment"
    GameManager.change_state(GameManager.GameState.DRIVING)

func _on_suburban_area_pressed():
    current_area = "suburban"
    GameManager.change_state(GameManager.GameState.DRIVING)

# ============ 对话事件处理 ============
func _on_interrupt_button_1_pressed():
    """基础插话"""
    print("点击了基础插话按钮")
    
    # 检查对话状态
    if dialogue_state != DialogueState.IN_DIALOGUE:
        print("❌ 对话状态不正确，忽略按钮点击")
        return
    
    var success_rate = GameManager.calculate_interrupt_success_rate("basic")
    var success = randf() < success_rate
    
    print("基础插话，成功率：%.1f%%, 结果：%s" % [success_rate * 100, "成功" if success else "失败"])
    
    if success:
        GameManager.update_player_attribute("empathy", 0.5)
        GameManager.update_player_attribute("self_connection", 0.2)
        GameManager.update_player_attribute("pressure", -0.1)
        
        if dialogue_label != null:
            var npc = test_npcs[current_npc_index]
            dialogue_label.text += "\n\n" + npc.interrupt_responses[0]
    else:
        GameManager.update_player_attribute("empathy", -0.3)
        GameManager.update_player_attribute("pressure", 0.4)
        if dialogue_label != null:
            dialogue_label.text += "\n\n对方似乎没有回应..."
    
    # 隐藏插话按钮，显示继续按钮
    if interrupt_button1 != null:
        interrupt_button1.visible = false
    if continue_button != null:
        continue_button.visible = true
        continue_button.text = "继续对话"
        continue_button.disabled = false
    
    update_all_displays()

func _on_interrupt_button_2_pressed():
    """深度插话"""
    print("点击了深度插话按钮")
    # 类似于基础插话的处理...

func _on_continue_dialogue_pressed():
    """继续对话"""
    print("点击了继续对话按钮，当前状态：", DialogueState.keys()[dialogue_state])
    
    match dialogue_state:
        DialogueState.IN_DIALOGUE:
            # 正常对话流程
            if current_dialogue_index < test_npcs[current_npc_index].dialogues.size() - 1:
                current_dialogue_index += 1
                show_next_dialogue()
            else:
                # 对话结束，但还没处理行程结算
                dialogue_state = DialogueState.DIALOGUE_FINISHED
                show_next_dialogue()
        
        DialogueState.DIALOGUE_FINISHED:
            # 结束当前乘客行程
            complete_current_trip()
        
        _:
            print("❌ 不应该在当前状态下点击继续按钮")

func complete_current_trip():
    """完成当前行程"""
    print("=== 完成当前行程 ===")
    
    dialogue_state = DialogueState.TRIP_COMPLETED
    
    var income = randi_range(40, 80)
    var mood_score = randf_range(40.0, 80.0)
    
    print("乘客下车，收入：", income, "元")
    GameManager.complete_passenger_trip(income, mood_score)
    
    # 检查是否需要更多乘客
    if GameManager.passengers_today < GameManager.max_passengers_per_day:
        print("需要接更多乘客，等待下一位...")
        start_driving_session()  # 重新开始驾驶会话
    else:
        print("今日乘客已满，准备回家")
        # 这里会通过GameManager.complete_passenger_trip触发day_completed信号

# ============ HomeUI 事件处理 ============
func _on_browse_dreamweave_pressed():
    print("浏览梦网")
    GameManager.update_player_attribute("pressure", -0.5)
    update_all_displays()

func _on_go_shopping_pressed():
    GameManager.change_state(GameManager.GameState.SHOP)

func _on_sleep_pressed():
    if GameManager.current_day >= 7:
        show_ending()
    else:
        GameManager.start_new_day()

# ============ ShopUI 事件处理 ============
func _on_return_home_pressed():
    GameManager.change_state(GameManager.GameState.HOME)

func show_ending():
    """显示结局界面"""
    print("=== 显示游戏结局 ===")
    
    var ending_type = GameManager.get_ending_type()
    var score = GameManager.calculate_final_score()
    
    # 创建结局界面
    create_ending_ui(ending_type, score)

func create_ending_ui(ending_type: String, score: float):
    """创建结局界面"""
    print("创建结局界面，类型：", ending_type, "，分数：", score)
    
    # 隐藏所有现有UI
    hide_all_ui_except(null)
    
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
    var ending_text = get_ending_description(ending_type)
    var description_label = RichTextLabel.new()
    description_label.text = ending_text
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
    restart_button.pressed.connect(_on_restart_game)
    ending_panel.add_child(restart_button)
    
    # 添加退出按钮
    var quit_button = Button.new()
    quit_button.text = "退出游戏"
    quit_button.custom_minimum_size = Vector2(200, 50)
    quit_button.pressed.connect(_on_quit_pressed)
    ending_panel.add_child(quit_button)
    
    # 应用字体
    if has_node("/root/FontManager"):
        FontManager.apply_theme_to_node(ending_container)
        FontManager.force_apply_font_to_node(description_label)
    
    # 添加到场景
    add_child(ending_container)
    current_ui = ending_container
    
    print("✅ 结局界面创建完成")

func get_ending_description(ending_type: String) -> String:
    """获取结局描述文本"""
    match ending_type:
        "find_yourself":
            return """恭喜！你找到了自己的影子。

在这些夜晚的载客过程中，你逐渐理解了什么是真正的自己。那些被影子学院压抑的部分，原来并不是需要被"整合"的缺陷，而是你最珍贵的本真。

你学会了在系统边缘生存，保持着人性的温度，拒绝成为完美的"高功能情绪单元"。

这是最好的结局。"""
        
        "connect_others":
            return """你与城市边缘的人们建立了真正的情感连接。

虽然还在寻找自己，但你已经找到了归属感。那些深夜的对话，那些真诚的理解，让你意识到选择性家庭的珍贵。

在这个情绪被管控的世界里，真实的人际连接是最宝贵的财富。

这是一个温暖的结局。"""
        
        "continue_searching":
            return """你还在路上。

这一周的经历让你开始质疑系统，开始思考什么是真正的自己。虽然答案还不清晰，但觉醒已经开始。

有时候，勇敢地承认"还在寻找"，本身就是一种诚实和进步。

路还很长，但方向是对的。"""
        
        "need_rest":
            return """你需要休息。

压力太大了，也许是时候停下来，好好照顾自己。

记住，自我关爱不是自私，而是为了更好地帮助他人。

休息不是失败，而是为了下一次更好的出发。"""
        
        _:
            return "游戏结束。感谢你的游玩！"

func _on_restart_game():
    """重新开始游戏"""
    print("重新开始游戏")
    
    # 移除结局界面
    if current_ui != null and current_ui.name == "EndingUI":
        current_ui.queue_free()
    
    # 重置游戏状态
    GameManager.initialize_player_stats()
    GameManager.current_day = 0
    GameManager.change_state(GameManager.GameState.MENU)

func update_home_display():
    """更新家中界面显示"""
    if stats_label != null:
        var daily_income = GameManager.daily_income
        var economic_status = GameManager.player_stats.get_economic_status() if GameManager.player_stats != null else "未知"
        stats_label.text = "今日收入: %d元\n当前状态: %s" % [daily_income, economic_status]

func update_shop_display():
    """更新商店界面显示"""
    if shop_money_label != null and GameManager.player_stats != null:
        shop_money_label.text = "当前余额: %d元" % GameManager.player_stats.money

func _on_day_completed():
    """响应一天结束"""
    last_visited_area = current_area

# ============ 驾驶控制事件处理 - 现在会影响NPC心情 ============
func _on_music_off_pressed():
    print("关闭音乐")
    GameManager.update_player_attribute("self_connection", 0.3)
    check_npc_music_preference("music_off")
    update_all_displays()

func _on_music_soothing_pressed():
    print("播放轻音乐")
    GameManager.update_player_attribute("pressure", -0.5)
    GameManager.update_player_attribute("empathy", 0.2)
    check_npc_music_preference("music_soothing")
    update_all_displays()

func _on_music_energetic_pressed():
    print("播放流行音乐")
    GameManager.update_player_attribute("openness", 0.3)
    GameManager.update_player_attribute("pressure", 0.2)
    check_npc_music_preference("music_energetic")
    update_all_displays()

func _on_window_open_pressed():
    print("开窗")
    GameManager.update_player_attribute("openness", 0.3)
    check_npc_preference("window_open")
    update_all_displays()

func _on_window_close_pressed():
    print("关窗")
    GameManager.update_player_attribute("self_connection", 0.2)
    check_npc_preference("window_closed")
    update_all_displays()

func _on_smooth_driving_pressed():
    print("平稳驾驶")
    GameManager.update_player_attribute("pressure", -0.2)
    GameManager.update_player_attribute("empathy", 0.1)
    check_npc_preference("smooth_driving")
    update_all_displays()

func _on_fast_driving_pressed():
    print("快速驾驶")
    GameManager.update_player_attribute("pressure", 0.3)
    GameManager.update_player_attribute("openness", 0.2)
    check_npc_preference("fast_driving")
    update_all_displays()

# ============ NPC偏好系统 ============
func check_npc_music_preference(music_type: String):
    """检查NPC对音乐的偏好"""
    check_npc_preference(music_type)

func check_npc_preference(preference_key: String):
    """检查NPC偏好并添加反应"""
    if current_npc_index >= test_npcs.size():
        return
    
    var npc = test_npcs[current_npc_index]
    if not npc.has("driving_preferences"):
        return
    
    var preferences = npc.driving_preferences
    if preference_key in preferences:
        var preference_value = preferences[preference_key]
        var reaction = ""
        
        if preference_value >= 0.8:
            reaction = "这样挺好的，我喜欢"
        elif preference_value >= 0.5:
            reaction = "嗯，还不错"
        elif preference_value <= 0.3:
            reaction = "这样我有点不太舒服..."
        
        if reaction != "" and dialogue_label != null:
            dialogue_label.text += "\n\n「" + reaction + "」"
            print("NPC偏好反应：", reaction)
