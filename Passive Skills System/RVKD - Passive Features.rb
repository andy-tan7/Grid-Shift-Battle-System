#===============================================================================
# Title: Passive Definitions
# Author: Revoked
# 
# This script defines passive skills and the features they apply to the actor
# equipping the effect.
# FEATURES is also used to apply on-equip effects for Titles.
#
# Some References for n:
#
# ▼ |  :param  |  :xparam | :sparam   | :elem | 
# 0 | Max HP   | Accuracy | TargRate  |       |
# 1 | Max MP   | Evasion  | GrdEffect | Fire  |
# 2 | Attack   | Critical | RecEffect | Water |
# 3 | Defense  | CrtEvade | ItmEffect | Wind  |
# 4 | Strength | MagEvade | MP Cost   | Earth |
# 5 | Magic    | MReflect | TP+ Rate  | Thund |
# 6 | Agility  | Counter  | PhysRate  | Ice   |
# 7 | Spirit   | HP Regen | MagiRate  | Light |
# 8 |          | MP Regen | FloorDmg  | Dark  |
# 9 |          | TP Regen | EXP Rate  |       |
#-------------------------------------------------------------------------------
# ** Module RVKD::Passives
#===============================================================================
module RVKD
  module Passives
    
    FEATURES = { #FType  n  value
      :mhp_5 => [:param, 0, 1.05],
      :mmp_5 => [:param, 1, 1.05],
      :atk_5 => [:param, 2, 1.05],
      :def_5 => [:param, 3, 1.05],
      :str_5 => [:param, 4, 1.05],
      :mag_5 => [:param, 5, 1.05],
      :agi_5 => [:param, 6, 1.05],
      :spr_5 => [:param, 7, 1.05],
      
      :acc_1 => [:xparam, 0, 0.01],
      :acc_3 => [:xparam, 0, 0.03],
      :acc_5 => [:xparam, 0, 0.05],
      :eva_3 => [:xparam, 1, 0.03],
      :eva_5 => [:xparam, 1, 0.05],
      
      :rec_10 => [:sparam, 2, 1.10],
      :pha_10 => [:sparam, 3, 1.10],
      
      :test => [:param, 0, 1.0]
    } #<- Do not delete. FEATURES
    
    PASSIVES = { # SkillName     Icon  Orb Description
      :mhp_5 => ["Max HP +5%",   704,  5,  "Boost maximum HP by 5%."],
      :mmp_5 => ["Max MP +5%",   705,  5,  "Boost maximum MP by 5%."],
      :atk_5 => ["Attack +5%",   717,  5,  "Boost Attack by 5%."],
      :def_5 => ["Defense +5%",  718,  5,  "Boost Defense by 5%."],
      :str_5 => ["Strength +5%", 718,  5,  "Boost Strength by 5%."],
      :mag_5 => ["Magic +5%",    718,  5,  "Boost Magic by 5%."],
      :agi_5 => ["Agility +5%",  718,  5,  "Boost Agility by 5%."],
      :spr_5 => ["Spirit +5%",   718,  5,  "Boost Spirit by 5%."],
      
      :acc_1 => ["Accuracy +1",  712,  1,  "Raise Accuracy by 1."],
      :acc_3 => ["Accuracy +3",  712,  5,  "Raise Accuracy by 3."],
      :acc_5 => ["Accuracy +5",  712,  8,  "Raise Accuracy by 5."],
      :eva_3 => ["Evasion +3",   713,  5,  "Raise Evasion by 3."],
      :eva_5 => ["Evasion +5",   713,  5,  "Raise Evasion by 5."],
      
      :rec_10 => ["Recovery Rate +10%", 715, 5, "Boost incoming recovery effects by 10%."],
      :pha_10 => ["Item Effect +10%", 296, 5, "Boost item effectiveness by 10%."],
      
      :test => ["Test Passive",   207,  1,  "This is a test ability."]
    } #<- Do not delete. PASSIVES

  end
end

#-------------------------------------------------------------------------------
# ** RPG::Skill
#===============================================================================
class RPG::Skill < RPG::UsableItem
  attr_accessor :passive_features
  attr_accessor :orb_cost
  attr_accessor :passive_index
  
  #----------------------------------------------------------------+
  # Retrieve Feature information for skills with a passive effect. |
  #=============================================/------------------+
  # new method: passive_features               /
  #-------------------------------------------/
  def passive_features
    return @passive_features if @passive_features
    @passive_features = []
    self.note.split(/[\r\n]+/).each do |line|
      case line
      when /feature\[(\w+)\]/i
        @passive_features.push(RVKD::Passives::FEATURES[$1.to_sym])
      end
    end
    @passive_features
  end
  
end

#-------------------------------------------------------------------------------
# ** Game_Actor
#===============================================================================
class Game_Actor < Game_Battler
  
  attr_accessor :passive_skills
  attr_accessor :rise
  alias rvkd_game_actor_init_skills_passive init_skills
  def init_skills
    rvkd_game_actor_init_skills_passive
    @passive_skills = []
    @rise = 0
  end
  
  def sorted_passives
    @passive_skills.sort_by! {|a| a.passive_index} 
    return @passive_skills
  end
  
  #----------------------------------------------------------------+
  # Creates a RPG::Skill object based on the effect symbol passed. |
  #=============================================/------------------+
  # new method: get_passive                    /
  #-------------------------------------------/
  def get_passive(symbol)
    data = RVKD::Passives::PASSIVES[symbol]
    skill = RPG::Skill.new
    skill.name = data[0]
    skill.icon_index = data[1]
    skill.orb_cost = data[2]
    skill.description = data[3]
    skill.passive_index = RVKD::Passives::PASSIVES.keys.index(symbol)
    skill.stype_id = 3
    skill.occasion = 2
    skill.passive_features = [RVKD::Passives::FEATURES[symbol]]
    skill.load_notetags_srs
    return skill
  end
  
  #----------------------------------------------------------------+
  # Add a generated passive to an actor based on the given symbol. |
  #=============================================/------------------+
  # new method: learn_passive                  /
  #-------------------------------------------/
  def learn_passive(symbol)
    @passive_skills.push(get_passive(symbol)) unless @passive_skills.include?(get_passive(symbol))
  end
  
end