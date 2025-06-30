# Main.gd - 简化版主脚本，只负责协调各个管理器
extends Control

# 管理器引用
var ui_manager: UIManager
var qte_system: DrivingQTESystem

# 当前游戏状态
var current_area: String = ""
var last_visited_area: String = ""

# 简化的对话状态
enum DialogueState {
    WAITING_FOR_PASSENGER,
    IN_DIALOGUE,
    DIALOGUE_FINISHED,
    TRIP_COMPLETED
}

var dialogue_state: DialogueState = DialogueState.WAITING_FOR_PASSENGER

# 简化的测试NPC数据
var test_npcs = [
    {
        "name": "Sarah",
        "dialogues": ["我今天加班到很晚...", "有时候觉得生活就是个循环", "你觉得这样的生活有意义吗？"],
        "interrupt_responses": ["是啊，工作压力很大", "生活确实需要思考"],
        "driving_preferences": {
            "smooth_driving": 1.0,
            "music_soothing": 0.8,
            "close_window": 0.9
        }
    },
    {
        "name": "老王", 
        "dialogues": ["年轻人，现在的世界变化太快了", "我记得以前的日子更简单", "你觉得简单的生活好吗？"],
        "interrupt_responses": ["确实，科技发展很快", "简单也有简单的美好"],
        "driving_preferences": {
            "smooth_driving": 1.0,
            "music_off": 0.7,
            "open_window": 0.6
        }
    }
]
var current_npc_index = 0
var current_dialogue_index = 0

func _ready():
    print("=== 主场景初始化 ===")
    
    # 初始化管理器
    initialize_managers()
    
    # 连接信号
    connect_signals()
    
    # 初始显示
    ui_manager.switch_to_ui("start")
    update_all_displays()
    
    print("=== 初始化完成 ===\n")

func initialize_managers():
    """初始化所有管理器"""
    print("初始化管理器...")
    
    # 创建UI管理器
    ui_manager = UIManager.new()
    add_child(ui_manager)
    await ui_manager.initialize(self)
    
    # 创建QTE系统
    qte_system = DrivingQTESystem.new()
    add_child(qte_system)
    
    print("✅ 管理器初始化完成")

func connect_signals():
    """连接各管理器的信号"""
    print("连接信号...")
    
    # GameManager信号
    GameManager.state_changed.connect(_on_game_state_changed)
    GameManager.day_completed.connect(_on_day_completed)
    
    # UIManager信号
    ui_manager.button_pressed.connect(_on_ui_button_pressed)
    ui_manager.area_selected.connect(_on_area_selected)
    
    # QTE系统信号
    qte_system.qte_event_started.connect(_on_qte_event_started)
    qte_system.qte_event_completed.connect(_on_qte_event_completed)
    qte_system.ai_assistant_speaks.connect(_on_ai_assistant_speaks)
    
    # 驾驶控制信号
    connect_driving_controls()
    
    print("✅ 信号连接完成")

func connect_driving_controls():
    """连接驾驶控制按钮信号"""
    var driving_ui = ui_manager.driving_ui
    if driving_ui == null:
        return
    
    # 音乐控制
    var music_controls = driving_ui.get_node("ControlArea/DrivingControls/MusicControls")
    music_controls.get_node("MusicOffButton").pressed.connect(_on_driving_action.bind("music_off"))
    music_controls.get_node("MusicSoothingButton").pressed.connect(_on_driving_action.bind("music_soothing"))
    music_controls.get_node("MusicEnergeticButton").pressed.connect(_on_driving_action.bind("music_energetic"))
    
    # 窗户控制
    var window_controls = driving_ui.get_node("ControlArea/DrivingControls/WindowControls")
    window_controls.get_node("WindowOpenButton").pressed.connect(_on_driving_action.bind("open_window"))
    window_controls.get_node("WindowCloseButton").pressed.connect(_on_driving_action.bind("close_window"))
    
    # 驾驶风格
    var style_controls = driving_ui.get_node("ControlArea/DrivingControls/DrivingStyleControls")
    style_controls.get_node("SmoothDrivingButton").pressed.connect(_on_driving_action.bind("smooth_driving"))
    style_controls.get_node("FastDrivingButton").pressed.connect(_on_driving_action.bind("fast_driving"))
    
    # 对话按钮
    var dialogue_area = driving_ui.get_node("ControlArea/DialogueArea/DialogueContainer")
    dialogue_area.get_node("InterruptContainer/InterruptButton1").pressed.connect(_on_interrupt_pressed.bind("basic"))
    dialogue_area.get_node("ContinueButton").pressed.connect(_on_continue_dialogue_pressed)

