#===============================================================================
# Title: Battle HUD
# Author: Revoked
# 
# This script transforms the original Window_ActorCommand window into a button
# display at the top of the screen in battle. It uses images to correspond with
# the indices of the original window.
#
# 
#
#  - Grid attributes are stored within Game_Temp.
#===============================================================================
# ** Configuration
#===============================================================================
module HUD
  TotalY = 5
  IconX = [444-70,396-70,348-70,300-70,252-70,204-70,156-70]#[444,396,348,300,252,204,156]
  IconY = 5
  MemorySwitch = 14
end

class Game_Temp
  attr_accessor :huds
  attr_accessor :hud_cursor
  attr_accessor :hud_icon
end

class Game_Actor
  attr_accessor :last_action
end

#==============================================================================
# ** Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  alias battlehud_scb_start start
  def start
    battlehud_scb_start
#~     @help_window.x = 64
#~     @help_window.width = Graphics.width-64
#~     @help_window.arrows_visible = false
    @enemy_window.y = 416
    @actor_window.y = 416
  end
end #Scene_Battle

#==============================================================================
# ** Spriteset Battle
#==============================================================================
class Spriteset_Battle
  alias actorhud_spb_initialize initialize
  def initialize
    actorhud_spb_initialize
    create_hud
  end
  
  alias actorhud_spb_dispose dispose
  def dispose
    actorhud_spb_dispose
    dispose_hud
  end
  
  def create_hud
    ahuds = []
    indices = []
    $game_party.battle_members.each do |member|
      ahuds.push(ActorHUD.new(member, @viewport2))
      indices.push(0)
    end
    $game_temp.huds = ahuds
    $game_temp.hud_cursor = indices
#    $game_temp.hud_icon = Window_HUDIcons.new
  end
  
  def dispose_hud
    $game_temp.huds.each do |hud| 
      hud.get_pieces.each do |piece|
        piece.get_description.dispose
        piece.dispose
      end
      hud.dispose
    end
#~     $game_temp.hud_icon.dispose
  end
end #Spriteset_Battle

#==============================================================================
# ** Window_ActorCommand
#==============================================================================
class Window_ActorCommand < Window_Command
  alias window_actorcommand_setup_hud setup
  def setup(actor)
    window_actorcommand_setup_hud(actor)
    p("setup")
    if $game_switches[HUD::MemorySwitch]
      ind = $game_party.battle_members.index(@actor)
      select(@actor.last_action) 
      $game_temp.hud_cursor[ind] = @actor.last_action if @actor.last_action
    end
  end
  
  attr_accessor :activated

  def update
    super
    if self.active
      if !@activated
        ind = $game_party.battle_members.index(@actor)
        if $game_switches[HUD::MemorySwitch]
          select(@actor.last_action) 
          $game_temp.hud_cursor[ind] = @actor.last_action if @actor.last_action
        end
        $game_temp.huds[ind].show
        @activated = true
      end
#~       $game_temp.hud_icon.show
      $game_temp.grid_arrow.show_indicator(@actor)
      check_input
      process_handling
    else
#~       $game_temp.huds.each {|x| x.hide unless x == nil}
    end
  end
  
  
  def process_handling #overwrite
    return unless open? && active
    return process_ok     if Input.trigger?(:C) #|| Input.trigger?(:DOWN)
    return process_cancel if cancel_enabled? && Input.trigger?(:B)
#~     return process_start  if Input.trigger?(:A)
    return process_prior_actor if Input.trigger?(:L) || Input.trigger?(:UP)
    return process_next_actor  if Input.trigger?(:R) || Input.trigger?(:DOWN)
    #return last_action    if Input.trigger?(:UP) 
  end
  
  def process_ok
    #$game_temp.hud_icon.hide
    if ok_enabled?
      $game_temp.huds.each {|hud| hud.hide_temp}
      @actor.last_action = $game_temp.hud_cursor[$game_party.battle_members.index(@actor)]
      #@actor.actions.push(Game_Action.new(@actor)) if !@actor.actions.last.item
      $game_temp.grid_arrow.hide_indicator
      Sound.play_ok
      Input.update
      Grid.hide_grid if [0,3].include?(index)
      @activated = false
      deactivate
      call_ok_handler
    else
      Sound.play_buzzer
    end
  end
  
  def ok_enabled?
    ind = $game_party.battle_members.index(@actor)
    if $game_temp.hud_cursor[ind] == 0 && !Input.press?(:X)
      atk_skill = $data_skills[@actor.actor.attack_id]
#~       return false if @actor.action_ap_cost(atk_skill) > TurnManager.display_ap
#~     elsif $game_temp.hud_cursor[ind] == 3
#~       return false if @actor.action_ap_cost($data_skills[22]) > TurnManager.display_ap
    end
    return true
  end
  
  def process_start
    deactivate
    SceneManager.scene.call_confirm_start
  end
  
  def process_prior_actor
    @actor.last_action = $game_temp.hud_cursor[$game_party.battle_members.index(@actor)]
    OrderManager.swap_top(false)
#~     SceneManager.scene.switch_prior_actor
  end

  def process_next_actor
