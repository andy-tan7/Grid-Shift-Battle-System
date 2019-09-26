#===============================================================================
# Title: Grid Shift Battle
# Author: Revoked
# Last Edited: April 22, 2019
# 
# This script adjusts the functionality of targeting within battles, making an
# 8x4 grid in which abilities have different ranges and areas. It splits up the
# actors and enemies between their respective 4x4 regions.
#
# Movement is possible within each side of the grid, but the median may not be
# crossed.
#
#  - Grid attributes are stored within Game_Temp.
#===============================================================================
# ** Configuration
#===============================================================================
module Grid
  MemorySwitch = 13
  OpacityVar = 11
end

class Game_Temp                   # *Game_Temp variables are not stored.
  attr_accessor :grid             # 2D Array. Grid[0]: Tiles. Grid[1]: Cursor.
  attr_accessor :indicators
  attr_accessor :fading_indicators
  attr_accessor :grid_arrow       # Instance of GridArrow. Also used in the HUD.
  attr_accessor :gi_troop         # GridInitial_Troop. Initialized enemy indices.
  attr_accessor :demo_region
end

class Game_System          # *Game_System variables are saved with game data.
  #attr_accessor :party_pos # Globally accessible variable for actor positions.
end

#~ class Game_Battler
#~   attr_accessor :grid_index
#~ end

class Game_Actor                 # *Instance variables for individual actors.
  attr_accessor :last_origin     # The last square selected by the actor.
  attr_accessor :last_aoe
  attr_accessor :last_sel_region # The region used for redirecting targets.
  attr_accessor :last_move_delay # Determine whether to refresh delay indicator.
  
  def last_position
    @actions.reverse_each do |action|
      next if action.item.nil? || !action.effect_area
      return action.effect_area[0] if [21,22,23].include?(action.item.id)
    end
    return $game_system.party_pos[$game_party.members.index($game_actors[self.id])]
  end
  
  def next_position
    @actions.each do |action|
      next if action.item.nil? || !action.effect_area
      return action.effect_area[0] if [21,22,23].include?(action.item.id)
    end
    return $game_system.party_pos[$game_party.members.index($game_actors[self.id])]
  end
  
  def position
    return $game_system.party_pos[$game_party.members.index($game_actors[self.id])]
  end
  
end

class Game_Enemy
  attr_accessor :last_origin
  attr_accessor :last_aoe
  
  def position
    return Grid.index_of_unit(self)
  end
#~   alias rvkd_grid_shift_ge_initialize initialize
#~   def initialize(index, enemy_id)
#~     rvkd_grid_shift_ge_initialize(index,enemy_id)
#~   end
  
end

module BattleManager
  class << self
    alias rvkd_bm_init_members init_members
    def init_members
      rvkd_bm_init_members
      @initial_positions = $game_system.party_pos.dup
    end
    
    alias rvkd_bm_battle_end battle_end
    def battle_end(result)
      $game_system.party_pos = @initial_positions.dup if $game_switches[16] == true
      rvkd_bm_battle_end(result)
    end
    
    alias rvkd_bm_gbs_process_victory process_victory
    def process_victory
      (0..Grid::MaxRow*Grid::MaxCol-1).to_a.each do |pos| 
        $game_temp.grid[0][pos].set_team(true)
        $game_temp.grid[0][pos].default_hidden
      end
      rvkd_bm_gbs_process_victory
    end
    
    alias rvkd_bm_gbs_process_defeat process_defeat
    def process_defeat
      (0..Grid::MaxRow*Grid::MaxCol-1).to_a.each do |pos| 
        $game_temp.grid[0][pos].set_team(false)
        $game_temp.grid[0][pos].default_hidden
      end
      rvkd_bm_gbs_process_defeat
    end
    
  end
end

module REGEXP
  TARGETS = /<(?:TARGETS|target):[ ](.*)>/i
end

#==============================================================================
# ** Game_Battler
#------------------------------------------------------------------------------
class Game_Battler
  attr_accessor :killed_units       #Recently slain targets, used to recover MP.
  
  alias game_battler_initialize_resource_recover initialize
  def initialize
    game_battler_initialize_resource_recover
    @killed_units = 0
  end
  
  
  #--------------------------------------------------------------------------
  # Aliased method: die
  # Adds the removal of all occurrences of the enemy from the grid when slain.
  #--------------------------------------------------------------------------
  alias game_battler_clear_grid_die die
  def die
    game_battler_clear_grid_die
    if self.is_a?(Game_Enemy)		
      for i in 0...$game_temp.grid[0].size		
        $game_temp.grid[0][i].remove_unit if $game_temp.grid[0][i].get_unit == self		
      end		
    end
  end
  
  #--------------------------------------------------------------------------
  # Aliased method: execute damage
  # Adds the recovery of MP to the slayer when an enemy is slain.
  #--------------------------------------------------------------------------
  alias game_battler_execute_damage_resource_recover execute_damage
  def execute_damage(user)
    game_battler_execute_damage_resource_recover(user)
    return unless $game_party.in_battle
    user.killed_units += 1 if self.hp <= 0
  end
  
  #--------------------------------------------------------------------------
  # Recovers MP to the slayer when an enemy is slain.
  #--------------------------------------------------------------------------
  def regain_mp(user)
    user.mp = user.mp + user.killed_units * 2
    user.create_popup(["#{user.killed_units * 2}", nil], :mp_heal)
    RPG::SE.new("TCO - Indicator2", 65, 100).play
    user.killed_units = 0
  end
  def rem_state(state_id)
    remove_state(state_id)
  end
  
end
#==============================================================================
# ** Game_Enemy
#------------------------------------------------------------------------------
class Game_Enemy < Game_Battler
  attr_accessor :grid_width       # The width of an enemy on the grid.
  attr_accessor :grid_height      # The height of an enemy on the grid.
  attr_accessor :movement_range   # The distance an enemy can move in one turn.
  #--------------------------------------------------------------------------
  # Aliased method: initialize
  # Called on enemy creation; initializes instance variables related to Grid.
  #--------------------------------------------------------------------------
  alias grid_enemy_initialize initialize
  def initialize(index, enemy_id)
    grid_enemy_initialize(index, enemy_id)
    @grid_width = 1
    @grid_height = 1
    @movement_range = 2
    self.note.split(/[\r\n]+/).each do |line|
      if line =~ /<grid size:[ ](\d+),[ ](\d+)>/ #Check for: <grid size: w, h>
        @grid_width  = $1.to_i 
        @grid_height = $2.to_i
      end
    end
  end
end
#==============================================================================
# ** RPG::Skill
#------------------------------------------------------------------------------
class RPG::UsableItem < RPG::BaseItem #RPG::Skill < RPG::UsableItem
  def ability_range
    return @ability_range if @ability_range
    self.note.split(/[\r\n]+/).each do |line|
      if line =~ ARC::REGEXP::AI_IN_RANGE
        return @ability_range = $1.to_i 
      end
      if line =~ ARC::REGEXP::AI_IN_ROW
        return @ability_range = $1.to_i 
      end
    end
    return 10
  end
  
  def min_max_range
    return [@min_range,@max_range] if @min_range && @max_range
    self.note.split(/[\r\n]+/).each do |line|
      if line =~ ARC::REGEXP::AI_KEEP_DIST
        @min_range = $1.to_i
      end
      if line =~ ARC::REGEXP::AI_MAX_DIST
        @max_range = $1.to_i
      end
    end
    return [@min_range,@max_range] if @min_range && @max_range
    return [0,ability_range]
  end
  
  alias rvkd_gsb_for_all? for_all?
  def for_all?
    self.note.split(/[\r\n]+/).each do |line|
      case line
      when REGEXP::TARGETS
        case $1
        when /ALLY COL/i
          return true
        when /COLUMN[ ](\d+)/i
          return true
        when /CROSS[ ](\d+)/i
          return true
        when /X[ ](\d+)/i
          return true
        when /EXPAND[ ](\d+)/i
          return true
        end
      end
    end
    rvkd_gsb_for_all?
  end
  
  
end

