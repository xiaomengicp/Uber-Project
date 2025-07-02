# Main.gd - 完整版本，集成NPCEventManager系统
extends Control

# 管理器引用
var ui_manager: UIManager
var qte_system: DrivingQTESystem
var shop_system: ShopSystem

# 当前游戏状态
var current_area: String = ""
var last_visited_area: String = ""

# NPC对话状态（新系统）
enum DialogueState {
    WAITING_FOR_PASSENGER,
    IN_DIALOGUE,
    DIALOGUE_FINISHED,
    TRIP_COMPLETED
}

var dialogue_state: DialogueState = DialogueState.WAITING_FOR_PASSENGER
var current_npc_event: NPCEvent = null
var current_dialogue_index: int = 0
var successful_interrupts: int = 0
var failed_interrupts: int = 0

# 备用测试数据（fallback）
var fallback_test_npcs = [
    {
        "name": "测试NPC",
        "area": "business_district", 
        "dialogues": [
            "这是一个测试对话，如果你看到这个说明NPCEventManager没有正常工作。",
            "请检查NPCEventManager是否正确加载了NPC数据文件。",
            "这只是备用的测试对话。"
        ],
        "interrupt_responses": {
            "empathy": "谢谢理解（测试回应）",
            "self_reflection": "是的我也这样想（测试回应）",
            "basic": "嗯嗯（测试回应）"
        },
        "economic_impact": {"base_fee": 50, "tip_range": [5, 15]}
    }
]

var fallback_npc_index = 0

func _ready():
    print("=== 主场景初始化 ===")
    
    # 等待NPCEventManager加载完成
    if NPCEventManager == null:
        print("⚠️  NPCEventManager未找到，将使用fallback模式")
    else:
        # 连接NPCEventManager信号
        if not NPCEventManager.npc_events_loaded.is_connected(_on_npc_events_loaded):
            NPCEventManager.npc_events_loaded.connect(_on_npc_events_loaded)
    
    # 初始化管理器
    await initialize_managers()
    
    # 验证UI节点
    await get_tree().process_frame
    verify_ui_nodes()
    
    # 连接信号
    connect_signals()
    
    # 初始显示
    ui_manager.switch_to_ui("start")
    update_all_displays()
    
    print("=== 初始化完成 ===")
    print_debug_info()

func _on_npc_events_loaded():
    """响应NPCEventManager加载完成"""
    print("✅ NPCEventManager加载完成，可以使用真实NPC数据")

func initialize_managers():
    """初始化所有管理器"""
    print("🔧 初始化管理器...")
    
    # 创建UI管理器
    ui_manager = UIManager.new()
    add_child(ui_manager)
    await ui_manager.initialize(self)
    
    # 创建QTE系统
    qte_system = DrivingQTESystem.new()
    add_child(qte_system)
    
    # 创建商店系统
    shop_system = ShopSystem.new()
    add_child(shop_system)
    
    print("✅ 管理器初始化完成")

func verify_ui_nodes():
    """验证UI节点结构"""
    print("🔍 验证UI节点...")
    
    var shop_ui = get_node_or_null("UIContainer/ShopUI")
    if shop_ui == null:
        print("❌ ShopUI节点不存在")
        return
    
    var required_shop_nodes = [
        "VBoxContainer/ShopTitle",
        "VBoxContainer/MoneyLabel", 
        "VBoxContainer/ScrollContainer",
        "VBoxContainer/ScrollContainer/ItemList",
        "VBoxContainer/ReturnButton"
    ]
    
    for node_path in required_shop_nodes:
        var node = shop_ui.get_node_or_null(node_path)
        if node == null:
            print("❌ 缺少商店节点：", node_path)
        else:
            print("✅ 商店节点存在：", node_path)

func connect_signals():
    """连接各管理器的信号"""
    print("🔗 连接信号...")
    
    # GameManager信号
    if GameManager.state_changed.is_connected(_on_game_state_changed):
        GameManager.state_changed.disconnect(_on_game_state_changed)
    GameManager.state_changed.connect(_on_game_state_changed)
    
    if GameManager.day_completed.is_connected(_on_day_completed):
        GameManager.day_completed.disconnect(_on_day_completed)
    GameManager.day_completed.connect(_on_day_completed)
    
    # UIManager信号
    ui_manager.button_pressed.connect(_on_ui_button_pressed)
    ui_manager.area_selected.connect(_on_area_selected)
    
    # QTE系统信号
    qte_system.qte_event_started.connect(_on_qte_event_started)
    qte_system.qte_event_completed.connect(_on_qte_event_completed)
    qte_system.ai_assistant_speaks.connect(_on_ai_assistant_speaks)
    
    # 商店系统信号
    shop_system.item_purchased.connect(_on_item_purchased)
    shop_system.purchase_failed.connect(_on_purchase_failed)
    shop_system.shop_updated.connect(_on_shop_updated)
    
    # 驾驶控制信号
    connect_driving_controls()
    
    print("✅ 信号连接完成")

