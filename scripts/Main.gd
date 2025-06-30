# Main.gd - 重新编写，确保更新
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

# 先用简单路径测试，如果不行再调整
@onready var empathy_label = $UIContainer/DrivingUI/CarWindowView/AttributesPanel/AttributesContainer/EmpathyLabel
@onready var self_label = $UIContainer/DrivingUI/CarWindowView/AttributesPanel/AttributesContainer/SelfLabel
@onready var openness_label = $UIContainer/DrivingUI/CarWindowView/AttributesPanel/AttributesContainer/OpennessLabel
@onready var pressure_label = $UIContainer/DrivingUI/CarWindowView/AttributesPanel/AttributesContainer/PressureLabel
@onready var money_label = $UIContainer/DrivingUI/CarWindowView/MoneyLabel

@onready var npc_name_label = $UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/NPCNameLabel
@onready var dialogue_label = $UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/DialogueLabel
@onready var interrupt_button1 = $UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/InterruptContainer/InterruptButton1
@onready var interrupt_button2 = $UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/InterruptContainer/InterruptButton2
@onready var continue_button = $UIContainer/DrivingUI/ControlArea/DialogueArea/DialogueContainer/ContinueButton

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
    
    # 首先检查基础UI节点
    print("检查基础UI节点:")
    print("  start_ui: ", start_ui)
    print("  driving_ui: ", driving_ui)
    print("  area_selection_ui: ", area_selection_ui)
    
    # 检查DrivingUI结构
    if driving_ui != null:
        print("DrivingUI 存在，检查子节点:")
        for child in driving_ui.get_children():
            print("  子节点: ", child.name, " (", child.get_class(), ")")
            if child.name == "CarWindowView":
                print("    CarWindowView 的子节点:")
                for grandchild in child.get_children():
                    print("      ", grandchild.name, " (", grandchild.get_class(), ")")
            elif child.name == "ControlArea":
                print("    ControlArea 的子节点:")
                for grandchild in child.get_children():
                    print("      ", grandchild.name, " (", grandchild.get_class(), ")")
    
    # 检查重要的对话节点
    print("检查对话节点:")
    print("  npc_name_label: ", npc_name_label)
    print("  dialogue_label: ", dialogue_label)
    print("  interrupt_button1: ", interrupt_button1)
    
    # 检查属性节点
    print("检查属性节点:")
    print("  empathy_label: ", empathy_label)
    
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
    print("准备显示UI：", ui.name if ui != null else "null")
    
    hide_all_ui_except(ui)
    
    if ui != null:
        ui.visible = true
        current_ui = ui
        print("✅ 成功切换到UI：", ui.name)
        print("   UI 可见性：", ui.visible)
        print("   UI 大小：", ui.size)
    else:
        print("❌ UI 为 null，无法显示")

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
    if GameManager.player_stats == null:
        print("GameManager.player_stats 为 null")
        return
        
    if empathy_label == null:
        print("属性标签节点未找到，跳过更新")
        return
        
    var stats = GameManager.player_stats
    empathy_label.text = "共情: %.0f" % stats.empathy
    self_label.text = "自省: %.0f" % stats.self_connection
    openness_label.text = "开放: %.0f" % stats.openness
    pressure_label.text = "压力: %.0f" % stats.pressure
    print("✅ 属性显示更新成功")

func update_money_display():
    """更新金钱显示"""
    if GameManager.player_stats == null or money_label == null:
        print("player_stats 或 money_label 为 null，跳过金钱显示更新")
        return
        
    money_label.text = "💰 %d元" % GameManager.player_stats.money
    
    if shop_money_label != null:
        shop_money_label.text = "当前余额: %d元" % GameManager.player_stats.money
    print("✅ 金钱显示更新成功")

func update_city_background():
    """根据当前区域更新城市背景"""
    if city_background == null:
        print("city_background 为 null，跳过背景更新")
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
    print("✅ 背景更新成功")

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
    
    print("开始接第", GameManager.passengers_today + 1, "个乘客")
    
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
    
    if npc_name_label == null or dialogue_label == null:
        print("❌ 对话节点未找到，无法显示对话")
        print("   npc_name_label: ", npc_name_label)
        print("   dialogue_label: ", dialogue_label)
        return
        
    var npc = test_npcs[current_npc_index]
    npc_name_label.text = "%s (第%d位乘客)" % [npc.name, GameManager.passengers_today + 1]
    
    if current_dialogue_index < npc.dialogues.size():
        dialogue_label.text = npc.dialogues[current_dialogue_index]
        print("✅ 显示对话：", npc.dialogues[current_dialogue_index])
        
        # 显示插话选项
        if interrupt_button1 != null:
            interrupt_button1.visible = true
            interrupt_button1.text = "嗯嗯"
            print("✅ 显示插话按钮")
        
        if continue_button != null:
            continue_button.visible = false
    else:
        # 对话结束
        dialogue_label.text = "谢谢你的陪伴，这次旅程很愉快。"
        if interrupt_button1 != null:
            interrupt_button1.visible = false
        if continue_button != null:
            continue_button.text = "结束行程"
            continue_button.visible = true
        print("✅ 显示对话结束界面")

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
    
    if interrupt_button1 != null:
        interrupt_button1.visible = false
    if continue_button != null:
        continue_button.visible = true
        continue_button.text = "继续对话"
    
    update_all_displays()

func _on_interrupt_button_2_pressed():
    """深度插话"""
    print("点击了深度插话按钮")
    # 类似处理...

func _on_continue_dialogue_pressed():
    """继续对话"""
    print("点击了继续对话按钮")
    
    if current_dialogue_index < test_npcs[current_npc_index].dialogues.size() - 1:
        current_dialogue_index += 1
        show_next_dialogue()
    else:
        # 对话结束
        var income = randi_range(40, 80)
        var mood_score = randf_range(40.0, 80.0)
        
        print("乘客下车，准备结算...")
        GameManager.complete_passenger_trip(income, mood_score)
        
        if GameManager.passengers_today < GameManager.max_passengers_per_day:
            print("需要更多乘客...")
            if npc_name_label != null:
                npc_name_label.text = "等待中..."
            if dialogue_label != null:
                dialogue_label.text = "正在等待下一位乘客上车..."
            
            await get_tree().create_timer(2.0).timeout
            start_driving_session()

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
    """显示结局"""
    var ending_type = GameManager.get_ending_type()
    var score = GameManager.calculate_final_score()
    
    print("游戏结束！结局：", ending_type, "，分数：", score)

func update_home_display():
    """更新家中界面显示"""
    pass

func update_shop_display():
    """更新商店界面显示"""
    pass

func _on_day_completed():
    """响应一天结束"""
    last_visited_area = current_area
