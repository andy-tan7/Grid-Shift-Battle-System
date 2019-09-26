#===============================================================================
# TheoAllen - Grid Basic Module 
# > For grid battle system
#===============================================================================

module Grid
  MaxRow = 4
  MaxCol = 8
  
  Movement = [1,2,3,4,6,7,8,9] # Don't remove or edit this
  
  AllyTone    = Tone.new(-140,10,255)
  EnemyTone   = Tone.new(255,-130,-110)
  NeutralTone = Tone.new(180,60,200)
    
  def self.position(index, dimension = nil)
    return -1 unless index
    return Position[index][dimension] if dimension == 0
    return Position[index][dimension] + ShiftY if dimension == 1
    p = Position[index].dup
    p[1] += ShiftY
    return p
  end
  def self.grid_places(index, dimension = nil)
    return GridPlaces[index][dimension] if dimension == 0
    return GridPlaces[index][dimension] + ShiftY if dimension == 1
    p = GridPlaces[index].dup
    p[1] += ShiftY
    return p
  end
  
  BaseX = 22
  BaseY = -3
  
  ShiftY = -4#4
  #-----------------------------------------------------------------------------
  # Position based on index
  #-----------------------------------------------------------------------------
  Position = 
[
[ 114+BaseX,122+BaseY],[173+BaseX,122+BaseY],[232+BaseX,122+BaseY],[292+BaseX,122+BaseY],[350+BaseX,122+BaseY],[409+BaseX,122+BaseY],[468+BaseX,122+BaseY],[525+BaseX,122+BaseY],
[ 104+BaseX,170+BaseY],[167+BaseX,170+BaseY],[229+BaseX,170+BaseY],[290+BaseX,170+BaseY],[352+BaseX,170+BaseY],[413+BaseX,170+BaseY],[474+BaseX,170+BaseY],[536+BaseX,170+BaseY],
[ 93+BaseX, 226+BaseY],[159+BaseX,226+BaseY],[224+BaseX,226+BaseY],[289+BaseX,226+BaseY],[353+BaseX,226+BaseY],[419+BaseX,226+BaseY],[483+BaseX,226+BaseY],[547+BaseX,226+BaseY],
[ 81+BaseX, 284+BaseY],[152+BaseX,284+BaseY],[219+BaseX,284+BaseY],[287+BaseX,284+BaseY],[355+BaseX,284+BaseY],[423+BaseX,284+BaseY],[492+BaseX,284+BaseY],[559+BaseX,284+BaseY]
]

  GridPlaces = 
[
[ 83+BaseX,90+BaseY], [143+BaseX,90+BaseY], [203+BaseX,90+BaseY], [262+BaseX,90+BaseY], [321+BaseX,90+BaseY], [378+BaseX,90+BaseY], [435+BaseX,90+BaseY], [492+BaseX,90+BaseY],
[ 72+BaseX,137+BaseY],[134+BaseX,137+BaseY],[196+BaseX,137+BaseY],[259+BaseX,137+BaseY],[321+BaseX,137+BaseY],[381+BaseX,137+BaseY],[441+BaseX,137+BaseY],[500+BaseX,137+BaseY],
[ 59+BaseX,188+BaseY],[125+BaseX,188+BaseY],[190+BaseX,188+BaseY],[256+BaseX,188+BaseY],[321+BaseX,188+BaseY],[384+BaseX,188+BaseY],[447+BaseX,188+BaseY],[510+BaseX,188+BaseY],
[ 45+BaseX,244+BaseY],[114+BaseX,244+BaseY],[183+BaseX,244+BaseY],[252+BaseX,244+BaseY],[321+BaseX,244+BaseY],[388+BaseX,244+BaseY],[453+BaseX,244+BaseY],[519+BaseX,244+BaseY]
]

  GridSound   = RPG::SE.new("FEA - Pop2", 85, 100)
  GridTab     = RPG::SE.new("FEA - Pick1", 85, 100)
  GridConfirm = RPG::SE.new("AO - Magic_Foodwing2", 95, 105)
  GridError   = RPG::SE.new("FEA - Error1", 75, 100)
  
  StateLight  = 1
  StateGrey   = 2
  
  
  AllySpaces  = [4,5,6,7,12,13,14,15,20,21,22,23,28,29,30,31]
  EnemySpaces = [0,1,2,3, 8, 9,10,11,16,17,18,19,24,25,26,27]
  
  AllyRows  = [[4,5,6,7],[12,13,14,15],[20,21,22,23],[28,29,30,31]]
  EnemyRows = [[0,1,2,3],[ 8, 9,10,11],[16,17,18,19],[24,25,26,27]]
  BothRows  = [[ 0, 1, 2, 3, 4, 5, 6, 7],
               [ 8, 9,10,11,12,13,14,15],
               [16,17,18,19,20,21,22,23],
               [24,25,26,27,28,29,30,31]]
               
  MiddleFour = [13,14,21,22]          
  
  EdgeTop   = [0,1,2,3,4,5,6,7]
  EdgeLeft  = [0,8,16,24]
  EdgeRight = [7,15,23,31]
  EdgeBtm   = [24,25,26,27,28,29,30,31]
  
  EdgeEnemy = [3,11,19,27]
  EdgeAlly  = [4,12,20,28]
  
  InitialPositions = [13,22,6,7]#[13,22,29,28]

  NoPointers = [:ally_row, :ally_col, :whole_gun_row]

  def self.ally_spaces