func _process(delta):
    """主循环处理"""
    # 更新AI助手倒计时显示
    if qte_system != null and qte_system.is_qte_active:
        ui_manager.update_ai_countdown(qte_system.countdown_timer)

# ============ 信号处理方法 ============
func _on_game_state_changed(new_state: GameManager.GameState):
    """响应游戏状态变化"""
    print("游戏状态变化：", GameManager.GameState.keys()[new_state])
    
    match new_state:
        GameManager.GameState.MENU:
            ui_manager.switch_to_ui("start")
        GameManager.GameState.AREA_SELECTION:
            ui_manager.switch_to_ui("area_selection")
            ui_manager.update_area_selection_display(GameManager.current_day)
        GameManager.GameState.DRIVING:
            ui_manager.switch_to_ui("driving")
            if GameManager.passengers_today == 0:
                start_driving_session()
        GameManager.GameState.HOME:
            ui_manager.switch_to_ui("home")
            update_home_display()
        GameManager.GameState.SHOP:
            ui_manager.switch_to_ui("shop")
            update_shop_display()

func _on_ui_button_pressed(button_id: String, data: Dictionary):
    """处理UI按钮点击"""
    print("处理按钮：", button_id)
    
    match button_id:
        "start_game":
            GameManager.initialize_player_stats()
            GameManager.current_day = 0
            GameManager.start_new_day()
        "continue_game":
            GameManager.change_state(GameManager.GameState.AREA_SELECTION)
        "settings":
            print("打开设置")
        "quit":
            get_tree().quit()
        "browse_dreamweave":
            GameManager.update_player_attribute("pressure", -0.5)
            update_all_displays()
        "go_shopping":
            GameManager.change_state(GameManager.GameState.SHOP)
        "sleep":
            if GameManager.current_day >= 7:
                show_ending()
            else:
                GameManager.start_new_day()
        "return_home":
            GameManager.change_state(GameManager.GameState.HOME)
        "restart_game":
            restart_game()

func _on_area_selected(area_name: String):
    """处理区域选择"""
    current_area = area_name
    GameManager.change_state(GameManager.GameState.DRIVING)

func _on_driving_action(action: String):
    """处理驾驶控制操作"""
    print("🚗 驾驶操作：", action)
    
    # 检查是否有活跃的QTE事件需要这个操作
    var qte_handled = qte_system.handle_driving_action(action)
    
    if not qte_handled:
        # 正常的驾驶操作，应用属性效果
        apply_driving_action_effects(action)
        check_npc_preference(action)
    
    update_all_displays()

func apply_driving_action_effects(action: String):
    """应用驾驶操作的属性效果"""
    match action:
        "music_off":
            GameManager.update_player_attribute("self_connection", 0.3)
        "music_soothing":
            GameManager.update_player_attribute("pressure", -0.5)
            GameManager.update_player_attribute("empathy", 0.2)
        "music_energetic":
            GameManager.update_player_attribute("openness", 0.3)
            GameManager.update_player_attribute("pressure", 0.2)
        "open_window":
            GameManager.update_player_attribute("openness", 0.3)
        "close_window":
            GameManager.update_player_attribute("self_connection", 0.2)
        "smooth_driving":
            GameManager.update_player_attribute("pressure", -0.2)
            GameManager.update_player_attribute("empathy", 0.1)
        "fast_driving":
            GameManager.update_player_attribute("pressure", 0.3)
            GameManager.update_player_attribute("openness", 0.2)

