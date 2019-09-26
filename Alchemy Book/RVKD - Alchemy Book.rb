#===============================================================================
# Title: Alchemy Knowledge
# Author: Revoked
# 
# This script handles the item shown in the Help Window when creating actions
# with Mix. Formulae that have been used in the past will show the item, while
# new formulae will show an ambiguous item.
#
#===============================================================================
# ■ Game_System
#===============================================================================
class Game_System
  
  attr_accessor :revealed_mix_formulae
  attr_accessor :revealed_mix_items
  attr_accessor :unchanged_mix_list
  alias rvkd_gs_initialize_mix initialize
  def initialize
    rvkd_gs_initialize_mix
    @revealed_mix_formulae = []
    @revealed_mix_items = []
    @unchanged_mix_list = []
  end
  
  def add_formula(mix, item = nil)
    if !@revealed_mix_formulae.include?(mix)
      @revealed_mix_formulae.push(mix) 
      if item
        @revealed_mix_items.push([item,mix])
      end
    end
  end

  def has_formula?(combo)
    return @revealed_mix_formulae.include?(combo)
  end

end
#===============================================================================
# ■ Game_Actor
#===============================================================================
class Game_Actor < Game_Battler
  
  def consume_mix_items(item = nil)
    combo = @mix_items.dup.flatten
    $game_system.add_formula([combo[0],combo[1]], item)
    $game_system.add_formula([combo[1],combo[0]], item)
    @last_mix_items = @mix_items.shift
  end
  
end #-------------------------------------------------------------------------- 

#===============================================================================
# ■ Scene_Skill
#===============================================================================
class Scene_Skill < Scene_ItemBase
  
  #Alias method: on_item_ok
  alias rvkd_scene_skill_on_item_ok on_item_ok
  def on_item_ok
    if item == $data_skills[32] && SceneManager.scene_is?(Scene_Skill)
      SceneManager.call(Scene_AlchBook)
    else
      rvkd_scene_skill_on_item_ok
    end
  end
  
end #--------------------------------------------------------------------------

#===============================================================================
# ■ Game_BattlerBase
#===============================================================================
class Game_BattlerBase
  def skill_tp_cost(skill)
    if skill.id == 32 && SceneManager.scene_is?(Scene_Skill)
      0
    else
      skill.tp_cost
    end
    
  end
end #--------------------------------------------------------------------------

#===============================================================================
# ■ Scene_AlchBook
#===============================================================================
class Scene_AlchBook < Scene_MenuBase
  
  def start
    super
    $game_system.unchanged_mix_list = $game_system.revealed_mix_items.dup
    create_help_window
    @help_window.x = 9
    @help_window.y = 51
    @help_window.opacity = 0
    create_command_window
    create_sort_window
    create_description_window
    create_item_window
    refresh_windows
    up_help
  end
  
  alias rvkd_scb_terminate terminate
  def terminate
    rvkd_scb_terminate
    $game_system.revealed_mix_items = $game_system.unchanged_mix_list.dup
  end
  
  alias rvkd_scb_update update
  def update
    rvkd_scb_update
  end
  
  def create_command_window
    @command_window = Window_AlchCommand.new(8,126)
    @command_window.opacity = 0
    @command_window.viewport = @viewport
    @command_window.help_window = @help_window
    @command_window.set_handler(:cancel, method(:return_scene))
    @command_window.set_handler(:view_formula, method(:open_list))
    @command_window.set_handler(:sort_formula, method(:process_sort))
    @command_window.set_handler(:change, method(:up_help))
  end
  
  def create_sort_window
    @sort_window = Window_AlchSortBox.new(236,126)
    @sort_window.opacity = 0
  end
  
  def create_description_window
    @desc_window = Window_AlchDescription.new(434,135)
  end
  
  def create_item_window
    @item_window = Window_AlchList.new(8, 182, 406, 216, @sort_window, @desc_window)
    @item_window.opacity = 0
    @item_window.viewport = @viewport
    @item_window.help_window = @help_window
    @item_window.set_handler(:cancel, method(:on_item_cancel))
  end
  
  def refresh_windows
    @item_window.refresh
  end
  
  def open_list
    @item_window.activate
    @item_window.select(0)
  end
  
  def on_item_cancel
    @item_window.unselect
    @command_window.activate
  end
  
  def process_sort
    refresh_windows
    @item_window.sort_items(sound = false)
    @command_window.activate
  end
  
  def up_help
    case @command_window.index
    when 0; @help_window.set_text('\i[454] ' + '\c[1]' + "Formulae" + '\c[0]' + 
                                  "\n" + "View revealed alchemy formulae.")
    when 1; @help_window.set_text('\i[203] ' + '\c[1]' + "Sort" + '\c[0]' + 
                                  "\n" + "Rearrange the list of alchemy formulae.")
    end
  end
  
end #-------------------------------------------------------------------------- 

#===============================================================================
# ■ Window_AlchCommand
#===============================================================================
class Window_AlchCommand < Window_HorzCommand
  def initialize(x,y)
    super(x,y)
    make_command_list
  end
  
  def window_width  ; 220 end
  def window_height ; 48 end
  def col_max ; 2 end
  def item_max ; 2 end
  
  def make_command_list
    add_command("Formulae", :view_formula)
    add_command("Sort", :sort_formula)
  end
  
  alias rvkd_whc_process_handling process_handling
  def process_handling
    rvkd_whc_process_handling
    return unless open? && active
    return process_down if ok_enabled? && Input.trigger?(:DOWN)
    return process_sort if Input.trigger?(:X)
  end
  
  def process_down
    select(0)
    process_ok
  end
  
  def process_sort
    call_handler(:sort_formula)
  end
  
end #--------------------------------------------------------------------------

