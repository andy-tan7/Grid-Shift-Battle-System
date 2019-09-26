class RPG::UsableItem < RPG::BaseItem
  attr_accessor :mods
  attr_reader :scopes
  
  def create_custom_attributes
    if self.is_a?(RPG::Skill) || (56..72).include?(id)
      @mods = {
        :base   => 0,
        :total  => 0,
        :added  => 0,
        :pierce => 0,
        :divide => 0,
        
        :crit_rate => 0,
        :crit_max  => 100,
        :charge       => 0,
        :delay_bonus  => 0,
        :extend => [],
      }
    elsif (1..30).include?(id)
      @mods = {}
      @mods[:total] = Array.new($data_actors.size+1,0)
      @mods[:added] = Array.new($data_actors.size+1,0)
    end
    if self.hit_type == 2 && (1..8).include?(self.damage.element_id)
      @mods[:base] = 10
      @mods[:charge] = 8
      @mods[:crit_max] = 75
    end
      
    if self.note =~ /<mods:[ ](.+)>/i
      list = $1.to_s
      list = list.split(", ")
      list.each do |pair|
        values = pair.split(" ")
        @mods[values[0].to_sym] = eval(values[1])
      end
    end
  end  
    
  def create_scope_attributes
    @scopes = {
      :range => 5,
      :range_type => :expand,
      :target_conditions => [:alive_only],
      :edge_limited => false,
      :team_limited => true,
    }
    if self.note =~ /<targets:[ ](.+)>/i
      list = $1.to_s.split(", ")
      list.each do |line|
        case line
#~~~~~~#[ Conditions ]
        when /POSITION/i
          @scopes[:target_conditions].push(:position_selectable)
        when /SELF ONLY/i
          @scopes[:target_conditions].push(:self_only)
        when /NOT SELF/i
          @scopes[:target_conditions].push(:not_self)
        when /DEAD ONLY/i
          @scopes[:target_conditions].push(:dead_only)
          @scopes[:target_conditions].delete(:alive_only)
        when /DEAD OR ALIVE/i
          @scopes[:target_conditions].push(:dead_or_alive)
          @scopes[:target_conditions].delete(:alive_only)
        when /NO CURSOR/i
          @scopes[:target_conditions].push(:no_cursor)
        when /EDGE LIMITED/i
          @scopes[:target_conditions].push(:edge_limited)
        when /TEAM UNLIMITED/i
          @scopes[:target_conditions].push(:team_unlimited)
        when /ROW BLOCK/i
          @scopes[:target_conditions].push(:row_block)
        when /FRONT ONLY/i
          @scopes[:target_conditions].push(:front_only)
        when /SAFE/i
          @scopes[:target_conditions].push(:safe)
#~~~~~~#[ Range / Selectable Region ]
        when /RANGE[ ](\d+)/i
          @scopes[:range] = $1.to_i
        when /ROW RANGE/i
          @scopes[:range_type] = :row
#~         when /ROW UNLIMITED/i
#~           @scopes[:range_type] = :row_unlimited
        when /ALLIES/i
          @scopes[:range_type] = :allies
        when /ENEMIES/i
          @scopes[:range_type] = :enemies
#~         when /GUARD/i
#~           @scopes[:range_type] = :guard
#~         when /MOVE/i
#~           @scopes[:range_type] = :move_select
#~~~~~~#[ Area Types / Area Sizes ]
        when /ROW[ ](\d+)/i
          @scopes[:area_type] = :row
          @scopes[:area_size] = $1.to_i
        when /ROW BACK[ ](\d+)/i
          @scopes[:area_type] = :row_back
          @scopes[:area_size] = $1.to_i
        when /COLUMN[ ](\d+)/i
          @scopes[:area_type] = :col
          @scopes[:area_size] = $1.to_i
        when /EXPAND[ ](\d+)/i
          @scopes[:area_type] = :expand
          @scopes[:area_size] = $1.to_i
        when /CROSS[ ](\d+)/i
          @scopes[:area_type] = :cross
          @scopes[:area_size] = $1.to_i
        when /E?X[ ](\d+)/i
          @scopes[:area_type] = :x
          @scopes[:area_size] = $1.to_i
#~         when /FULL ROW/i       #\s?(\d*)/i
#~           @scopes[:target_field] = :ally_row
#~         when /FULL COL/i
#~           @scopes[:target_field] = :ally_col
        end
      end
    end
   # p(@scopes) if self.id == 144 && self.is_a?(RPG::Skill)
  end
   
   

end

module DataManager
  class <<self; alias load_database_rvkd_csa load_database; end
  def self.load_database
    load_database_rvkd_csa
    init_attributes_csa
  end
  
  #--------------------------------------------------------------------------
  # new method: load_notetags_hms
  #--------------------------------------------------------------------------
  def self.init_attributes_csa
    groups = [$data_skills,$data_items]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.create_custom_attributes
        obj.create_scope_attributes
      end
    end
  end
  
end # DataManager

class RPG::UsableItem::Damage
  # Method overwrite: eval
  #   Adds a fourth parameter (item) to refer to the skill's attributes.
  def eval(a, b, v, item)
    [Kernel.eval(@formula), 0].max * sign rescue 0
  end
end