func check_npc_preference(action: String):
    """检查NPC偏好并添加反应"""
    if current_npc_index >= test_npcs.size() or dialogue_state != DialogueState.IN_DIALOGUE:
        return
    
    var npc = test_npcs[current_npc_index]
    if not npc.has("driving_preferences"):
        return
    
    var preferences = npc.driving_preferences
    if action in preferences:
        var preference_value = preferences[action]
        var reaction = ""
        
        if preference_value >= 0.8:
            reaction = "这样挺好的，我喜欢"
        elif preference_value >= 0.5:
            reaction = "嗯，还不错"
        elif preference_value <= 0.3:
            reaction = "这样我有点不太舒服..."
        
        if reaction != "":
            add_npc_reaction_to_dialogue(reaction)

func add_npc_reaction_to_dialogue(reaction: String):
    """在对话中添加NPC反应"""
    var dialogue_label = ui_manager.get_dialogue_label()
    if dialogue_label != null:
        dialogue_label.text += "\n\n「" + reaction + "」"
        print("NPC反应：", reaction)

# ============ QTE事件处理 ============
func _on_qte_event_started(event):
    """QTE事件开始"""
    print("🚗 QTE事件开始：", event.ai_prompt)
    
    # 显示AI助手（在UIManager中处理）
    var is_urgent = event.countdown_time < 3.0
    ui_manager.show_ai_assistant(event.ai_prompt, is_urgent)

func _on_qte_event_completed(event, success: bool):
    """QTE事件完成"""
    print("🏁 QTE事件完成：", "成功" if success else "失败")
    
    # 延迟隐藏AI助手面板
    await get_tree().create_timer(2.0).timeout
    ui_manager.hide_ai_assistant()
    
    # 更新显示
    update_all_displays()
    
    # 添加NPC反应
    var reaction = event.npc_positive_reaction if success else event.npc_negative_reaction
    if reaction != "":
        add_npc_reaction_to_dialogue(reaction)

func _on_ai_assistant_speaks(message: String, urgent: bool):
    """AI助手说话"""
    ui_manager.show_ai_assistant(message, urgent)

# ============ 对话系统处理 ============
func _on_interrupt_pressed(interrupt_type: String):
    """处理插话按钮"""
    print("插话类型：", interrupt_type)
    
    if dialogue_state != DialogueState.IN_DIALOGUE:
        print("❌ 对话状态不正确，忽略插话")
        return
    
    var success_rate = GameManager.calculate_interrupt_success_rate(interrupt_type)
    var success = randf() < success_rate
    
    print("插话成功率：%.1f%%, 结果：%s" % [success_rate * 100, "成功" if success else "失败"])
    
    # 应用插话结果
    apply_interrupt_result(interrupt_type, success)
    
    # 更新UI状态
    var buttons = ui_manager.get_interrupt_buttons()
    buttons.button1.visible = false
    
    var continue_button = ui_manager.get_continue_button()
    continue_button.visible = true
    continue_button.text = "继续对话"
    continue_button.disabled = false
    
    update_all_displays()

func apply_interrupt_result(interrupt_type: String, success: bool):
    """应用插话结果"""
    var dialogue_label = ui_manager.get_dialogue_label()
    
    if success:
        # 应用成功效果
        match interrupt_type:
            "basic":
                GameManager.update_player_attribute("empathy", 0.5)
                GameManager.update_player_attribute("self_connection", 0.2)
                GameManager.update_player_attribute("pressure", -0.1)
        
        # 添加NPC积极回应
        if dialogue_label != null:
            var npc = test_npcs[current_npc_index]
            dialogue_label.text += "\n\n" + npc.interrupt_responses[0]
    else:
        # 应用失败效果
        GameManager.update_player_attribute("empathy", -0.3)
        GameManager.update_player_attribute("pressure", 0.4)
        
        # 添加失败反应
        if dialogue_label != null:
            dialogue_label.text += "\n\n对方似乎没有回应..."