func connect_driving_controls():
    """连接驾驶控制按钮信号"""
    var driving_ui = get_node_or_null("UIContainer/DrivingUI")
    if driving_ui == null:
        print("❌ DrivingUI节点不存在")
        return
    
    # 音乐控制
    var music_controls = driving_ui.get_node_or_null("ControlArea/DrivingControls/MusicControls")
    if music_controls != null:
        var music_off_btn = music_controls.get_node_or_null("MusicOffButton")
        var music_soothing_btn = music_controls.get_node_or_null("MusicSoothingButton")
        var music_energetic_btn = music_controls.get_node_or_null("MusicEnergeticButton")
        
        if music_off_btn: music_off_btn.pressed.connect(_on_driving_action.bind("music_off"))
        if music_soothing_btn: music_soothing_btn.pressed.connect(_on_driving_action.bind("music_soothing"))
        if music_energetic_btn: music_energetic_btn.pressed.connect(_on_driving_action.bind("music_energetic"))
    
    # 窗户控制
    var window_controls = driving_ui.get_node_or_null("ControlArea/DrivingControls/WindowControls")
    if window_controls != null:
        var window_open_btn = window_controls.get_node_or_null("WindowOpenButton")
        var window_close_btn = window_controls.get_node_or_null("WindowCloseButton")
        
        if window_open_btn: window_open_btn.pressed.connect(_on_driving_action.bind("open_window"))
        if window_close_btn: window_close_btn.pressed.connect(_on_driving_action.bind("close_window"))
    
    # 驾驶风格
    var style_controls = driving_ui.get_node_or_null("ControlArea/DrivingControls/DrivingStyleControls")
    if style_controls != null:
        var smooth_btn = style_controls.get_node_or_null("SmoothDrivingButton")
        var fast_btn = style_controls.get_node_or_null("FastDrivingButton")
        
        if smooth_btn: smooth_btn.pressed.connect(_on_driving_action.bind("smooth_driving"))
        if fast_btn: fast_btn.pressed.connect(_on_driving_action.bind("fast_driving"))
    
    # 对话按钮
    var dialogue_area = driving_ui.get_node_or_null("ControlArea/DialogueArea/DialogueContainer")
    if dialogue_area != null:
        var interrupt_btn1 = dialogue_area.get_node_or_null("InterruptContainer/InterruptButton1")
        var interrupt_btn2 = dialogue_area.get_node_or_null("InterruptContainer/InterruptButton2")
        var continue_btn = dialogue_area.get_node_or_null("ContinueButton")
        
        if interrupt_btn1: interrupt_btn1.pressed.connect(_on_interrupt_pressed.bind("basic"))
        if interrupt_btn2: interrupt_btn2.pressed.connect(_on_interrupt_pressed.bind("deep"))
        if continue_btn: continue_btn.pressed.connect(_on_continue_dialogue_pressed)

func _process(delta):
    """主循环处理"""
    # 更新AI助手倒计时显示
    if qte_system != null and qte_system.is_qte_active:
        ui_manager.update_ai_countdown(qte_system.countdown_timer)

func _input(event):
    """处理调试输入"""
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_F1:
                debug_npc_system()
            KEY_F2:
                # 快速添加金钱用于测试
                if GameManager.player_stats != null:
                    GameManager.player_stats.money += 100
                    print("💰 添加100元，当前：", GameManager.player_stats.money, "元")
                    update_all_displays()
            KEY_F3:
                # 快速前进一天用于测试解锁
                GameManager.current_day += 1
                print("📅 前进到第", GameManager.current_day, "天")
            KEY_F4:
                # 测试购买功能
                test_shop_purchase()
            KEY_F5:
                # 调试属性
                debug_player_attributes()

# ============ 信号处理方法 ============
func _on_game_state_changed(new_state: GameManager.GameState):
    """响应游戏状态变化"""
    print("🎮 游戏状态变化：", GameManager.GameState.keys()[new_state])
    
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
    print("🔘 处理按钮：", button_id)
    
    match button_id:
        "start_game":
            GameManager.initialize_player_stats()
            GameManager.current_day = 0
            if shop_system != null:
                shop_system.reset_shop()
            if NPCEventManager != null:
                NPCEventManager.reset_progress()
            GameManager.start_new_day()
        "continue_game":
            GameManager.change_state(GameManager.GameState.AREA_SELECTION)
        "settings":
            print("🔧 打开设置")
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
        "purchase_item":
            handle_item_purchase(data.get("item_id", ""))

