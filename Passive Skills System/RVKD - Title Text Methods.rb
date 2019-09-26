#===============================================================================
# Title: Title Text Methods
# Author: Revoked
# 
# This script adds methods that conveniently define strings to be evaluated
# by Titles Definitions.
#-------------------------------------------------------------------------------
# ** Game_Actor
#===============================================================================
class Game_Actor < Game_Battler
  #----------------------------------------------------------------+
  # Given a symbol for a title feature, applies it to the actor.   |
  #=============================================/------------------+
  # new method: set_title_feature              /
  #-------------------------------------------/
  def set_title_feature(symbol)
    symbol = symbol.to_sym
    $data_actors[self.id].add_feature(*RVKD::Passives::FEATURES[symbol])
  end
  #----------------------------------------------------------------+
  # Given a symbol for a title feature, removes it from the actor. |
  #=============================================/------------------+
  # new method: remove_title_feature           /
  #-------------------------------------------/
  def rem_title_feature(symbol)
    symbol = symbol.to_sym
    $data_actors[self.id].remove_feature(*RVKD::Passives::FEATURES[symbol])
  end
end
#-------------------------------------------------------------------------------
# ** Module Bubs::ToGTitleSystem
#===============================================================================
module Bubs
  module ToGTitleSystem
    
  Icon = {
    :main => 208,
    :side => 209,
    :hunt => 210,
    :misc => 211,
    :spec => 212
  }
    
  Main = [[  0,  0,  0,  0,  0], #0
          [120,140,180,240,320], #1 
          [150,180,240,330,450], #2
          [240,280,360,480,640], #3
          [350,400,500,650,850], #4
          [420,500,660,900,1220], #5 
          [500,620,860,1220,1700], #6
          [750,900,1200,1650,2250], #7
          [1000,1200,1600,2200,3000], #8
          [1500,1750,2250,3000,4000], #9
          [1800,2200,3000,4200,5800], #10
          [2400,3000,4200,6000,8400], #11
          [3500,4350,6050,8600,12000]] #12
        
  Side = [[125,150,200,275,375],
          [160,200,280,400,560],
          [250,300,400,550,750],
          [370,440,580,790,1070],
          [440,540,740,1040,1440],
          [540,700,1020,1500,2140],
          [800,1000,1400,2000,2800],
          [1080,1360,1920,2760,3880],
          [1600,1950,2650,3700,5100],
          [1920,2440,3480,5040,7120],
          [2600,3400,5000,7400,10600],
          [3700,4750,6850,10000,14200]]
          
  Spec = [[125,150,200,275,375],
          [160,200,280,400,560],
          [250,300,400,550,750],
          [370,440,580,790,1070],
          [440,540,740,1040,1440],
          [540,700,1020,1500,2140],
          [800,1000,1400,2000,2800],
          [1080,1360,1920,2760,3880],
          [1600,1950,2650,3700,5100],
          [1920,2440,3480,5040,7120],
          [2600,3400,5000,7400,10600],
          [3700,4750,6850,10000,14200]]
  
  M1 = [120,140,180,240,320] 
  M2 = [150,180,240,330,450]  
  M3 = [240,280,360,480,640] 
  M4 = [350,400,500,650,850] 
  M5 = [420,500,660,900,1220] 
  M6 = [500,620,860,1220,1700]
  M7 = [750,900,1200,1650,2250]
  M8 = [1000,1200,1600,2200,3000]
  M9 = [1500,1750,2250,3000,4000]
  M10 = [1800,2200,3000,4200,5800]
  M11 = [2400,3000,4200,6000,8400]
  M12 = [3500,4350,6050,8600,12000]
  
  S1 = [125,150,200,275,375]
  S2 = [160,200,280,400,560]
  S3 = [250,300,400,550,750]
  S4 = [370,440,580,790,1070]
  S5 = [440,540,740,1040,1440]
  S6 = [540,700,1020,1500,2140]
  S7 = [800,1000,1400,2000,2800]
  S8 = [1080,1360,1920,2760,3880]
  S9 = [1600,1950,2650,3700,5100]
  S10 = [1920,2440,3480,5040,7120]
  S11 = [2600,3400,5000,7400,10600]
  S12 = [3700,4750,6850,10000,14200]
  
  #----------------------------------------------------------------+
  # This method is used to shorten lengths of title ranks in the   |
  # Definitions script. Returns from the arrays of defined SPs.    |
  #=============================================/------------------+
  # new method: self.rank_sp                   /
  #-------------------------------------------/
  def self.rank_sp(symbol,tier = 1,rank = 1)
    case symbol
    when :main
      return Main[tier][rank]
    when :side
      return Side[tier][rank]
    when :spec
      return Spec[tier][rank]
    else
      return 100
    end
  end
  
  #----------------------------------------------------------------+
  # This method takes a skill name and its effect description, and |
  # returns a script code to be evaulated based on its effect.     |
  #=============================================/------------------+
  # new method: self.make_script               /
  #-------------------------------------------/
  def self.make_script(name, desc, trigger = :X, id = nil)
    if desc[0..6] == "Alchemy" || desc[0..3] == "Item"
      item = true; desc = desc.split(' ')[1..-1].join(' ')
    end
    id ||= $data_items.find { |i| i && i.name == name }.id rescue nil if item
    id ||= $data_skills.find{ |s| s && s.name == name }.id rescue nil #if id.nil?
    id ||= $data_items.find { |i| i && i.name == name }.id rescue nil
    skill = name.downcase.to_sym
    trait =
      case desc
      when /BASE POWER[ ][+](\d+)/i, /\AATTACK[ ][+](\d+)/i 
        :base
      when /DAMAGE[ ][+](\d+)[%]/i, /RECOVERY[ ][+](\d+)[%]/i
        :total
      when /SPIRIT PIERCE[ ][+](\d+)/i, /DEFENSE PIERCE[ ][+](\d+)/i
        :pierce
      when /SPIRIT IGNORE[ ][+](\d+)/i, /DEFENSE IGNORE[ ][+](\d+)/i
        :divide
      when /HEALING[ ][+](\d+)/i
        :added
      when /CRITICAL RATE[ ][+](\d+)[%]/i
        :crit_rate
      when /WEAKNESS AMP[ ][+](\d+)[%]/i
        :weakamp
      when /CAST TIME[ ][+](\d+)/i
        :charge
      when /CAST TIME[ ][-](\d+)/i ; value = -($1.to_i)
        :charge
      when /TURN DELAY[ ][+](\d+)/i
        :delay_bonus
      when /TURN DELAY[ ][-](\d+)/i ; value = -($1.to_i)
        :delay_bonus
      when /RECOVER MP[ ][+](\d+)/i
        :mp_heal
      when /CURE[ ](.+)/i ; value = trigger
        :cure
      when /BUFF:[ ](.+)/i ; value = $1
        :buff
      when /EXTEND:[ ](.+)/i ; value = $1
        :extend
      when /TACTIC:[ ](.+)/i, /LEARN:[ ](.+)/i, /ZENITH:[ ](.+)/i
        :learn
      end
    value ||= $1.to_i
    
    line = ""
    return line if trait.nil?
    if item && id < 30
      return "" unless trigger.is_a?(Integer)
      line += "$data_items[#{id}].mods[:#{trait.to_s}][#{trigger}] += #{value}"
      line += " rescue $data_items[#{id}].mods[:#{trait.to_s}][#{trigger}] = #{value}"
      return line
    elsif item 
      line += "$data_items[#{id}].mods[:#{trait.to_s}] += #{value}"
      line += " rescue $data_items[#{id}].mods[:#{trait.to_s}] = #{value}"
      return line
    end
    
    if value.is_a?(Integer) || trait == :cure
      #line = "$game_system.skl[:#{skill.to_s}][:#{trait.to_s}] += #{value}"
      line = "$data_skills[#{id}].mods[:#{trait.to_s}] += #{value}"
      line += " rescue $data_skills[#{id}].mods[:#{trait.to_s}] = #{value}"
    elsif trait == :buff
      ids = $data_states.select{|st| st.name.include?(name) rescue false}.collect{|i| i.id}
      value = find_passive_key(value)
      line = "#{ids}.each{|i| $data_states[i].add_feature(*RVKD::Passives::FEATURES[:#{value}])}"
    elsif value.is_a?(String) && trigger.is_a?(Symbol)
      id = [id, $data_skills.find{|s| s && s.name == value}.id]
      skill = skill.to_s.gsub(" ","_")
      line = "$data_skills[#{id[0]}].chain_skill[:#{trigger.to_s}] = #{id[1]}"
      line += " ; $data_skills[#{id[0]}].mods[:extend].push(#{id[1]})"
      line += " rescue $data_skills[#{id[0]}].mods[:extend] = [#{id[1]}]"
    elsif trait == :learn && id.is_a?(Integer)
      return "learn_skill(#{id})"
    end
    
    line += " ; learn_skill(#{id})" if id.is_a?(Integer) && id > 0
    id.size.times {|i| line += " ; learn_skill(#{id[i]})"} if id.is_a?(Array)
    line
  end
  
  #----------------------------------------------------------------+
  # Given a symbol for a passive title feature, returns the string |
  # that applies the feature to the actor when evaluated.          |
  #=============================================/------------------+
  # new method: self.ef      ("equip feature") /
  #-------------------------------------------/
  def self.make_desc(desc)
    if desc[0..6] == "Alchemy" || desc[0..3] == "Item"
      desc = desc.split(' ')[1..-1].join(' ')
    end
    return desc
  end
  
  def self.find_passive_key(name)
    #"Attack +5%"
    RVKD::Passives::PASSIVES.each do |key,passive|
      if passive[0] == name
