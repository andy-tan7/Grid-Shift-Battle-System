#===============================================================================
# Title: Grid Methods
# Author: Revoked
# 
# This script provides methods with Grid-related functions in the Grid module.
#===============================================================================
module Grid
#---------------------------------------------\
# ** Tile Appearance Modifications             \
#===============================================\
  #---------------------------------------------------------+
  # Resets all tiles to their default unselected opacities. |
  #===============================================/---------+
  # new methods: hide_grid, hide_outside_region  /
  #---------------------------------------------/
  def self.hide_grid
    $game_temp.grid[0].each {|sq| sq.hide; sq.unlight}
  end
  def self.hide_outside_region(r)
    $game_temp.grid[0].each_with_index {|s,i| s.hide_outside if !r.include?(i)}
  end
  
  #-------------------------------------------------+
  # Raise the opacity of tiles containing battlers. |
  #==========================================/------+
  # new methods: show_actor_squares, enemy  /
  #----------------------------------------/
  def self.show_actor_squares
    $game_temp.grid[0].each {|grid| grid.show if grid.get_unit.is_a?(Game_Actor)}
  end
  def self.show_enemy_squares
    $game_temp.grid[0].each {|grid| grid.show if grid.get_unit.is_a?(Game_Enemy)}
  end
  
  def self.ally_demo_region(actor,item)
    origin = actor.position
    Grid.demo_reset_grid(origin)
    range_item = item.scopes[:range]
    range_type = item.scopes[:range_type]
    return unless range_type && range_item && origin
    region = Grid.base_region(origin,range_type,range_item)
    region -= [origin] unless range_type == :self_only
    region -= Grid.ally_spaces  if item.for_opponent?
    region -= Grid.enemy_spaces if item.for_friend?
    region.each do |tile|
      $game_temp.grid[0][tile].show_faint
    end
  end
  
  #--------------------------------------------------------+
  # Lights up regions on the grid to indicate enemy logic. |
  #===============================================/--------+
  # new methods: demo_show_region, light, reset  /
  #---------------------------------------------/
  def self.demo_show_region(user,range, type = :expand)
    origin = $game_temp.grid[0].index($game_temp.grid[0].select{|p| p.get_unit==user}.reverse[0])
    case type
    when :expand
      $game_temp.demo_region = Grid.expand_search(origin,range)
    when :row
      $game_temp.demo_region = Grid.linear(origin,[6],range)
    end
    $game_temp.demo_region -= Grid.enemy_spaces
    $game_temp.demo_region.each do |tile|
      $game_temp.grid[0][tile].show_less
    end
  end
  def self.demo_light_target(targ,user)
    user.last_aoe = []
    $game_temp.demo_region.each do |tile|
      if $game_temp.grid[0][tile].get_unit == targ
        user.last_origin = tile
        $game_temp.grid_arrow.show_indicator(targ)
        user.last_aoe += [tile]
        $game_temp.grid[0][tile].green
        $game_temp.grid_arrow.bitmap = Cache.rvkd("GridArrow1")
      end
    end
  end
  def self.demo_reset_grid(ally = nil)
    if ally
      $game_temp.grid[0].each_with_index do |tile, i| 
        tile.hide unless ally == i
        tile.unlight unless ally == i
      end
      return
    else
      $game_temp.grid[0].each {|tile| tile.hide; tile.unlight}
      $game_temp.grid_arrow.hide_indicator
    end
  end
  
end