#===============================================================================
# Title: Scene_Flasks
# Author: Revoked
# 
# This script adds a new menu where the player can view, equip, and remove any
# consumable flasks that have been earned in the game.
# 
#   - Scene is called from either Scene_Item or Scene_Shop (Flasks).
#   - Basic attributes are shown on the right side.
#   - Attributes augmented by passive abilities are drawn in green.
#
#===============================================================================
# ** Game_Flask
#===============================================================================
class Game_Flask
  
  attr_accessor :item
  attr_accessor :charges
  attr_accessor :max_charges
  
  def initialize(item,charges = nil)
    charges ||= item.max_charges
    @item = item
    @charges = charges
    @max_charges = item.max_charges
    @base_icon = @item.icon_index
  end
  def consume_charge
    @charges -= 1
  end
  def deplete
    @charges = 0
  end
  def refill(amount = @max_charges)
    @charges = [@charges+amount,@max_charges].min
  end
  def icon_index
    return @item.icon_index if @base_icon < 1000 #temp
    return @base_icon + 5 if empty?
    return @base_icon + ratio
  end
  def ratio
    return ((1 - @charges.to_f / @max_charges) * 5).to_i
  end
  def empty?
    return @charges == 0
  end
  def full?
    return @charges >= @max_charges
  end
  
end #Game_Flask

#==============================================================================
# ■ Game_BattlerBase
#==============================================================================
class Game_BattlerBase
  
  def item_conditions_met?(item)
    return usable_item_conditions_met?(item) if SceneManager.scene_is?(Scene_Battle) || SceneManager.scene_is?(Scene_Flasks)
    return usable_item_conditions_met?(item) && $game_party.has_item?(item)
  end
  
end # Game_BattlerBase

#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  
  def use_flask(flask,item)
    use_item(item)
    flask.consume_charge
  end
  
  def use_item(item)
    if item.is_a?(RPG::Skill) 
      pay_skill_cost(item) 
    end
    item.effects.each {|effect| item_global_effect_apply(effect) }
  end
  
end #Game_Battler

#==============================================================================
# ■ Game_Party
#==============================================================================
class Game_Party
  
  attr_reader :flasks
  attr_accessor :maximum_flasks
  attr_accessor :in_town
  
  def set_flask(slot,item)
    @flasks[slot] = item
  end
  alias rvkd_gp_init_all_items init_all_items
  def init_all_items
    rvkd_gp_init_all_items
    @in_town = true
    @maximum_flasks = 6
    @flasks = []#Array.new(@maximum_flasks)
    init_flasks
  end
  
  def init_flasks
    @flasks.push(Game_Flask.new($data_items[1]))
    @flasks.push(Game_Flask.new($data_items[1]))
    @flasks.push(Game_Flask.new($data_items[9]))
    @flasks.push(Game_Flask.new($data_items[5]))
  end
  
  def flasks_full?
    @flasks.compact.size >= @maximum_flasks
  end
  
  def equip_flask(item, index = nil, current_charges = 0)
    index ||= @flasks.size
    if @flasks[index].is_a?(Game_Flask)
      gain_item(@flasks[index].item,1)
    end
    consume_item(item)
    @flasks[index] = Game_Flask.new(item,current_charges)
  end
  
  def remove_flask(index)
    return unless @flasks[index]
    gain_item(@flasks[index].item,1)
    @flasks[index] = nil#.delete_at(index)
  end
  
  def shift_flasks
    @flasks.compact!
    @flask_charges.compact!
  end
  
  def has_flask?(item)
    @flasks.each {|flask| return true if flask.item.id == item.id}
    return false
  end
  
  def refill_cost
    @flasks.size * 40
  end
  
  def pay_refill_cost
    lose_gold(refill_cost)
  end
  
  def can_refill?
    return @in_town && @flasks.any? {|flask| flask && !flask.full?}
  end
  
end #Game_Party

