#===============================================================================
# Title: Gained Title Display (Map)
# Author: Revoked
# 
# This script provides a visual representation of actors gaining titles on the
# field. 
#
#===============================================================================
# ** Configuration
#===============================================================================
module Banner
  TitleSound = RPG::SE.new("AO - MyHome_Recruitment",75,100)
  
  StartSound = RPG::SE.new("AO - Furniture_Recovery",90,100)
  LeaveSound = RPG::SE.new("AO - Mercenary_Battle",80,100)
  EnterSound = RPG::SE.new("AO - Magic_Foodwing3",80,100)
  SweepSound = RPG::SE.new("TC - Sweep",80,100)
  
  PosY = [31,69,107,145,183,221,259,297]
end

class Game_Temp
  attr_accessor :remember_banners
  attr_accessor :remember_banner_phase
  attr_accessor :remember_joiners
  attr_accessor :remember_leavers
  attr_accessor :remember_removed
  attr_accessor :remember_header
  attr_accessor :remember_posx
  alias rvkd_gt_banners_remember_initialize initialize
  def initialize
    rvkd_gt_banners_remember_initialize
    @remember_banners = [[],[],[]]
    @remember_banner_phase = [0,0]
    @remember_joiners = []
    @remember_leavers = []
    @remember_removed = []
    @remember_header = nil
    @remember_posx = 471
  end

end

#==============================================================================
# ■ Scene_Map
#==============================================================================
class Scene_Map
  def get_spriteset
    return @spriteset
  end
  
  #--------------------------------------------------------------------------
  # alias method: start
  #--------------------------------------------------------------------------
  alias rvkd_scm_banners_start start
  def start
    rvkd_scm_banners_start
    resume_banners
  end
  
  #--------------------------------------------------------------------------
  # new method: resume_banners
  #--------------------------------------------------------------------------
  def resume_banners
    unless $game_temp.remember_banners[0].empty?
      @spriteset.title_banners = $game_temp.remember_banners[0].flatten!
    end
    unless $game_temp.remember_banners[1].empty?
      @spriteset.party_banners = $game_temp.remember_banners[1].flatten!
    end
    unless $game_temp.remember_banners[2].empty?
      @spriteset.red_banners = $game_temp.remember_banners[2].flatten!
    end
    @spriteset.tickdown = $game_temp.remember_banner_phase[0]
    @spriteset.banner_phase = $game_temp.remember_banner_phase[1]
    @spriteset.joiners = $game_temp.remember_joiners
    @spriteset.leavers = $game_temp.remember_leavers
    @spriteset.removed = $game_temp.remember_removed
    @spriteset.header_banner = $game_temp.remember_header
    @spriteset.posx = $game_temp.remember_posx
  end
  #--------------------------------------------------------------------------
  # * Overwrite: Call Menu Screen
  #--------------------------------------------------------------------------
  def call_menu
    return if $game_system.menu_disabled
    Sound.play_open_menu
    @spriteset.clear_banners
#~     if @spriteset.banners?
#~       bs = @spriteset.title_banners ? @spriteset.title_banners : []
#~       pb = @spriteset.party_banners ? @spriteset.party_banners : []
#~       rb = @spriteset.red_banners ? @spriteset.red_banners : []
#~       $game_temp.remember_banners = [[bs],[pb],[rb]]
#~       $game_temp.remember_banner_phase = [@spriteset.tickdown,@spriteset.banner_phase]
#~       $game_temp.remember_joiners = @spriteset.joiners
#~       $game_temp.remember_leavers = @spriteset.leavers
#~       $game_temp.remember_removed = @spriteset.removed
#~       $game_temp.remember_header = @spriteset.header_banner
#~       $game_temp.remember_posx = @spriteset.posx
#~     end
    SceneManager.call(Scene_Menu)
    Window_MenuCommand::init_command_position
  end
end

