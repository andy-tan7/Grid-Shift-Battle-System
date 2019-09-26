class Game_BattlerBase
  
  #Overwrite method: skill_cost_payable?(skill)
  def skill_cost_payable?(skill)
    result = tp >= skill_tp_cost(skill) && mp >= skill_mp_cost(skill)
    result = true if SceneManager.scene_is?(Scene_Battle) && 
                     self.current_action.item == skill
    return result
  end
  
end