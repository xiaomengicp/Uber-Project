# scripts/ui/UIBase.gd
# 简单版本 - 只负责基础UI切换功能
class_name UIBase
extends Node

# 信号定义
signal ui_switched(ui_name: String)

# UI节点引用
var ui_container: Control
var ui_nodes: Dictionary = {}
var current_ui: Control

func initialize_ui_nodes(main_scene: Control) -> bool:
    """初始化UI节点引用"""
    print("🔧 UIBase: 初始化UI节点...")
    
    ui_container = main_scene.get_node("UIContainer")
    if ui_container == null:
        print("❌ UIBase: 无法找到UIContainer")
        return false
    
    # 获取所有UI节点
    var start_ui = ui_container.get_node("StartUI")
    var area_selection_ui = ui_container.get_node("AreaSelectionUI")
    var driving_ui = ui_container.get_node("DrivingUI")
    var home_ui = ui_container.get_node("HomeUI")
    var shop_ui = ui_container.get_node("ShopUI")
    
    # 检查节点是否存在
    if start_ui == null or area_selection_ui == null or driving_ui == null or home_ui == null or shop_ui == null:
        print("❌ UIBase: 某些UI节点不存在")
        return false
    
    # 存储UI节点映射
    ui_nodes = {
        "start": start_ui,
        "area_selection": area_selection_ui,
        "driving": driving_ui,
        "home": home_ui,
        "shop": shop_ui
    }
    
    print("✅ UIBase: UI节点初始化完成")
    return true

func switch_to_ui(ui_name: String):
    """切换到指定UI"""
    print("🔄 UIBase: 切换到UI - ", ui_name)
    
    if ui_name not in ui_nodes:
        print("❌ UIBase: 未知的UI名称：", ui_name)
        return
    
    var target_ui = ui_nodes[ui_name]
    if target_ui == null:
        print("❌ UIBase: UI节点不存在：", ui_name)
        return
    
    # 隐藏所有UI
    hide_all_ui()
    
    # 显示目标UI
    target_ui.visible = true
    current_ui = target_ui
    
    print("✅ UIBase: 切换到UI成功：", ui_name)
    ui_switched.emit(ui_name)

func hide_all_ui():
    """隐藏所有UI"""
    for ui_name in ui_nodes:
        var ui = ui_nodes[ui_name]
        if ui != null:
            ui.visible = false

func get_ui_node(ui_name: String) -> Control:
    """获取UI节点"""
    return ui_nodes.get(ui_name, null)

func get_current_ui() -> Control:
    """获取当前显示的UI"""
    return current_ui
