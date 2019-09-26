#===============================================================================
# Title: (Addon) Formation Text
# Author: Revoked
# 
# This script handles the drawing of most text in the Formation menu.
#===============================================================================
# ** Configuration
#===============================================================================
module GSForm
  
  Letters = ["Front","Mid","Long","Rear"]
  Terms = ["Cornerstone","Stable Focus", "Vital Edge", "Perception", 
           "Marginal Cover","Clear Pace","Full Impact","Perfect Location",
           "Masked Vantage","Fringe Supply","Crisis Fervor"]
  
  FX_Corner   = [0,12]
  FX_Focus    = [5,6,9,10]
  FX_Vital    = [1,2,13,14]
  FX_Percept  = [7,11]
  FX_Cover    = [0,3,12,15]
  FX_Clear    = [1,5,9,13]
  FX_Impact   = [4,8]
  FX_Location = [6,10]
  FX_Vantage  = [2,14]
  FX_Supply   = [3,7,11,15]
  FX_Crisis   = [4,8]
  
  
  Str = "Strength +5%"
  Mag = "Magic +5%"
  Cri = "Critical +5%"
  Eva = "Evasion +3%"
  Def = "Defense +5%"
  Agi = "Agility +5%"
  Mel = "Melee +10%"
  Acc = "Accuracy +3"
  Ran = "Projectile +10%"
  Pha = "Item Effect +10%"
  Grd = "Guard Effect +10%"
  
  def self.convert(num)
    row = num / 4 + 1
    col = num % 4
    return Letters[col]+" "+row.to_s
  end
  
end

#==============================================================================
# ■ Scene_GSForm
#==============================================================================
class Scene_GSForm

  def update_text
    @text_window.clear_all
    active_effect = false
    index = $game_system.party_pos.index(num_full(@grid_cursor_index))
    if index != nil && index < $game_party.battle_members.size
      @text_window.title_left_text($game_party.battle_members[index].name)
      active_effect = true
    end
    @text_window.title_right_text(GSForm.convert(@grid_cursor_index))
    position_effects(@grid_cursor_index,active_effect)
  end
  
  #--------------------------------------------------------------------------
  # new method: position_effects
  #--------------------------------------------------------------------------
  def position_effects(index,active_effect)
    @text_window.active_effect = active_effect
    if GSForm::FX_Corner.include?(index)
      @text_window.draw_effect(GSForm::Terms[0],GSForm::Str)
    end
    if GSForm::FX_Focus.include?(index)
      @text_window.draw_effect(GSForm::Terms[1],GSForm::Mag)
    end
    if GSForm::FX_Vital.include?(index)
      @text_window.draw_effect(GSForm::Terms[2],GSForm::Cri)
    end
    if GSForm::FX_Percept.include?(index)
      @text_window.draw_effect(GSForm::Terms[3],GSForm::Eva)
    end
    if GSForm::FX_Cover.include?(index)
      @text_window.draw_effect(GSForm::Terms[4],GSForm::Def)
    end
    if GSForm::FX_Clear.include?(index)
      @text_window.draw_effect(GSForm::Terms[5],GSForm::Agi)
    end
    if GSForm::FX_Impact.include?(index)
      @text_window.draw_effect(GSForm::Terms[6],GSForm::Mel)
    end
    if GSForm::FX_Location.include?(index)
      @text_window.draw_effect(GSForm::Terms[7],GSForm::Acc)
    end
    if GSForm::FX_Vantage.include?(index)
      @text_window.draw_effect(GSForm::Terms[8],GSForm::Ran)
    end
    if GSForm::FX_Supply.include?(index)
      @text_window.draw_effect(GSForm::Terms[9],GSForm::Pha)
    end
    if GSForm::FX_Crisis.include?(index)
      @text_window.draw_effect(GSForm::Terms[10],GSForm::Grd)
    end
  end
  
end #Scene_GSForm

#==============================================================================
# ■ Window_GSFormInfo
#==============================================================================
class Window_GSFormInfo < Window_Base
  
  attr_accessor :active_effect
  def initialize(x = 26, y = 140, w = 260, h = 238)
    super(x,y,w,h)
    self.opacity = 0
    @effects = 0
    @active_effect = false
  end
  
  #--------------------------------------------------------------------------
  # new method: clear_all
  #--------------------------------------------------------------------------
  def clear_all
    contents.clear
    @effects = 0
  end

  #--------------------------------------------------------------------------
  # new method: title_right_text
  #--------------------------------------------------------------------------
  def title_right_text(text)
    return unless text.is_a?(String)
    change_color(text_color(0))
    draw_text(text, 0, 0, 232, 24, 2)
  end
  
  #--------------------------------------------------------------------------
  # new method: title_left_text
  #--------------------------------------------------------------------------
  def title_left_text(text)
    return unless text.is_a?(String)
    change_color(text_color(1))
    draw_text(text, 4, 0, 232, 24, 0)
  end
  
  #--------------------------------------------------------------------------
  # new method: draw_effect
  #--------------------------------------------------------------------------
  def draw_effect(title,text)
    @active_effect? change_color(text_color(2)) : change_color(text_color(7))
    draw_text(title, 4, 26+24*(@effects*2), 232, 24, 0)
    contents.font.italic = true
    @active_effect? change_color(text_color(0)) : change_color(text_color(8))
    draw_text(text, 16, 48+24*(@effects*2), 232, 24, 0)
    contents.font.italic = false
    @effects += 1
  end
  
  def draw_text(text, x, y, text_width, text_height, alignment = 0)
    contents.draw_text(x, y, text_width, text_height, text, alignment)
  end
  
end

#==============================================================================
# 
# ▼ End of File
# 
#==============================================================================