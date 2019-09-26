class Game_Actor < Game_Battler

#~   alias :rvkd_position_param :param
#~   def param(param_id)
#~     value = rvkd_position_param(param_id) # alias
#~     value += param_position_bonus(param_id)
#~     [[value, param_max(param_id)].min, param_min(param_id)].max.to_i
#~   end
  
  #--------------------------------------------------------------------------
  # alias : xparam
  #--------------------------------------------------------------------------
#~   alias :rvkd_position_xparam :xparam
#~   def xparam(xparam_id)
#~     xparam_position_bonus(xparam_id) + rvkd_position_xparam(xparam_id)
#~   end
  
  #--------------------------------------------------------------------------
  # alias : sparam
  #--------------------------------------------------------------------------
  alias rvkd_game_actor_sparam sparam
  def sparam(sparam_id)
    rvkd_game_actor_sparam(sparam_id) + sparam_position_bonus(sparam_id)
  end
  
#~   def param_position_bonus(param_id)
#~     return 0 unless self.position
#~     return 0
#~   end
#~   def xparam_position_bonus(param_id)
#~     return 0 unless self.position
#~   end
  
  def sparam_position_bonus(sparam_id)
    #return 0 unless self.position.is_a?(Integer)
    col = self.position % 8
    case sparam_id
    when 0
      case col
      when 4 ; return 0.5
      when 5 ; return 0.2
      when 6 ; return 0
      when 7 ; return -0.2
      end
#~     when 6
#~       case col
#~       when 4 ; return 0.1
#~       when 5 ; return 0
#~       when 6 ; return -0.05
#~       when 7 ; return -0.10
#~       end
#~     when 7
#~       return 0
    end
    return 0
  end
  
end