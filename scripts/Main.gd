# Main.gd - 主场景控制脚本
# 挂载到Main.tscn的根节点

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

# 属性显示标签
@onready var empathy_label = $UIContainer/DrivingUI/TopPanel/AttributesContainer/EmpathyLabel
@onready var self_label = $UIContainer/DrivingUI/TopPanel/AttributesContainer/SelfLabel
@onready var openness_label = $UIContainer/DrivingUI/TopPanel/AttributesContainer/OpennessLabel
@onready var pressure_label = $UIContainer/DrivingUI/TopPanel/AttributesContainer/PressureLabel
@onready var money_label = $UIContainer/DrivingUI/TopPanel/MoneyLabel

# 对话相关节点
@onready var npc_name_label = $UIContainer/DrivingUI/DialogueArea/DialogueContainer/NPCNameLabel
@onready var dialogue_label = $UIContainer/DrivingUI/DialogueArea/DialogueContainer/DialogueLabel
@onready var interrupt_button1 = $UIContainer/DrivingUI/DialogueArea/DialogueContainer/InterruptContainer/InterruptButton1
@onready var interrupt_button2 = $UIContainer/DrivingUI/DialogueArea/DialogueContainer/InterruptContainer/InterruptButton2
@onready var continue_button = $UIContainer/DrivingUI/DialogueArea/DialogueContainer/ContinueButton

# 家中界面
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
    print("主场景初始化...")
    
    # 应用字体主题
    if has_node("/root/FontManager"):
        FontManager.apply_theme_to_node(self)
    
    # 连接GameManager信号
    GameManager.state_changed.connect(_on_game_state_changed)
    GameManager.day_completed.connect(_on_day_completed)
    
    # 初始显示开始界面
    show_ui(start_ui)
    
    # 隐藏所有其他界面
    hide_all_ui_except(start_ui)
    
    # 初始化界面显示
    update_all_displays()

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
    ui.visible = true
    current_ui = ui
    print("切换到UI：", ui.name)

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

func update_attributes_display():
    """更新属性显示"""
    if GameManager.player_stats:
        var stats = GameManager.player_stats
        empathy_label.text = "共情: %.0f" % stats.empathy
        self_label.text = "自省: %.0f" % stats.self_connection
        openness_label.text = "开放: %.0f" % stats.openness
        pressure_label.text = "压力: %.0f" % stats.pressure

func update_money_display():
    """更新金钱显示"""
    if GameManager.player_stats:
        money_label.text = "💰 %d元" % GameManager.player_stats.money
        shop_money_label.text = "当前余额: %d元" % GameManager.player_stats.money

func update_area_selection_display():
    """更新区域选择界面"""
    day_label.text = "第 %d 天" % GameManager.current_day
    
    # 解锁逻辑
    if GameManager.current_day >= 2:
        entertainment_button.disabled = false
    if GameManager.current_day >= 3:
        suburban_button.disabled = false
    
    # 禁用昨天访问的区域
    reset_area_buttons()
    if last_visited_area == "business":
        business_button.disabled = true
        business_button.text = "商业区\n(昨日已访问)"
    elif last_visited_area == "residential":
        residential_button.disabled = true
        residential_button.text = "居住区\n(昨日已访问)"

func reset_area_buttons():
    """重置区域按钮状态"""
    business_button.disabled = false
    residential_button.disabled = false
    business_button.text = "商业区\n高收入，高压力环境"
    residential_button.text = "居住区\n温馨但收入一般"

func start_driving_session():
    """开始驾驶会话"""
    update_all_displays()
    current_npc_index = randi() % test_npcs.size()
    current_dialogue_index = 0
    show_next_dialogue()

func show_next_dialogue():
    """显示下一段对话"""
    var npc = test_npcs[current_npc_index]
    npc_name_label.text = npc.name
    
    if current_dialogue_index < npc.dialogues.size():
        dialogue_label.text = npc.dialogues[current_dialogue_index]
        
        # 显示插话选项
        interrupt_button1.visible = true
        interrupt_button1.text = "嗯嗯"
        
        # 检查是否有深度插话选项
        if GameManager.player_stats.can_interrupt("emotional"):
            interrupt_button2.visible = true
            interrupt_button2.text = "听起来你很难过"
        else:
            interrupt_button2.visible = false
        
        continue_button.visible = false
    else:
        # 对话结束
        dialogue_label.text = "谢谢你的陪伴，这次旅程很愉快。"
        interrupt_button1.visible = false
        interrupt_button2.visible = false
        continue_button.text = "结束行程"
        continue_button.visible = true

func update_home_display():
    """更新家中界面显示"""
    var stats = GameManager.player_stats
    stats_label.text = "今日收入: %d元\n当前状态: %s\n压力状况: %s" % [
        GameManager.daily_income,
        stats.get_economic_status(),
        stats.get_pressure_status()
    ]

func update_shop_display():
    """更新商店界面显示"""
    update_money_display()
    # TODO: 动态加载商品列表