#==============================================================================
# ** Game_Troop 
#------------------------------------------------------------------------------
class Game_Troop
  #--------------------------------------------------------------------------
  # Aliased method: setup. 
  # Store initial troop positions, since the grid is not created yet.
  #--------------------------------------------------------------------------
  alias grid_selector_gat_setup setup
  def setup(troop_id)
    $game_temp.gi_troop = []
    grid_selector_gat_setup(troop_id)
    $game_troop.members.each {|unit| set_grid_index(unit)}
  end

  #--------------------------------------------------------------------------
  # Sets the indices of an enemy based on their size and database coordinates.
  # Larger enemies will have their sizes considered and given more indices.
  #--------------------------------------------------------------------------
  def set_grid_index(unit)
    gp = Grid::Position.dup
#    gp.each {|gp_piece| gp_piece[1] += Grid::ShiftY}
    xpos, ypos = 0
    for c in 0...8
      c < 7 ? po = (gp[c][0]+gp[c+1][0])/2 : po = (gp[c][0]+gp[c][0]+62)/2
      break if unit.x < po
    end
    for r in 0...4
      r < 3 ? po = (gp[r*8][1]+gp[(r+1)*8][1])/2 : po = (gp[r*8][1]+gp[r*8][1]+54)/2
      break if unit.y < po
    end
    origin = c + Grid::MaxCol*r
    front_spaces = [origin]
    if unit.grid_height > 1
      front_spaces = [origin]
      for i in 1...unit.grid_height
        front_spaces.push(origin - i*Grid::MaxCol)
      end
    end
    indices = front_spaces.dup
    if unit.grid_width > 1
      front_spaces.each do |head|
        for x in 1...unit.grid_width
          indices.push(head - x)
        end
      end
    end
    indices.each {|pos| $game_temp.gi_troop[pos] = unit}
  end
 
  
end

#==============================================================================
# ** Spriteset Battle
#==============================================================================

class Spriteset_Battle
  alias grid_selector_spb_initialize initialize
  def initialize
    @indicator_frame = 0
    @indicator_count = 1
    grid_selector_spb_initialize
    create_grid
  end
  
  #--------------------------------------------------------------------------
  # Aliased method: dispose
  # Called at battle end to also dispose the grid.
  #--------------------------------------------------------------------------
  alias grid_selector_spb_dispose dispose
  def dispose
    grid_selector_spb_dispose
    dispose_grid
  end
  
  alias grid_selector_spb_update update
  def update
    grid_selector_spb_update
    update_indicators 
  end
  
  def update_indicators
    #return unless @indicator_count
    @indicator_count += 1
    if @indicator_count >= 5
      @indicator_frame += 1
      @indicator_frame = 0 if @indicator_frame > 10
      $game_temp.indicators.each{|indicator| indicator.set_frame(@indicator_frame)}
      $game_temp.fading_indicators.each do |i|
        #msgbox_p(i.opacity)
        i.opacity < 5 ? $game_temp.fading_indicators.delete(i) : i.opacity -= [(300.0/i.opacity).round.to_i,8].max
      end
      @indicator_count = 0
    end
  end
  
  #--------------------------------------------------------------------------
  # Create every element of the grid at battle start. Adds default troop positions.
  #--------------------------------------------------------------------------
  def create_grid
    return if $game_temp.grid != nil
    $game_temp.indicators = []
    $game_temp.fading_indicators = []
    $game_temp.grid = [[],[4]]
    ally = false; i = 0
    while i < (Grid.max_index)
      $game_temp.grid[0].push(GridSelector.new(Grid::GridPlaces[i],nil,@viewport1))
      i+=1#; ally = !ally if i % 4 == 0
    end
    for i in 0...$game_temp.grid[0].size
      if $game_temp.gi_troop[i] != nil
        $game_temp.grid[0][i].set_unit($game_temp.gi_troop[i])
      end
    end
    $game_party.battle_members.each do |member|
#~       index = $game_party.battle_members.index(member)
#~       $game_temp.grid[0][$game_system.party_pos[index]].set_unit(member)
      $game_temp.grid[0][member.position].set_unit(member)
    end
    Grid.ally_spaces.each {|pos| $game_temp.grid[0][pos].set_team(true)}
    Grid.enemy_spaces.each {|pos| $game_temp.grid[0][pos].set_team(false)}
    $game_temp.grid_arrow = GridArrow.new(4,@viewport2)
  end
  
  #--------------------------------------------------------------------------
  # Dispose elements of the grid at the end of battle.
  #--------------------------------------------------------------------------
  def dispose_grid
    $game_temp.grid[0].each {|tile| tile.dispose if tile != nil}
    $game_temp.grid[1] = [0]
    $game_temp.grid = nil
  end
  
end


#==============================================================================
# ** Game_Action
#------------------------------------------------------------------------------
class Game_Action
  attr_accessor :initial_targets # Accessible instance variable for the action's targets.
  
  attr_accessor :valid_range #Locations of possible positions for the skill.
  attr_accessor :effect_area #Locations of the damage points of the skill.
  attr_accessor :clear_area  #Locations on the grid to clear indicators.
  
  alias rvkd_gsb_ga_clear clear
  def clear
    rvkd_gsb_ga_clear
    @effect_area = nil
  end
  
  def get_targets(area)
    return units_in_area(area)
  end
  
  #--------------------------------------------------------------------------
  # Method Overwrite: targets_for_opponents
  # Returns target array of enemy units.
  #--------------------------------------------------------------------------
  def targets_for_opponents
    if @active_chain_skill || (item.operate_time(@subject) > 0 && @subject.is_a?(Game_Actor))
      return make_chain_targets(item,@subject.last_origin)
    end
    return @initial_targets if @initial_targets
    if item.for_random?
      Array.new(item.number_of_targets) { opponents_unit.random_target }
    elsif item.for_one?
      num = 1 + (attack? ? subject.atk_times_add.to_i : 0)
      return make_chain_targets(item,@subject.last_origin) if @subject.is_a?(Game_Actor)
      if @target_index < 0
        [opponents_unit.random_target] * num
      else
        [opponents_unit.smooth_target(@target_index)] * num
      end
    else
      opponents_unit.alive_members
    end
  end
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
  #--------------------------------------------------------------------------
  # Method Overwrite: targets_for_friends
  # Returns target array of allied units.
  #--------------------------------------------------------------------------
  def targets_for_friends
    if @active_chain_skill == true ||  item.operate_time(@subject) > 0
      if item.scopes[:target_conditions].include?(:self_only)
        return make_chain_targets(item,@subject.position)
      end
      return make_chain_targets(item,@subject.last_origin)
    end
    return units_in_area(@effect_area) if @effect_area.is_a?(Array)
    if @subject.state?(211) && item.is_a?(RPG::Item) && item.for_one?
      return @initial_targets if item.note =~ /<area>/
    end
    if item.for_user?
      [subject]
    elsif item.for_dead_friend?
      if item.for_one?
        [friends_unit.smooth_dead_target(@target_index)] #smooth_dead_target(@target_index)]
      else
        friends_unit.members #dead_members
      end
    elsif item.for_friend? || item.for_dead_friend?
      if item.for_one?
        if @target_index < 0
          [friends_unit.random_target]
        else
          [friends_unit.smooth_target(@target_index)]
        end
      else
        friends_unit.alive_members
      end
    end
  end
#------------------------------------------------------------------------------
  
#------------------------------------------------------------------------------
# Returns a new array of units based on the last origin of an actor's action.
# Used for Extend, and if the target(s) change inside the area of effect.
#--------------------------------------------------------------------------
  def make_chain_targets(item,origin)
    area = [origin]
    aoe = true
    case item.scopes[:area_type]
    when :single
      aoe = false
    when :cross
      area += Grid.cross_shape(origin,item.scopes[:area_size])
    when :x
      area += Grid.x_shape(origin,item.scopes[:area_size])
    when :expand
      area += Grid.expand_search(origin,item.scopes[:area_size])
    when :row
      area += Grid.linear(origin,[4,6],item.scopes[:area_size])
    when :row_back
      area += Grid.linear(origin,[4],item.scopes[:area_size])
    when :col
      area += Grid.linear(origin,[2,8],item.scopes[:area_size])
    end
    area -= Grid.enemy_spaces if item.scopes[:range_type] == :allies
    area -= Grid.ally_spaces if item.scopes[:range_type] == :enemies
    area -= Grid.ally_spaces if item.scopes[:target_conditions].include?(:safe)
    return units_in_area(area,item) if aoe == true
    #return units_in_area(area) if item.operate_time(@subject) > 0
    return enemy_in_region(@subject.last_sel_region)
  end
  