func _on_area_selected(area_name: String):
    """处理区域选择"""
    # 修复区域名称映射
    var area_mapping = {
        "business": "business_district",
        "residential": "residential", 
        "entertainment": "entertainment",
        "suburban": "suburban"
    }
    
    current_area = area_mapping.get(area_name, area_name)
    print("🗺️ 区域选择：UI名称=", area_name, " 映射到=", current_area)
    
    GameManager.change_state(GameManager.GameState.DRIVING)
    
# ============ NPC对话系统（新版本）============
func start_driving_session():
    """开始驾驶会话"""
    print("=== 开始驾驶会话 ===")
    
    dialogue_state = DialogueState.WAITING_FOR_PASSENGER
    successful_interrupts = 0
    failed_interrupts = 0
    current_npc_event = null
    
    if qte_system != null:
        qte_system.reset_trip_events()
    
    show_waiting_for_passenger()
    
    # 等待2秒模拟乘客上车
    await get_tree().create_timer(2.0).timeout
    start_npc_dialogue()

func show_waiting_for_passenger():
    """显示等待乘客状态"""
    var npc_name_label = get_node_or_null("UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/NPCNameLabel")
    var dialogue_label = get_node_or_null("UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/DialogueLabel")
    var buttons = get_interrupt_buttons()
    var continue_button = get_continue_button()
    
    if npc_name_label: npc_name_label.text = "等待乘客中..."
    if dialogue_label: dialogue_label.text = "正在等待乘客上车..."
    
    # 隐藏所有按钮
    if buttons.button1: buttons.button1.visible = false
    if buttons.button2: buttons.button2.visible = false
    if continue_button: continue_button.visible = false

func start_npc_dialogue():
    """开始NPC对话 - 使用NPCEventManager"""
    print("=== 开始NPC对话 ===")
    
    dialogue_state = DialogueState.IN_DIALOGUE
    current_dialogue_index = 0
    
    # 尝试从NPCEventManager获取事件
    if NPCEventManager != null:
        var selected_event = NPCEventManager.select_random_event_for_area(
            current_area, 
            GameManager.current_day, 
            GameManager.player_stats
        )
        
        if selected_event != null:
            current_npc_event = selected_event
            print("✅ 使用NPCEventManager事件：", current_npc_event.id, " (", current_npc_event.npc_name, ")")
            await get_tree().process_frame
            show_npc_dialogue()
            return
    
    # Fallback到测试数据
    print("⚠️  NPCEventManager不可用，使用fallback数据")
    start_fallback_dialogue()

func show_npc_dialogue():
    """显示NPC对话内容"""
    if dialogue_state != DialogueState.IN_DIALOGUE or current_npc_event == null:
        return
    
    var npc_name_label = get_node_or_null("UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/NPCNameLabel")
    var dialogue_label = get_node_or_null("UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/DialogueLabel")
    var buttons = get_interrupt_buttons()
    var continue_button = get_continue_button()
    
    if npc_name_label:
        npc_name_label.text = "%s (第%d位乘客)" % [current_npc_event.npc_name, GameManager.passengers_today + 1]
    
    if current_dialogue_index < current_npc_event.dialogue_segments.size():
        # 显示当前对话
        if dialogue_label:
            var dialogue_text = current_npc_event.dialogue_segments[current_dialogue_index]
            dialogue_label.text = dialogue_text
            print("✅ 显示NPC对话[%d]: %s..." % [current_dialogue_index, dialogue_text.substr(0, 50)])
        
        # 显示插话选项
        setup_interrupt_options(buttons)
        if continue_button: continue_button.visible = false
        
        # 每段对话都尝试触发QTE事件
        maybe_trigger_qte_event()
    else:
        print("❌ 对话索引超出范围")

func setup_interrupt_options(buttons: Dictionary):
    """设置插话选项"""
    if buttons.button1:
        buttons.button1.visible = true
        buttons.button1.text = "嗯嗯"
        buttons.button1.disabled = false
    
    # 根据玩家属性设置第二个插话选项
    if buttons.button2:
        var player_stats = GameManager.player_stats
        if player_stats != null:
            var available_interrupt = get_available_deep_interrupt()
            if available_interrupt != "":
                buttons.button2.visible = true
                buttons.button2.text = get_interrupt_display_text(available_interrupt)
                buttons.button2.disabled = false
                buttons.button2.set_meta("interrupt_type", available_interrupt)
            else:
                buttons.button2.visible = false
        else:
            buttons.button2.visible = false