#==============================================================================
# ■ Game_Interpreter
#==============================================================================
class Game_Interpreter
  
  #--------------------------------------------------------------------------
  # new method: earn_title
  #--------------------------------------------------------------------------
  def earn_title(symbols)
    actors = []
    symbols.each do |symbol|
      for i in 1...5
        if Bubs::ToGTitleSystem::POTENTIAL_TITLES[i].include?(symbol.to_sym)
          actors.push(i) if $game_party.members.include?($game_actors[i])
        end
      end
    end
    SceneManager.scene.get_spriteset.show_title_banners(symbols,actors)
  end
  #--------------------------------------------------------------------------
  # new method: party_change
  #--------------------------------------------------------------------------
  def party_change(joiners,leavers, titles = nil, actors = nil)
    SceneManager.scene.get_spriteset.party_change(joiners,leavers,titles,actors)
  end
  
end #Game_Interpreter

#==============================================================================
# ■ Spriteset_Map
#==============================================================================
class Spriteset_Map
  
  attr_accessor :title_banners
  attr_accessor :party_banners
  attr_accessor :red_banners
  attr_accessor :header_banner
  attr_accessor :tickdown
  attr_accessor :banner_phase
  attr_accessor :joiners
  attr_accessor :leavers
  attr_accessor :removed
  attr_accessor :posx
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias rvkd_spm_earned_titles_initialize initialize
  def initialize
    @title_banners = []
    @party_banners = []
    @red_banners = []
    @header_banner = nil
    @waiting = 0
    @tickdown = 0
    @banner_phase = 0
    rvkd_spm_earned_titles_initialize
    @title_names = nil
    @title_actors = nil
  end
  
  #--------------------------------------------------------------------------
  # alias method: setup_title_banners
  #--------------------------------------------------------------------------
  def setup_title_banners(names,actors)
    @title_names = names
    @title_actors = actors
  end
  
  #--------------------------------------------------------------------------
  # alias method: update
  #--------------------------------------------------------------------------
  alias rvkd_spm_earned_titles_update update
  def update
    rvkd_spm_earned_titles_update
    party_banner_phase_update
    title_banner_phase_update
  end
  
  #--------------------------------------------------------------------------
  # new update method: title_banner_phase_update
  #--------------------------------------------------------------------------
  def title_banner_phase_update
    if @title_banners && !@title_banners.empty?
      if @tickdown == 200
        @title_banners.each {|banner| banner.move(-250,banner.y,100,20)}
        @header_banner.move(0,0,0,10)
        @tickdown += 1
      elsif @tickdown >= 225
        @tickdown = 0
        dispose_banners
      elsif @waiting > 0
        @waiting -= 1
        @header_banner.update_move
        return
      else
        update_banners 
        @tickdown += 1
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # new update method: party_banner_phase_update
  #--------------------------------------------------------------------------
  def party_banner_phase_update
    if @banner_phase > 0
      update_banners
    end
    case @banner_phase 
    when 1
      @tickdown += 1
      if @tickdown == 20
        @banner_phase = 2 
        transform_red; @tickdown = 0
      end
    when 2
      @tickdown += 1
      if @tickdown == 35 || @removed.empty?
        @banner_phase = 3
        dispose_reds; @tickdown = 0
      end
    when 3
      @tickdown += 1
      if @tickdown == 40
        collapse
        @banner_phase = 4
        @tickdown = 0
      end
    when 4
      @tickdown += 1
      if !@joiners.empty? && @tickdown == 17
        add_joiner(@joiners[0])
        Banner::EnterSound.play
        @tickdown = 0
      elsif @tickdown == 20
        $game_system.menu_disabled = false
      elsif @tickdown == 80
        @banner_phase = 5
        finale; @tickdown = 0
      end
    when 5
      @tickdown += 1
      if @tickdown == 18
        @banner_phase = 6
        banner_sweep; @tickdown = 0
        @header_banner.move(471,-26,255,10)
      end
    when 6
      @tickdown += 1
      if @tickdown == 13
        clear_banners
        $game_temp.remember_banner_phase = [0,0]
        $game_temp.remember_banners[1].clear
        $game_temp.remember_banners[2].clear
        @tickdown = 0
        @banner_phase = 0
        if @title_names && @title_actors
          show_title_banners(@title_names,@title_actors)
        end
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: banners?
  #--------------------------------------------------------------------------
  def banners?
    return !@title_banners.empty? || !@party_banners.empty? || !red_banners.empty?
  end
  #--------------------------------------------------------------------------
  # new method: update_banners
  #--------------------------------------------------------------------------
  def update_banners
    @title_banners.each {|banner| banner.update_move }
    @party_banners.each {|banner| banner.update_move}
    @red_banners.each {|banner| banner.update_move}
    @header_banner.update_move if @header_banner
  end
  #--------------------------------------------------------------------------
  # new method: dispose_banners
  #--------------------------------------------------------------------------
  def dispose_banners
    return if @title_banners.empty?
    @title_banners.each {|banner| banner.dispose}
    @title_banners = []
  end
  
  #--------------------------------------------------------------------------
  # new method: show_title_banners
  #--------------------------------------------------------------------------
  def show_title_banners(names,actors)
    return if names.size != actors.size #failsafe
    ind = 0; res_ind = []
    pos = 0; res_pos = []
    while ind < actors.size
      if $game_party.members.include?($game_actors[actors[ind]])
        if $game_actors[actors[ind]].title_learned?(names[ind]) == false
          res_ind.push(ind)
          res_pos.push(pos)
          pos+=1
        end
      end
      ind+=1
    end
    gain_titles(names,actors)
    return if pos <= 0
    @waiting = 5
    Banner::TitleSound.play
    show_header_banner
    for i in 0...res_ind.size
      show_title_banner(names[res_ind[i]].to_s,res_pos[i], actors[res_ind[i]])
    end
  end

  #--------------------------------------------------------------------------
  # new method: gain_titles
  #--------------------------------------------------------------------------
  def gain_titles(names,actors)
    for i in 0...names.size
      $game_actors[actors[i]].add_title(names[i])
    end
  end

  #--------------------------------------------------------------------------
  # new method: show_header_banner
  #--------------------------------------------------------------------------
  def show_header_banner
    @header_banner = BannerBG.new(0,0,@viewport)
    @header_banner.bitmap = Cache.banner("[TPX] Title")
    @header_banner.opacity = 0
    @header_banner.move(0,0,255,10)
  end
  #--------------------------------------------------------------------------
  # new method: show_title_banner
  #--------------------------------------------------------------------------
  def show_title_banner(name, index, actor)
    banner = Window_GainBanner.new(-245,31+(38*index),30+index*2,actor,name,@viewport2)
    banner.move(0,31+(38*index),255,26)
    @title_banners.push(banner)
  end