#~   def range_from_origin(item,origin)
#~     area = [origin]
#~     item.note.split(/[\r\n]+/).each do |line|
#~       case line
#~       when REGEXP::TARGETS
#~         case $1
#~         when /RANGE[ ](\d+)/i
#~           area += Grid.expand_search(origin,$1.to_i)
#~         when /ROW[ ](\d+)/i
#~           area += Grid.linear(origin, @subject.actor? ? 4 : 6, $1.to_i)
#~         when /SAFE/i
#~           area -= Grid.ally_spaces
#~         end
#~       end
#~     end
#~     return area
#~   end
  
#~   def area_from_origin(item,origin)
#~     area = [origin]
#~     item.note.split(/[\r\n]+/).each do |line|
#~       case line
#~       when REGEXP::TARGETS
#~         case $1
#~         when /SELF TARGET/i
#~         when /RANGE[ ](\d+)/i
#~         when /ALLY COL/i
#~           area += Grid.vertical(origin)
#~         when /ALLY ROW/i
#~           area += Grid.horizontal(origin)
#~           area -= Grid.enemy_spaces
#~         when /COLUMN[ ](\d+)/i
#~           area += Grid.linear(origin,[2,8],$1.to_i)
#~         when /CROSS[ ](\d+)/i
#~           area += Grid.cross_shape(origin,$1.to_i)
#~         when /X[ ](\d+)/i
#~           area += Grid.x_shape(origin,$1.to_i)
#~         when /EXPAND[ ](\d+)/i
#~           area += Grid.expand_search(origin,$1.to_i)
#~         when /SAFE/i
#~           area -= Grid.ally_spaces
#~         end
#~       end
#~     end
#~     return area
#~   end
  
end
#------------------------------------------------------------------------------
# Return an array of battler objects within the specified area.
#--------------------------------------------------------------------------
def units_in_area(area,item = nil)
  units = []
  area.each do |index|
    next unless index
    if $game_temp.grid[0][index].get_unit.is_a?(Game_Battler)
      units.push($game_temp.grid[0][index].get_unit)
    end
    if item && item.scopes[:target_conditions].include?(:dead_only)
      units.reject! {|unit| unit.alive?}
    elsif item && item.scopes[:target_conditions].include?(:alive_only)
      units.reject! {|unit| !unit.alive?}
    end
  end
  return units
end

#--------------------------------------------------------------------------
# Return one enemy from the region. Prioritizes the last enemy selected.
#--------------------------------------------------------------------------
def enemy_in_region(area)
  if $game_temp.grid[0][@subject.last_origin].get_unit.is_a?(Game_Enemy)
    return [$game_temp.grid[0][@subject.last_origin].get_unit]
  end
  return [] if !area.is_a?(Array) || area.empty?
  area.each do |index|
    if $game_temp.grid[0][index].get_unit.is_a?(Game_Enemy)
      return [$game_temp.grid[0][index].get_unit]
    end
  end
  return []
end

  
#==============================================================================
# ** Window_Escape
#------------------------------------------------------------------------------
class Window_Escape < Window_Command
  
  def initialize
    super(224,184)
    #super(544,72)
    make_command_list
  end
  
  alias rvkd_we_escape_process_handling process_handling
  def process_handling
    rvkd_we_escape_process_handling
    return process_left if open? && active && Input.trigger?(:LEFT)
  end
  
  def process_left
    process_cancel
  end
  
  def make_command_list
    add_command("Escape", :escape, BattleManager.can_escape?)
  end
  def window_width; 192 end#96 end
  def col_max; 1 end
  def row_max; 1 end
  def item_max; 1 end
  
end
  
  
#==============================================================================
# ** Game_Unit
#------------------------------------------------------------------------------
class Game_Unit
  def speed
    return 1
    #return 1 if members.size == 0
    #members.inject(0) {|r, member| r += member.spd } / members.size * (members.size ** 0.5)
  end
  
  def random_dead_target
    members.empty? ? nil : dead_members[rand(dead_members.size)]
  end
  
  def smooth_dead_target(index)
    member = members[index]
    (member) ? member : members[0]
  end
end
#==============================================================================
# ** Game_System
#------------------------------------------------------------------------------
class Game_System
  attr_accessor :escape_bonus
  alias rvkd_gsb_gs_initialize initialize
  def initialize
    rvkd_gsb_gs_initialize
    @escape_bonus = 10
  end
end
#==============================================================================
# [M] BattleManager
#------------------------------------------------------------------------------
module BattleManager
  def self.make_escape_ratio
#~     msgbox_p($game_party.speed)
#~     msgbox_p($game_troop.speed)
    @escape_ratio = 0.3 + 0.2 * ($game_party.speed / $game_troop.speed)**2
#~     msgbox_p(@escape_ratio)
  end
  
  def self.process_escape
    #$game_message.add(sprintf(Vocab::EscapeStart, $game_party.name))
    success = @preemptive ? true : (rand < @escape_ratio + $game_system.escape_bonus/100.0)
    Sound.play_escape
    if success
      process_abort
    else
      $game_system.escape_bonus += 5
      #$game_message.add('\.' + Vocab::EscapeFailure)
      #$game_party.clear_actions
    end
    #wait_for_message
    return success
  end
  
end