func get_available_deep_interrupt() -> String:
    """获取可用的深度插话类型"""
    var player_stats = GameManager.player_stats
    if player_stats == null:
        return ""
    
    # 按优先级检查
    if player_stats.empathy >= 60:
        return "empathy"
    elif player_stats.self_connection >= 60:
        return "self_reflection"
    elif player_stats.openness >= 60:
        return "openness"
    
    return ""

func get_interrupt_display_text(interrupt_type: String) -> String:
    """获取插话选项的显示文本"""
    match interrupt_type:
        "empathy":
            return "我理解你的感受"
        "self_reflection":
            return "这让我想到自己..."
        "openness":
            return "也许可以换个角度"
        _:
            return "嗯嗯"

func _on_interrupt_pressed(interrupt_type: String):
    """处理插话按钮"""
    print("💬 插话类型：", interrupt_type)
    
    if dialogue_state != DialogueState.IN_DIALOGUE:
        print("❌ 对话状态不正确，忽略插话")
        return
    
    # 如果是深度插话，获取实际的插话类型
    if interrupt_type == "deep":
        var button2 = get_interrupt_buttons().button2
        if button2 and button2.has_meta("interrupt_type"):
            interrupt_type = button2.get_meta("interrupt_type")
        else:
            interrupt_type = "basic"  # fallback
    
    var success_rate = GameManager.calculate_interrupt_success_rate(interrupt_type)
    var success = randf() < success_rate
    
    print("插话成功率：%.1f%%, 结果：%s" % [success_rate * 100, "成功" if success else "失败"])
    
    apply_interrupt_result(interrupt_type, success)
    
    var buttons = get_interrupt_buttons()
    if buttons.button1: buttons.button1.visible = false
    if buttons.button2: buttons.button2.visible = false
    
    var continue_button = get_continue_button()
    if continue_button:
        continue_button.visible = true
        continue_button.text = "继续对话"
        continue_button.disabled = false
    
    update_all_displays()

func apply_interrupt_result(interrupt_type: String, success: bool):
    """应用插话结果"""
    var dialogue_label = get_node_or_null("UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/DialogueLabel")
    
    if success:
        successful_interrupts += 1
        
        # 根据插话类型给予不同的属性奖励
        match interrupt_type:
            "empathy":
                GameManager.update_player_attribute("empathy", 1.0)
                GameManager.update_player_attribute("pressure", -0.3)
            "self_reflection":
                GameManager.update_player_attribute("self_connection", 1.2)
                GameManager.update_player_attribute("empathy", 0.4)
            "openness":
                GameManager.update_player_attribute("openness", 1.0)
                GameManager.update_player_attribute("self_connection", 0.3)
            "basic":
                GameManager.update_player_attribute("empathy", 0.3)
                GameManager.update_player_attribute("self_connection", 0.2)
                GameManager.update_player_attribute("pressure", -0.1)
        
        # 显示NPC的回应
        if dialogue_label != null:
            var response = ""
            if current_npc_event != null:
                response = current_npc_event.get_interrupt_response(interrupt_type)
            
            if response != "":
                dialogue_label.text += "\n\n「" + response + "」"
            else:
                dialogue_label.text += "\n\n（乘客点了点头）"
            
        print("✅ 插话成功！获得属性奖励")
    else:
        failed_interrupts += 1
        
        # 失败惩罚
        GameManager.update_player_attribute("empathy", -0.2)
        GameManager.update_player_attribute("pressure", 0.4)
        
        # 添加失败反应
        if dialogue_label != null:
            dialogue_label.text += "\n\n（对方似乎没有回应...）"
            
        print("❌ 插话失败")

func _on_continue_dialogue_pressed():
    """继续对话"""
    print("▶️ 继续对话，当前状态：", DialogueState.keys()[dialogue_state])
    
    match dialogue_state:
        DialogueState.IN_DIALOGUE:
            if current_npc_event != null and current_dialogue_index < current_npc_event.dialogue_segments.size() - 1:
                current_dialogue_index += 1
                show_npc_dialogue()
            elif fallback_npc_index >= 0 and current_dialogue_index < fallback_test_npcs[fallback_npc_index].dialogues.size() - 1:
                # fallback模式
                current_dialogue_index += 1
                show_fallback_dialogue()
            else:
                dialogue_state = DialogueState.DIALOGUE_FINISHED
                show_dialogue_finished()
        DialogueState.DIALOGUE_FINISHED:
            complete_current_trip()

func show_dialogue_finished():
    """显示对话结束"""
    var dialogue_label = get_node_or_null("UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/DialogueLabel")
    var buttons = get_interrupt_buttons()
    var continue_button = get_continue_button()
    
    if dialogue_label:
        dialogue_label.text = "谢谢你的陪伴，这次旅程很愉快。"
    
    if buttons.button1: buttons.button1.visible = false
    if buttons.button2: buttons.button2.visible = false
    if continue_button:
        continue_button.text = "结束行程"
        continue_button.visible = true
        continue_button.disabled = false

