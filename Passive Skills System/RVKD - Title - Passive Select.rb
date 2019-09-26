#===============================================================================
# Title: (Addon) Title | Passive 
# Author: Revoked
# 
# This script adds a selection window in Scene_ToGTitles which allows for the
# player to go to the Passives screen. It also draws the actor's current title
# in help window during the initial selection.
#===============================================================================
# ** Scene_ToGTitles
#===============================================================================
class Scene_ToGTitles < Scene_MenuBase
  alias rvkd_sc_togt_start start
  def start
    rvkd_sc_togt_start
    create_first_command_window
    @first_command_window.actor = @actor
    @first_command_window.activate.select(0)
    @titlelist_window.set_handler(:cancel, method(:open_fc_window))
    @help_window.opacity = 0
    fc_initial_help
    @title_effects_standard_window.actor = @actor
    @title_effects_standard_window.title = @actor.title
    @title_effects_standard_window.show
  end

  def create_first_command_window
    @first_command_window = Window_ToGSelect_Option.new(@help_window)
    @first_command_window.set_handler(:eq_titles, method(:fc_titles))
    @first_command_window.set_handler(:eq_passives, method(:fc_passives))
    @first_command_window.set_handler(:cancel, method(:return_scene))
    @first_command_window.set_handler(:pagedown, method(:next_actor))
    @first_command_window.set_handler(:pageup,   method(:prev_actor))
    @first_command_window.set_handler(:change, method(:fc_initial_help))
  end
  
  def fc_titles
    @titlelist_window.actor = @actor
    @titlelist_window.activate.select(0)
#~     @title_effects_standard_window.show
#~     @title_effects_standard_window.actor = @actor
#~     @title_effects_standard_window.title = @titlelist_window.title
  end
  
  def fc_passives
    SceneManager.call(Scene_Passive)
  end
  
  def open_fc_window
    @first_command_window.show
    @titlelist_window.unselect
    @first_command_window.actor = @actor
    @first_command_window.activate.select(0)
    @title_effects_standard_window.actor = @actor
    @title_effects_standard_window.title = @actor.title
  end
  
  def on_actor_change
    @status_window.actor = @actor
    @titlelist_window.actor = @actor
    @hint_window.actor   = @actor
    @titlelist_window.refresh
    @first_command_window.actor = @actor
    @first_command_window.activate.select(0)
    @title_effects_standard_window.actor = @actor
    @title_effects_standard_window.title = @actor.title
  end
  
  def fc_initial_help
    if @actor.title_mastered?(@actor.title.symbol)
      str = @actor.title.description.split("\n")
      @help_window.set_text(str[0]+"\eC[14]\n"+str[1])
    else
      @help_window.set_text(@actor.title.description)
    end
    return unless @actor.title.ranks[6]
    q = @actor.title.ranks[6].script.gsub(/learn_passive/,"")[/-?\w+/].to_sym
    q = RVKD::Passives::PASSIVES[q][1] rescue 216
    @help_window.draw_icon(q, 0, 24)
  end
  
  alias rvkd_sctogt_on_title_command_cancel on_title_command_cancel
  def on_title_command_cancel
    rvkd_sctogt_on_title_command_cancel
    @first_command_window.show
  end
  
  alias rvkd_sctogt_on_title_ok on_title_ok
  def on_title_ok
    rvkd_sctogt_on_title_ok
    @first_command_window.hide
  end
  
end #Scene_ToGTitles
#===============================================================================
# ** Window_ToGSelect_Option
#===============================================================================
class Window_ToGSelect_Option < Window_Command
  
  def initialize(help_window)
    @help_window = help_window
    super(8, 362)
    self.width = 624
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
    add_command("Equip Titles",   :eq_titles)
    add_command("Equip Passives", :eq_passives)
  end
  
  def cursor_up(wrap)
    @index=0
    Sound.play_ok
    Input.update
    deactivate
    call_handler(:eq_titles)
  end
  
  def process_cursor_move
    return unless cursor_movable?
    last_index = @index
    cursor_right(Input.trigger?(:RIGHT)) if Input.repeat?(:RIGHT)
    cursor_left (Input.trigger?(:LEFT))  if Input.repeat?(:LEFT)
    cursor_pagedown   if !handle?(:pagedown) && Input.trigger?(:R)
    cursor_pageup     if !handle?(:pageup)   && Input.trigger?(:L)
    Sound.play_cursor if @index != last_index
    cursor_up   (Input.trigger?(:UP))    if Input.repeat?(:UP)
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
  
end #Window_ToGSelect_Option

#==============================================================================
# 
# ▼ End of File
# 
#==============================================================================