#==============================================================================
# ** Scene_Battle
#------------------------------------------------------------------------------
class Scene_Battle < Scene_Base
  attr_accessor :help_window
  attr_accessor :actor_command_window
  attr_reader :actor_window
  #--------------------------------------------------------------------------
  # * Actor [OK]
  #--------------------------------------------------------------------------
  alias grid_selector_scb_start start
  def start
    battle_member_pos = []
    $game_party.battle_members.each {|mem| battle_member_pos.push{mem.position}}
    fix_actor_positions if battle_member_pos.detect{|e| $game_system.party_pos.count(e) > 1} != nil
    grid_selector_scb_start
    create_escape_window
    BattleManager.make_escape_ratio
    @frontline_a = Grid.frontline(true)
    @frontline_b = Grid.frontline(false)
  end
  
  def create_escape_window
    @escape_window = Window_Escape.new
    @escape_window.set_handler(:ok, method(:run_away))
    @escape_window.set_handler(:cancel, method(:escape_cancel))
    @escape_window.set_handler(:left, method(:escape_cancel))
    @escape_window.hide
    @escape_window.deactivate
    @escape_item = nil
  end
  
  def open_escape_window
    return unless [21,22].include?(BattleManager.actor.input.item.id)
    @escape_item = BattleManager.actor.input.item
    RPG::SE.new("FER - Sys_Att_Window", 75, 100).play
    @actor_window.deactivate
    @escape_window.show
    @escape_window.activate
  end
  
  def run_away   
    @escape_window.deactivate
    @escape_window.hide
    BattleManager.actor.force_action(9, -1)
    $game_party.members.each do |mem|
      mem.rem_state(1); mem.rem_state(2)
    end
    @help_window.hide
    @skill_window.hide
    @item_window.hide
    @actor_window.reset_cursor
    turn_end if !command_escape
  end
  
  def escape_cancel
    @escape_window.deactivate
    @escape_window.hide
    @actor_window.active = true
    @help_window.set_item(@escape_item)
    @escape_item = nil
  end
  
  alias rvkd_scb_gsb_process_action_end process_action_end
  def process_action_end
    rvkd_scb_gsb_process_action_end
    temp_fl_a = @frontline_a
    temp_fl_e = @frontline_e
    @frontline_a = Grid.frontline(true)
    @frontline_b = Grid.frontline(false)
    if temp_fl_a != @frontline_a || temp_fl_e != @frontline_b
      Grid.ally_spaces.each {|pos| $game_temp.grid[0][pos].set_team(true)}
      Grid.enemy_spaces.each {|pos| $game_temp.grid[0][pos].set_team(false)}
      ((0..(Grid::MaxRow*Grid::MaxCol-1)).to_a - Grid.ally_spaces - Grid.enemy_spaces).each {|p| $game_temp.grid[0][p].clear_team}
      $game_temp.grid[0].each do |grid|
        grid.hide; grid.unlight
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # Overwrite method: on_actor_ok
  # Called when an actor is selected as the target in the grid.
  # Updates the acting actor's instance variables, used upon action execution.
  # Closes the HUD. It is reopened later by another method.
  #--------------------------------------------------------------------------
  def on_actor_ok
    
    #
    action = BattleManager.actor.input
    action.effect_area = $game_temp.grid[1]
    #
    
    targs = []
    for i in 0...$game_temp.grid[1].size
      targs.push($game_temp.grid[0][$game_temp.grid[1][i]].get_unit)
    end
    if BattleManager.actor.input.item.for_friend?
      for i in 0...$game_temp.grid[1].size
        $game_temp.grid[0][$game_temp.grid[1][i]].set_mod(:blue_projection)
        $game_temp.indicators.push($game_temp.grid[0][$game_temp.grid[1][i]].indicator)
      end
    else
      for i in 0...$game_temp.grid[1].size
        $game_temp.grid[0][$game_temp.grid[1][i]].set_mod(:red_projection)
        $game_temp.indicators.push($game_temp.grid[0][$game_temp.grid[1][i]].indicator)
      end
    end
    targs.compact!
    BattleManager.actor.input.initial_targets = targs
    BattleManager.actor.last_origin = $game_temp.grid[1][0]
    BattleManager.actor.last_aoe = $game_temp.grid[1]
    BattleManager.actor.input.target_index = $game_party.battle_members.index(targs[0])
    @actor_window.hide
    @skill_window.hide
    @item_window.hide
    next_command
  end

  
  #---#
  # ? #
  #---#
  alias grid_selector_scb_on_actor_cancel on_actor_cancel
  def on_actor_cancel
    grid_selector_scb_on_actor_cancel
    $game_temp.grid_arrow.show_indicator(BattleManager.actor)
#    p(BattleManager.actor.name)
  end
  
  alias grid_selector_scb_on_skill_cancel on_skill_cancel
  def on_skill_cancel
    grid_selector_scb_on_skill_cancel
    $game_temp.grid_arrow.show_indicator(BattleManager.actor)
  end
  
  alias grid_selector_scb_on_item_cancel on_item_cancel
  def on_item_cancel
    grid_selector_scb_on_item_cancel
    $game_temp.grid_arrow.show_indicator(BattleManager.actor)
  end
  
  #---#
  # ? #
  #---#
  alias grid_selector_scb_on_enemy_cancel on_enemy_cancel
  def on_enemy_cancel
    grid_selector_scb_on_enemy_cancel
    $game_temp.grid_arrow.show_indicator(BattleManager.actor)
  end
  
  #--------------------------------------------------------------------------
  # Repair positions at battle start if multiple actors occupy the same position.
  #--------------------------------------------------------------------------
  def fix_actor_positions
    positions = $game_system.party_pos
    while positions.detect{|e| positions.count(e) > 1} != nil
      rpt = positions.detect{|e| positions.count(e) > 1}
      positions[positions.index(rpt)] = adjacent_pos(rpt)
    end
  end
  
  #--------------------------------------------------------------------------
  # Return a position adjacent to the specified origin.
  #--------------------------------------------------------------------------
  def adjacent_pos(origin)
    area = (Grid.cross_shape(origin,1) - [origin]).reverse!
    area.each {|p| return p if !$game_system.party_pos.include?(p)}
  end

end

#==============================================================================
# ** Window_BattleStatus
#==============================================================================
class Window_Selectable < Window_Base
  
  #--------------------------------------------------------------------------
  # Called when the Grid cursor becomes active.
  #--------------------------------------------------------------------------
  def init_battle_menu
    @blocked = false
    @grid_arrow = $game_temp.grid_arrow
    @help_window = SceneManager.scene.help_window#Window_Help.new(2) ##
#~     @help_window.x = 128 #64
#~     @help_window.width = Graphics.width-128 #64
    @help_window.arrows_visible = false
    reset_cursor
    @selectable_region = nil
  end

  #--------------------------------------------------------------------------
  # Reset cursor attributes. 
  #--------------------------------------------------------------------------
  def reset_cursor
    Grid.hide_grid
    @escaping = false
    @blocked = false
    @help_window.hide if SceneManager.scene.actor_command_window.active
    @grid_arrow.hide_arrow
    @range_type = nil
    @range_item = nil
    @area_type = nil
    @area_size = nil
    @row_block = false
    #@total_range_region = nil
    @selectable_region = nil
    @position_selectable = false
    @restrict = [false,false,false] #areabound, allies, enemies
    @self_only = false
    @not_self = false
    @dead_only = false
    normal_enemy_color
    normal_actor_color
    $game_temp.grid[1] = [11]
    if BattleManager.actor && !SceneManager.scene.actor_window.active
      $game_temp.grid_arrow.show_indicator(BattleManager.actor)
    end
  end  
  
  #--------------------------------------------------------------------------
  # Process to highlight selected unit(s) on the Order Bar to the left.
  #--------------------------------------------------------------------------
  def check_targeting
    targs = []; pos = $game_temp.grid.dup
    return if pos[1].compact.empty?
    pos[1].each {|sq| targs.push(pos[0][sq].get_unit) if pos[0][sq].get_unit != nil}
    targs.size==1 ?OrderManager.select(targs[0]): OrderManager.select_m(targs)
  end
  
  #--------------------------------------------------------------------------
  # Check for player input. Called while the grid is active.
  #--------------------------------------------------------------------------
  def check_input
    @last_index = $game_temp.grid[1][0]
    grid_down  if Input.repeat?(:DOWN)
    grid_left  if Input.repeat?(:LEFT)
    grid_right if Input.repeat?(:RIGHT)
    grid_up    if Input.repeat?(:UP)
#~     check_escape if escapable && Input.trigger?(:RIGHT) 
    if @last_index != $game_temp.grid[1][0]
     # msgbox_p(OrderManager.current_unit)
     #msgbox_p($data_skills[17].SceneManager.scene.stiff_time(OrderManager.current_unit))