#~     return AllySpaces
    f = frontline(true)
    f ||= 7 ; spaces = []
    MaxRow.times {|a| spaces += ((8*a+f)..(8*(a+1)-1)).to_a }
    return spaces
  end
  def self.enemy_spaces
#~     return EnemySpaces
    f = frontline(false)
    f ||= 0 ; spaces = []
    MaxRow.times {|a| spaces += ((8*a)..(f+(8*a))).to_a }
    return spaces
  end
  def self.neutral_spaces
    return BothRows - (ally_spaces + enemy_spaces)
  end
  
  def self.left_edge
    front = frontline
    return [front,front+8,front+16,front+24]
  end
  def self.right_edge
    front = frontline(false)
    return [front,front+8,front+16,front+24]
  end
  
  def self.frontline(allies = true)
    xs = []
    if allies
      return 4 #
      members = $game_party.alive_members
      members.each {|mem| xs.push(mem.position % 8)}
      return xs.min
    else
      return 3 #
      members = $game_troop.alive_members
      members.each {|mem| xs.push(mem.position % 8)}
      return xs.max
    end
  end
  
  def self.grid_row(origin)
    BothRows.each {|row| return row.dup if row.include?(origin)}
  end
  
  def self.ally_row(origin)
    AllyRows.each {|row| return row.dup if row.include?(origin)}
  end
  def self.enemy_row(origin)
    EnemyRows.each {|row| return row.dup if row.include?(origin)}
  end
  def self.get_unit_row(unit)
    grid_units = []
    $game_temp.grid[0].each {|x| grid_units.push(x.get_unit)}
    origin = grid_units.index(unit)
    BothRows.each {|row| return BothRows.dup.index(row) if row.include?(origin)}
  end
  
  def self.repair_cross_edge(origin)
    origin += 1 if EdgeLeft.include?(origin)
    origin -= 1 if EdgeRight.include?(origin)
    origin += MaxCol if EdgeTop.include?(origin)
    origin -= MaxCol if EdgeBtm.include?(origin)
    return origin
  end
  
  def self.enemies_in_range(selectable_region)
    units = []
    selectable_region.each {|tile| units.push($game_temp.grid[0][tile].get_unit)}
    return units
  end

  def self.closest_enemy_on_row(origin)
    for i in 0...BothRows.size
      row = i if BothRows[i].include?(origin)
    end
    BothRows[row].reverse_each do |sq|
      if $game_temp.grid[0][sq].get_unit != nil && $game_temp.grid[0][sq].get_unit.enemy?
        return sq
      end
    end
    poz = BattleManager.actor.last_position
    for i in 0...BothRows.size
      if BothRows[i].include?(poz)
        return EnemyRows[i][3]
      end
    end
    return -1
  end
  


end

#===============================================================================
# * Grid Counting Module
#===============================================================================

