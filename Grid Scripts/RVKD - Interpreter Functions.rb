#===============================================================================
# Title: Interpreter Functions
# Author: Revoked
# 
# This script defines convenient methods for improving the flow of scenes and
# system functions, adding new concepts as well as creating alternate versions
# of default functions.
#-------------------------------------------------------------------------------
# ** Game_System
#===============================================================================
class Game_Interpreter
  
  alias rvkd_game_interpreter_initialize initialize
  def initialize(depth = 0)
    rvkd_game_interpreter_initialize(depth)
    @saved_leader = nil
  end
  #=============================================/
  # Alternate Functions                        /
  #-------------------------------------------/
  def fadeout_custom(dur)
    Fiber.yield while $game_message.visible
    screen.start_fadeout(dur)
    wait(dur)
  end
  
  def fadein_custom(dur)
    Fiber.yield while $game_message.visible
    screen.start_fadein(dur)
    wait(dur)
  end  
  
  #=============================================/
  # New Functions                              /
  #-------------------------------------------/
  def save_leader
    @saved_leader = $game_party.leader.id
  end
  
  def set_leader(actor = nil)
    if actor && $game_party.members.include?($game_actors[actor])
      $game_party.set_leader(actor)
    elsif @saved_leader
      set_leader(@saved_leader) 
      @saved_leader = nil
    end
  end
  
  def indoor_bgm
    bgm = RPG::BGM.last
    return if bgm.name == ""
    bgm.volume = (bgm.volume * 0.8).to_i
    msgbox_p(bgm.volume)
    bgm.play
  end
  
  def outdoor_bgm
    bgm = RPG::BGM.last
    return if bgm.name == ""
    bgm.volume = (bgm.volume / 0.8).to_i
    msgbox_p(bgm.volume)
    bgm.play
  end
  
end # Game_Interpreter

#===============================================================================
# ** Game_Party
#===============================================================================
class Game_Party < Game_Unit
  
  def set_leader(actor)
    actor = $game_actors[actor] if actor.is_a?(Integer)
    return unless actor.is_a?(Game_Actor) && members.include?(actor)
    @actors.unshift(@actors.delete(actor.id))
    $game_player.refresh
    $game_map.need_refresh = true
  end
  
end # Game_Party