#==============================================================================
# ■ RPG::Item
#==============================================================================
class RPG::Item < RPG::UsableItem
  
  attr_reader :max_charges
  
  alias rvkd_cca create_custom_attributes
  def create_custom_attributes
    rvkd_cca
    if self.id < 30
      @max_charges = 5
      @max_charges = $1.to_i if self.note =~ /<charges:[ ](.+)>/i
    end
  end
  
end #RPG::Item

#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  
  alias rvkd_scb_flask_on_item_ok on_item_ok
  def on_item_ok
    @flask = @item_window.flask
    rvkd_scb_flask_on_item_ok
  end
  
end #Scene_Battle

#==============================================================================
# ■ Window_BattleItem
#==============================================================================
class Window_BattleItem < Window_ItemList
  
  def item
    @data && index >= 0 ? @data[index].item : nil
  end
  def flask
    @data && index >= 0 ? @data[index] : nil
  end

  def make_item_list
    @data = $game_party.flasks
    @data.push(nil) if include?(nil)
  end
  
  def enable?(flask)
    return $game_party.usable?(flask.item) && flask.charges > 0
  end
  
  def draw_item(index)
    flask = @data[index]
    item = flask.item
    if item
      rect = item_rect(index)
      rect.width -= 4
      draw_item_name(item, rect.x, rect.y, enable?(flask))
      draw_flask_charges(rect, flask)
    end
  end
  def draw_flask_charges(rect, flask)
    return unless flask
    draw_text(rect, "#{flask.charges}/#{flask.max_charges}", 2)
  end
  
end #Window_BattleItem

#==============================================================================
# ■ Window_ItemList
#==============================================================================
class Window_ItemList < Window_Selectable
  
  def enable?(item)
    return $game_party.usable?(item) unless SceneManager.scene_is?(Scene_Item)
    return false
  end

end #Window_ItemList

#==============================================================================
# ■ Scene_Item
#==============================================================================
class Scene_Item < Scene_ItemBase
  
  alias rvkd_scene_item_flask_start start
  def start
    rvkd_scene_item_flask_start
    create_category_desc_windows
    @category_window.set_handler(:change, method(:update_category_desc_windows))
    update_category_desc_windows
  end
  
  def on_category_ok
    if @category_window.current_symbol == :item
      to_flask_menu
    else
      @item_window.activate
      @item_window.select_last
      hide_desc_windows
    end
  end

  def to_flask_menu
    SceneManager.call(Scene_Flasks)
  end
  
  def update_category_desc_windows
    case @category_window.index
    when 0
      @desc_flask_window.refresh
      @desc_flask_window.show
      @desc_weapon_window.hide
      @desc_armours_window.hide
    when 1
      @desc_weapon_window.refresh
      @desc_weapon_window.show
      @desc_flask_window.hide
      @desc_armours_window.hide
    when 2
      @desc_armours_window.refresh
      @desc_armours_window.show
      @desc_flask_window.hide
      @desc_weapon_window.hide
    else
      @desc_flask_window.hide
      @desc_weapon_window.hide
      @desc_armours_window.hide
    end
    @desc_header.set_header(@category_window.index)
  end
  
  def hide_desc_windows
    @desc_header.hide
    @desc_weapon_window.hide
    @desc_armours_window.hide
  end
  
  def create_category_desc_windows
    @desc_header = Window_DescHeader.new
    @desc_flask_window = Window_DescFlask.new
    @desc_weapon_window = Window_DescWeapon.new
    @desc_armours_window = Window_DescArmour.new
    @desc_flask_window.hide
    @desc_weapon_window.hide
    @desc_armours_window.hide
  end
  
end #Scene_Item

