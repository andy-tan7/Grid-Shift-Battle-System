#===============================================================================
# Title: Scene_Passive
# Author: Revoked
# 
# This script adds a new menu where the player can view, assign, and remove any
# passive abilities the characters have earned in the game.
# 
#   - Scene is called from either Scene_ToGTitles or Scene_Skill (Passive).
#   - Basic attributes are shown on the right side.
#   - Attributes augmented by passive abilities are drawn in green.
#
#===============================================================================
# ** 
#===============================================================================
module REGEXP
  STONES = /<(?:STONES|stone):[ ](.*)>/i
end
#==============================================================================
# ■ Scene_Skill
#==============================================================================
class Scene_Skill < Scene_ItemBase
  #--------------------------------------------------------------------------
  # alias method: start
  #--------------------------------------------------------------------------
#~   alias rvkd_scs_start start
#~   def start(passive = false)
#~     rvkd_scs_start
#~   end
  
  alias rvkd_scs_create_command_window_passive create_command_window
  def create_command_window
    rvkd_scs_create_command_window_passive
    @command_window.select(2) if $closed_passive
    $closed_passive = false
  end
  #--------------------------------------------------------------------------
  # alias method: command_skill
  #--------------------------------------------------------------------------
  alias rvkd_normal_command_skill command_skill
  def command_skill
    if @command_window.current_data[:name] == "Passive"
      SceneManager.call(Scene_Passive)
    else
      rvkd_normal_command_skill
    end
  end
  
end #Scene_Skill

#==============================================================================
# ■ Game_BattlerBase
#==============================================================================
class Game_BattlerBase
  def skill_orb_cost(skill)
    return skill.orb_cost if skill.orb_cost
    cost = 5
    skill.note.split(/[\r\n]+/).each do |line|
      cost = $1.to_i if line =~ REGEXP::STONES
    end
    skill.orb_cost = cost
    return cost
  end
end #Game_BattlerBase

#==============================================================================
# ■ Game_Actor
#==============================================================================
class Game_Actor < Game_Battler
  attr_accessor :equipped_passives
  #--------------------------------------------------------------------------
  # alias method: start
  #--------------------------------------------------------------------------
  alias rvkd_ga_passive_setup setup
  def setup(actor_id)
    rvkd_ga_passive_setup(actor_id)
    @equipped_passives = []
  end
  
  #--------------------------------------------------------------------------
  # new method: total_orb_level
  #--------------------------------------------------------------------------
  def total_orb_level
    total_level = 0
    self.actor_titles.each do |title|
      total_level += [5,self.title_rank[title]].min
    end
    total_level
  end
  
  #--------------------------------------------------------------------------
  # new method: available_orbs
  #--------------------------------------------------------------------------  
  def available_orbs
    spent_orbs = 0
    return total_orb_level if @equipped_passives.empty?
    @equipped_passives.each do |skill|
      spent_orbs += self.skill_orb_cost(skill)
    end
    return total_orb_level - spent_orbs
  end
  
  #--------------------------------------------------------------------------
  # new method: allocate_passive
  #--------------------------------------------------------------------------
  def allocate_passive(skill)
    @equipped_passives.push(skill)
    if skill.passive_features
      skill.passive_features.each {|fx| $data_actors[self.id].add_feature(*fx)}
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: unequip_passive
  #--------------------------------------------------------------------------
  def unequip_passive(skill)
    @equipped_passives.delete(skill)
    if skill.passive_features
      skill.passive_features.each {|fx| $data_actors[self.id].remove_feature(*fx)}
      @hp = [@hp,mhp].min
      @mp = [@mp,mmp].min
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: passives_exist?
  #--------------------------------------------------------------------------
  def passives_exist?
    (skills+sorted_passives).each do |skill|
      return true if skill.stype_id == 3
    end
    return false
  end
  
  #--------------------------------------------------------------------------
  # new method: passive_boosted_stats
  #--------------------------------------------------------------------------
  def passive_boosted_stats
    boosted = []
    @equipped_passives.each do |passive|
      boosted.push(0)  if passive.name.include?("Max HP")
      boosted.push(1)  if passive.name.include?("Max MP")
      boosted.push(2)  if passive.name.include?("Attack +")
      boosted.push(3)  if passive.name.include?("Defense +")
      boosted.push(4)  if passive.name.include?("Strength +")
      boosted.push(5)  if passive.name.include?("Magic +")
      boosted.push(6)  if passive.name.include?("Agility +")
      boosted.push(7)  if passive.name.include?("Spirit +")
      boosted.push(10) if passive.name.include?("Accuracy +")
      boosted.push(11) if passive.name.include?("Evasion +")
      boosted.push(12) if passive.name.include?("Critical +")
    end
    return boosted
  end
  
