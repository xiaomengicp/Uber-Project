# FontManager.gd - 字体管理器 (Mac系统优化版)
# 放在 scripts/autoload/FontManager.gd，并添加到AutoLoad

extends Node

var default_font: FontFile
var ui_theme: Theme

func _ready():
    setup_fonts()
    create_ui_theme()

func setup_fonts():
    """设置字体支持中文"""
    default_font = FontFile.new()
    
    # Mac系统字体路径
    var mac_font_paths = [
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/Helvetica.ttc", 
        "/System/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/Menlo.ttc",
        "/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/Avenir.ttc"
    ]
    
    # Windows字体路径（备用）
    var windows_font_paths = [
        "C:/Windows/Fonts/msyh.ttc",  # 微软雅黑
        "C:/Windows/Fonts/simhei.ttf", # 黑体
        "C:/Windows/Fonts/simsun.ttc", # 宋体
    ]
    
    # Linux字体路径（备用）
    var linux_font_paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/TTF/DejaVuSans.ttf"
    ]
    
    # 合并所有路径
    var all_font_paths = mac_font_paths + windows_font_paths + linux_font_paths
    
    print("正在搜索字体...")
    
    for font_path in all_font_paths:
        print("尝试加载字体: ", font_path)
        if FileAccess.file_exists(font_path):
            var font_data = FileAccess.open(font_path, FileAccess.READ)
            if font_data:
                var buffer = font_data.get_buffer(font_data.get_length())
                font_data.close()
                
                if buffer.size() > 0:
                    default_font.data = buffer
                    print("✅ 成功加载字体: ", font_path)
                    return
                else:
                    print("❌ 字体文件为空: ", font_path)
            else:
                print("❌ 无法打开字体文件: ", font_path)
        else:
            print("❌ 字体文件不存在: ", font_path)
    
    # 如果所有字体都加载失败，尝试使用Godot内置字体
    print("⚠️  所有系统字体加载失败，尝试使用内置字体")
    try_builtin_font()

func try_builtin_font():
    """尝试使用Godot内置字体"""
    # 创建一个基础的FontFile，依赖Godot的默认字体渲染
    default_font = FontFile.new()
    
    # 或者可以尝试加载项目中的字体文件
    var project_font_paths = [
        "res://assets/fonts/NotoSansCJK-Regular.ttf",
        "res://assets/fonts/SourceHanSans.ttf",
        "res://assets/fonts/chinese_font.ttf"
    ]
    
    for font_path in project_font_paths:
        if ResourceLoader.exists(font_path):
            default_font = load(font_path) as FontFile
            if default_font:
                print("✅ 使用项目字体: ", font_path)
                return
    
    print("⚠️  使用Godot默认字体渲染")

func create_ui_theme():
    """创建UI主题"""
    ui_theme = Theme.new()
    
    # 即使没有自定义字体，也设置字体大小
    ui_theme.set_font_size("font_size", "Button", 16)
    ui_theme.set_font_size("font_size", "Label", 14)
    ui_theme.set_font_size("font_size", "RichTextLabel", 14)
    
    # 如果有加载到字体，则应用
    if default_font and (default_font.data.size() > 0 or default_font.get_font_name() != ""):
        ui_theme.set_font("font", "Button", default_font)
        ui_theme.set_font("font", "Label", default_font)
        ui_theme.set_font("font", "RichTextLabel", default_font)
        print("✅ 字体主题创建成功")
    else:
        print("⚠️  使用默认字体主题")

func apply_theme_to_node(node: Node):
    """将主题应用到节点"""
    if ui_theme and node is Control:
        node.theme = ui_theme
        
        # 递归应用到子节点
        for child in node.get_children():
            apply_theme_to_node(child)

# 添加一个检查函数用于调试
func debug_font_info():
    """输出字体调试信息"""
    print("=== 字体调试信息 ===")
    print("默认字体对象: ", default_font)
    if default_font:
        print("字体数据大小: ", default_font.data.size() if default_font.data else 0)
        print("字体名称: ", default_font.get_font_name() if default_font.has_method("get_font_name") else "未知")
    print("UI主题: ", ui_theme)
    print("===================")