#      SceneManager.scene.update_forecast
      #$game_temp.grid[0][$game_temp.grid[1][0]].get_unit.animation_id = 86 unless $game_temp.grid[0][$game_temp.grid[1][0]].get_unit.nil?
      make_area_field($game_temp.grid[1][0]) if !static_area?
      Grid::GridSound.play 
      check_targeting
      @grid_arrow.update_position 
      set_help_window
      special_indicators
      blink_selected_units unless moving_skill? || @blocked
      for i in 0...$game_temp.grid[0].size
        $game_temp.grid[0][i].unlight unless $game_temp.grid[1].include?(i)
      end      
    end
  end
  
  def escapable
    return false if BattleManager.can_escape? == false
    if Grid::EdgeRight.include?(@last_index) && @range_type == :move_select
      if Grid::EdgeRight.include?(BattleManager.actor.position)
        return true
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: set_help_window
  #--------------------------------------------------------------------------
  def set_help_window
    if !SceneManager.scene.mix_window.selected_items.empty? #actor.current_action && actor.current_action.mixed_item
      combo = SceneManager.scene.mix_window.selected_items
      if $game_system.has_formula?(combo)
        set_help_with_target(BattleManager.actor.input.item)
      else
        icon_a = '\i[' + $data_items[combo[0]].icon_index.to_s + ']'
        desc_a = $data_items[combo[0]].name
        icon_b = '\i[' + $data_items[combo[1]].icon_index.to_s + ']'
        desc_b = $data_items[combo[1]].name
        target = $game_temp.grid[0][$game_temp.grid[1][0]].get_unit
        if target 
          state_icons = []
          target.states.each {|state| state_icons.push("\\i[#{state.icon_index}]")}
          state_icons.delete('\i[0]')
          target = '  \i[198]  \c[1]'+target.name if target.is_a?(Game_Actor) 
          target = '  \i[199]  \c[2]'+target.name if target.is_a?(Game_Enemy) 
          if !state_icons.empty?
            target += "  ("
            state_icons.each {|icon_string| target += icon_string}
            target += ")"
          end
        else
          target = ""
        end
        col = BattleManager.actor.input.item.for_friend? ? '\c[1]' : '\c[2]' 
        @help_window.set_text(('\i[454] ' + col + "Unknown" + '\c[0]' + 
                              target + "\n" + "" + 
                              '\c[0]' + icon_a + desc_a + " + " + icon_b + desc_b))
      end
    else
      set_help_with_target(BattleManager.actor.input.item)
    end
  end

  def set_help_with_target(item)
    icon = '\i[' + item.icon_index.to_s + '] '
    col = BattleManager.actor.input.item.for_friend? ? '\c[1]' : '\c[2]' 
    name = col + item.name + '\c[0]'
    desc = item.description
    target = $game_temp.grid[0][$game_temp.grid[1][0]].get_unit rescue nil
    if target && $game_temp.grid[1].size == 1
      state_icons = []
      target.states.each {|state| state_icons.push("\\i[#{state.icon_index}]")}
      state_icons.delete('\i[0]')
      target = '  \i[198]  \c[1]'+target.name if target.is_a?(Game_Actor) 
      target = '  \i[199]  \c[2]'+target.name if target.is_a?(Game_Enemy) 
      if !state_icons.empty?
        target += "  ("
        state_icons.each {|icon_string| target += icon_string}
        target += ")"
      end
    elsif units_in_area($game_temp.grid[1]).size >= 1
      affected = units_in_area($game_temp.grid[1]).dup
      array_name = []
      array_side = []
      affected.each {|targ| array_name.push(targ.name)}
      affected.each {|targ| array_side.push(targ.is_a?(Game_Actor))}
      target = '  \i[198]  \c[1]' if affected.size > 0
      for i in 0...array_name.size
        target += ", " if i > 0
        target += array_side[i] ? '\c[1]' : '\c[2]'
        target += array_name[i]
      end
    else
      target = ""
    end    
    item_text = icon + name + target + "\n" + '\c[0]' + desc
    @help_window.set_text(item_text)
  end
  #--------------------------------------------------------------------------
  # Return whether the area should be updated on move (Single target fields).
  #--------------------------------------------------------------------------
  def static_area?
    return true if @position_selectable
    return true if @range_type == :single_attack
    return true if @range_type == :limited_gun_row
    return true if @range_type == :potion_range
    return false
  end
  
  def no_ally_show?
    return true if BattleManager.actor.input.item.for_opponent?
    return true if @range_type == :single_ally
    return true if @range_type == :potion_range
    return true if @range_type == :potion_salve
    return true if @self_only
    return false
  end
  
#~   #--------------------------------------------------------------------------
#~   # Return whether the skill includes a GridArrow on the origin.
#~   #--------------------------------------------------------------------------
#~   def no_pointer?
#~     return true if @no_pointer
#~     return true if Grid::NoPointers.include?(@range_type)
#~     return false
#~   end
  
  #--------------------------------------------------------------------------
  # Return whether the skill includes selectable movement of an actor.
  #--------------------------------------------------------------------------
  def moving_skill?
    return true if @range_type == :move_select
    return true if @range_type == :guard
    return false
  end
  
  def swap_skill?
    return true if @range_type == :swap_select
  end
  
  def not_self?
    return true if swap_skill?
    return true if @not_self
  end
  
  # *not used
  def select_single(g_index)
    unit = $game_temp.grid[0][g_index].get_unit
    if unit.is_a?(Game_Enemy)
      index = $game_troop.alive_members.index(unit)
    elsif unit.is_a?(Game_Actor)
      index = $game_party.battle_members.index(unit)
    end
    if index == nil
      select(0)
      return 0 
    end
    if @selectable_region != nil && @selectable_region.include?(index)
      $game_temp.grid[1] = [index]
    else
      $game_temp.grid[1] = [rand(0..Grid::MaxCol/2)+rand(0...Grid::MaxCol/2)*8]
    end
    select(index)
  end
  
  #--------------------------------------------------------------------------
  # Return the position of the closest enemy within the selectable region.
  #--------------------------------------------------------------------------
  def get_closest_enemy(origin)
    for i in 0...@selectable_region.size
      if $game_temp.grid[0][@selectable_region[i]].get_unit.is_a?(Game_Enemy)
        return @selectable_region[i]
      end
    end
    return @selectable_region[0] unless @selectable_region[0].nil?
    return -1
  end
  
  #--------------------------------------------------------------------------
  # Auto-select the origin of the most efficient location for an area attack.
  #--------------------------------------------------------------------------
  def get_optimal_origin(selectable,atype,a_size = 1)
    return BattleManager.actor.last_position if selectable.empty?
    num_in_ori = []
    case atype
    when :cross
      amethod = Grid.method(:cross_shape)
    when :x
      amethod = Grid.method(:x_shape)
    when :expand
      amethod = Grid.method(:expand_search)
    when :row
      amethod = Grid.method(:horizontal)
    when :row_back
      amethod = Grid.method(:row_back)
    when :col
      amethod = Grid.method(:vertical)
    end
    selectable.each {|ori| num_in_ori << num_enemies_in(amethod.call(ori,a_size))}
    return selectable[num_in_ori.index(num_in_ori.max)]
  end
  
  #--------------------------------------------------------------------------
  # Determines the number of enemies in a target area.
  #--------------------------------------------------------------------------
  def num_enemies_in(area)
    enemies = []
    for i in 0...area.size
      if $game_temp.grid[0][area[i]].get_unit.is_a?(Game_Enemy)
        enemies.push($game_temp.grid[0][area[i]].get_unit)
      end
    end
    enemies.uniq!
    return enemies.size
  end
  
#~   #--------------------------------------------------------------------------
#~   # * Square Manipulation ^
#~   #--------------------------------------------------------------------------
#~   # Alter the opacity of squares on the grid.
#~   def show_actor_squares
#~     $game_temp.grid[0].each {|grid| grid.show if grid.get_unit.is_a?(Game_Actor)}
#~   end
#~   def show_enemy_squares
#~     $game_temp.grid[0].each {|grid| grid.show if grid.get_unit.is_a?(Game_Enemy)}
#~   end
#~   #--------------------------------------------------------------------------
#~   # Lower the opacity of all squares on the grid. Called on reset.
#~   #--------------------------------------------------------------------------
#~   def hide_grid
#~     $game_temp.grid[0].each {|sq| sq.hide; sq.unlight}
#~   end
#~   def hide_outside_region(r)
#~     $game_temp.grid[0].each_with_index {|s,i| s.hide_outside if !r.include?(i)}
#~   end
  #--------------------------------------------------------------------------
  # Show the squares within the region in which a character can move.
  #--------------------------------------------------------------------------
  def show_movable_region
    grd = $game_temp.grid[0]
    for g in 0...$game_temp.grid[0].size
      grd[g].show if @selectable_region.include?(g) unless grd[g].get_unit != nil
    end
  end
  
  #--------------------------------------------------------------------------
  # Show the squares within the region in which a character can swap.
  #--------------------------------------------------------------------------
  def show_swappable_region
    grd = $game_temp.grid[0]
    for g in 0...$game_temp.grid[0].size
      grd[g].show if @selectable_region.include?(g) unless g == @selectable_region[0]
    end
  end
  
  #--------------------------------------------------------------------------
  # Show the squares within the selectable region for range-limited actions.
  #--------------------------------------------------------------------------
  def show_selectable_region
    for g in 0...$game_temp.grid[0].size
      $game_temp.grid[0][g].show_less if @selectable_region.include?(g)
    end
    #@total_range_region.each do |tile| 
    #  $game_temp.grid[0][tile].show_faint unless @selectable_region.include?(tile)
    #end
  end
  
  #--------------------------------------------------------------------------
  # Highlight the squares to indicate the area of effect of the action.
  #--------------------------------------------------------------------------
  def light_selected_region