#===============================================================================
# ■ Window_AlchList
#===============================================================================
class Window_AlchList < Window_Selectable
  
  def initialize(x,y,width,height,sort_window,desc_window)
    super(x,y,width,height)
    @sort_type = 0
    @data = $game_system.revealed_mix_items
    @sort_window = sort_window
    @desc_window = desc_window
    @sort_type = sort_alchemy(@sort_type)
  end
  
  def sort_items(sound = true)
    Sound.play_cursor if sound
    @sort_type = sort_alchemy(@sort_type)
    refresh
    #msgbox_p(@sort_type)
    select(0) if sound
  end
  
  def col_max ; 1 end
    
  def process_handling
    return process_cancel if cancel_enabled? && Input.trigger?(:B)
    return sort_items if Input.trigger?(:X) #|| Input.trigger?(:C)
  end
  
  def sort_window=(sort_window)
    @sort_window = sort_window
  end
  
  def item_max
    @data ? @data.size : 1
  end
  
  def item
    @data && index >= 0 ? @data[index] ? @data[index][0] : nil : nil
  end
  
  def draw_item(index)
    mix = @data[index]
    if mix
      rect = item_rect(index)
      rect.width -= 4
      contents.font.size = 20
      draw_item_name(mix[0], rect.x, rect.y, true)
      contents.font.size = 20
      draw_item_name($data_items[mix[1][0]], rect.x + 128, rect.y, true)
      draw_item_name($data_items[mix[1][1]], rect.x + 256, rect.y, true)
    end
  end
  
  def refresh
    create_contents
    draw_all_items
  end
  
  def update_help
    @help_window.set_item(item)
    @desc_window.set_item(item)
  end
  
  def sort_alchemy(type = 0)
    case type
    when 0 
      @data = $game_system.unchanged_mix_list.dup
      @data.each do |entry|
        duplicates = @data.select {|row| row == entry}
        duplicates.reverse_each do |duplicate|
          if duplicate[1].sort == entry[1].sort
            @data.delete(duplicate) unless duplicate[1][0] == duplicate[1][1]
          end
        end
      end
      sort_text("Effect Type")
    when 1
      @data.reverse!
      sort_text("Effect Type (R)")
    when 2
      @data.sort_by! {|entry| entry[0].name}
      sort_text("Effect A-Z")
    when 3
      @data.reverse!
      sort_text("Effect Z-A")
    when 4
      @data = $game_system.unchanged_mix_list.dup
      @data.sort! do |a,b|
        comp = (a[1][0] <=> b[1][0])
        comp.zero? ? (a[1][1] <=> b[1][1]) : comp
      end
      sort_text("Component Type")
    when 5
      @data.reverse!
      sort_text("Component Type (R)")
    when 7
      @data.reverse!
      sort_text("Component Z-A")
    when 6
      @data.sort! do |a,b|
        comp = ($data_items[a[1][0]].name <=> $data_items[b[1][0]].name)
        comp.zero? ? ($data_items[a[1][1]].name <=> $data_items[b[1][1]].name) : comp
      end
      sort_text("Component A-Z")
    end
    type += 1
    type = 0 if type > 7
    return type
  end
  
  def sort_text(text)
    @sort_window.set_text(text) if @sort_window
  end
  
end #--------------------------------------------------------------------------
#===============================================================================
# ■ Window_AlchSortBox
#===============================================================================
class Window_AlchSortBox < Window_Base
  
  def initialize(x,y)
    super(x,y,178,48)
    self.opacity = 255
  end
  
  def set_text(text)
    contents.clear
    contents.font.size = 22
    draw_text(text,-12,0,178,24,1)
  end
  
  def draw_text(text, x, y, text_width, text_height, alignment = 0)
    contents.draw_text(x, y, text_width, text_height, text, alignment)
  end
  
end 

#===============================================================================
# ■ Window_AlchDescription
#===============================================================================
class Window_AlchDescription < Window_Base
  
  def initialize(x,y)
    super(x,y,198,260)
    self.opacity = 0
  end
  
  def standard_padding; 0 end
  
  def set_item(item)
    contents.clear
    return if item.nil?
    contents.font.size = 22
    draw_text_ex(166, -1, "\\i[#{RVKD::MixDesc.ele_icon(item)}]")
    draw_text_ex(0,0, "\\i[#{item.icon_index}]")
    #color = RVKD::MixDesc.ele_text_color(item)
    contents.font.color = Color.new(*RVKD::MixDesc.ele_text_color(item))
    draw_text(item.name, 28, 0, 100, 24)#item.name)
#~     results = RVKD::MixDesc.descriptions(item)
#~     results.each do |result|
#~       #draw_text(result[0],)
#~     end
  end
  
  def draw_text(text, x, y, text_width, text_height, alignment = 0)
    contents.draw_text(x, y, text_width, text_height, text, alignment)
  end
  
end

module RVKD
  module MixDesc
    def self.descriptions(item)
      result = []
      
    end
    
    def self.ele_text_color(item)
      case item.damage.element_id
      when 1; return [255, 120, 76, 255]
      when 2; return [36, 128, 216, 255]
      when 3; return [64, 224, 64, 255]
      when 4; return [224, 128, 64, 255]
      when 5; return [255, 204, 32, 255]
      when 6; return [64, 192, 240, 255]
      when 7; return [225, 225, 64, 255]
      when 8; return [176, 142, 224, 255]
      else
        return [255,255,255,255]
      end
    end
    
    def self.ele_icon(item)
      return 212 unless item
      case item.damage.element_id
      when 1; return 176
      when 2; return 177
      when 3; return 178
      when 4; return 179
      when 5; return 180
      when 6; return 181
      when 7; return 182
      when 8; return 183
      else
        return 212
      end
    end
    
  end
end

# End of script.
