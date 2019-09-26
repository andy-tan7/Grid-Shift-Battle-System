#===============================================================================
# Title: HP Bar Scan
# Author: Revoked
# 
# This script ties the display of enemy HP Bars to a variable, only revealing
# the bars under certain conditions, such as 'Scan' being used on that enemy.
#===============================================================================
# ** Configuration
#===============================================================================
class Game_System
  attr_accessor :hpbar
end

def initialHpbar
  $game_system.hpbar = [false, false, false, false, false, false, false, false]
end

def scanAll
  for i in 0...$game_system.hpbar.size
    $game_system.hpbar[i] = true
  end
end

def scanHP(targ)
  for i in 0...$game_troop.members.size
    if $game_troop.members[i] == target
      return if [142,143,144,145].include?($game_troop.members[i].enemy_id)
      $game_system.hpbar[i] = true
    end
  end
end

def hideAllBars
  for i in 0...$game_system.hpbar.size
    $game_system.hpbar[i] = false
  end
end

#==============================================================================
# 
# ▼ End of File
# 
#==============================================================================