end #Game_Actor

#==============================================================================
# ■ Scene_Passive
#==============================================================================
class Scene_Passive < Scene_ItemBase
  
  #--------------------------------------------------------------------------
  # overwrite method: start
  #--------------------------------------------------------------------------
  def start
    super
    create_help_window
    @help_window.x = 9
    @help_window.y = 51
    @help_window.opacity = 0
    create_command_window
    create_item_window
    create_equipped_window
    create_actor_window
    create_status_window
    refresh_windows
    up_help
  end
  
  #--------------------------------------------------------------------------
  # alias method: terminate
  #--------------------------------------------------------------------------
  alias rvkd_smb_terminate terminate
  def terminate
    $closed_passive = true
    rvkd_smb_terminate
  end
  
  #--------------------------------------------------------------------------
  # overwrite method: create_command_window
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_PassiveCommand.new(@help_window, @actor)
    @command_window.set_handler(:cancel, method(:return_scene))
    @command_window.set_handler(:equip, method(:equip_passives))
    @command_window.set_handler(:remove, method(:remove_passives))
    @command_window.set_handler(:pagedown, method(:next_actor))
    @command_window.set_handler(:pageup,   method(:prev_actor))
    @command_window.set_handler(:change,   method(:up_help))
  end
  
  #--------------------------------------------------------------------------
  # overwrite method: create_item_window
  #--------------------------------------------------------------------------
  def create_item_window
    @item_window = Window_PassiveList.new(8, 182, 229, 216)
    @item_window.opacity = 0
    @item_window.actor = @actor
    @item_window.viewport = @viewport
    @item_window.help_window = @help_window
    @item_window.set_handler(:ok,     method(:on_item_ok))
    @item_window.set_handler(:cancel, method(:on_item_cancel))
    @item_window.set_handler(:right,  method(:switch_to_equipped))
  end
  
  #--------------------------------------------------------------------------
  # overwrite method: create_status_window
  #--------------------------------------------------------------------------
  def create_status_window
    @status_window = Window_EquipStatus.new(482, 126)
    @status_window.x = 480
    @status_window.y = 102
    @status_window.viewport = @viewport
    @status_window.actor = @actor
  end
      
  #--------------------------------------------------------------------------
  # overwrite method: create_actor_window
  #--------------------------------------------------------------------------
  def create_actor_window
    @actor_window = Window_ActorFace.new(245,126)
    @actor_window.viewport = @viewport
    @actor_window.actor = @actor
    @actor_window.opacity = 0
  end
  
  #--------------------------------------------------------------------------
  # new method: create_equipped_window
  #--------------------------------------------------------------------------
  def create_equipped_window
    @equipped_window = Window_EquippedList.new(245, 182, 229, 216)
    @equipped_window.opacity = 0
    @equipped_window.actor = @actor
    @equipped_window.viewport = @viewport
    @equipped_window.help_window = @help_window
    @equipped_window.set_handler(:ok,     method(:on_equipped_ok))
    @equipped_window.set_handler(:cancel, method(:on_item_cancel))
    @equipped_window.set_handler(:left,  method(:switch_to_item))
  end

  
  #--------------------------------------------------------------------------
  # new method: equip_passives
  #--------------------------------------------------------------------------
  def equip_passives
    @item_window.activate
    @item_window.select_last
  end
  
  #--------------------------------------------------------------------------
  # new method: remove_passives
  #--------------------------------------------------------------------------
  def remove_passives
    @equipped_window.activate
    @equipped_window.select_last
  end
  
  #--------------------------------------------------------------------------
  # overwrite method: on_item_ok
  #--------------------------------------------------------------------------
  def on_item_ok
    @actor.last_skill.object = item
    @actor.allocate_passive(item)
    @actor.equipped_passives.sort! {|a,b| a.id <=> b.id}
    refresh_windows
    activate_item_window
  end
  
  #--------------------------------------------------------------------------
  # overwrite method: on_item_cancel
  #--------------------------------------------------------------------------
  def on_item_cancel
    @item_window.unselect
    @equipped_window.unselect
    @command_window.activate
  end
  
  #--------------------------------------------------------------------------
  # overwrite method: on_actor_change
  #--------------------------------------------------------------------------
  def on_actor_change
    @command_window.actor = @actor
    @item_window.actor = @actor
    @equipped_window.actor = @actor
    @actor_window.actor = @actor
    @status_window.actor = @actor
    @status_window.scene_passive_refresh
    @command_window.activate
  end
  
  #--------------------------------------------------------------------------
  # new method: on_equipped_ok
  #--------------------------------------------------------------------------
  def on_equipped_ok
    on_item_cancel if @equipped_window.item.nil?
    @actor.last_skill.object = @equipped_window.item
    @actor.unequip_passive(@equipped_window.item)
    refresh_windows
    if @actor.equipped_passives.empty?
      on_item_cancel
      Sound.play_cancel
    else
      if @equipped_window.item_max <= @equipped_window.index
        @equipped_window.index -= 1
      end
      @equipped_window.activate
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: up_help
  #--------------------------------------------------------------------------
  def up_help
    case @command_window.index
    when 0; @help_window.set_text('\i[206] ' + '\c[1]' + "Assign" + '\c[0]' + 
                                  "\n" + "Equip Passive abilities with Title Orbs.")
    when 1; @help_window.set_text('\i[207] ' + '\c[1]' + "Remove" + '\c[0]' + 
                                  "\n" + "Remove assigned Passive abilities.")
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: refresh_windows
  #--------------------------------------------------------------------------
  def refresh_windows
    @item_window.refresh
    @equipped_window.refresh
    @status_window.scene_passive_refresh
    @actor_window.refresh
    @command_window.refresh
  end
  
  #--------------------------------------------------------------------------
  # new method: switch_to_equipped
  #--------------------------------------------------------------------------
  def switch_to_equipped
    @item_window.unselect
    @item_window.deactivate
    @command_window.select(1)
    remove_passives
    refresh_windows
  end
  
  #--------------------------------------------------------------------------
  # new method: switch_to_item
  #--------------------------------------------------------------------------
  def switch_to_item
    @equipped_window.unselect
    @equipped_window.deactivate
    @command_window.select(0)
    equip_passives
    refresh_windows
  end
  