class << Grid
  #----------------------------------------------------------------------------
  # * Grid direction rules
  #----------------------------------------------------------------------------
  # 2 = DOWNWARD
  # 4 = FORWARD
  # 6 = BACKWARD
  # 8 = UPWARD
  #
  # 1 = DOWN-LEFT
  # 3 = DOWN-RIGHT
  # 7 = UP-LEFT
  # 9 = UP-RIGHT
  #----------------------------------------------------------------------------
  # * Get neighbor grid
  #----------------------------------------------------------------------------
  def neighbor(index, dir, times = 1)
    if times > 1
      index = neighbor(index, dir, times - 1)
    end
    return nil unless index
    coordinate = index
    coordinate = point(index) unless index.is_a?(Array)
    case dir
    when 2; coordinate[1] += 1  # DOWN
    when 4; coordinate[0] -= 1  # FORWARD
    when 6; coordinate[0] += 1  # BACKWARD
    when 8; coordinate[1] -= 1  # UP
      
    # Diagonal direction
    when 1
      coordinate[0] -= 1
      coordinate[1] += 1
    when 3
      coordinate[0] += 1
      coordinate[1] += 1
    when 7
      coordinate[0] -= 1
      coordinate[1] -= 1
    when 9
      coordinate[0] += 1
      coordinate[1] -= 1
    end
    return cell(*coordinate)
  end
  
  #-----------------------------------------------------------------------------
  # Translate point coordinate [x,y] into Cell Index
  # > Column equal as X axis
  # > Row equal as Y axis
  #-----------------------------------------------------------------------------
  def cell(col, row)
    return nil if out_of_bound?(row, 0, Grid::MaxRow - 1)
    return nil if out_of_bound?(col, 0, Grid::MaxCol - 1)
    return (Grid::MaxCol * row) + col
  end
  
  #-----------------------------------------------------------------------------
  # * Translate cell index into point [x,y]
  #-----------------------------------------------------------------------------
  def point(index)
    return [index % Grid::MaxCol, index / Grid::MaxCol]
  end
  
  #-----------------------------------------------------------------------------
  # * Simply check if the value is out of bound
  #-----------------------------------------------------------------------------
  def out_of_bound?(value, min, max)
    return value > max || value < min
  end
  
  #-----------------------------------------------------------------------------
  # * Max Index
  #-----------------------------------------------------------------------------
  def max_index
    Grid::MaxRow * Grid::MaxCol
  end
  
  #-----------------------------------------------------------------------------
  #                           TARGETING PART!
  #-----------------------------------------------------------------------------
  # * Surrounding grid
  #-----------------------------------------------------------------------------
  def surrounding(index, directions = Grid::Movement, compact = true)
    result = directions.collect {|dir| neighbor(index, dir)} + [index]
    return result.compact.uniq if compact
    return result.uniq
  end
  
  #-----------------------------------------------------------------------------
  # * Spread search. Expand node using BFS iteration
  #-----------------------------------------------------------------------------
  def spread(index, directions = Grid::Movement,limit = 1,compact = true)
    return [] unless index
    return [] if limit < 0
    i = 0
    result = [index]
    iteration = [index]
    until i == limit
      temp_res = []
      iteration.each do |it| 
        cells = surrounding(it, directions, compact)
        cells.delete_if {|c| result.include?(c)}
        temp_res += cells
      end
      temp_res.uniq!
      iteration = temp_res
      result += temp_res
      i += 1
    end
    return result.compact.uniq if compact
    return result.uniq
  end
  
  #-----------------------------------------------------------------------------
  # * Linear repeated search
  #-----------------------------------------------------------------------------
  def linear(index, directions = Grid::Movement,limit = 1,compact = true)
    result = []
    directions.each do |dir|
      result += spread(index, [dir], limit, compact)
    end
    return result.uniq
  end
  
  #-----------------------------------------------------------------------------
  # * Random grid drop
  #-----------------------------------------------------------------------------
  def random_grid(index = nil)
    return rand(max_index) unless index
    result = nil
    result = rand(max_index) until result != index
    return result
  end
  
  #-----------------------------------------------------------------------------
  # * Horizontal line
  #-----------------------------------------------------------------------------
  def horizontal(index, limit = Grid::MaxCol)
    linear(index, [4,6], limit)
  end
  # Custom
  def row_back(index, limit = Grid::MaxCol)
    linear(index, [4], limit)
  end
  
  #-----------------------------------------------------------------------------
  # * Vertical line
  #-----------------------------------------------------------------------------
  def vertical(index, limit = Grid::MaxRow)
    linear(index, [2,8], limit)
  end
  #-----------------------------------------------------------------------------
  # * Eight direction spread
  #-----------------------------------------------------------------------------
  def dir8(index, limit = 1)
    spread(index, [1,2,3,4,6,7,8,9], limit)
  end
  
  #-----------------------------------------------------------------------------
  # * Four direction spread
  #-----------------------------------------------------------------------------
  def dir4(index, limit = 1)
    spread(index, [2,4,6,8], limit)
  end
  
  #-----------------------------------------------------------------------------
  # * X shaped area
  #-----------------------------------------------------------------------------
  def x_shape(index, limit = 1)
    linear(index, [1,3,7,9], limit)
  end
  
  #-----------------------------------------------------------------------------
  # * Cross shaped area
  #-----------------------------------------------------------------------------
  def cross_shape(index, limit = 1)
    linear(index, [2,4,6,8], limit)
  end
  
  #-----------------------------------------------------------------------------
  # * All area
  #-----------------------------------------------------------------------------
  def all_area
    Array.new(Grid::MaxRow * Grid::MaxCol) {|i| i }
  end
  
  #-----------------------------------------------------------------------------
  # * Expand Search (custom)
  #-----------------------------------------------------------------------------
  def expand_search(origin,limit = 2)
    xs = Grid.horizontal(origin,limit) #(11,3) -> [11,10,9,8, 12,13,14]
    incrs = []
    decrs = []
    xs.each do |x|
      incrs.push(x) if x > origin #[12,13,14]
      decrs.push(x) if x < origin #[10,9,8]
    end
    area = [origin]
    area += vertical(origin,limit)
    limit-=1
    for i in 0...incrs.size
      area += (vertical(incrs[i],limit-i))
    end
    for i in 0...decrs.size
      area += (vertical(decrs[i],limit-i))
    end
    return area.uniq!
  end
  