#    $game_temp.grid[0][$game_temp.grid[1][0]].show_more unless moving_skill? || swap_skill? || no_pointer?
    for i in 0...$game_temp.grid[1].size
      next unless $game_temp.grid[1][i]
      $game_temp.grid[0][$game_temp.grid[1][i]].light unless $game_temp.grid[1][i] == -1
    end
  end
  
  #--------------------------------------------------------------------------
  # Add a state that darkens the tone of the actor for visual indications.
  #--------------------------------------------------------------------------
  def grey_actor_color
    $game_party.battle_members.each {|mem| mem == BattleManager.actor ? mem.add_new_state(1) : mem.add_new_state(2)}
  end
  
  #--------------------------------------------------------------------------
  # Add a state that darkens the tone of the enemy for visual indications.
  #--------------------------------------------------------------------------
  def grey_enemy_color
    $game_troop.alive_members.each do |mem| 
      inRegion = false
      @selectable_region.each {|sq| inRegion = true if $game_temp.grid[0][sq].get_unit} if @selectable_region != nil
      mem.add_new_state(2) if !inRegion
    end
  end
  
  def normal_actor_color
    $game_party.battle_members.each {|mem| mem.remove_state(2);mem.remove_state(1)}
  end
  def normal_enemy_color
    $game_troop.alive_members.each {|mem| mem.remove_state(2); mem.remove_state(1)}
  end
  
  #--------------------------------------------------------------------------
  # Add a periodic flash onto targets currently within the area region.
  #--------------------------------------------------------------------------
  def blink_selected_units
    $game_party.battle_members.each {|mem| mem.remove_state(1)}
    $game_troop.alive_members.each {|mem| mem.remove_state(1)}
    $game_temp.grid[1].each do |index|
      break unless index
      if $game_temp.grid[0][index].get_unit != nil
        $game_temp.grid[0][index].get_unit.add_new_state(1)
      end
    end
    BattleManager.actor.add_new_state(1) if swap_skill?
  end

  def special_indicators
    return unless @range_type == :guard
    row = []
    
  end
  
  #--------------------------------------------------------------------------
  # ● Grid Movement Methods
  #--------------------------------------------------------------------------
  # Move the anchor of the cursor if boundary conditions are met.
  #--------------------------------------------------------------------------
  def grid_down
    if (empty_selection? || atBtmBound || atBtmEdge)
      Grid::GridError.play if Input.trigger?(:DOWN) && !@restrict[0]; return; end
    $game_temp.grid[1][0] += 8
    #msgbox_p(SceneManager.scene.mix_window.selected_items)
  end
  def grid_up
    if (empty_selection? || atTopBound || atTopEdge)
      Grid::GridError.play if Input.trigger?(:UP) && !@restrict[0]; return; end
    $game_temp.grid[1][0] -= 8
  end
  def grid_right
    if !empty_selection? && atRightEdge && Input.trigger?(:RIGHT)
      if [7,15,23,31].include?(BattleManager.actor.position)
        SceneManager.scene.open_escape_window
        return
      end
    end
    if (empty_selection? || atRightBound || atRightEdge)
      Grid::GridError.play if Input.trigger?(:RIGHT) && !@restrict[0]
      return
    end
    $game_temp.grid[1][0] += 1
  end
  def grid_left
    if (empty_selection? || atLeftBound || atLeftEdge)
      Grid::GridError.play if Input.trigger?(:LEFT) && !@restrict[0]
      return
    end
    $game_temp.grid[1][0] -= 1
  end
  #--------------------------------------------------------------------------
  # ● Boundary Checks
  #--------------------------------------------------------------------------
  # Determines whether the anchor point is at the edge of the grid boundaries.
  #--------------------------------------------------------------------------
  def empty_selection?
    return $game_temp.grid[1].compact.empty?
  end

  def atLeftBound
    return true if $game_temp.grid[1].any? {|pos| Grid.left_edge.include?(pos)} if @restrict[1]
    $game_temp.grid[1].each {|pos| return true if [0,8,16,24].include?(pos)} if @restrict[0]
    front = $game_temp.grid[0][$game_temp.grid[1][0]].get_unit
    if front != nil && @row_block #@range_type == :limited_gun_row
      return true unless $game_temp.grid[0][$game_temp.grid[1][0]-1].get_unit == front
    end
    return false
  end
  def atRightBound  
    return true if $game_temp.grid[1].any? {|pos| Grid.right_edge.include?(pos)} if @restrict[2]
    $game_temp.grid[1].each {|pos| return true if [7,15,23,31].include?(pos)} if @restrict[0]
    return true if [3,11,19,27].include?($game_temp.grid[1][0]) && @restrict[2] #enemies
    return false
  end
  def atBtmBound
    return true if $game_temp.grid[1].any? {|pos| (24..31).include?(pos)} if @restrict[0]
    return true if $game_temp.grid[1][0] >= Grid::MaxCol*(Grid::MaxRow-1)
    return false
  end
  def atTopBound
    return true if $game_temp.grid[1].any? {|pos| (0..7).include?(pos)} if @restrict[0]
    return true if $game_temp.grid[1][0] < Grid::MaxCol
    return false
  end
  
  #--------------------------------------------------------------------------
  # Determines whether the anchor point is within the selectable region.
  #--------------------------------------------------------------------------
  def atLeftEdge
    return true if Grid::EdgeLeft.include?($game_temp.grid[1][0])
    return false if @selectable_region == nil
    return true if !@selectable_region.include?($game_temp.grid[1][0]-1)
    return false 
  end
  def atRightEdge
    return true if Grid::EdgeRight.include?($game_temp.grid[1][0])
    return false if @selectable_region == nil
    return true if !@selectable_region.include?($game_temp.grid[1][0]+1)
    return false 
  end
  def atTopEdge
    return true if Grid::EdgeTop.include?($game_temp.grid[1][0])
    return false if @selectable_region == nil
    return true if !@selectable_region.include?($game_temp.grid[1][0]-Grid::MaxCol)
    return false 
  end
  def atBtmEdge
    return true if Grid::EdgeBtm.include?($game_temp.grid[1][0])
    return false if @selectable_region == nil
    return true if !@selectable_region.include?($game_temp.grid[1][0]+Grid::MaxCol)
    return false
  end

end