func complete_current_trip():
    """完成当前行程"""
    print("=== 完成当前行程 ===")
    
    dialogue_state = DialogueState.TRIP_COMPLETED
    
    var base_income = 50
    var tip_range = [5, 15]
    
    # 从NPCEvent获取经济数据
    if current_npc_event != null:
        var economic_impact = current_npc_event.economic_impact
        base_income = economic_impact.get("base_fee", 50)
        tip_range = economic_impact.get("tip_range", [5, 15])
        
        # 标记事件已遇见
        NPCEventManager.mark_event_encountered(current_npc_event, GameManager.current_day)
    elif fallback_npc_index >= 0:
        # fallback模式
        var npc = fallback_test_npcs[fallback_npc_index]
        var economic = npc.get("economic_impact", {"base_fee": 50, "tip_range": [5, 15]})
        base_income = economic.base_fee
        tip_range = economic.tip_range
    
    # 根据插话成功次数计算奖励
    var mood_bonus = 0
    if successful_interrupts > 0:
        mood_bonus = randi_range(tip_range[0], tip_range[1])
    
    var total_income = base_income + mood_bonus
    var mood_score = 50.0 + (successful_interrupts * 15) - (failed_interrupts * 8)
    
    print("基础费用：%d元" % base_income)
    if mood_bonus > 0:
        print("满意度奖励：%d元" % mood_bonus)
    print("总收入：%d元" % total_income)
    print("NPC心情：%.1f" % mood_score)
    
    GameManager.complete_passenger_trip(total_income, mood_score)
    
    # 清理状态
    current_npc_event = null
    fallback_npc_index = -1
    
    # 如果还需要更多乘客
    if GameManager.passengers_today < GameManager.max_passengers_per_day:
        print("需要接更多乘客...")
        start_driving_session()
    else:
        print("今日乘客已满，前往家中")

# ============ Fallback对话系统 ============
func start_fallback_dialogue():
    """开始fallback对话（使用测试数据）"""
    print("⚠️  使用fallback对话系统")
    
    # 选择合适的fallback NPC
    fallback_npc_index = 0  # 目前只有一个测试NPC
    current_dialogue_index = 0
    
    await get_tree().process_frame
    show_fallback_dialogue()

func show_fallback_dialogue():
    """显示fallback对话"""
    if fallback_npc_index < 0 or fallback_npc_index >= fallback_test_npcs.size():
        return
    
    var npc = fallback_test_npcs[fallback_npc_index]
    var npc_name_label = get_node_or_null("UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/NPCNameLabel")
    var dialogue_label = get_node_or_null("UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/DialogueLabel")
    var buttons = get_interrupt_buttons()
    var continue_button = get_continue_button()
    
    if npc_name_label:
        npc_name_label.text = "%s (第%d位乘客)" % [npc.name, GameManager.passengers_today + 1]
    
    if current_dialogue_index < npc.dialogues.size():
        if dialogue_label:
            dialogue_label.text = npc.dialogues[current_dialogue_index]
            print("✅ 显示fallback对话[%d]: %s..." % [current_dialogue_index, npc.dialogues[current_dialogue_index].substr(0, 50)])
        
        # 显示插话选项
        setup_interrupt_options(buttons)
        if continue_button: continue_button.visible = false
        
        # 尝试触发QTE事件
        maybe_trigger_qte_event()

func maybe_trigger_qte_event():
    """可能触发QTE事件"""
    if qte_system != null and qte_system.should_trigger_event():
        print("✅ 触发QTE事件")
        qte_system.trigger_random_event()
    else:
        print("❌ 未触发QTE事件")

# ============ 驾驶系统处理 ============
func _on_driving_action(action: String):
    """处理驾驶控制操作"""
    print("🚗 驾驶操作：", action)
    
    var qte_handled = qte_system.handle_driving_action(action) if qte_system != null else false
    
    if not qte_handled:
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
    if dialogue_state != DialogueState.IN_DIALOGUE:
        return
    
    var preferences = {}
    var reaction = ""
    
    # 从NPCEvent获取偏好
    if current_npc_event != null:
        preferences = current_npc_event.driving_preferences
    elif fallback_npc_index >= 0:
        # fallback模式下可以添加一些基本偏好
        preferences = {
            "smooth_driving": 0.8,
            "music_soothing": 0.7,
            "close_window": 0.6
        }
    
    if action in preferences:
        var preference_value = preferences[action]
        
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
    var dialogue_label = get_node_or_null("UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/DialogueLabel")
    if dialogue_label != null:
        dialogue_label.text += "\n\n「" + reaction + "」"
        print("💬 NPC反应：", reaction)