#~     SceneManager.scene.switch_next_actor
    @actor.last_action = $game_temp.hud_cursor[$game_party.battle_members.index(@actor)]
    OrderManager.swap_top
  end
  
  def cancel_enabled?
    handle?(:cancel)# && $game_party.total_actions > 0
  end
  
  def process_cancel
    Sound.play_cancel
    Input.update
    @activated = false
    deactivate
    call_cancel_handler
    $game_temp.huds.each {|x| x.hide unless x == nil}
    TurnManager.sort_actions
  end
  
  def last_action
    return if @actor.last_action == nil
    select(@actor.last_action)
    process_ok
  end
  
  def process_cursor_move
  end
  
  def check_input
    ind = $game_party.battle_members.index(@actor)
    last_index = $game_temp.hud_cursor[ind]
    max_commands = $game_temp.huds[ind].max_commands
    if Input.trigger?(:LEFT)
      if $game_temp.hud_cursor[ind] == 0
        $game_temp.hud_cursor[ind] = max_commands - 1 
        #process_prior_actor
      else
       $game_temp.hud_cursor[ind] -= 1
      end
    elsif Input.repeat?(:LEFT) && $game_temp.hud_cursor[ind] > 0
      $game_temp.hud_cursor[ind] -= 1
    end
    if Input.trigger?(:RIGHT)
      if $game_temp.hud_cursor[ind] >= max_commands -1
        $game_temp.hud_cursor[ind] = 0 
        #process_next_actor
      else
        $game_temp.hud_cursor[ind] += 1
      end
    elsif Input.repeat?(:RIGHT) && $game_temp.hud_cursor[ind] < max_commands-1
      $game_temp.hud_cursor[ind] += 1
    end
    if last_index != $game_temp.hud_cursor[ind]
      Sound.play_cursor #unless [:L,:R,:UP,:DOWN].any? {|i| Input.press?(i)}
      select($game_temp.hud_cursor[ind])
      $game_temp.huds[ind].update_buttons
    end
    if Input.trigger?(:X)
      select(3)
      process_ok
    end
  end
  
end #Window_ActorCommand

#==============================================================================
# ** ActorHUD
#==============================================================================
class ActorHUD < Sprite
  def initialize(actor, viewport)
    super(viewport)
    @actor = actor
    @index = $game_party.battle_members.index(@actor)
    self.bitmap = Cache.rvkd("BPortrait_#{@actor.name}")
    self.y = HUD::TotalY
    self.opacity = 0
    @background = Sprite.new(viewport)
    @selected = nil
    @description = nil
    @commands = []
    coms = @actor.battle_commands
    #@commands.push(HUDPiece.new(@actor,"Escape",0,viewport))
    for c in 0...coms.size
      @commands.push(HUDPiece.new(@actor,coms[coms.size-1-c],c,viewport))
    end
    @commands.reverse!
  end
  
  def max_commands
    return @commands.size
  end
  
  def get_pieces
    return @commands
  end
  
  def update_buttons
    @commands.each {|cmd| cmd.unlight}
    @commands[$game_temp.hud_cursor[@index]].light
  end
  
  def show
    self.opacity = 215#195
    @commands.each {|cmd| cmd.show}
    update_buttons
  end
  
  def hide
    self.opacity = 0
    @commands.each {|cmd| cmd.hide}
  end
  
  def hide_temp
    @commands.each {|cmd| cmd.hide_temp}
  end

end #ActorHUD

#==============================================================================
# ** HUDPiece (Buttons)
#==============================================================================
class HUDPiece < Sprite
  def initialize(actor,command_name,index,viewport)
    super(viewport)
    self.z = 2
    self.x = HUD::IconX[index]
    self.y = HUD::IconY+HUD::TotalY
    name = convert_name(command_name)
    @basic_name = "HUD_#{name}"
    @select_name = "HUD_#{name}#{actor.name[0,3]}"
    @com_nom  = HUDCom.new(name,viewport)
    self.bitmap = Cache.rvkd(@basic_name)
    self.opacity = 0
  end

  def get_description
    return @com_nom
  end
  
  def show
    self.opacity = 255
  end
  def hide
    self.opacity = 0
    @com_nom.disappear
  end
  def hide_temp
    self.opacity = 0
  end
  
  def light
    self.bitmap = Cache.rvkd(@select_name)
    @com_nom.appear
  end
  def unlight
    self.bitmap = Cache.rvkd(@basic_name)
    @com_nom.disappear
  end
  
  def convert_name(name)
    case name
    when "SKILL TYPE 1"
      return "Ability"
    when "SKILL TYPE 2"
      return "Tactic"
    when "SKILL 22"
      return "Move"
    end
    return name
  end
  
end #HUDPiece

#==============================================================================
# ** HUDCom (Command name splash)
#==============================================================================
class HUDCom < Sprite
  
  def initialize(command_name,viewport)
    super(viewport)
    self.z = 4
    self.x = 449
    self.y = HUD::TotalY
    self.bitmap = Cache.rvkd("BCOM_#{command_name}")
    self.opacity = 0
  end
  
  def appear
    self.opacity = 255
  end
  def disappear
    self.opacity = 0
  end
  
end #HUDCom

#==============================================================================
# 
# ▼ End of File
# 
#==============================================================================