#===============\
# Party Banners |
#===============/
  
  #--------------------------------------------------------------------------
  # new method: party_change
  #--------------------------------------------------------------------------
  def party_change(joiners, leavers, titles = nil, actors = nil)
    @joiners = clear_joiners(joiners)
    @leavers = leavers
    place_initial
    @banner_phase = 1
    @title_names = titles if titles
    @title_actors = actors if actors
  end
  #--------+-----------------------------------------------------------------
  # Step 0 | Cut conflicts out of joiner array
  #--------+-----------------------------------------------------------------
  def clear_joiners(joiners)
    joiners.reverse_each do |join|
      joiners.delete(join) if $game_party.members.include?($game_actors[join])
    end
    return joiners
  end
  #--------+-----------------------------------------------------------------
  # Step 1 | Get the array and the size of the array of current party members.
  #--------+-----------------------------------------------------------------
  def get_party
    mems = []
    for i in 0...$game_party.members.count
      mems.push($game_party.members[i].id)
    end
    return mems
  end
  #--------+-----------------------------------------------------------------
  # Step 2 | Place transparent banners of current party members on the right.
  #--------+-----------------------------------------------------------------
  def place_initial
    @party_banners = []
    @header_banner = BannerBG.new(384,0,@viewport)
    @header_banner.bitmap = Cache.banner("[TPX] Formation")
    @header_banner.opacity = 0
    @header_banner.move(384,0,255,10)
    @posx = 471
    Banner::StartSound.play
    ind = 0
    $game_system.menu_disabled = true
    back = $game_party.members.count
    $game_party.members.each do |r|
      banner = BannerBG.new(@posx,205+40*ind,@viewport2)
      banner.bitmap = Cache.banner("[TPJ]#{r.id}")
      banner.opacity = 0
      banner.z = 49-ind
      banner.move(@posx,Banner::PosY[ind],255,10)
      @party_banners.push(banner)
      ind+=1
    end
    #Step 3: Reveal and slide-up the banners of current party members (All Gold)
  end
  
  #--------+-----------------------------------------------------------------
  # Step 4 | Check leaver array to blend and redden leaver banners.
  #--------+-----------------------------------------------------------------
  # Check the leaver array to see if it includes any people in the party.
  # Match leaver IDs with placed banner party member IDs
  # Turn ticked banners red
  def transform_red
    trans = []
    pty = $game_party.members
    for i in 0...pty.size
      trans.push(i) if @leavers.include?(pty[i].id)
    end
    @removed = []
    @red_banners = []
    trans.each do |r|
      banner = BannerBG.new(@posx,Banner::PosY[i],@viewport2)
      banner.bitmap = Cache.banner("[TPL]#{pty[r].id}")
      banner.opacity = 0
      banner.z = 39-r
      banner.move(@posx,Banner::PosY[r],255,3)
      @red_banners.push(banner)
      @party_banners[r].move(@posx,Banner::PosY[r],0,30)
      @removed.push(r)
    end
  end
  
  #--------+-----------------------------------------------------------------
  # Step 5 | Move red banners off-screen and dispose them, playing leaver SFX.
  #--------+-----------------------------------------------------------------
  def dispose_reds#(remo)
    @posx = 800
    if @red_banners.size > 0
      Banner::LeaveSound.play
    end
    @removed.reverse_each {|index| @party_banners.delete_at(index)}
    @red_banners.each do |red|
      red.move(@posx,red.y,0,11)
    end
  end
  
  #--------+-----------------------------------------------------------------
  # Step 6 | Shift the remaining party banners up to fill any empty spaces.
  #--------+-----------------------------------------------------------------
  def collapse
    @posx = 471
    for i in 0...@party_banners.size
      @party_banners[i].move(@posx,Banner::PosY[i],255,10)
    end
    @removed.reverse_each do |j|
      $game_party.remove_actor($game_party.members[j].id)
    end
  end
  #--------+-----------------------------------------------------------------
  # Step 7 | Slide in new joiners from the bottom, playing joiner SFX each time.
  #--------+-----------------------------------------------------------------
  def add_joiner(actor_id)
    @posx = 471
    distance = @party_banners.size
    banner = BannerBG.new(@posx,191+38*distance,@viewport2)
    banner.bitmap = Cache.banner("[TPJ]#{actor_id}")
    banner.opacity = 250
    banner.z = 30 + @joiners.size
    banner.move(@posx,Banner::PosY[@party_banners.size],255,15)
    @party_banners.push(banner)
    $game_party.add_actor(@joiners.shift)
  end  

  #--------+-----------------------------------------------------------------
  # Step 8 | After a delay, sweep final banners up and slide them off left.
  #--------+-----------------------------------------------------------------
  def finale
    Banner::SweepSound.play
    @posx = 471
    @party_banners.each  {|banner| banner.move(@posx,Banner::PosY[0],255,10)}
  end

  def banner_sweep
    @posx = -50
    @party_banners.each  {|banner| banner.move(@posx,Banner::PosY[0],0,10)}
  end
  
  def clear_banners
    @header_banner.dispose if @header_banner
    @title_banners.each  {|banner| banner.dispose}
    @party_banners.each  {|banner| banner.dispose}
    @red_banners.each    {|banner| banner.dispose}
  end
  