end


#============================================================================
# GRID SHIFT Special Methods
#----------------------------------------------------------------------------
module Grid
  
  #--------------------------------------------------------------------------
  # Called when moving in battle. Updates the position on the grid for the actor.
  #--------------------------------------------------------------------------
  def self.grid_move_a(actor)
    $game_temp.grid[0][actor.position].remove_unit
    $game_system.party_pos[$game_party.battle_members.index(actor)] = actor.current_action.effect_area[0]
    $game_temp.grid[0][actor.current_action.effect_area[0]].set_unit(actor)
  end
  
  def self.grid_move_b(actor,target)
    first_pos = actor.position
    second_pos = actor.last_origin
    first_index = $game_party.battle_members.index(actor)
    second_index = $game_party.battle_members.index(target)
    $game_system.party_pos[$game_party.battle_members.index(actor)] = actor.last_origin
    $game_system.party_pos[$game_party.battle_members.index(target)] = first_pos
    $game_temp.grid[0][first_pos].set_unit(target)
    $game_temp.grid[0][second_pos].set_unit(actor)
  end
  def self.grid_move_forced(actors,positions)
#~     if actors[0].is_a?(Integer)
#~       arr = []; actors.each{|actor| arr.push($game_actors[actor])}
#~       actors = arr;
#~     end
    for i in 0...actors.size
      $game_temp.grid[0][$game_actors[actors[i]].position].remove_unit 
      $game_system.party_pos[$game_party.battle_members.index($game_actors[actors[i]])] = positions[i]
    end
    for i in 0...actors.size
      $game_temp.grid[0][positions[i]].set_unit($game_actors[actors[i]])
    end
  end
  #--------------------------------------------------------------------------
  # Called when moving in battle. Checks if the user moved behind a guarding ally.
  #--------------------------------------------------------------------------
  def self.grid_check_cover(user)
    covered = false
    row = Grid.grid_row(user.position)
    row.delete_if {|a| a >= user.position}
    row.each do |index|
      if $game_temp.grid[0][index].get_unit.is_a?(Game_Actor)
        covered = true if $game_temp.grid[0][index].get_unit.state?(106)
      end
    end
    user.add_state(107) if covered
    # Actors behind guarding allies are also protected.
  end
  #--------------------------------------------------------------------------
  # Called when selecting a position to move to. Determines distance delay.
  #--------------------------------------------------------------------------
  def self.move_delay(unit)
    origin = unit.position
    location = $game_temp.grid[1][0]
    delta = (origin - location).abs
    return 6 if [2,7,9,16].include?(delta)
    return 3
  end
  #--------------------------------------------------------------------------
  # Remove the area behind an actor (for easier selection).
  #--------------------------------------------------------------------------
  def self.ally_cut_behind(origin,area)
    area.delete_if {|x| x >= origin}
    return area
  end

  #--------------------------------------------------------------------------
  # Called by an enemy when determining valid targets for range-limited skills.
  #--------------------------------------------------------------------------
  def self.distance_btwn(subj,targ, row = true, col = true)
    grid_units = []
    $game_temp.grid[0].each {|p| grid_units.push(p.get_unit)}
    s = subj.is_a?(Game_Battler) ? grid_units.rindex(subj) : subj
    t = targ.is_a?(Game_Battler) ? grid_units.rindex(targ) : targ
    dx = (t % Grid::MaxCol - s % Grid::MaxCol).abs
    dy = (t / Grid::MaxCol - s / Grid::MaxCol).abs
    dist = 0; dist += dx if row == true; dist += dy if col == true
    return dist
  end

  #--------------------------------------------------------------------------
  # Returns a boolean to determine whether an actor is behind an ally.
  #--------------------------------------------------------------------------
  def self.cover_btwn(user,targ)
    grid_units = []
    $game_temp.grid[0].each {|x| grid_units.push(x.get_unit)}
    area = Grid::AllyRows[Grid.get_unit_row(targ)].dup
    area.delete_if {|a| a >= grid_units.index(targ)}
    area.each do |square|
      if $game_temp.grid[0][square].get_unit.is_a?(Game_Battler)
        return true if !$game_temp.grid[0][square].get_unit.state?(31)
      end
    end
    return false
  end

  #+------------------------
  #| Enemy Movement methods
  #+------------------------
  # Returns an array the position(s) of a unit (some enemies are large).
  def self.subj_positions(unit)
    positions = []
    $game_temp.grid[0].each do |tile|
      positions.push($game_temp.grid[0].index(tile)) if tile.get_unit == unit
    end
    return positions unless positions.empty?
  end

  #--------------------------------------------------------------------------
  # Returns the coordinate of the middle point of a large unit's occupied tiles.
  #--------------------------------------------------------------------------
  def self.average_x(unit)
    x_positions = []