# ============ QTE事件处理 ============
func _on_qte_event_started(event):
    """QTE事件开始"""
    print("🚗 QTE事件开始：", event.ai_prompt)
    var is_urgent = event.countdown_time < 3.0
    ui_manager.show_ai_assistant(event.ai_prompt, is_urgent)

func _on_qte_event_completed(event, success: bool):
    """QTE事件完成"""
    print("🏁 QTE事件完成：", "成功" if success else "失败")
    await get_tree().create_timer(2.0).timeout
    ui_manager.hide_ai_assistant()
    update_all_displays()
    
    var reaction = event.npc_positive_reaction if success else event.npc_negative_reaction
    if reaction != "":
        add_npc_reaction_to_dialogue(reaction)

func _on_ai_assistant_speaks(message: String, urgent: bool):
    """AI助手说话"""
    ui_manager.show_ai_assistant(message, urgent)

# ============ 商店系统处理 ============
func handle_item_purchase(item_id: String):
    """处理物品购买"""
    if item_id == "" or GameManager.player_stats == null or shop_system == null:
        print("❌ 购买失败：无效的物品ID或系统未初始化")
        return
    
    print("🛒 尝试购买物品：", item_id)
    
    # 通过商店系统购买物品
    var purchase_result = shop_system.purchase_item(item_id, GameManager.player_stats)
    
    if purchase_result.success:
        var item = purchase_result.item
        var story_text = purchase_result.get("story_text", "")
        var remaining_money = purchase_result.remaining_money
        
        print("✅ 购买成功：", item.name, " 剩余：", remaining_money, "元")
        
        # 显示购买结果
        show_purchase_success(item.name, story_text, remaining_money)
        
        # 更新所有显示
        update_all_displays()
        update_shop_display()
    else:
        print("❌ 购买失败")

func show_purchase_success(item_name: String, story_text: String, remaining_money: int):
    """显示购买成功信息"""
    print("🎉 购买成功：", item_name)
    print("📖 ", story_text)
    print("💰 剩余金额：", remaining_money, "元")

func update_shop_display():
    """更新商店显示"""
    if GameManager.player_stats == null or shop_system == null:
        print("❌ 无法更新商店显示：系统未初始化")
        return
    
    var current_money = GameManager.player_stats.money
    var current_day = GameManager.current_day
    var available_items = shop_system.get_available_items(current_day, GameManager.player_stats)
    
    print("🛒 更新商店显示：")
    print("   当前金额：", current_money, "元")
    print("   当前天数：", current_day)
    print("   可用物品：", available_items.size(), "个")
    
    # 更新金钱显示
    var money_label = get_node_or_null("UIContainer/ShopUI/VBoxContainer/MoneyLabel")
    if money_label != null:
        money_label.text = "当前余额: %d元" % current_money
    
    # 更新商品列表
    update_shop_items_display(available_items, current_money)

func update_shop_items_display(available_items: Array, player_money: int):
    """更新商品列表显示"""
    var item_list = get_node_or_null("UIContainer/ShopUI/VBoxContainer/ScrollContainer/ItemList")
    if item_list == null:
        print("❌ ItemList节点不存在")
        return
    
    # 清空现有商品
    for child in item_list.get_children():
        child.queue_free()
    
    # 按分类组织商品
    var categories = organize_items_by_category(available_items)
    
    # 为每个分类创建商品显示
    for category in categories.keys():
        create_shop_category_section(item_list, category, categories[category], player_money)

func organize_items_by_category(items: Array) -> Dictionary:
    """按分类组织商品"""
    var categories = {}
    for item in items:
        var category = item.get("category", "other")
        if category not in categories:
            categories[category] = []
        categories[category].append(item)
    return categories

func create_shop_category_section(parent: VBoxContainer, category: String, items: Array, player_money: int):
    """创建商品分类区域"""
    # 分类标题
    var category_label = Label.new()
    category_label.text = get_category_display_name(category)
    category_label.add_theme_font_size_override("font_size", 18)
    category_label.add_theme_color_override("font_color", Color.YELLOW)
    parent.add_child(category_label)
    
    # 商品列表
    for item in items:
        create_shop_item_button(parent, item, player_money)
    
    # 分隔线
    var separator = HSeparator.new()
    parent.add_child(separator)