func _on_day_completed():
    """响应一天结束"""
    last_visited_area = current_area
    print("一天结束，最后访问区域：", last_visited_area)

# ============ StartUI 事件处理 ============
func _on_start_game_pressed():
    """开始游戏按钮"""
    print("开始新游戏")
    GameManager.start_new_day()

func _on_continue_game_pressed():
    """继续游戏按钮"""
    print("继续游戏")
    GameManager.change_state(GameManager.GameState.AREA_SELECTION)

func _on_settings_pressed():
    """设置按钮"""
    print("打开设置")

func _on_quit_pressed():
    """退出按钮"""
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

# ============ DrivingUI 事件处理 ============
func _on_interrupt_button_1_pressed():
    """基础插话"""
    var success_rate = GameManager.calculate_interrupt_success_rate("basic")
    var success = randf() < success_rate
    
    print("基础插话，成功率：%.1f%%, 结果：%s" % [success_rate * 100, "成功" if success else "失败"])
    
    if success:
        # 应用属性变化
        GameManager.update_player_attribute("empathy", 0.5)
        GameManager.update_player_attribute("self_connection", 0.2)
        GameManager.update_player_attribute("pressure", -0.1)
        
        # 显示回应
        var npc = test_npcs[current_npc_index]
        dialogue_label.text += "\n\n" + npc.interrupt_responses[0]
    else:
        GameManager.update_player_attribute("empathy", -0.3)
        GameManager.update_player_attribute("pressure", 0.4)
        dialogue_label.text += "\n\n对方似乎没有回应..."
    
    # 隐藏插话按钮，显示继续按钮
    interrupt_button1.visible = false
    interrupt_button2.visible = false
    continue_button.visible = true
    continue_button.text = "继续对话"
    
    update_all_displays()

func _on_interrupt_button_2_pressed():
    """深度插话"""
    var success_rate = GameManager.calculate_interrupt_success_rate("emotional")
    var success = randf() < success_rate
    
    print("深度插话，成功率：%.1f%%, 结果：%s" % [success_rate * 100, "成功" if success else "失败"])
    
    if success:
        GameManager.update_player_attribute("empathy", 1.5)
        GameManager.update_player_attribute("self_connection", 0.5)
        GameManager.update_player_attribute("pressure", -0.2)
        
        var npc = test_npcs[current_npc_index]
        dialogue_label.text += "\n\n" + npc.interrupt_responses[1]
    else:
        GameManager.update_player_attribute("empathy", -0.3)
        GameManager.update_player_attribute("self_connection", -0.5)
        GameManager.update_player_attribute("pressure", 0.4)
        dialogue_label.text += "\n\n对方看起来有些不舒服..."
    
    interrupt_button1.visible = false
    interrupt_button2.visible = false
    continue_button.visible = true
    continue_button.text = "继续对话"
    
    update_all_displays()

func _on_continue_dialogue_pressed():
    """继续对话"""
    if current_dialogue_index < test_npcs[current_npc_index].dialogues.size() - 1:
        current_dialogue_index += 1
        show_next_dialogue()
    else:
        # 行程结束
        var income = randi_range(40, 80)  # 随机收入
        var mood_score = randf_range(40.0, 80.0)  # 随机心情分数
        
        GameManager.complete_passenger_trip(income, mood_score)

# ============ HomeUI 事件处理 ============
func _on_browse_dreamweave_pressed():
    """浏览梦网"""
    print("浏览梦网")
    # 简单的梦网互动
    GameManager.update_player_attribute("pressure", -0.5)
    update_all_displays()

func _on_go_shopping_pressed():
    """去购物"""
    GameManager.change_state(GameManager.GameState.SHOP)

func _on_sleep_pressed():
    """睡觉，开始新一天"""
    if GameManager.should_game_end():
        show_ending()
    else:
        GameManager.start_new_day()

# ============ ShopUI 事件处理 ============
func _on_return_home_pressed():
    """返回家中"""
    GameManager.change_state(GameManager.GameState.HOME)

func show_ending():
    """显示结局"""
    var ending_type = GameManager.get_ending_type()
    var score = GameManager.calculate_final_score()
    
    print("游戏结束！")
    print("结局类型：", ending_type)
    print("最终分数：%.1f" % score)
    
    # 显示结局界面
    var ending_text = get_ending_text(ending_type)
    dialogue_label.text = ending_text
    
    # 切换到开始界面
    await get_tree().create_timer(3.0).timeout
    GameManager.change_state(GameManager.GameState.MENU)

func get_ending_text(ending_type: String) -> String:
    """获取结局文本"""
    match ending_type:
        "find_yourself":
            return "你找到了真正的自己，在城市的边缘中发现了内心的宁静。"
        "connect_others":
            return "你与乘客们建立了真挚的连接，找到了属于自己的选择性家庭。"
        "continue_searching":
            return "虽然还在路上，但你已经开始了寻找真实自我的旅程。"
        "need_rest":
            return "你需要休息和重新开始，但这也是觉醒的第一步。"
        _:
            return "谢谢你的陪伴，愿你在现实中也能找到内心的平静。"
