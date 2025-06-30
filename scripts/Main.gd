# Main.gd - 修复版本，解决字体、结局界面和按钮状态问题
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
        "interrupt_responses": ["是啊，工作压力很大", "生活确实需要思考"]
    },
    {
        "name": "老王", 
        "dialogues": ["年轻人，现在的世界变化太快了", "我记得以前的日子更简单", "你觉得简单的生活好吗？"],
        "interrupt_responses": ["确实，科技发展很快", "简单也有简单的美好"]
    }
]
var current_npc_index = 0
var current_dialogue_index = 0

func _ready():
    print("=== 主场景初始化 ===")
    
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
    else:
        print("❌ 对话标签或字体管理器未找到")

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

# ============ 驾驶控制事件处理 ============
func _on_music_off_pressed():
    print("关闭音乐")
    GameManager.update_player_attribute("self_connection", 0.3)
    update_all_displays()

func _on_music_soothing_pressed():
    print("播放轻音乐")
    GameManager.update_player_attribute("pressure", -0.5)
    GameManager.update_player_attribute("empathy", 0.2)
    update_all_displays()

func _on_music_energetic_pressed():
    print("播放流行音乐")
    GameManager.update_player_attribute("openness", 0.3)
    GameManager.update_player_attribute("pressure", 0.2)
    update_all_displays()

func _on_window_open_pressed():
    print("开窗")
    GameManager.update_player_attribute("openness", 0.3)
    update_all_displays()

func _on_window_close_pressed():
    print("关窗")
    GameManager.update_player_attribute("self_connection", 0.2)
    update_all_displays()

func _on_smooth_driving_pressed():
    print("平稳驾驶")
    GameManager.update_player_attribute("pressure", -0.2)
    GameManager.update_player_attribute("empathy", 0.1)
    update_all_displays()

func _on_fast_driving_pressed():
    print("快速驾驶")
    GameManager.update_player_attribute("pressure", 0.3)
    GameManager.update_player_attribute("openness", 0.2)
    update_all_displays()