#==============================================================================
# ■ Scene_Flasks
#==============================================================================
class Scene_Flasks < Scene_Item
  
  def start
    create_main_viewport
    create_background
    @actor = $game_party.menu_actor
    create_actor_window
    create_help_window
    create_command_window
    create_slot_window
    create_item_window
    create_menu_status
    @help_window.opacity = 0
    @help_window.x = 9
    @help_window.y = 51
    update_category_help
    refresh_windows
  end
  
  def create_command_window
    @command_window = Window_FlaskCategory.new
    @command_window.opacity = 0
    @command_window.set_handler(:cancel, method(:return_scene))
    @command_window.set_handler(:change, method(:update_category_help))
    @command_window.set_handler(:equip, method(:command_equip_slots))
    @command_window.set_handler(:use, method(:command_use_item))
    @command_window.set_handler(:sort, method(:command_sort_flasks))
    @command_window.set_handler(:refill, method(:command_refill_flasks))
  end
  
  def create_slot_window
    @slot_window = Window_FlaskSlots.new(8,182, 199, 216)
    @slot_window.opacity = 0
    @slot_window.set_handler(:ok,     method(:on_slot_ok))
    @slot_window.set_handler(:cancel, method(:on_slot_cancel))
    @slot_window.set_handler(:change, method(:update_help))
    @slot_window.help_window = @help_window
  end
  
  def create_item_window
    @item_window = Window_FlaskInventory.new(215,182, 199, 216)
    @item_window.opacity = 0
    @item_window.set_handler(:ok,     method(:on_item_ok))
    @item_window.set_handler(:cancel, method(:on_item_cancel))
    @item_window.help_window = @help_window
    @description_window = Window_ItemDescription.new(nil)
    @description_window.viewport = @viewport
    @description_window.hide
  end
  
  def create_actor_window
    @actor_window = Window_ItemMenuActor.new
    @actor_window.set_handler(:ok,     method(:on_actor_ok))
    @actor_window.set_handler(:cancel, method(:on_actor_cancel))
  end
  #--------------------------------------------------------------------------
  # new method: create_menu_status
  #--------------------------------------------------------------------------
  def create_menu_status
    @menu_status = LunaMenu_Status.new(@viewport, :itemmenu)
    @menu_status.actor_window = @actor_window
    @menu_status.update
  end
  def status_window
    @actor_window
  end
  #--------------------------------------------------------------------------
  # alias method: update
  #--------------------------------------------------------------------------
  alias menu_luna_update update
  def update
    menu_luna_update
    @menu_status.update
  end
  
  #--------------------------------------------------------------------------
  # alias method: terminate
  #--------------------------------------------------------------------------
  alias menu_luna_terminate terminate
  def terminate
    menu_luna_terminate
    @menu_status.dispose
  end
  #------------------------ Luna
  def command_equip_slots
    @command_window.deactivate
    @description_window.window_item = @slot_window
    @description_window.show
    @slot_window.activate
    @slot_window.select(0)
    refresh_windows
  end
  
  def command_use_item
    @command_window.deactivate
    @description_window.window_item = @slot_window
    @description_window.show
    @slot_window.activate
    @slot_window.select(0)
    refresh_windows
  end
  
  def command_sort_flasks
    curr = $game_party.flasks.dup
    $game_party.flasks.compact!
    $game_party.flasks.sort_by! {|flask| flask.item.id}
    RPG::SE.new("AO - Card_Select", 80, 100).play if $game_party.flasks != curr
    refresh_windows
    @command_window.select(0)
    @command_window.activate
  end
  
  def command_refill_flasks
    $game_party.pay_refill_cost
    $game_party.flasks.each {|flask| flask.refill}
    RPG::SE.new("AO - Magic_Healbomb", 80, 130).play
    refresh_windows
    @command_window.select(0)
    @command_window.activate
  end
  
  def flask
    @slot_window.flask
  end
  
  def item
    if @slot_window.using_item
      return @slot_window.item rescue nil
    else
      return @item_window.item rescue nil
    end
  end
  
  def item_usable?
    flask && flask.charges > 0 && user.usable?(item) && item_effects_valid?
  end

  
  def on_slot_ok
    if @slot_window.using_item == true && item
      determine_item
      @description_window.no_refresh = true
      @actor_window.show
      @menu_status.update
      refresh_windows
    else
      @slot_window.deactivate
      @description_window.window_item = @item_window
      @item_window.light_items = true
      @item_window.show.activate
      @item_window.select(@item_window.last_index)
      refresh_windows
    end
  end
  
  def on_item_ok
    if @item_window.item
      $game_party.equip_flask(@item_window.item,@slot_window.index)
      @item_window.last_index = @item_window.index
    else
      $game_party.remove_flask(@slot_window.index)
      @item_window.last_index = 0
    end
    @item_window.light_items = false
    @item_window.unselect
    @item_window.deactivate
    @description_window.window_item = @slot_window
    @slot_window.activate
    refresh_windows
  end
  
  def on_actor_ok
    if item_usable?
      p(1)
      use_flask
    else
      Sound.play_buzzer
    end
  end
  
  def on_actor_cancel
    @actor_window.hide.deactivate
    @slot_window.activate
    @description_window.no_refresh = false
  end
  
  def on_slot_cancel
    refresh_windows
    @slot_window.unselect
    @slot_window.deactivate
    @description_window.hide
    @command_window.activate
  end
  
  def on_item_cancel
    @item_window.light_items = false
    @item_window.unselect
    refresh_windows
    @item_window.deactivate
    @description_window.window_item = @slot_window
    @slot_window.activate
  end
    
  def refresh_windows
    @item_window.refresh
    @slot_window.refresh
    @command_window.refresh
    @description_window.refresh
  end

  def play_se_for_item
    Sound.play_use_item
  end
  
  def use_flask
    play_se_for_item
    user.use_flask(flask,item)
    use_item_to_actors
    check_common_event
    check_gameover
    @actor_window.refresh
    refresh_windows
  end
  
  def update_help
    @slot_window.update_help
  end
  
  def update_category_help
    return unless @command_window
    @slot_window.using_item = (@command_window.current_symbol == :use)
    @slot_window.refresh if @command_window.current_symbol == :use
    @help_window.set_text(category_text(@command_window.current_symbol))
  end
  
  def category_text(category)
    case category
    when :none; return ""
    when :use; return ('\i[223] ' + '\c[1]' + "Use" + '\c[0]' + 
                    "\n" + "Consume charges from currently equipped flasks.")
    when :equip; return ('\i[202] ' + '\c[1]' + "Equip" + '\c[0]' + 
                    "\n" + "Outfit equipped flasks. Flasks lose all charges when removed.")
    when :sort; return ('\i[203] ' + '\c[1]' + "Sort" + '\c[0]' + 
                    "\n" + "Rearrange equipped flasks.")
    when :refill; return ('\i[187] ' + '\c[1]' + "Refill" + '\c[0]' + 
                    "\n" + "Refill currently equipped flasks. Unavailable outside of designated refill areas.")
    end
    return ""
  end
  