end #Spriteset_Map

#==============================================================================
# ■ Window_GainBanner
#==============================================================================
class Window_GainBanner < Window_Base
  def initialize(x,y,z,actor_id,symbol,viewport)
    super(x,y,250,34)
    self.windowskin = Cache.system("Window")
    self.x = x
    self.y = y
    self.z = viewport.z
    self.opacity = 0
    @banner_bg = BannerBG.new(x,y,viewport)
    @banner_bg.bitmap = Cache.banner("[TBG]"+actor_id.to_s)
    @banner_bg.z = z-1
    @banner_bg.opacity = 55
    @text = $data_titles[symbol.to_sym].name
    @rect = Rect.new(42,-2,208,40)
    contents.font.color.alpha = 255
    draw_text(@rect,@text,0)
  end
  
  #--------------------------------------------------------------------------
  # new method: move
  #--------------------------------------------------------------------------
  def move(x,y,opacity,duration)
    @target_x = x.to_f
    @target_y = y.to_f
    @target_opacity = opacity
    @duration = duration
  end
  
  #--------------------------------------------------------------------------
  # new method: update_move
  #--------------------------------------------------------------------------
  def update_move
    return if @duration == 0 || !@duration
    d = @duration
    set_x((self.x * (d - 1) + @target_x) / d)
    set_y((self.y * (d - 1) + @target_y) / d)
    set_op((@banner_bg.opacity * (d - 1) + @target_opacity) / d)
    @duration -= 1
  end
  
  def set_x(new_x)
    self.x = new_x
    @banner_bg.x = new_x
  end
  def set_y(new_y)
    self.y = new_y
    @banner_bg.y = new_y
  end
  def set_op(new_op)
    @banner_bg.opacity = new_op
  end
  
  def dispose
    @banner_bg.dispose
    contents.dispose unless disposed?
    super
  end
  
  def standard_padding; 0 end
    