#~     Grid.subj_positions(unit).each {|p| x_positions.push(Grid::Position[p][0])}
    Grid.subj_positions(unit).each {|p| x_positions.push(Grid.position(p,0))}
    return (x_positions.inject(0){|sum,x| sum + x} / x_positions.size)
  end

  def self.average_y(unit)
    y_positions = []
    mod = 0
    mod = -8 if [142,143,144,145].include?(unit.enemy_id)
#~     Grid.subj_positions(unit).each {|p| y_positions.push(Grid::Position[p][1])}
    Grid.subj_positions(unit).each {|p| y_positions.push(Grid.position(p,1))}
    return (y_positions.inject(0){|sum,y| sum + y} / y_positions.size) + unit.grid_height * 10 + mod
  end

  #--------------------------------------------------------------------------
  # Returns the distance between the unit and the closest actor.
  #--------------------------------------------------------------------------
  def self.closest_target_distance(unit, origin = -1)
    distances = []
    if origin == -1
      $game_party.alive_members.each {|a| distances.push(Grid.distance_btwn(unit,a))}
    else
      $game_party.alive_members.each {|a| distances.push(Grid.distance_btwn(origin,a))}
    end
    return distances.min
  end

  def self.find_closest_targets(unit, origin = -1)
    distances = []
    #if unit.is_a?(Game_Enemy)
      if origin == -1
        $game_party.alive_members.each {|a| distances.push(Grid.distance_btwn(unit,a))}
      else
        $game_party.alive_members.each {|a| distances.push(Grid.distance_btwn(origin,a))}
      end
      min = distances.min
      indices = []
      for i in 0...distances.size
        indices.push(i) if distances[i] == min
      end
      origins = []
      indices.each {|i| origins.push(Grid.index_of_unit($game_party.alive_members[i])) }
      return origins
    #end
    return []
  end
  
  def self.find_opp_origins(unit)
    origins = []
    if unit.is_a?(Game_Enemy)
      $game_party.alive_members.each {|a| origins.push(Grid.index_of_unit(a))}
    end
    return origins
  end
  
  def self.on_same_row?(index1, index2)
    return index1/8 == index2/8
  end
  #--------------------------------------------------------------------------
  # Determines a random valid location for an enemy to move to.
  # Prioritizes the closest tile to an enemy if there are multiple locations.
  #--------------------------------------------------------------------------
  def self.find_move_position(unit, max_range = 2)
    origin = Grid.index_of_unit(unit)
    targets_in_range = 0
    Grid.actor_indices.each {|pos| targets_in_range += 1 if pos <= max_range }
    return origin if targets_in_range > 0
    return nil if Grid.expand_search(origin,max_range) == nil
    possible_locations = Grid.expand_search(origin,max_range) - Grid.ally_spaces
    distances = []; valid_locations = []
    possible_locations.each {|loc| distances.push(Grid.closest_target_distance(loc))} 
    for i in 0...possible_locations.size
      valid_locations.push(possible_locations[i]) if distances[i] == distances.min
    end
    valid_locations.delete_if {|x| !Grid.unit_fits(unit,x)}
    return valid_locations[rand(valid_locations.size)] if !valid_locations.empty?
    possible_locations.delete_if {|x| !Grid.unit_fits(unit,x)}
    possible_locations.delete_if {|x| Grid.closest_target_distance(x) >= Grid.closest_target_distance(origin)}
    return possible_locations[rand(possible_locations.size)] if !possible_locations.empty?
    return origin
  end
  
  #0:either, >=1:yes, <=-1:no;  2:stay on same
  def self.find_edge_position(unit, max_range = 2, keep_dist = [3,3], same_row = 0)
    origin = Grid.index_of_unit(unit)
    possible_locations = Grid.expand_search(origin,max_range) - Grid.ally_spaces
    distances = []; valid_locations = []
    possible_locations.each {|loc| distances.push(Grid.closest_target_distance(loc))}
    enemy_origins = Grid.find_opp_origins(unit)
    same = enemy_origins.select{|x| Grid.on_same_row?(x,origin)}
    same = same.min
    same ||= enemy_origins.sample
    
    for i in 0...possible_locations.size
      if same_row == 2
        if keep_dist[0] == distances[i] && 
          Grid.on_same_row?(possible_locations[i],same)
          valid_locations.push(possible_locations[i])
        end
      elsif same_row == 1
        if keep_dist[0] == distances[i]
          eligible = false
          enemy_origins.each {|x| eligible = true if Grid.on_same_row?(possible_locations[i],x)}
          valid_locations.push(possible_locations[i]) if eligible
        end
      else
        valid_locations.push(possible_locations[i]) if distances[i] == keep_dist[0]
      end
    end
    valid_locations.delete_if {|x| !Grid.unit_fits(unit,x)}
    if valid_locations.size == 0
      for i in 0...possible_locations.size
        if same_row == 2
          if (keep_dist[0]..keep_dist[1]).include?(distances[i]) && 
            Grid.on_same_row?(possible_locations[i],same)
            valid_locations.push(possible_locations[i])
          end
        elsif same_row == 1
          if (keep_dist[0]..keep_dist[1]).include?(distances[i])
            eligible = false
            enemy_origins.each {|x| eligible = true if Grid.on_same_row?(possible_locations[i],x)}
            valid_locations.push(possible_locations[i]) if eligible
          end
        else
          valid_locations.push(possible_locations[i]) if distances[i] == keep_dist[1]
        end
      end
    end
    valid_locations.delete_if {|x| !Grid.unit_fits(unit,x)}
