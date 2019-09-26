class Spriteset_Battle
  def get_battle_units
    return @battle_units
  end
end

class Spriteset_BattleUnit
  attr_accessor :battler
  attr_reader :unit
end

class Scene_Battle
  alias rvkd_sb_swap_start_actor_command_selection start_actor_command_selection
  def start_actor_command_selection
    rvkd_sb_swap_start_actor_command_selection
    @actor_command_window.activated = false
    @actor_window.reset_cursor
  end
end

module BattleManager
  def self.set_actor_index(index)
    @actor_index = index
  end
end

module OrderManager
  
  def self.swap_top(forward = true)
    fail = true unless @top_unit.battler.actor? && @units[0].battler.actor?
    fail = true if @units[0].operate
    if fail == true
      Grid::GridError.play 
      return 
    end
    @units.delete_if {|unit| unit.battler == @top_unit.battler && unit.forecast}
    b_units = SceneManager.scene.spriteset.get_battle_units
    
    index = 0
    index += 1 while @units[index].battler.actor? && !@units[index].operate
    index -= 1
    
    if forward
      temp = @top_unit.battler
      @top_unit.battler = @units[0].battler
      index.times {|i| @units[i].battler = @units[i+1].battler}
      @units[index].battler = temp
    else
      temp = @top_unit.battler
      @top_unit.battler = @units[index].battler
      index.times {|i| @units[index-i].battler = @units[index-i-1].battler}
      @units[0].battler = temp
    end
    
    rems = [@top_unit.battler]
    (index+1).times {|i| rems.push(@units[i].battler)}
    b_units.each do |key,u|
      b_units.delete(key) and u.dispose if rems.include?(b_units[key].battler)
    end
    
    BattleManager.set_actor_index($game_party.members.index(@top_unit.battler))
    $game_temp.huds.each {|x| x.hide unless x == nil}
    SceneManager.scene.start_actor_command_selection
    OrderManager.clear_forecast
    OrderManager.update_delay_time
    SceneManager.scene.update_forecast
    Sound.play_swap_commander
    #
  end
  
#~   def self.swap_top_backward
#~     return unless @top_unit.battler.actor? && @units[0].battler.actor?
#~     return if @units[0].operate
#~     @units.delete_if {|unit| unit.battler == @top_unit.battler && unit.forecast}
#~     b_units = SceneManager.scene.spriteset.get_battle_units
#~     
#~     index = 0
#~     index += 1 while @units[index].battler.actor? && !@units[index].operate
#~     index -= 1
#~     
#~     
#~     rems = [@top_unit.battler]
#~     (index+1).times {|i| rems.push(@units[i].battler)}
#~     b_units.each do |key,u|
#~       b_units.delete(key) and u.dispose if rems.include?(b_units[key].battler)
#~     end
#~     
#~     BattleManager.set_actor_index($game_party.members.index(@top_unit.battler))
#~     $game_temp.huds.each {|x| x.hide unless x == nil}
#~     SceneManager.scene.start_actor_command_selection
#~   end
    
  
end