#        msgbox_p(key)
        return key
      end
    end
    return nil
  end
  #----------------------------------------------------------------+
  # Given a symbol for a passive title feature, returns the string |
  # that applies the feature to the actor when evaluated.          |
  #=============================================/------------------+
  # new method: self.ef      ("equip feature") /
  #-------------------------------------------/
  def self.ef(effect)
    return "" unless effect.is_a?(Symbol) || effect.is_a?(String)
    effect = effect.to_s
    line = "self.set_title_feature(\"#{effect}\")"
    return line
  end
  
  #----------------------------------------------------------------+
  # Given a symbol for a passive title feature, returns the string |
  # that removes the feature from the actor when evaluated.        |
  #=============================================/------------------+
  # new method: self.rf     ("remove feature") /
  #-------------------------------------------/
  def self.rf(effect)
    return "" unless effect.is_a?(Symbol) || effect.is_a?(String)
    effect = effect.to_s
    line = "self.rem_title_feature(\"#{effect}\")"
    return line
  end
  
  #----------------------------------------------------------------+
  # Given a symbol for a skill, its id, its button trigger, and id |
  # of the skill to add a new chain extension to, returns string.  |
  #=============================================/------------------+
  # new method: self.ne      ("new extension") /
  #-------------------------------------------/
  def self.ne(symbol,skill_id,trigger,id)
    if id.is_a?(Integer)
      line = "$data_skills[#{skill_id}].chain_skill[:#{trigger.to_s}] = #{id}"
      line += " and $game_system.skl[:#{symbol.to_s}][:extend].push(#{id})"
      line += " and learn_skill(#{id})" if id > 0
    end
    line += " and learn_skill(#{skill_id})" if skill_id > 0
    return line
  end
  
  #----------------------------------------------------------------+
  # Returns the inputted text with a set colour and a line break.  |
  #=============================================/------------------+
  # new method: self.dc        ("description") /
  #-------------------------------------------/
  def self.dc(passive,sentence)
    passive = RVKD::Passives::PASSIVES[passive][0] if passive.is_a?(Symbol)
    line = "\eC[26]"+sentence+"\eC[0]\n" + "     " + passive
    return line
  end
  
  #----------------------------------------------------------------+
  # Returns the inputted text with a set colour and a line break.  |
  #=============================================/------------------+
  # new method: self.ds        ("description") /
  #-------------------------------------------/
  def self.ds(sentence)
    "\eC[26]"+sentence+"\eC[0]\n     "
  end
  
  #----------------------------------------------------------------+
  # Returns the inputted text with a set colour and a line break.  |
  #=============================================/------------------+
  # new method: self.ta        ("text line A") /
  #-------------------------------------------/
  def self.ta(sentence)
    line = "\eC[26]"+sentence+"\eC[0]\n"
    return line
  end
  
  #----------------------------------------------------------------+
  # Returns the inputted text with preceding space to fit an icon. |
  #=============================================/------------------+
  # new method: self.tb        ("text line B") /
  #-------------------------------------------/
  def self.tb(standard,mastered = "")
    line = "     "+standard #+ "\eC[14] ("+mastered+")\ec[0]"
  end

  
  end #Module ToGTitleSystem
end #Module Bubs