#~     msgbox_p(valid_locations)
    valid_locations.delete_if {|x| x/8 == same/8 && valid_locations.size > 1} if same_row == -1 
#~     valid_locations.delete_if {|x| x/8 != same/8 && valid_locations.size > 1} if same_row >= 1 
#~     valid_locations.delete_if {|x| x/8 != origin/8 && valid_locations.size > 1} if same_row == 2 
#~     msgbox_p(valid_locations)
    return valid_locations[rand(valid_locations.size)] if !valid_locations.empty?
    possible_locations.delete_if {|x| !Grid.unit_fits(unit,x)}
    backup_spots = possible_locations.select{|loc| loc == keep_dist}
    return backup_spots[rand(possible_locations.size)] if !backup_spots.empty?
    return origin
  end
  
  #--------------------------------------------------------------------------
  # With a final location, shifts all indices of the unit to complete movement.
  #--------------------------------------------------------------------------
  def self.set_unit_location(unit, final_index)
    origin = Grid.index_of_unit(unit)
    shift = final_index - origin
    ori_locations = Grid.indices_of_unit(unit)
    fin_locations = []
    ori_locations.each {|index| fin_locations.push(index + shift)}
    ori_locations.each {|index| $game_temp.grid[0][index].remove_unit}
    fin_locations.each {|index| $game_temp.grid[0][index].set_unit(unit)}
  end

  #--------------------------------------------------------------------------
  # Return a boolean based on whether a unit fits in a theoretical location.
  # Designed for use with larger enemies.
  #--------------------------------------------------------------------------
  def self.unit_fits(unit,target_origin)
    unit_origin = Grid.index_of_unit(unit)
    unit_area = Grid.indices_of_unit(unit)
    diff = target_origin - unit_origin
    target_area = []
    unit_area.each {|pos| target_area.push(pos+diff)}
    rEdge = lEdge = tEdge = bEdge = false
    #validity check
    target_area.each do |pos|
      return false if $game_temp.grid[0][pos].get_unit != nil && $game_temp.grid[0][pos].get_unit != unit
      return false if Grid.ally_spaces.include?(pos)
      rEdge = true if Grid::EdgeRight.include?(pos)
      lEdge = true if Grid::EdgeLeft.include?(pos)
      tEdge = true if Grid::EdgeTop.include?(pos)
      bEdge = true if Grid::EdgeBtm.include?(pos)
    end
    return false if rEdge && lEdge
    return false if tEdge && bEdge
    return true
  end

  #--------------------------------------------------------------------------
  # Return the index of specified Battler object on the grid.
  # The bottom right tile of an enemy's unit size is considered the "origin".
  #--------------------------------------------------------------------------
  def self.index_of_unit(unit)
    units = []
    for i in 0...$game_temp.grid[0].size
      units.push($game_temp.grid[0][i].get_unit)
    end
    return units.rindex(unit) #rindex: last index, to find the head of large enemies.
  end

  #--------------------------------------------------------------------------
  # Returns all spaces occupied by a unit (for large enemies).
  #--------------------------------------------------------------------------
  def self.indices_of_unit(unit)
    indices = []
    for i in 0...$game_temp.grid[0].size
      indices.push(i) if $game_temp.grid[0][i].get_unit == unit
    end
    return indices
  end

  #--------------------------------------------------------------------------
  # Return all indices of the grid occupied by an actor (Game_Actor).
  #--------------------------------------------------------------------------
  def self.actor_indices
    actor_positions = []
    for i in 0...$game_temp.grid[0].size
      actor_positions.push(i) if $game_temp.grid[0][i].get_unit.is_a?(Game_Actor)
    end
    return actor_positions
  end

  #--------------------------------------------------------------------------
  # Return all indices of the grid occupied by an enemy (Game_Enemy).
  #--------------------------------------------------------------------------
  def self.enemy_indices
    enemy_positions = []
    for i in 0...$game_temp.grid[0].size
      enemy_positions.push(i) if $game_temp.grid[0][i].get_unit.is_a?(Game_Enemy)
    end
    return enemy_positions
  end

  #--------------------------------------------------------------------------
  # Note: Game_Actor < Game_Battler
  #       Game_Enemy < Game_Battler
  # Return all indices of the grid occupied by anyone (Game_Battler).
  #--------------------------------------------------------------------------
  def self.battler_indices
    battler_positions = []
    for i in 0...$game_temp.grid[0].size
      battler_positions.push(i) if $game_temp.grid[0][i].get_unit.is_a?(Game_Battler)
    end
    return battler_positions
  end

  #--------------------------------------------------------------------------
  # Old method of moving an enemy. Specifies a range and the enemy moves forward.
  #--------------------------------------------------------------------------
  def self.move_whole_unit(unit,range = 1,dir = 6)
    ori_locations = Grid.indices_of_unit(unit)
    final_locations = []
    ori_locations.each {|index| final_locations.push(Grid.neighbor(index,dir))}
    return if !(final_locations & Grid.ally_spaces).empty?
    ori_locations.each {|index| $game_temp.grid[0][index].remove_unit}
    final_locations.each {|index| $game_temp.grid[0][index].set_unit(unit)}
  end
  
  def self.base_region(origin,range_type,range,area_type = nil,area_size = nil)
    region = [origin]
    case range_type
    when :expand
      region += expand_search(origin,range)
    when :row #|| :row_limited || :row_unlimited
      region += horizontal(origin,range)
    when :col
      region += vertical(origin,range)
    when :allies
      region += ally_spaces
    when :enemies
      region += enemy_spaces
    end
    return region
  end
  
end