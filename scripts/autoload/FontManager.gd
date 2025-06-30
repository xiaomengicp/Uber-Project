# FontManager.gd - 修复版字体管理器
# 优先加载项目中的中文字体

extends Node

var default_font: FontFile
var ui_theme: Theme

func _ready():
    setup_fonts()
    create_ui_theme()

func setup_fonts():
    """设置字体支持中文"""
    default_font = FontFile.new()
    
    print("正在搜索中文字体...")
    
    # 首先尝试加载项目中的字体文件
    var project_font_paths = [
        "res://assets/fonts/chinese-font.ttf",
        "res://assets/fonts/chinese-font.otf", 
        "res://assets/fonts/chinese-font.ttc",
        "res://assets/fonts/SourceHanSans.ttc",
        "res://assets/fonts/NotoSansCJK-Regular.ttf",
        "res://assets/fonts/chinese_font.ttf",
        "res://assets/fonts/chinese_font.otf"
    ]
    
    # 使用ResourceLoader加载项目中的字体
    for font_path in project_font_paths:
        print("尝试加载项目字体: ", font_path)
        if ResourceLoader.exists(font_path):
            var loaded_font = ResourceLoader.load(font_path)
            if loaded_font is FontFile:
                default_font = loaded_font
                print("✅ 成功加载项目字体: ", font_path)
                return
            else:
                print("❌ 字体格式不正确: ", font_path)
        else:
            print("❌ 项目字体文件不存在: ", font_path)
    
    # 如果项目字体失败，尝试直接读取文件数据
    for font_path in project_font_paths:
        var file_path = font_path.replace("res://", "")
        print("尝试直接读取字体文件: ", file_path)
        if FileAccess.file_exists(file_path):
            var font_data = FileAccess.open(file_path, FileAccess.READ)
            if font_data:
                var buffer = font_data.get_buffer(font_data.get_length())
                font_data.close()
                
                if buffer.size() > 0:
                    default_font.data = buffer
                    print("✅ 成功直接加载字体文件: ", file_path)
                    return
                else:
                    print("❌ 字体文件为空: ", file_path)
            else:
                print("❌ 无法打开字体文件: ", file_path)
    
    # 最后尝试系统字体（但跳过不支持中文的）
    var system_chinese_fonts = [
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/Hiragino Sans GB.ttc",
        "/System/Library/Fonts/STHeiti Light.ttc",
        "/Library/Fonts/Microsoft/SimHei.ttf",
        "C:/Windows/Fonts/msyh.ttc",
        "C:/Windows/Fonts/simhei.ttf"
    ]
    
    for font_path in system_chinese_fonts:
        print("尝试加载系统中文字体: ", font_path)
        if FileAccess.file_exists(font_path):
            var font_data = FileAccess.open(font_path, FileAccess.READ)
            if font_data:
                var buffer = font_data.get_buffer(font_data.get_length())
                font_data.close()
                
                if buffer.size() > 0:
                    default_font.data = buffer
                    print("✅ 成功加载系统中文字体: ", font_path)
                    return
    
    print("⚠️  所有中文字体加载失败，使用默认字体")

func create_ui_theme():
    """创建UI主题"""
    ui_theme = Theme.new()
    
    # 设置字体大小
    ui_theme.set_font_size("font_size", "Button", 18)
    ui_theme.set_font_size("font_size", "Label", 16)
    ui_theme.set_font_size("font_size", "RichTextLabel", 16)
    
    # 如果成功加载了字体，就应用它
    if default_font and (default_font.data.size() > 0 or default_font != null):
        ui_theme.set_font("font", "Button", default_font)
        ui_theme.set_font("font", "Label", default_font)
        ui_theme.set_font("font", "RichTextLabel", default_font)
        print("✅ 字体主题创建成功，使用自定义字体")
    else:
        print("⚠️  使用默认字体主题")
    
    # 添加一些样式
    create_button_styles()

func create_button_styles():
    """创建按钮样式"""
    # 普通状态
    var normal_style = StyleBoxFlat.new()
    normal_style.bg_color = Color(0.2, 0.3, 0.4)
    normal_style.corner_radius_top_left = 4
    normal_style.corner_radius_top_right = 4
    normal_style.corner_radius_bottom_left = 4
    normal_style.corner_radius_bottom_right = 4
    normal_style.border_width_left = 1
    normal_style.border_width_right = 1
    normal_style.border_width_top = 1
    normal_style.border_width_bottom = 1
    normal_style.border_color = Color(0.4, 0.5, 0.6)
    
    # 悬停状态
    var hover_style = normal_style.duplicate()
    hover_style.bg_color = Color(0.3, 0.4, 0.5)
    
    # 按下状态
    var pressed_style = normal_style.duplicate()
    pressed_style.bg_color = Color(0.1, 0.2, 0.3)
    
    ui_theme.set_stylebox("normal", "Button", normal_style)
    ui_theme.set_stylebox("hover", "Button", hover_style)
    ui_theme.set_stylebox("pressed", "Button", pressed_style)

func apply_theme_to_node(node: Node):
    """将主题应用到节点"""
    if ui_theme and node is Control:
        node.theme = ui_theme
        print("应用字体主题到：", node.name)
        
        # 递归应用到子节点
        for child in node.get_children():
            apply_theme_to_node(child)

# 添加一个专门用于强制应用字体的函数
func force_apply_font_to_node(node: Control):
    """强制将字体应用到特定节点"""
    if not ui_theme or not default_font:
        return
        
    if node is RichTextLabel:
        # 对RichTextLabel特殊处理
        var rich_label = node as RichTextLabel
        rich_label.add_theme_font_override("normal_font", default_font)
        rich_label.add_theme_font_size_override("normal_font_size", 16)
        print("强制应用字体到RichTextLabel：", node.name)
    elif node is Label:
        # 对Label特殊处理
        var label = node as Label
        label.add_theme_font_override("font", default_font)
        label.add_theme_font_size_override("font_size", 16)
        print("强制应用字体到Label：", node.name)
    elif node is Button:
        # 对Button特殊处理
        var button = node as Button
        button.add_theme_font_override("font", default_font)
        button.add_theme_font_size_override("font_size", 18)
        print("强制应用字体到Button：", node.name)

func debug_font_paths():
    """调试：列出可能的字体文件"""
    print("=== 调试字体路径 ===")
    var paths_to_check = [
        "assets/fonts/",
        "res://assets/fonts/",
        "./assets/fonts/"
    ]
    
    for path in paths_to_check:
        print("检查路径: ", path)
        var dir = DirAccess.open(path)
        if dir:
            dir.list_dir_begin()
            var file_name = dir.get_next()
            while file_name != "":
                print("  发现文件: ", file_name)
                file_name = dir.get_next()
        else:
            print("  路径不存在")
    print("===================")