end #Scene_Flasks

#==============================================================================
# ■ Window_FlaskCategory
#==============================================================================
class Window_FlaskCategory < Window_HorzCommand
  def initialize
    super(8, 126)
  end
  def window_width ; 406 end
  def col_max ; 4 end
  def spacing ; 2 end
    
  def make_command_list
    add_command("Use",    :use)
    add_command("Equip",  :equip)
    add_command("Sort",   :sort)
    add_command("Refill", :refill, $game_party.can_refill?)
  end
end #Window_FlaskCategory

#==============================================================================
# ■ Window_FlaskSlots
#==============================================================================
class Window_FlaskSlots < Window_Selectable
  
  attr_accessor :using_item
  
  def initialize(x, y, width, height)
    super(x,y, width, height)
    @index = 0
    @data = []
    @using_item = false
  end  
  
  def item_max ; $game_party.maximum_flasks end
  def standard_padding ; 12 end
    
  def col_max ; 1 end
  def row_max ; item_max end
  def spacing ; 0 end
    
  def line_height
    return [24, (24*8)/[$game_party.maximum_flasks,1].max].max
  end
  
  def item
    return @data[index].item if @data && index >= 0 && @data[index]
    return nil
  end
  
  def flask
    @data && index >= 0 ? @data[index] : nil
  end
  
  def ok_enabled?
    return item && flask.charges > 0 if @using_item
    return true
  end
  
  def enable?(flask)
    return flask.charges > 0 && $game_party.usable?(flask.item) if @using_item
    return true
  end
  
  def process_handling
    return unless open? && active
    return process_ok       if Input.trigger?(:C)
    return process_cancel   if Input.trigger?(:B)
  end

  def process_ok
    if ok_enabled?
      Sound.play_ok
      Input.update
      deactivate
      call_ok_handler
    else
      Sound.play_buzzer
    end
  end
  
  def make_item_list
    @data = $game_party.flasks
  end
  
  def draw_item(index)
    if @data[index]
      flask = @data[index]
      item = flask.item 
    end
    if item
      rect = item_rect(index)
      rect.width -= 4
      draw_flask_name(flask, rect.x, rect.y, enable?(flask))
      draw_flask_charges(rect, flask)
    else
      rect = item_rect(index)
      rect.width -= 4
      draw_item_name($data_items[30], rect.x, rect.y, false)
      draw_flask_charges(rect, flask)
    end
  end
  
  def draw_flask_charges(rect, flask)
    return unless flask
    draw_text(rect, "#{flask.charges}/#{flask.max_charges}", 2)
  end
  
  def update_help
    @help_window.set_item(item) if flask && item
  end
  
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end
  
  def draw_flask_name(flask, x, y, enabled = true, width = 172)
    return unless flask
    draw_icon(flask.icon_index, x, y+(line_height - 24)/2, enabled)
    change_color(normal_color, enabled)
    draw_text(x + 28, y, width, line_height, flask.item.name)
  end
  