end #Window_GainBanner
  
#==============================================================================
# ■ Window_InfoTitle
#==============================================================================
class Window_InfoTitle < Window_Base
  def initialize(viewport)
    super(0,0,200,35)
    self.x = 0
    self.y = 30
    self.z = 40
    @banner_bg = BannerBG.new(0,30,viewport)
    @banner_bg.bitmap = Cache.banner("[TPX] Title")
    @banner_bg.opacity = 0
    self.opacity = 0
  end
  
  #--------------------------------------------------------------------------
  # new method: move
  #--------------------------------------------------------------------------
  def move(x,y,opacity,duration)
    @target_x = x.to_f
    @target_y = y.to_f
    @target_opacity = opacity
    @duration = duration
  end
  
  #--------------------------------------------------------------------------
  # new method: update_move
  #--------------------------------------------------------------------------
  def update_move
    return if @duration == 0 || !@duration
    d = @duration
    set_x((self.x * (d - 1) + @target_x) / d)
    set_y((self.y * (d - 1) + @target_y) / d)
    set_op((@banner_bg.opacity * (d - 1) + @target_opacity) / d)
    @duration -= 1
  end
  
  def set_x(new_x)
    self.x = new_x
    @banner_bg.x = new_x
  end
  def set_y(new_y)
    self.y = new_y
    @banner_bg.y = new_y
  end
  def set_op(new_op)
    @banner_bg.opacity = new_op
  end
  
  def dispose
    @banner_bg.dispose
    contents.dispose unless disposed?
    super
  end
  
  def standard_padding; 0 end
    
end #Window_InfoTitle

#==============================================================================
# ■ BannerBG
#==============================================================================
class BannerBG < Sprite_Base
  
  def move(x,y,opacity,duration)
    @target_x = x.to_f
    @target_y = y.to_f
    @target_opacity = opacity
    @duration = duration
  end
  
  def update_move
    return if @duration == 0 || !@duration
    d = @duration
    self.x = ((self.x * (d - 1) + @target_x) / d)
    self.y = ((self.y * (d - 1) + @target_y) / d)
    self.opacity = ((self.opacity * (d - 1) + @target_opacity) / d)
    @duration -= 1
  end
  
end #BannerBG

#==============================================================================
# 
# ▼ End of File
# 
#==============================================================================