end #Scene_Passive

#==============================================================================
# ■ Window_EquipStatus
#==============================================================================
class Window_EquipStatus < Window_Base
  
  #--------------------------------------------------------------------------
  # new method: scene_passive_refresh
  #--------------------------------------------------------------------------
  def scene_passive_refresh(param = nil)
    contents.clear
    boosted = @actor.passive_boosted_stats
    8.times do |i| 
      boosted.include?(i) ? change_color(text_color(24)) : change_color(normal_color)
      draw_passive_item(0, (line_height-1) * (1 + i), 0 + i)
    end
    3.times do |i|
      boosted.include?(10+i) ? change_color(text_color(24)) : change_color(normal_color)
      draw_passive_item_ex(0, (line_height-1)*(9+i), i)
    end
  end
  
  #--------------------------------------------------------------------------
  # * Draw Item
  #--------------------------------------------------------------------------
  def draw_passive_item(x, y, param_id)
    draw_passive_param_name(x + 4, y, param_id)
    draw_passive_current_param(x + 94, y, param_id) if @actor
  end
  
  def draw_passive_item_ex(x, y, param_id)
    draw_passive_xparam_name(x + 4, y, param_id) 
    draw_passive_current_xparam(x + 94, y, param_id) if @actor
  end
  
  #--------------------------------------------------------------------------
  # * Draw Parameter Name
  #--------------------------------------------------------------------------
  def draw_passive_param_name(x, y, param_id)
    draw_text(x, y, 80, line_height, Vocab::param(param_id))
  end
  
  def draw_passive_xparam_name(x, y, param_id)
    draw_text(x, y, 80, line_height, Vocab.xparam(param_id)) 
  end
  
  #--------------------------------------------------------------------------
  # * Draw Current Parameter
  #--------------------------------------------------------------------------
  def draw_passive_current_param(x, y, param_id)
    draw_text(x, y, 32, line_height, @actor.param(param_id), 2)
  end
  
  def draw_passive_current_xparam(x, y, param_id)
    text = !XPARAM_DISPLAY_MULT ? sprintf("%0.2f", @actor.xparam(param_id)) : "#{(@actor.xparam(param_id) * 100).to_i}"
    draw_text(x, y, 32, line_height, text, 2)
  end
  