# 可以在_on_continue_dialogue_pressed中添加调试
func _on_continue_dialogue_pressed():
    """继续对话 - 添加QTE状态调试"""
    print("继续对话，当前状态：", DialogueState.keys()[dialogue_state])
    
    # 调试QTE状态
    debug_qte_system()
    
    match dialogue_state:
        DialogueState.IN_DIALOGUE:
            if current_dialogue_index < test_npcs[current_npc_index].dialogues.size() - 1:
                current_dialogue_index += 1
                show_next_dialogue()
            else:
                dialogue_state = DialogueState.DIALOGUE_FINISHED
                show_dialogue_finished()
        
        DialogueState.DIALOGUE_FINISHED:
            complete_current_trip()
  

# ============ 驾驶会话管理 ============
# 在Main.gd中修改这些方法来确保QTE正确重置

func start_driving_session():
    """开始驾驶会话 - 确保QTE系统正确重置"""
    print("=== 开始驾驶会话 ===")
    
    dialogue_state = DialogueState.WAITING_FOR_PASSENGER
    
    # 确保QTE系统完全重置
    if qte_system != null:
        qte_system.reset_trip_events()
        print("✅ QTE系统状态已重置")
    else:
        print("❌ qte_system为null")
    
    show_waiting_for_passenger()
    
    # 等待2秒模拟乘客上车
    await get_tree().create_timer(2.0).timeout
    start_npc_dialogue()

func maybe_trigger_qte_event():
    """可能触发QTE事件 - 添加更多调试信息"""
    print("🎯 尝试触发QTE事件...")
    
    if qte_system == null:
        print("❌ qte_system为null，无法触发QTE")
        return
    
    if qte_system.should_trigger_event():
        print("✅ 条件满足，触发QTE事件")
        qte_system.trigger_random_event()
    else:
        print("❌ 条件不满足，未触发QTE事件")

func show_next_dialogue():
    """显示下一段对话 - 确保每段对话都尝试触发QTE"""
    if dialogue_state != DialogueState.IN_DIALOGUE:
        return
    
    var npc = test_npcs[current_npc_index]
    var npc_name_label = ui_manager.get_npc_name_label()
    var dialogue_label = ui_manager.get_dialogue_label()
    var buttons = ui_manager.get_interrupt_buttons()
    var continue_button = ui_manager.get_continue_button()
    
    if npc_name_label != null:
        npc_name_label.text = "%s (第%d位乘客)" % [npc.name, GameManager.passengers_today + 1]
    
    if current_dialogue_index < npc.dialogues.size():
        # 显示当前对话
        if dialogue_label != null:
            dialogue_label.text = npc.dialogues[current_dialogue_index]
            print("✅ 显示对话[%d]: %s" % [current_dialogue_index, npc.dialogues[current_dialogue_index]])
        
        # 显示插话选项
        buttons.button1.visible = true
        buttons.button1.text = "嗯嗯"
        buttons.button1.disabled = false
        continue_button.visible = false
        
        # 每段对话都尝试触发QTE事件
        print("🎯 对话[%d]显示完成，尝试触发QTE..." % current_dialogue_index)
        maybe_trigger_qte_event()
    else:
        print("❌ 对话索引超出范围")

# 另外，在complete_current_trip中也确保重置
func complete_current_trip():
    """完成当前行程 - 确保状态完全重置"""
    print("=== 完成当前行程 ===")
    
    dialogue_state = DialogueState.TRIP_COMPLETED
    
    var income = randi_range(40, 80)
    var mood_score = randf_range(40.0, 80.0)
    
    GameManager.complete_passenger_trip(income, mood_score)
    
    # 如果还需要更多乘客，确保QTE系统准备好下一次
    if GameManager.passengers_today < GameManager.max_passengers_per_day:
        print("需要接更多乘客，准备QTE系统...")
        if qte_system != null:
            # 额外的重置调用确保干净状态
            qte_system.reset_trip_events()
        start_driving_session()
    else:
        print("今日乘客已满，前往家中")

# 调试QTE系统状态的方法
func debug_qte_system():
    """调试QTE系统状态"""
    if qte_system == null:
        print("❌ qte_system为null")
        return
    
    print("=== QTE系统状态 ===")
    var status = qte_system.get_qte_status()
    for key in status.keys():
        print("  ", key, ": ", status[key])
    print("==================")

          