#==============================================================================
# ** Window_BattleActor
#==============================================================================
class Window_BattleActor < Window_BattleStatus
  alias grid_selector_wba_initialize initialize
  def initialize(info_viewport)
    grid_selector_wba_initialize(info_viewport)
    init_battle_menu
  end
  
  def dispose
    contents.dispose unless disposed?
    @help_window.dispose
    super
  end
  
  #--------------------------------------------------------------------------
  # Called by the superclass on every frame. 
  #--------------------------------------------------------------------------
  def update
    super
    return if @escaping
    if self.active 
      check_field if @range_type == nil 
      @grid_arrow.update_index if @grid_arrow.opacity > 0
      update_squares
      check_input
      light_selected_region
    end
  end
  
  #--------------------------------------------------------------------------
  # Method overwrite: process_handling
  #--------------------------------------------------------------------------
  def process_handling
    return unless open? && active
    return process_ok     if Input.trigger?(:C)
    return process_cancel if cancel_enabled? && Input.trigger?(:B)
  end
  
  #--------------------------------------------------------------------------
  # Method overwrite: ok_enabled?. Checks whether the current origin is valid.
  #--------------------------------------------------------------------------
  def ok_enabled?     
    return false if empty_selection? || @blocked == true
    for i in 0...$game_temp.grid[1].size
      unit = $game_temp.grid[0][$game_temp.grid[1][i]].get_unit
      if unit.is_a?(Game_Battler)
        return false if @self_only && unit != BattleManager.actor
        return false if not_self? && $game_temp.grid[1][0] == @selectable_region[0]
        return false if @dead_only && !unit.state?(31)
        return false if @alive_only && $game_temp.grid[1].none?{|tile| $game_temp.grid[0][tile].get_unit && $game_temp.grid[0][tile].get_unit.alive?}
        return false if @position_selectable unless !not_self? && unit == BattleManager.actor
        return true if BattleManager.actor.input.item.for_friend? && unit.is_a?(Game_Actor)
        return true if BattleManager.actor.input.item.for_opponent? && unit.is_a?(Game_Enemy)
        #return true if !moving_skill?
      else
        return true if @position_selectable
      end
    end
    return false
  end

  #--------------------------------------------------------------------------
  # Method overwrite: process_ok. Called when confirming a selected position.
  #--------------------------------------------------------------------------
  def process_ok#
    if ok_enabled?
      BattleManager.actor.last_sel_region = @selectable_region
      Sound.play_ok if $game_temp.grid[1].size == 1
      Grid::GridConfirm.play if $game_temp.grid[1].size > 1
      Input.update
      deactivate
      $game_temp.huds.each {|x| x.hide unless x == nil} #ank
      call_ok_handler
      reset_cursor
    else
      Sound.play_buzzer
    end
  end
  
  #--------------------------------------------------------------------------
  # Method overwrite: process_cancel. Called when escaping targeting window.
  #--------------------------------------------------------------------------
  def process_cancel
    Sound.play_cancel
    Input.update
    deactivate
    call_cancel_handler
    reset_cursor
  end
  
  #--------------------------------------------------------------------------
  # Sets up the selectable region of the item and prepares grid targeting.
  #--------------------------------------------------------------------------
  def check_field
    reset_cursor
    subject = BattleManager.actor
    item    = subject.input.item
    scopes  = item.scopes
    @range_type = scopes[:range_type]
    @range_item = scopes[:range]
    @area_type  = scopes[:area_type] ? scopes[:area_type] : :single
    @area_size  = scopes[:area_size]
    e_array = $game_temp.grid[0].collect {|tile| tile.get_unit}
    origin = subject.last_position
    #CHECK RESTRICTIONS
    @item_range = 0 if scopes[:target_conditions].include?(:self_only)
    @selectable_region = Grid.base_region(origin,@range_type,@range_item,@area_type,@area_size)
    scopes[:target_conditions].each {|condition|
      case condition
      when :position_selectable
        @position_selectable = true
      when :self_only
        @self_only = true
      when :not_self
        @not_self = true
      when :dead_only
        @dead_only = true
      when :alive_only
        @alive_only = true
      when :no_cursor
        @no_cursor = true
      when :edge_limited
        @restrict[0] = true
      when :row_block
        @row_block = true
        greyout_blockers
      when :front_only
        @selectable_region = cut_behind(@selectable_region)
      end
    } #~ each condition
    if scopes[:target_conditions].include?(:team_unlimited)
      @restrict[1] = true if item.for_friend?
      @restrict[2] = true if item.for_opponent?
    else
      #@total_range_region = @selectable_region.dup
      @selectable_region -= Grid.ally_spaces  if item.for_opponent?
      @selectable_region -= Grid.enemy_spaces if item.for_friend?
    end
    @restrict[1] = true if @range_type == :allies
    @restrict[2] = true if @range_type == :enemies
    #Change "origin" to enemy position if for enemy
    if item.for_opponent?
      origin = @selectable_region[0]
      @selectable_region.each do |tile| 
        origin = tile ; break if $game_temp.grid[0][tile].get_unit
      end
    end
    optimal_types = [:row,:col,:expand,:cross,:x,:row_back]
    if optimal_types.include?(@area_type) && item.for_opponent?
      origin = get_optimal_origin(@selectable_region,@area_type,@area_size)
    end
    Grid.hide_outside_region(@selectable_region)
    make_area_field(origin)
    check_targeting
    blink_selected_units
    @grid_arrow.hide_indicator
    @help_window.show
    set_help_window
    @grid_arrow.show_arrow unless @no_cursor
  end
  
  #--------------------------------------------------------------------------
  # Given the anchor point of the area, create the area of effect of the action.
  #--------------------------------------------------------------------------
  def make_area_field(origin)
    case @area_type
    when :single
      $game_temp.grid[1] = [origin]
    when :cross
      $game_temp.grid[1] = Grid.cross_shape(origin,@area_size)
    when :x
      $game_temp.grid[1] = Grid.x_shape(origin,@area_size)
    when :expand
      $game_temp.grid[1] = Grid.expand_search(origin,@area_size)
    when :row
      $game_temp.grid[1] = Grid.linear(origin,[4,6],@area_size)
      $game_temp.grid[1].reverse_each {|pos| $game_temp.grid[1].delete(pos) unless @selectable_region.include?(pos)} if @restrict[1] || @restrict[2]
    when :row_back
      $game_temp.grid[1] = Grid.linear(origin,[4],@area_size)
    when :col
      $game_temp.grid[1] = Grid.linear(origin,[2,8],@area_size)
    end
  end  
  
  #--------------------------------------------------------------------------
  # Sets the origin of an attack to either the closest enemy, or the last target.
  #--------------------------------------------------------------------------
  def set_origin(origin)
    included = @selectable_region.include?(BattleManager.actor.last_origin)
    if $game_switches[Grid::MemorySwitch] && included && !$game_temp.grid[0][BattleManager.actor.last_origin].get_unit.nil?
      $game_temp.grid[1] = [BattleManager.actor.last_origin]
    else
      $game_temp.grid[1] = [get_closest_enemy(origin)]
    end        
  end
  #--------------------------------------------------------------------------
  # Adds a state to change the colour of targets obstructing a linear action.
  #--------------------------------------------------------------------------
  def greyout_blockers
    cut_behind(@selectable_region).each do |spc|
      if $game_temp.grid[0][spc].get_unit.is_a?(Game_Actor) && $game_temp.grid[0][spc].get_unit != BattleManager.actor
        @blocked = true unless $game_temp.grid[0][spc].get_unit.dead?
        $game_temp.grid[0][spc].get_unit.add_new_state(2)
      end
    end
  end
  #--------------------------------------------------------------------------
  # Intended for use with ROW ONLY target areas. Removes targets behind actor.
  #--------------------------------------------------------------------------
  def cut_behind(area)
    area.delete_if {|x| x >= BattleManager.actor.last_position}
    return area
  end
  #--------------------------------------------------------------------------
  # * Square Manipulation ^
  #--------------------------------------------------------------------------
  # Called every frame to update the graphics of squares on the grid.
  #--------------------------------------------------------------------------
  def update_squares
    if @position_selectable == true && @selectable_region == nil
      show_empty_spaces
    elsif @selectable_region != nil
      if moving_skill?
        show_movable_region
      elsif swap_skill?
        show_swappable_region
      else
        show_selectable_region
        #show_actor_squares unless no_ally_show?
      end
    else
      Grid.show_actor_squares unless no_ally_show?
    end
  end
  
  #--------------------------------------------------------------------------
  # Show the squares that may be selected for actions which target empty spaces.
  #--------------------------------------------------------------------------
  def show_empty_spaces
    $game_temp.grid[0].each do |grid|
      grid.show if !grid.get_unit.is_a?(Game_Battler) && Grid.ally_spaces.include?($game_temp.grid[0].index(grid))
    end
  end
  
  def process_cursor_move #Remove method's function
  end
end 

#==============================================================================
# ** GridArrow
#==============================================================================
class GridArrow < Sprite
  def initialize(index, viewport)
    super(viewport)
    @index = 1
