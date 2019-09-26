#===============================================================================
# Title: Title Banners
# Author: Revoked
# 
# This script displays a visual flourish of battle members' titles at the end
# of battle.
#===============================================================================
# ** Configuration
#===============================================================================
module Banner
  
  FontName = "EB Garamond 08 Standard Digit"
  RankFont = "EB Garamond 08 Standard Digit"#"TW Cen MT Condensed"
  
  OrbOffsetX = 23
  OrbOffsetY = 11
  
  IconOffsetX = 43
  IconOffsetY = 8
  
  TitleOrbOffsetX = 38
  TitleOrbOffsetY = 14
  
  InitY = [128,160,192,224]
  
  FinOrder = [0 ,23, 1,22, 2,21,3,20, 4,19, 5,18,12,11,13,10,14, 9,15,8,16,7,17,6]
  FinTimes = [10,10,10,10,10,10,9,10,10,10,10,10,10,10,10,10,10,10, 9,8, 7,6, 5,4]
  
end #Banner
#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle
  def getSpriteset; @spriteset end
end # Scene_Battle

#==============================================================================
# ■ Spriteset_Battle
#==============================================================================
class Spriteset_Battle 

  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias rvkd_spb_initialize initialize
  def initialize
    @banner_sprites = []
    @collapse = false
    rvkd_spb_initialize
    @counter = 0
    @mod_rate = 1
    @slide_index = 0
    create_initial_ranks
  end
  
  #--------------------------------------------------------------------------
  # alias method: dispose
  #--------------------------------------------------------------------------
  alias rvkd_spb_dispose dispose
  def dispose
    rvkd_spb_dispose
    dispose_banners
  end
  
  #--------------------------------------------------------------------------
  # alias method: update
  #--------------------------------------------------------------------------
  alias rvkd_spb_update update
  def update
    rvkd_spb_update
    update_banners if !@banner_sprites.empty?
  end
  
  #--------------------------------------------------------------------------
  # new method: dispose_banners
  #--------------------------------------------------------------------------
  def dispose_banners
    @banner_sprites.each do |group|
      group.each {|banner| banner.dispose}
    end
  end
  #--------------------------------------------------------------------------
  # new method: update_banners
  #--------------------------------------------------------------------------
  def update_banners
    if @collapse
      @banner_sprites.each {|banners| banners.each {|banner| banner.update_move if banner.sliding}}
      @counter += 1
      return if @counter % @mod_rate != 0 && @counter < 36
      moving_index_a = Banner::FinOrder[@slide_index] / 6
      moving_index_b = Banner::FinOrder[@slide_index] % 6
      @slide_index += 1
      return if moving_index_a >= @banner_sprites.size
      @banner_sprites[moving_index_a][moving_index_b].sliding = true
      @collapse = false if @slide_index >= @banner_sprites.size * 6
    else
      @banner_sprites.each {|banners| banners.each {|banner| banner.update_move}}
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: create_initial_ranks
  #--------------------------------------------------------------------------
  def create_initial_ranks
    @initial_ranks = []
    $game_party.battle_members.each do |member|
      @initial_ranks.push(member.title_rank[member.current_title])
    end
  end
  #--------------------------------------------------------------------------
  # new method: start_banners
  #--------------------------------------------------------------------------
  def start_banners
    section_index = 0
    $game_party.battle_members.each do |actor|
      create_titles(actor,section_index)
      section_index += 1
    end
    if @banner_sprites.size >= 1
      @banner_sprites[0].each {|banner| banner.move(176,Banner::InitY[0],0,15)}
    end
    if @banner_sprites.size >= 2
      @banner_sprites[1].each {|banner| banner.move(176,Banner::InitY[1],0,15)}
    end
    if @banner_sprites.size >= 3
      @banner_sprites[2].each {|banner| banner.move(176,Banner::InitY[2],0,15)}
    end
    if @banner_sprites.size >= 4
      @banner_sprites[3].each {|banner| banner.move(176,Banner::InitY[3],0,15)}
    end
  end
  #--------------------------------------------------------------------------
  # new method: create_titles
  #--------------------------------------------------------------------------
  def create_titles(actor,section_index)
    title_array = []
    title_array.push(Window_TitleName.new(176,192,actor,11*(4-section_index),@viewport))
    for i in 1...6
      ttl = actor.title
      if i >= actor.title_rank[ttl.symbol]
        type = 0
      else
        if actor.title_rank[ttl.symbol] > @initial_ranks[$game_party.battle_members.index(actor)]
          type = 2
        else
          type = 1
        end
      end
      banner = Window_TitleBanner.new(176,192,ttl,i,type,11*(4-section_index)-i*2,@viewport)
      title_array.push(banner)
    end
    @banner_sprites.push(title_array)
  end 
  
  #--------------------------------------------------------------------------
  # new method: spread_out
  #--------------------------------------------------------------------------
  def spread_out
    if @banner_sprites.size >= 1
      for i in 0...6
        @banner_sprites[0][i].move(54, 6+30*i, 255, 20)
      end
    end
    if @banner_sprites.size >= 2
      for i in 0...6
        @banner_sprites[1][i].move(336, 6+30*i, 255, 20)
      end
    end
    if @banner_sprites.size >= 3
      for i in 0...6
        @banner_sprites[2][i].move(54, 216+30*i, 255, 20)
      end
    end
    if @banner_sprites.size >= 4
      for i in 0...6
        @banner_sprites[3][i].move(336, 216+30*i, 255, 20)
      end
    end
  end
  #--------------------------------------------------------------------------
  # new method: collapse_banners
  #--------------------------------------------------------------------------
  def collapse_banners
    RPG::SE.new("AO - BG_Buff",95,90).play
    @check_array = Array.new(6*@banner_sprites.size)
    for grp in 0...@banner_sprites.size
      for b in 0...6
        @banner_sprites[grp][b].move(336,366,255,Banner::FinTimes[grp*6+b])
      end
    end
    $game_troop.screen.pictures[50].show("[TZB] Banner",0,336,366,100,100,0,0)
    $game_troop.screen.pictures[50].move(0,336,366,100,100,255,0,40)
    @slide_index = 0
    @counter = 0
    @mod_rate = 3
    @collapse = true
  end
  #--------------------------------------------------------------------------
  # new method: exit_banners
  #--------------------------------------------------------------------------
  def exit_banners
    @banner_sprites.each do |group|
      group.each {|banner| banner.move(780,366,255,15)}
    end
    $game_troop.screen.pictures[50].move(0,780,366,100,100,255,0,15)
  end
  