end #Window_FlaskSlots

#==============================================================================
# ■ Window_FlaskInventory
#==============================================================================
class Window_FlaskInventory < Window_Selectable
  
  attr_accessor :last_index
  attr_accessor :light_items
  
  def initialize(x, y, width, height)
    super(x,y, width, height)
    @index = 0
    @last_index = 0
    @data = []
    @light_items = false
  end
  
  
  def process_handling
    return unless open? && active
    return process_ok       if ok_enabled?        && Input.trigger?(:C)
    return process_cancel   if cancel_enabled?    && Input.trigger?(:B)
  end  
  
  def item_max
    @data ? @data.size : 1
  end
  def item
    @data && index >= 0 ? @data[index] : nil
  end
    
  def include?(item)
    return item.id < 30 rescue true
  end
  
  def enable?(item)
    return false if $game_party.flasks_full? 
    return true if @light_items == true
    return false
  end
  
  def make_item_list
    @data = $game_party.items.select {|item| include?(item) }
    @data.push(nil) if include?(nil)
  end
  
  def draw_item(index)
    item = @data[index]
    if item
      rect = item_rect(index)
      rect.width -= 4
      draw_item_name(item, rect.x, rect.y, enable?(item))
      draw_item_number(rect, item)
    end
  end
  
  def draw_item_number(rect, item)
    draw_text(rect, sprintf(":%2d", $game_party.item_number(item)), 2)
  end
  
  def update_help
    @help_window.set_item(item)
  end
  
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end
  
end #Window_FlaskInventory

#==============================================================================
# ■ Window_DescFlask
#==============================================================================
class Window_DescFlask < Window_Selectable
  
  def initialize(x = 422,y = 154,width = 210,height = 240)
    super(x,y,width,height)
    self.opacity = 0
    @data = []
    refresh
  end
  
  def item_max ; $game_party.maximum_flasks end
  def standard_padding ; 12 end
    
  def col_max ; 1 end
  def row_max ; item_max end
  def spacing ; 0 end
    
  def include?(item); true end
  def enable?(item); true end
    
  def line_height
    return [27, (27*8)/[$game_party.maximum_flasks,1].max].max
  end
    
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end
  
  def make_item_list
    @data = $game_party.flasks
  end
  
  def draw_item(index)
    if @data[index]
      flask = @data[index]
      item = flask.item 
    end
    if item
      rect = item_rect(index)
      rect.width -= 4
      draw_flask_name(flask, rect.x, rect.y, enable?(flask))
      draw_flask_charges(rect, flask)
    else
      rect = item_rect(index)
      rect.width -= 4
      draw_item_name($data_items[30], rect.x, rect.y, false)
      draw_flask_charges(rect, flask)
    end
  end
  
  def draw_flask_name(flask, x, y, enabled = true, width = 172)
    return unless flask
    draw_icon(flask.icon_index, x, y+(line_height - 24)/2, enabled)
    change_color(normal_color, enabled)
    draw_text(x + 28, y, width, line_height, flask.item.name)
  end
  
  def draw_flask_charges(rect, flask)
    return unless flask
    draw_text(rect, "#{flask.charges}/#{flask.max_charges}", 2)
  end
  