func create_shop_item_button(parent: VBoxContainer, item: Dictionary, player_money: int):
    """创建单个商品按钮"""
    var item_container = HBoxContainer.new()
    item_container.custom_minimum_size = Vector2(0, 60)
    
    # 商品信息
    var info_label = Label.new()
    var affordable = "💰" if player_money >= item.price else "❌"
    var effects_text = format_item_effects(item.get("effects", {}))
    info_label.text = "%s %s - %d元\n%s\n%s" % [affordable, item.name, item.price, item.description, effects_text]
    info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info_label.add_theme_font_size_override("font_size", 12)
    
    # 购买按钮
    var buy_button = Button.new()
    buy_button.text = "购买"
    buy_button.custom_minimum_size = Vector2(60, 50)
    buy_button.disabled = player_money < item.price
    
    # 连接购买信号
    buy_button.pressed.connect(_on_item_purchase_requested.bind(item.id))
    
    item_container.add_child(info_label)
    item_container.add_child(buy_button)
    parent.add_child(item_container)

func format_item_effects(effects: Dictionary) -> String:
    """格式化物品效果显示"""
    var effect_strings = []
    for effect in effects.keys():
        var value = effects[effect]
        var effect_name = get_effect_display_name(effect)
        var sign = "+" if value > 0 else ""
        effect_strings.append("%s%s %s" % [sign, value, effect_name])
    return "效果: " + ", ".join(effect_strings)

func get_effect_display_name(effect: String) -> String:
    """获取效果的显示名称"""
    match effect:
        "empathy": return "共情"
        "self_connection": return "自省"
        "openness": return "开放"
        "pressure": return "压力"
        "energy": return "活力"
        _: return effect

func get_category_display_name(category: String) -> String:
    """获取分类显示名称"""
    match category:
        "basic": return "🏠 生活必需品"
        "exploration": return "🔍 自我探索"
        "healing": return "💖 情感治愈"
        "special": return "⭐ 特殊物品"
        _: return "📦 其他"

func _on_item_purchase_requested(item_id: String):
    """处理购买请求"""
    print("🛒 请求购买物品：", item_id)
    handle_item_purchase(item_id)

# ============ 商店系统信号处理 ============
func _on_item_purchased(item_id: String, item_data: Dictionary):
    """物品购买成功回调"""
    print("🎉 物品购买成功：", item_data.name)
    handle_special_item_effects(item_id, item_data)

func _on_purchase_failed(reason: String):
    """购买失败回调"""
    print("💸 购买失败：", reason)

func _on_shop_updated():
    """商店更新回调"""
    print("🔄 商店状态已更新")
    if GameManager.current_state == GameManager.GameState.SHOP:
        update_shop_display()

func handle_special_item_effects(item_id: String, item_data: Dictionary):
    """处理特殊物品效果"""
    match item_id:
        "therapy_session":
            print("🧠 获得心理咨询，解锁深度自我探索")
            GameManager.player_stats.purchased_items.append("therapy_unlocked")
        "academy_consultation":
            print("🎓 与前学院生交流，了解逃离路径")
            GameManager.player_stats.purchased_items.append("academy_escape_knowledge")
        "family_contact":
            print("👥 接触选择性家庭网络")
            GameManager.player_stats.purchased_items.append("family_network_access")
        "shadow_integration":
            print("🌗 真正的影子整合开始")
            GameManager.player_stats.purchased_items.append("true_shadow_work")

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
    
    var stats = GameManager.player_stats
    var attributes_container = get_node_or_null("UIContainer/DrivingUI/CarWindowView/AttributesPanel/AttributesContainer")
    
    if attributes_container != null:
        var empathy_label = attributes_container.get_node_or_null("EmpathyLabel")
        var self_label = attributes_container.get_node_or_null("SelfLabel")
        var openness_label = attributes_container.get_node_or_null("OpennessLabel")
        var pressure_label = attributes_container.get_node_or_null("PressureLabel")
        
        if empathy_label: empathy_label.text = "共情: %.0f" % stats.empathy
        if self_label: self_label.text = "自省: %.0f" % stats.self_connection
        if openness_label: openness_label.text = "开放: %.0f" % stats.openness
        if pressure_label: pressure_label.text = "压力: %.0f" % stats.pressure

func update_money_display():
    """更新金钱显示"""
    if GameManager.player_stats == null:
        return
    
    var money_label = get_node_or_null("UIContainer/DrivingUI/CarWindowView/MoneyLabel")
    if money_label != null:
        money_label.text = "💰 %d元" % GameManager.player_stats.money