end #Spriteset_Battle

#==============================================================================
# ■ Window_TitleName
#==============================================================================
class Window_TitleName < Window_Base
  attr_accessor :sliding
  def initialize(x, y, actor, z, viewport)
    super(x,y,300,40)
    self.windowskin = Cache.system("Window")
    self.x = x
    self.y = y
    self.z = z
    @sliding = false
    @banner_bg = BannerBG.new(x,y,viewport)
    @banner_bg.bitmap = Cache.banner("Bar - Title")
    @banner_bg.z = z-1
    @banner_bg.opacity = 255
    @banner_orb = BannerOrb.new(x,y,viewport)
    @banner_orb.bitmap = Cache.banner("Orb - Title1")
    @banner_orb.x = x + Banner::TitleOrbOffsetX + 20
    @banner_orb.y = y + Banner::TitleOrbOffsetY
    @banner_orb.z = z
    contents.font.size = 20
    contents.font.name = Banner::FontName#Banner::RankFont
    text = actor.title.name
    draw_text(Rect.new(72,1,300,40),text,0)
  end
  
  def move(x,y,opacity,duration)
    @target_x = x.to_f
    @target_y = y.to_f
    @target_opacity = opacity
    @duration = duration
  end
  def update_move
    return if @duration == 0 || !@duration
    d = @duration
    set_x((self.x * (d - 1) + @target_x) / d)
    set_y((self.y * (d - 1) + @target_y) / d)
    self.opacity = 0
    #self.opacity = (self.opacity * (d - 1) + @target_opacity) / d
    @duration -= 1
  end
  def set_x(new_x)
    self.x = new_x
    @banner_bg.x = new_x
    @banner_orb.x = new_x + Banner::TitleOrbOffsetX
  end
  def set_y(new_y)
    self.y = new_y
    @banner_bg.y = new_y
    @banner_orb.y = new_y + Banner::TitleOrbOffsetY
  end
  
  def standard_padding; 0 end
    
  def dispose
    @banner_orb.dispose
    @banner_bg.dispose
    contents.dispose unless disposed?
    super
  end
  
end #Window_TitleName