end #Window_EquipStatus

#==============================================================================
# ■ Window_ActorFace
#==============================================================================
class Window_ActorFace < Window_Base
  
  #--------------------------------------------------------------------------
  # overwrite method: initialize
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(x, y, 229, 48)
    @actor = nil
  end
  
  def actor=(actor)
    return if @actor == actor
    @actor = actor
    refresh
  end
  
  #--------------------------------------------------------------------------
  # overwrite method: refresh
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    return unless @actor
    draw_actor_face_small(@actor, 4, 0)
    draw_text(@actor.name, 60, 12, 120, 24, 0)
    draw_icon(Bubs::ToGTitleSystem::RANK_ACTIVE_ICON, 132, 12)
    min = @actor.available_orbs
    max = @actor.total_orb_level
    change_color(text_color(14)) if min <= 0 && min != max
    draw_text(min, 96, 12, 80, 24, 2)
    change_color(text_color(0))
    draw_text("/", 176, 12, 16, 24, 1)
    draw_text(max, 192, 12, 80, 24, 0)
  end
  
  def draw_actor_face_small(actor, x, y, enabled = true)
    draw_face(actor.face_name+"sm", actor.face_index, x, y, enabled)
  end
  
  def standard_padding ; 0 end
  
  def draw_text(text, x, y, text_width, text_height, alignment = 0)
    contents.draw_text(x, y, text_width, text_height, text, alignment)
  end
  
end #Window_ActorFace

#==============================================================================
# ■ Window_PassiveCommand
#==============================================================================
class Window_PassiveCommand < Window_Command
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(help_window, actor)
    @help_window = help_window
    @actor = actor
    super(8, 126)
    self.width = 229
    self.height = 48
    self.opacity = 0
    clear_command_list
    make_command_list
    refresh
    select(0)
    activate
    open
  end
  
  def col_max ; 2 end
  def spacing ; 16 end
  def alignment ; 1 end
    
  def make_command_list
    add_command("Assign",  :equip,  @actor.passives_exist?)
    add_command("Remove", :remove, !@actor.equipped_passives.empty?)
  end
  
  def actor=(actor)
    return if @actor == actor
    @actor = actor
    refresh
    select_last
  end
  
  def select_last
    skill = @actor.last_skill.object
    if skill
      select_ext(skill.stype_id)
    else
      select(0)
    end
  end
  
end #Window_PassiveCommand

#==============================================================================
# ■ Window_SkillList
#==============================================================================
class Window_SkillList < Window_Selectable
  
  attr_reader :actor
  #--------------------------------------------------------------------------
  # overwrite method: make_item_list (show only equipped passives in menu)
  #--------------------------------------------------------------------------
  def make_item_list
    if @stype_id == 3
      @data = @actor ? @actor.equipped_passives : []
    else
      @data = @actor ? @actor.skills.select {|skill| include?(skill) } : []
    end
  end
end #Window_SkillList