#~     self.x = Grid::GridPlaces[4][0]
#~     self.y = Grid::GridPlaces[4][1]
    self.x = Grid.grid_places(4,0)
    self.y = Grid.grid_places(4,1)
    self.bitmap = Cache.rvkd("GridArrow#{@index}")
  end
  
  
  alias sprite_update_grid update
  def update
    sprite_update_grid
    self.update_index if self.opacity > 0
  end
  
  #--------------------------------------------------------------------------
  # Called from BattleActor or BattleEnemy.
  #--------------------------------------------------------------------------
  def show_arrow
    return if $game_temp.grid[1][0] == -1
    self.opacity = 185
    update_position
  end
  
  #--------------------------------------------------------------------------
  # Called from BattleActor or BattleEnemy.
  #--------------------------------------------------------------------------
  def hide_arrow
    self.opacity = 0
  end
  
  #--------------------------------------------------------------------------
  # Called every frame from BattleActor or BattleEnemy. Updates the image.
  #--------------------------------------------------------------------------
  def update_index
    @index += 1
    @index = 1 if @index > 36
    self.bitmap = Cache.rvkd("GridArrow#{@index/6}") if @index % 6 == 0
  end
  #--------------------------------------------------------------------------
  # Adjusts the position of the arrow.
  #--------------------------------------------------------------------------
  def update_position
    self.x = Grid.position($game_temp.grid[1][0],0)-17
    self.y = Grid.position($game_temp.grid[1][0],1)-58
#~     self.x = Grid::Position[$game_temp.grid[1][0]][0]-17
#~     self.y = Grid::Position[$game_temp.grid[1][0]][1]-58
  end
  #--------------------------------------------------------------------------
  # Shows an arrow above the actor inputting a command. Called from HUD.
  #--------------------------------------------------------------------------
  def show_indicator(a)
    if self.opacity == 185
      update_index
      return
    end
    @lastIndicator = a.id-1
    self.opacity = 185
    $game_temp.grid[0][a.last_position].light
    $game_temp.grid[0][a.last_position].show
    self.x = Grid.position(a.last_position,0)-17
    self.y = Grid.position(a.last_position,1)-58
#~     self.x = Grid::Position[a.last_position][0]-17
#~     self.y = Grid::Position[a.last_position][1]-58
  end
  
  def hide_indicator
    unlight_indicator
    hide_arrow
  end
  def unlight_indicator
    $game_temp.grid[0][@lastIndicator].unlight
  end
end

#==============================================================================
# ** GridSelector
#==============================================================================
class GridSelector < Sprite_Battler #Sprite
  
  def initialize(index, ally, viewport)# = nil)
    super(viewport)
    @allied = ally
    @hidden = true
    @position = Grid::GridPlaces.index(index)
    @opa_mod = 0#@position % 8 < 4 ? 40 : 0
    @color_mods = []
    self.z = 2
    self.x = index[0]
    self.y = index[1] + Grid::ShiftY
    self.bitmap = Cache.rvkd("G#{@position}")
    @static_target = GridIndicator.new(@position,viewport)
    @static_target.x = self.x
    @static_target.y = self.y
    @target_bubble = Sprite.new(viewport)
    @target_bubble.x = self.x
    @target_bubble.y = self.y
    @target_bubble.z = 4
    reset_target
    reset_bubble
  end
  #--------------------------------------------------------------------------
  # Set the tile to contain the specified BattleUnit.
  #--------------------------------------------------------------------------
  def set_unit(obj)
    @unit = obj
  end
  def set_team(a)
    @allied = a
  end
  def clear_team
    @allied = nil
  end
  #--------------------------------------------------------------------------
  # Return the BattleUnit contained within the tile.
  #--------------------------------------------------------------------------
  def get_unit
    return @unit
  end
  #--------------------------------------------------------------------------
  # Removes the BattleUnit contained in the tile.
  #--------------------------------------------------------------------------
  def remove_unit
    @unit = nil
  end
  
  def ally?
    return @allied
  end
  
  def light
    #self.bitmap = Cache.rvkd("G#{@position}L")
    @target_bubble.bitmap = Cache.rvkd("GL#{@position}")
    @target_bubble.opacity = 195
    #self.tone = Tone.new(255,255,255)
  end
  def unlight
    #self.bitmap = Cache.rvkd("G#{@position}")
    @target_bubble.bitmap = nil
    @target_bubble.opacity = 0
    #self.tone = Tone.new#(255,255,255)
  end
  
  def green
    set_mod(:red_projection)
    $game_temp.indicators.push(@static_target)
    #@target_bubble.bitmap = Cache.rvkd("G#{@position}I")
    #self.bitmap = Cache.rvkd("G#{@position}I")
  end
  
  def hide
    default_hidden
    if !@color_mods.empty?
      apply_mod
    else
      reset_target
    end
    @hidden = true
  end
  def show
    self.opacity = 215 + $game_variables[Grid::OpacityVar] / 2
    @hidden = false
  end
  def show_more
    self.opacity = @opa_mod/2 + [self.opacity,180+$game_variables[Grid::OpacityVar]/2].max
    @hidden = false
  end
  def show_less
    self.opacity = @opa_mod + 120 + $game_variables[Grid::OpacityVar] / 2
    @hidden = false
  end
  def show_faint
    self.opacity = @opa_mod + 120 + $game_variables[Grid::OpacityVar] / 2
#~     self.tone = ally? ? Tone.new(-40,60,200) : Tone.new(255,-155,-145)
    self.color = @allied ? Color.new(128,128,224,128) : Color.new(224,128,128,128)
    @hidden = false
  end
  AllyTone    = Tone.new(-140,10,255)
  EnemyTone   = Tone.new(255,-130,-110)
  NeutralTone = Tone.new(180,60,200)
  def hidden_opacity
    self.opacity = 40 + $game_variables[Grid::OpacityVar]
  end
  
  def hide_outside
    self.opacity = 20 + $game_variables[Grid::OpacityVar]
    self.color = Color.new(50,50,50,50)#(0,0,0)
  end
  
  def default_hidden
    hidden_opacity
    self.color = Color.new(0,0,0,0)#(0,0,0)
    self.tone = Grid::AllyTone    if ally? == true
    self.tone = Grid::EnemyTone   if ally? == false
    self.tone = Grid::NeutralTone if ally? == nil
#~     if ally? == nil
#~       self.bitmap.gradient_fill_rect(0,0,100,100,Color.new(255,-130,-110,200),Color.new(-140,10,255,200))
#~     end
  end
  
  def reset_bubble
    @target_bubble.bitmap = nil
  end
  
  def reset_target
    @static_target.bitmap = nil
  end
  
  def apply_mod
    return if @color_mods.empty?
    case @color_mods.last
    when :red_projection
      #@static_target.bitmap = Cache.rvkd("GC2_#{@position}")
      @static_target.tone = Tone.new(255,-140,-180)
      #self.tone = ally? ? Tone.new(-160,-20,215) : Tone.new(120,-60,220)
    when :blue_projection
      #@static_target.bitmap = Cache.rvkd("GC2_#{@position}")
      @static_target.tone = Tone.new(-30,120,255)
    end
    @static_target.opacity = 60 + $game_variables[Grid::OpacityVar] / 2
  end
  
  def set_mod(type)
    @color_mods.push(type)
    apply_mod
  end
  
  def clear_mod
    @color_mods.pop unless @color_mods.empty?
    unlight
    hide
    if @color_mods.empty?
      #@static_target = 
      $game_temp.indicators.delete(@static_target)
      @static_target.opacity = 60 + $game_variables[Grid::OpacityVar] / 2
      @static_target.set_frame(1)
      $game_temp.fading_indicators.push(@static_target)
    end
  end
  
  def set_indicator_frame(frame)
    @static_target.set_frame(frame)
  end
  
  def indicator
    #msgbox_p("deleted") if @static_target.nil?
    return @static_target
  end
  
  def selector
    return @target_bubble
  end
 
end

class GridIndicator < Sprite
  
  def initialize(position,viewport)
    super(viewport)
    @position = position
    self.opacity = 60 + $game_variables[Grid::OpacityVar] / 2
    self.z = 3
  end
  
#~   def set_indicator
#~     $game_temp.indicators.push(self)
#~   end
#~   
#~   def clear_indicator
#~     $game_temp.indicators.delete(self)
#~   end
#~   
  def set_frame(frame)
    frame = 10 - frame if frame > 5
    frame = 1 if frame == 0
    self.bitmap = Cache.rvkd("GC#{frame}_#{@position}")
  end
  
end

#==============================================================================
# 
# ▼ End of File
# 
#==============================================================================