#==============================================================================
# ■ Window_TitleBanner
#==============================================================================
class Window_TitleBanner < Window_Base
  #-----------------------------------------------------
  # State: 0 || nil : grey, 1 : earned, 2 : new gain
  #-----------------------------------------------------
  attr_accessor :sliding
  def initialize(x, y, title, tier, state, z, viewport)
    super(x,y,300,40)
    self.z = z#z + 2
    self.windowskin = Cache.system("Window")
    @sliding = false
    @banner_bg   = BannerBG.new(x,y,viewport)
    @banner_bg.z = z-1#z + 1
    @banner_orb  = BannerOrb.new(x,y,viewport)
    @banner_orb.x = x + Banner::OrbOffsetX
    @banner_orb.y = y + Banner::OrbOffsetY
    @banner_orb.z = z
    @banner_bg.opacity = 0
    @banner_orb.opacity = 255
    case state
    when 0
      @banner_bg.bitmap = Cache.banner("Bar - Locked")
      @banner_orb.bitmap = Cache.banner("Orb - Locked")
      contents.font.color = Color.new(255,255,255,128)
      draw_icon(title.ranks[tier].icon, 43, 8, false)
    when 1
      @banner_bg.bitmap = Cache.banner("Bar - Default")
      @banner_orb.bitmap = Cache.banner("Orb - Learned")
      contents.font.color = Color.new(255,255,255,255)
      draw_icon(title.ranks[tier].icon, 43, 8)
    when 2
      @banner_bg.bitmap = Cache.banner("Bar - Gained")
      @banner_orb.bitmap = Cache.banner("Orb - Learned")
      contents.font.color = Color.new(255,255,255,255)
      draw_icon(title.ranks[tier].icon, 43, 8)
    end
    contents.font.size = 18#20
    contents.font.name = Banner::RankFont
    #contents.font.name = Banner::FontName
    text = title.ranks[tier].name
    text += (" - "+title.ranks[tier].description) if !title.ranks[tier].description.empty?
    draw_text(Rect.new(70,1,300,40),text,0)
  end
  
  def move(x,y,opacity,duration)
    @target_x = x.to_f
    @target_y = y.to_f
    @target_opacity = opacity
    @duration = duration
  end
  
  def update_move
    return if @duration == 0 || !@duration
    d = @duration
    set_x((self.x * (d - 1) + @target_x) / d)
    set_y((self.y * (d - 1) + @target_y) / d)
    self.opacity = 0
    @banner_bg.opacity = (@banner_bg.opacity * (d - 1) + @target_opacity) / d
    @duration -= 1
  end
  
  def set_x(new_x)
    self.x = new_x
    @banner_bg.x = new_x
    @banner_orb.x = new_x + Banner::OrbOffsetX
  end
  def set_y(new_y)
    self.y = new_y
    @banner_bg.y = new_y
    @banner_orb.y = new_y + Banner::OrbOffsetY
  end
  
  def standard_padding; 0 end
    
  def dispose
    @banner_orb.dispose
    @banner_bg.dispose
    contents.dispose unless disposed?
    super
  end
  
end #Window_TitleBanner

#==============================================================================
# ■ BannerBG
#==============================================================================
class BannerBG < Sprite_Base
  def initialize(wx,wy,viewport)
    super(viewport)
    self.x = wx
    self.y = wy
  end
end #BannerBG

#==============================================================================
# ■ BannerOrb
#==============================================================================
class BannerOrb < Sprite_Base
  def initialize(wx,wy,viewport,learned = false)
    super(viewport)
    self.x = wx + Banner::OrbOffsetX
    self.y = wy + Banner::OrbOffsetY
  end
end #BannerOrb

#+==============================================================================
#| DataManager Initialize
#+==============================================================================
module DataManager
  class << self
    alias rvkd_ex_attr_skl_setup_new_game setup_new_game
    def setup_new_game
      rvkd_ex_attr_skl_setup_new_game
      $game_system.initial_ranks
    end
    
    alias rvkd_ex_attr_skl_setup_battle_test setup_battle_test
    def setup_battle_test
      rvkd_ex_attr_skl_setup_battle_test
      $game_system.initial_ranks
      $game_party.members.each {|actor| actor.gain_title_sp(100)}
    end
  end
end

#==============================================================================
# ■ Game_System
#==============================================================================
class Game_System
  attr_accessor :old_ranks
  #--------------------------------------------------------------------------
  # new method: initial_ranks
  #--------------------------------------------------------------------------
  def initial_ranks
    @old_ranks = {}
    update_ranks
  end
  
  #--------------------------------------------------------------------------
  # new method: update_ranks
  #--------------------------------------------------------------------------
  def update_ranks
    rnk = @old_ranks
    rnk[:amnesiac]         = $game_actors[1].title_rank[:amnesiac] 
    rnk[:aspiring_blade]   = $game_actors[1].title_rank[:aspiring_blade] 
    rnk[:umbral_heart]     = $game_actors[1].title_rank[:umbral_heart] 
    rnk[:motif]            = $game_actors[1].title_rank[:motif] 
    rnk[:remnant]          = $game_actors[1].title_rank[:remnant] 
    rnk[:necron_end]       = $game_actors[1].title_rank[:necron_end] 
    rnk[:skilled_initiate] = $game_actors[1].title_rank[:skilled_initiate] 
    
    rnk[:that_lass]        = $game_actors[2].title_rank[:that_lass]  
    rnk[:practical_geek]   = $game_actors[2].title_rank[:practical_geek]  
    rnk[:empath]           = $game_actors[2].title_rank[:empath]  
    rnk[:devious_youth]    = $game_actors[2].title_rank[:devious_youth]  
    rnk[:vaughn_nemesis]   = $game_actors[2].title_rank[:vaughn_nemesis]  
    
    rnk[:elementalist]     = $game_actors[3].title_rank[:elementalist]
    rnk[:rune_mage]        = $game_actors[3].title_rank[:rune_mage]
    rnk[:rune_sword]       = $game_actors[3].title_rank[:rune_sword]
    rnk[:the_princess]     = $game_actors[3].title_rank[:the_princess]
    
    rnk[:thunder_guard]    = $game_actors[4].title_rank[:thunder_guard]
    rnk[:thunder_fist]     = $game_actors[4].title_rank[:thunder_fist]
    rnk[:royal_guardian]   = $game_actors[4].title_rank[:royal_guardian]
    @old_ranks  = rnk
  end
  
end #Game_System

#==============================================================================
# 
# ▼ End of File
# 
#==============================================================================