#==============================================================================
# ■ Window_PassiveList
#==============================================================================
class Window_PassiveList < Window_Selectable
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super
    @actor = nil
    @stype_id = 3
    @data = []
  end
  
  def col_max ; 1 end
  
  def process_handling
    return unless open? && active
    return process_ok       if ok_enabled?        && Input.trigger?(:C)
    return process_cancel   if cancel_enabled?    && Input.trigger?(:B)
    return process_right if handle?(:pagedown) && Input.trigger?(:R)
    return process_right if Input.trigger?(:RIGHT)
  end
    
  def process_right
    if !@actor.equipped_passives.empty?
      Sound.play_cursor
      Input.update
      deactivate
      call_handler(:right)
    end
  end
  
  #--------------------------------------------------------------------------
  # * Set Actor
  #--------------------------------------------------------------------------
  def actor=(actor)
    return if @actor == actor
    @actor = actor
    refresh
    self.oy = 0
  end
  #--------------------------------------------------------------------------
  # * Get Number of Items
  #--------------------------------------------------------------------------
  def item_max
    @data ? @data.size : 1
  end
  #--------------------------------------------------------------------------
  # * Get Skill
  #--------------------------------------------------------------------------
  def item
    @data && index >= 0 ? @data[index] : nil
  end
  #--------------------------------------------------------------------------
  # * Get Activation State of Selection Item
  #--------------------------------------------------------------------------
  def current_item_enabled?
    enable?(@data[index])
  end
  #--------------------------------------------------------------------------
  # * Include in Skill List? 
  #--------------------------------------------------------------------------
  def include?(item)
    item && item.stype_id == @stype_id
  end
  #--------------------------------------------------------------------------
  # * Display in Enabled State?
  #--------------------------------------------------------------------------
  def enable?(item)
    return false if @actor.equipped_passives.include?(item)
    return @actor.skill_orb_cost(item) <= @actor.available_orbs
  end
  #--------------------------------------------------------------------------
  # * Create Skill List
  #--------------------------------------------------------------------------
  def make_item_list
    @data = @actor ? @actor.skills.select {|skill| include?(skill) } : []
    @data += @actor.passive_skills
  end
  #--------------------------------------------------------------------------
  # * Restore Previous Selection Position
  #--------------------------------------------------------------------------
  def select_last
    select(@data.index(@actor.last_skill.object) || 0)
  end
  #--------------------------------------------------------------------------
  # * Draw Item
  #--------------------------------------------------------------------------
  def draw_item(index)
    skill = @data[index]
    if skill
      rect = item_rect(index)
      rect.width -= 4
      draw_item_name(skill, rect.x, rect.y, enable?(skill))
      draw_skill_cost(rect, skill)
    end
  end
  
  def draw_skill_cost(rect, skill)
    draw_text(rect, @actor.skill_orb_cost(skill), 2)
  end

  def update_help
    @help_window.set_item(item)
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end

end #Window_PassiveList

#==============================================================================
# ■ Window_EquippedList
#==============================================================================
class Window_EquippedList < Window_Selectable
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super
    @actor = nil
    @stype_id = 3
    @data = []
  end
  
  def process_handling
    return unless open? && active
    return process_ok       if ok_enabled?        && Input.trigger?(:C)
    return process_cancel   if cancel_enabled?    && Input.trigger?(:B)
    return process_left   if handle?(:pageup)   && Input.trigger?(:L)
    return process_left   if Input.trigger?(:LEFT)
  end
  
  def process_left
    if @actor.passives_exist?
      Sound.play_cursor
      Input.update
      deactivate
      call_handler(:left)
    end
  end
  
  def col_max ; 1 end
  
  def actor=(actor)
    return if @actor == actor
    @actor = actor
    refresh
    self.oy = 0
  end
  
  def item_max
    @data ? @data.size : 1
  end
  
  def item
    @data && index >= 0 ? @data[index] : nil
  end

  def current_item_enabled?
    enable?(@data[index])
  end

  def include?(item)
    item && item.stype_id == @stype_id
  end

  def enable?(item)
    return true
  end

  def make_item_list
    @data = @actor ? @actor.equipped_passives.select {|skill| include?(skill) } : []
  end

  def select_last
    select(@data.index(@actor.last_skill.object) || 0)
  end

  def draw_item(index)
    skill = @data[index]
    if skill
      rect = item_rect(index)
      rect.width -= 4
      draw_item_name(skill, rect.x, rect.y, true)
      draw_skill_cost(rect, skill)
    end
  end

  def draw_skill_cost(rect, skill)
    draw_text(rect, @actor.skill_orb_cost(skill), 2)
  end

  def update_help
    @help_window.set_item(item)
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end

end #Window_EquippedList

#==============================================================================
# 
# ▼ End of File
# 
#==============================================================================