end #Window_DescFlask
  
#==============================================================================
# ■ Window_DescWeapon
#==============================================================================
class Window_DescWeapon < Window_Selectable
  
  def initialize(x = 422,y = 156,width = 210,height = 236)
    super(x,y,width,height)
    self.opacity = 0
    @data = []
    refresh
  end
  
  def item_max ; $game_party.members.size end
  def standard_padding ; 12 end
    
  def col_max ; 1 end
  def row_max ; item_max end
  def spacing ; 0 end
    
  def include?(item); true end
  def enable?(item); true end
    
  def line_height
    return 24#[24, (216)/[$game_party.members.size,1].max].max
  end
  
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end
  
  def make_item_list
    @data = $game_party.members.collect {|actor| actor.weapons[0]}
  end
  
  def draw_item(index)
    item = @data[index]
    if item
      rect = item_rect(index)
      rect.width -= 4
      draw_icon(223 + $game_party.members[index].id, rect.x, rect.y, true)
      draw_item_name(item, rect.x + 28, rect.y, enable?(item))
    end
  end
  
  def draw_item_name(item, x, y, enabled = true, width = 172)
    return unless item
    draw_icon(item.icon_index, x, y, enabled)
    change_color(normal_color, enabled)
    draw_text(x + 28, y, width, 24, item.name)
  end
  
end #Window_DescWeapon

#==============================================================================
# ■ Window_DescArmour
#==============================================================================
class Window_DescArmour < Window_Selectable
  
  def initialize(x = 422,y = 156,width = 210,height = 236)
    super(x,y,width,height)
    self.opacity = 0
    @data = []
    refresh
  end
  
  def item_max ; $game_party.members.size end
  def standard_padding ; 12 end
    
  def col_max ; 1 end
  def row_max ; item_max end
  def spacing ; 0 end
    
  def include?(item); true end
  def enable?(item); true end
    
  def line_height
    return 24#[24, (216)/[$game_party.members.size,1].max].max
  end
  
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end
  
  def make_item_list
    @data = $game_party.members.collect {|actor| actor.equips}
  end
  
  def draw_item(index)
    items = @data[index]
    if items
      rect = item_rect(index)
      rect.width -= 4
      draw_icon(223 + $game_party.members[index].id, rect.x, rect.y, true)
      for i in 1..items.size
        draw_icon(items[i].icon_index, rect.x+4+24*i, rect.y, true) if items[i]
      end
    end
  end
  
  def draw_item_name(item, x, y, enabled = true, width = 172)
    return unless item
    draw_icon(item.icon_index, x, y, enabled)
    change_color(normal_color, enabled)
    draw_text(x + 28, y, width, 24, item.name)
  end
  
end #Window_DescArmour

#==============================================================================
# ■ Window_DescHeader
#==============================================================================
class Window_DescHeader < Window_Base
  def initialize(x = 426,y = 122,width = 210,height = 48)
    super(x,y,width,height)
    self.opacity = 0
    set_header
  end
  
  def set_header(index = 0)
    show unless self.visible
    contents.clear
    change_color(Color.new(255, 120, 76, 255))
    text = "\eC[2]"
    case index
    when 0
      text += "Equipped Flasks"
    when 1
      text += "Equipped Weapons"
    when 2
      text += "Equipped Armour"
    end
    draw_text_ex(0,0,text)
  end
  
end #Window_DescHeader
#==============================================================================
# 
# ▼ End of File
# 
#==============================================================================