func show_waiting_for_passenger():
    """显示等待乘客状态"""
    var npc_name_label = ui_manager.get_npc_name_label()
    var dialogue_label = ui_manager.get_dialogue_label()
    var buttons = ui_manager.get_interrupt_buttons()
    var continue_button = ui_manager.get_continue_button()
    
    if npc_name_label != null:
        npc_name_label.text = "等待乘客中..."
    if dialogue_label != null:
        dialogue_label.text = "正在等待乘客上车..."
    
    # 隐藏所有按钮
    buttons.button1.visible = false
    buttons.button2.visible = false
    continue_button.visible = false

func start_npc_dialogue():
    """开始NPC对话"""
    print("=== 开始NPC对话 ===")
    
    dialogue_state = DialogueState.IN_DIALOGUE
    current_npc_index = randi() % test_npcs.size()
    current_dialogue_index = 0
    
    print("选择NPC：", test_npcs[current_npc_index].name)
    
    await get_tree().process_frame
    show_next_dialogue()


func show_dialogue_finished():
    """显示对话结束"""
    var dialogue_label = ui_manager.get_dialogue_label()
    var buttons = ui_manager.get_interrupt_buttons()
    var continue_button = ui_manager.get_continue_button()
    
    if dialogue_label != null:
        dialogue_label.text = "谢谢你的陪伴，这次旅程很愉快。"
    
    buttons.button1.visible = false
    buttons.button2.visible = false
    continue_button.text = "结束行程"
    continue_button.visible = true
    continue_button.disabled = false


# ============ 显示更新方法 ============
func update_all_displays():
    """更新所有显示"""
    update_attributes_display()
    update_money_display()
    update_city_background()

func update_attributes_display():
    """更新属性显示"""
    if GameManager.player_stats == null:
        return
    
    var labels = ui_manager.get_attribute_labels()
    var stats = GameManager.player_stats
    
    if labels.empathy != null:
        labels.empathy.text = "共情: %.0f" % stats.empathy
    if labels.self != null:
        labels.self.text = "自省: %.0f" % stats.self_connection
    if labels.openness != null:
        labels.openness.text = "开放: %.0f" % stats.openness
    if labels.pressure != null:
        labels.pressure.text = "压力: %.0f" % stats.pressure

func update_money_display():
    """更新金钱显示"""
    if GameManager.player_stats == null:
        return
    
    var money_label = ui_manager.get_money_label()
    if money_label != null:
        money_label.text = "💰 %d元" % GameManager.player_stats.money

func update_city_background():
    """更新城市背景"""
    var city_background = ui_manager.get_city_background()
    var city_label = ui_manager.get_city_label()
    
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

func update_home_display():
    """更新家中显示"""
    var daily_income = GameManager.daily_income
    var economic_status = GameManager.player_stats.get_economic_status() if GameManager.player_stats != null else "未知"
    ui_manager.update_home_display(daily_income, economic_status)

func update_shop_display():
    """更新商店显示"""
    if GameManager.player_stats != null:
        ui_manager.update_shop_display(GameManager.player_stats.money)

# ============ 结局系统 ============
func show_ending():
    """显示结局"""
    var ending_type = GameManager.get_ending_type()
    var score = GameManager.calculate_final_score()
    var ending_description = get_ending_description(ending_type)
    
    ui_manager.create_ending_ui(ending_type, score, ending_description)

func get_ending_description(ending_type: String) -> String:
    """获取结局描述"""
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

func restart_game():
    """重新开始游戏"""
    # 移除结局界面
    if ui_manager.current_ui != null and ui_manager.current_ui.name == "EndingUI":
        ui_manager.current_ui.queue_free()
    
    # 重置游戏状态
    GameManager.initialize_player_stats()
    GameManager.current_day = 0
    GameManager.change_state(GameManager.GameState.MENU)

func _on_day_completed():
    """响应一天结束"""
    last_visited_area = current_area