func update_city_background():
    """更新城市背景"""
    var city_background = get_node_or_null("UIContainer/DrivingUI/CarWindowView/BackgroundCity")
    var city_label = get_node_or_null("UIContainer/DrivingUI/CarWindowView/CityLabel")
    
    if city_background == null:
        return
    
    match current_area:
        "business":
            city_background.color = Color(0.3, 0.4, 0.6)
            if city_label: city_label.text = "商业区夜景"
        "residential":
            city_background.color = Color(0.4, 0.3, 0.4)
            if city_label: city_label.text = "居住区夜景"
        "entertainment":
            city_background.color = Color(0.5, 0.2, 0.4)
            if city_label: city_label.text = "娱乐区夜景"
        "suburban":
            city_background.color = Color(0.2, 0.4, 0.3)
            if city_label: city_label.text = "郊外夜景"
        _:
            city_background.color = Color(0.2, 0.3, 0.5)
            if city_label: city_label.text = "城市夜景"

func update_home_display():
    """更新家中显示"""
    var daily_income = GameManager.daily_income
    var economic_status = GameManager.player_stats.get_economic_status() if GameManager.player_stats != null else "未知"
    
    var stats_label = get_node_or_null("UIContainer/HomeUI/CenterContainer/VBoxContainer/StatsLabel")
    if stats_label != null:
        stats_label.text = "今日收入: %d元\n当前状态: %s" % [daily_income, economic_status]

# ============ 辅助方法 ============
func get_interrupt_buttons() -> Dictionary:
    """获取插话按钮"""
    var container = get_node_or_null("UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/InterruptContainer")
    if container == null:
        return {"button1": null, "button2": null}
    
    return {
        "button1": container.get_node_or_null("InterruptButton1"),
        "button2": container.get_node_or_null("InterruptButton2")
    }

func get_continue_button() -> Button:
    """获取继续按钮"""
    return get_node_or_null("UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/ContinueButton")

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
    
    # 重置各个系统
    if shop_system != null:
        shop_system.reset_shop()
    if NPCEventManager != null:
        NPCEventManager.reset_progress()
    
    GameManager.change_state(GameManager.GameState.MENU)

func _on_day_completed():
    """响应一天结束"""
    last_visited_area = current_area

# ============ 调试方法 ============
func debug_npc_system():
    """调试NPC系统状态"""
    print("=== NPC系统调试信息 ===")
    
    if NPCEventManager == null:
        print("❌ NPCEventManager为null")
        return
    
    var debug_info = NPCEventManager.get_debug_info()
    print("总事件数量：", debug_info.total_events)
    print("各区域事件数量：", debug_info.events_by_area)
    print("各NPC事件数量：", debug_info.events_by_npc)
    print("已遇见事件数量：", debug_info.encountered_events)
    print("NPC遇见次数：", debug_info.npc_encounter_counts)
    
    if GameManager.player_stats != null:
        print("\n当前玩家状态：")
        print("天数：", GameManager.current_day)
        print("区域：", current_area)
        print("共情：", GameManager.player_stats.empathy)
        print("自省：", GameManager.player_stats.self_connection)
        print("开放：", GameManager.player_stats.openness)
        print("压力：", GameManager.player_stats.pressure)
    
    print("==========================")

func debug_player_attributes():
    """调试玩家属性"""
    if GameManager.player_stats == null:
        print("❌ 玩家数据为null")
        return
    
    print("=== 玩家属性调试 ===")
    print("共情：%.1f (解锁深度插话：%s)" % [GameManager.player_stats.empathy, "是" if GameManager.player_stats.empathy >= 60 else "否"])
    print("自省：%.1f (解锁深度插话：%s)" % [GameManager.player_stats.self_connection, "是" if GameManager.player_stats.self_connection >= 60 else "否"])
    print("开放：%.1f (解锁深度插话：%s)" % [GameManager.player_stats.openness, "是" if GameManager.player_stats.openness >= 60 else "否"])
    print("压力：%.1f (影响成功率：%.1f%%)" % [GameManager.player_stats.pressure, GameManager.player_stats.pressure * 0.45])
    print("===================")

func test_shop_purchase():
    """测试商店购买功能"""
    if shop_system == null or GameManager.player_stats == null:
        print("❌ 系统未初始化")
        return
    
    # 确保有足够金钱
    GameManager.player_stats.money = 500
    
    # 尝试购买咖啡
    var result = shop_system.purchase_item("coffee", GameManager.player_stats)
    if result.success:
        print("✅ 测试购买成功：", result.item.name)
        show_purchase_success(result.item.name, result.story_text, result.remaining_money)
    else:
        print("❌ 测试购买失败")
    
    update_all_displays()

func print_debug_info():
    """打印调试信息"""
    print("\n=== 调试信息 ===")
    print("调试快捷键：")
    print("  F1 - 显示NPC系统调试信息")
    print("  F2 - 添加100元金钱")
    print("  F3 - 前进一天")
    print("  F4 - 测试购买功能")
    print("  F5 - 调试玩家属性")
    print("===================")
