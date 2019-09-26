#===============================================================================
# Title: Formation Scene
# Author: Revoked
# 
# This script displays the positions of actors on the grid, and allows for the
# adjustment of their positions in battle. It also allows the player to change
# the order of their positions in the menu.
#
#  - Information regarding bonuses from certain positions is also shown.
#===============================================================================
# ** Configuration
#===============================================================================
module GSForm
  ImgShiftX = -12 #+ Grid::ShiftX
  ImgShiftY = +68 #+ Grid::ShiftY
  
  FacePosX = [560,510,460,410,360]
  FacePosY = 68
end

#==============================================================================
# ■ Game_Interpreter
#==============================================================================
class Game_Interpreter
  #----------------------------------------------------------------------------
  # Called by Common Event #11; retains positions when toggling party leader.
  #----------------------------------------------------------------------------
  def toggle_party_leader
    leader_id = $game_party.members[0].id
    $game_party.rem_actor(leader_id)
    $game_party.add_actor(leader_id)
    index = $game_party.battle_members.size - 1
    $game_system.party_pos.insert(index,$game_system.party_pos.shift)
  end
end

#==============================================================================
# ■ Window_MenuCommand
#==============================================================================
class Window_MenuCommand < Window_Command
  
  alias rvkd_formation_wmc_update update
  def update
    rvkd_formation_wmc_update
    formation_shortcut
  end
  
  def formation_shortcut
    if Input.trigger?(:X)
      select(5)
      process_ok
    end
  end
end



#==============================================================================
# ■ Scene_GSForm
#==============================================================================
class Scene_GSForm < Scene_MenuBase  
  
  #--------------------------------------------------------------------------
  # Full array to right_half array index conversion
  #--------------------------------------------------------------------------
  def num_half(num)
    return num - ((num / 8 + 1)*4)
  end
  def num_full(num)
    return ((num / 4 + 1) * 4) + num
  end
  
  attr_accessor :faces
  #--------------------------------------------------------------------------
  # start
  #--------------------------------------------------------------------------
  def start
    super
    init_grid
    draw_actor_sprites
    draw_actor_faces
    create_help_window
    @moving_sprites = []
    @grid_arrow = GridArrow.new(4,@viewport2)
    @grid_arrow.opacity = 0
    @grid_arrow.z = 40
    @help_window.opacity = 0
    @help_window.x = 9
    @help_window.y = 51
    @help_window.width = Graphics.width - 16
    @help_window.arrows_visible = false
    create_command_window
    @face_window = Window_GSFormFaces.new
    @face_window.arrows_visible = false
    @text_window = Window_GSFormInfo.new
    @order_sel = false
    @select_phase = 0
    @counter = 0
    @grid_tab_index = 0
  end
  #--------------------------------------------------------------------------
  # create_command_window
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_GSFormCommand.new(@help_window)
    @command_window.set_handler(:cancel, method(:return_scene))
    @command_window.set_handler(:move, method(:swap_selection))
    @command_window.set_handler(:order, method(:order_selection))
  end
  #--------------------------------------------------------------------------
  # * Pre-Termination Processing
  #--------------------------------------------------------------------------
  def terminate
    @grid.each {|tile| tile.menu_hide}
    dispose_all_windows
    (120/20).times do
      @grid_arrow.opacity =- 40
      @party.each {|mem| mem.opacity -= 40}
      @faces.each {|f| f.opacity -= 40}
      @grid.each {|tile| tile.opacity -= 20}
      Graphics.wait(1)
    end
    @grid_arrow.dispose
    @grid.each {|tile| tile.dispose}
    @party.each {|mem| mem.dispose}
    @faces.each {|f| f.dispose}
    Graphics.freeze
    dispose_main_viewport
    dispose_background
  end
  #--------------------------------------------------------------------------
  # * Update
  #--------------------------------------------------------------------------
  alias rvkd_gsform_scmb_update update
  def update
    rvkd_gsform_scmb_update
    @party.each {|sp| sp.update_index}
    if [1,2].include?(@select_phase)
      @grid_arrow.update_index
      check_input
    end
    if @select_phase == 3
      moving_units
    end
  end
  
  #--------------------------------------------------------------------------
  # * Swap Movement Animation
  #--------------------------------------------------------------------------
  def moving_units
    @moving_sprites.each do |sprite|
      sprite.shadow.x += sprite.x_vels[@counter]
      sprite.shadow.y += sprite.y_const[@counter]
      sprite.x += sprite.x_vels[@counter]
      sprite.y += sprite.y_vel
      sprite.y_vel += 1
    end
    @counter += 1
    if @counter >= 20
      update_text
      @party.each {|mem| mem.dispose}
      @counter = 0; @select_phase = 1; @moving_sprites = []; draw_actor_sprites
      @grid_arrow.opacity = 255
    end
  end
  def reactivate
    reset_faces
    @command_window.activate
  end
  def reset_faces
    @faces.each {|face| face.dispose}
    draw_actor_faces
  end
  #--------------------------------------------------------------------------
  # * Quick Switch Function
  #--------------------------------------------------------------------------
  def switch_to_swap
    Grid::GridSound.play
    @command_window.select(0)
    swap_selection
    update_text
  end
  def switch_to_order
    @text_window.clear_all
    Sound.play_cursor
    up_one_level
    @command_window.select(1)
    @command_window.deactivate
    order_selection
  end
  
  #--------------------------------------------------------------------------
  # init_grid
  #--------------------------------------------------------------------------
  def init_grid
    @grid = []; i = 0
    while i < 32
      @grid.push(GridSelector.new(Grid::GridPlaces[i],true,@viewport1)) if i%8>3
      i+=1
    end
    @grid.each do |tile|
      tile.tone = Tone.new(50,50,50)
      tile.opacity = 100 + $game_variables[Grid::OpacityVar] / 2
      tile.x = tile.x + GSForm::ImgShiftX
      tile.y = tile.y + GSForm::ImgShiftY
      tile.selector.x = tile.x
      tile.selector.y = tile.y
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: draw_actor_sprites
  #--------------------------------------------------------------------------
  def draw_actor_sprites
    @party = []
    for i in 0...$game_party.battle_members.size
      index = $game_party.battle_members[i].position
      #index = $game_system.party_pos[i]
      if index.nil?
        msgbox_p($game_system.party_pos) 
        msgbox_p(i)
      end
      @party.push(GridSprite.new(index,$game_party.battle_members[i],@viewport2))
    end
    for i in 0...$game_party.battle_members.size
      @grid[num_half($game_system.party_pos[i])].menu_show
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: draw_actor_faces
  #--------------------------------------------------------------------------
  def draw_actor_faces
    @faces = []
    $game_party.members.reverse_each do |mem|
      index = $game_party.members.size - $game_party.members.index(mem) - 1
      @faces.push(GridFace.new(index,mem,@viewport3, $game_party.members.index(mem)>3))
    end
  end
  
  
  #--------------------------------------------------------------------------
  # new method: check_input
  #--------------------------------------------------------------------------
  def check_input
    @last_index = @grid_cursor_index
    if Input.trigger?(:B)
      Sound.play_cancel
      up_one_level
      return
    end
    if Input.trigger?(:C)
      if @sel_origin == @last_index; Sound.play_buzzer; return; end
      if @select_phase == 2 && ($game_system.party_pos.dup.first($game_party.members.size) & [num_full(@sel_origin),num_full(@last_index)]).empty?
        Sound.play_buzzer; return
      end
      if @order_sel == false; confirm_action; return
      elsif $game_system.party_pos.index(num_full(@last_index)) != nil
        confirm_action
      else; Sound.play_buzzer
      end
    end
    if Input.trigger?(:UP) && @select_phase == 1 && [0,1,2,3].include?(@last_index)
      switch_to_order 
      return
    end
    grid_down  if Input.repeat?(:DOWN)
    grid_left  if Input.repeat?(:LEFT)
    grid_right if Input.repeat?(:RIGHT)
    grid_up    if Input.repeat?(:UP)
    if Input.trigger?(:X)
      tab_increment if @grid_tab_index == @grid_cursor_index && $game_party.members.size > 1
      @grid_cursor_index = num_half($game_system.party_pos[@grid_tab_index])
      Grid::GridTab.play unless $game_party.members.size <= 1
      tab_increment
    end
    if @grid_cursor_index != @last_index
      @grid_arrow.set_position(num_full(@grid_cursor_index))
      @grid[@last_index].unlight unless @last_index == @sel_origin
      @grid[@grid_cursor_index].light
      update_text
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: tab_increment
  #--------------------------------------------------------------------------
  def tab_increment
    @grid_tab_index += 1 
    @grid_tab_index = 0 if @grid_tab_index >= $game_party.battle_members.size
  end
  
  #--------------------------------------------------------------------------
  # new method: confirm_action
  #--------------------------------------------------------------------------
  def confirm_action
    if @select_phase == 2
      RPG::SE.new("AO - Card_Select", 80, 100).play
      @grid[@sel_origin].unlight
      @grid_arrow.opacity = 0
      if @order_sel == true
        swap_member_order(@sel_origin,@last_index)
        @select_phase = 1
      else
        swap_locations(@sel_origin,@last_index)
        @select_phase = 3
      end
      @sel_origin = nil
      @bitmap_set = false
      return
    end
    if @select_phase == 1
      Sound.play_ok
      @sel_origin = @last_index
      @grid[@sel_origin].menu_dark
      @select_phase = 2
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: up_one_level
  #--------------------------------------------------------------------------
  def up_one_level
    @select_phase -= 1
    if @select_phase <= 0
      @select_phase = 0
      @grid_arrow.opacity = 0
      @grid[@last_index].unlight
      @command_window.activate
      @text_window.clear_all
    end
    if @select_phase == 1
      @grid[@sel_origin].unlight if @sel_origin != @grid_cursor_index
      @grid[@sel_origin].menu_hide
      #@grid[@sel_origin].menu_show if $game_system.party_pos.include?(num_full(@sel_origin))
      @bitmap_set = false
      @sel_origin = nil
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: swap_locations
  #--------------------------------------------------------------------------
  def swap_locations(one,two)
    locations = $game_system.party_pos.dup
    p(locations)
    if locations.index(num_full(one)) != nil
      first  = locations.index(num_full(one))
      $game_system.party_pos[first]  = num_full(two)
    end
    if locations.index(num_full(two)) != nil
      second = locations.index(num_full(two))
      $game_system.party_pos[second] = num_full(one)
    end
    @grid.each {|tile| tile.menu_hide}
    jump_sprite(@party[first], num_full(two)) if first
    jump_sprite(@party[second], num_full(one)) if second
  end
  
  #--------------------------------------------------------------------------
  # new method: jump_sprite
  #--------------------------------------------------------------------------
  def jump_sprite(member,target_index)
    return if member.nil?
#~     final_x = Grid::Position[target_index][0] + GSForm::ImgShiftX - 16
#~     final_y = Grid::Position[target_index][1] + GSForm::ImgShiftY - 32
    final_x = Grid.position(target_index,0) + GSForm::ImgShiftX - 16
    final_y = Grid.position(target_index,1) + GSForm::ImgShiftY - 32
    dx = final_x - member.x
    dy = final_y - member.y
    xv = dx/20.0
    x_ds = Array.new(20,xv.to_i)
    while x_ds.inject(0){|sum,x| sum + x} > dx
      x_ds[rand(20)] -= 1
    end
    while x_ds.inject(0){|sum,x| sum + x} < dx
      x_ds[rand(20)] += 1
    end
    final_shadow_y = final_y + 21
    sdy = final_shadow_y - member.shadow.y
    yv = sdy/20.0
    sy_vel = Array.new(20,yv.to_i)
    while sy_vel.inject(0){|sum,y| sum + y} > sdy
      sy_vel[rand(20)] -= 1
    end
    while sy_vel.inject(0){|sum,y| sum + y} < sdy
      sy_vel[rand(20)] += 1
    end
    member.y_const = sy_vel
    member.x_vels = x_ds
    member.y_vel = dy / 20 - 0.5*1*20 + 1
    
    @moving_sprites.push(member)
  end
  
  #--------------------------------------------------------------------------
  # new method: swap_member_order
  #--------------------------------------------------------------------------
  def swap_member_order(first_pindex,second_pindex)
    one = $game_system.party_pos[first_pindex]
    two = $game_system.party_pos[second_pindex]
    locations = $game_system.party_pos.dup
    if first_pindex < 4 && second_pindex < 4
      $game_system.party_pos[first_pindex] = two
      $game_system.party_pos[second_pindex] = one
    else
      Grid::GridConfirm.play
    end
    @grid.each {|tile| tile.menu_hide}
    $game_party.swap_order(first_pindex, second_pindex)
    @party.each {|mem| mem.dispose}
    @faces.each {|f| f.dispose}
    draw_actor_sprites
    draw_actor_faces
  end

  #--------------------------------------------------------------------------
  # new method: swap_selection
  #--------------------------------------------------------------------------
  def swap_selection
    @order_sel = false
    @grid_cursor_index = num_half($game_system.party_pos[0])
    @grid[@grid_cursor_index].light
    @grid_arrow.opacity = 255
    @grid_arrow.set_position($game_system.party_pos[0])
    @select_phase = 1
    update_text
  end
  
  #--------------------------------------------------------------------------
  # new method: order_selection
  #--------------------------------------------------------------------------
  def order_selection
    @text_window.clear_all
    @face_window.activate
  end
  
  #--------------------------------------------------------------------------
  # Grid Movement methods
  #--------------------------------------------------------------------------
  def grid_down
    if [12,13,14,15].include?(@grid_cursor_index)
      Grid::GridError.play if Input.trigger?(:DOWN); return; end
    @grid_cursor_index += 4
    Grid::GridSound.play 
  end
  def grid_left
    if [0,4,8,12].include?(@grid_cursor_index)
      Grid::GridError.play if Input.trigger?(:LEFT); return; end
    @grid_cursor_index -= 1 
    Grid::GridSound.play 
  end
  def grid_right
    if [3,7,11,15].include?(@grid_cursor_index)
      Grid::GridError.play if Input.trigger?(:RIGHT); return; end
    @grid_cursor_index += 1 
    Grid::GridSound.play 
  end
  def grid_up
    if [0,1,2,3].include?(@grid_cursor_index)
      Grid::GridError.play if Input.trigger?(:UP); return; end
    @grid_cursor_index -= 4 
    Grid::GridSound.play 
  end
  
end # Scene_GSForm

#==============================================================================
# ** GridSprite
#==============================================================================
class GridSprite < Sprite_Battler #Sprite
  attr_accessor :shadow
  attr_accessor :x_vels
  attr_accessor :y_vel
  attr_accessor :y_const
  def initialize(index,actor,viewport)
    super(viewport)
    @x_vels = [0]
    @y_vel = 0
    @frame = 0
    @actor = actor
    self.bitmap = Cache.rvkd("Sp#{@actor.id}#{@frame}")
#~     self.x = Grid::Position[index][0] + GSForm::ImgShiftX - 16
#~     self.y = Grid::Position[index][1] + GSForm::ImgShiftY - 32
    self.x = Grid.position(index,0) + GSForm::ImgShiftX - 16
    self.y = Grid.position(index,1) + GSForm::ImgShiftY - 32
    self.z = 30
    @shadow = GridShadow.new(self.x,self.y,viewport)
  end
  
  #--------------------------------------------------------------------------
  # new method: update_index
  #--------------------------------------------------------------------------
  def update_index
    @frame+=1
    @frame = 0 if (@frame / 15) >= 4
    if @frame % 15 == 0
      self.bitmap = Cache.rvkd("Sp#{@actor.id}#{@frame/15}")
    end
  end
end

#==============================================================================
# ** GridShadow
#==============================================================================
class GridShadow < Sprite
  
  def initialize(xpos,ypos,viewport)
    super(viewport)
    self.bitmap = Cache.rvkd("Shadow")
    self.x = xpos
    self.y = ypos + 21
    self.z = 25
  end
end #GridShadow

#==============================================================================
# ** GridFace
#==============================================================================
class GridFace < Sprite
  def initialize (index,actor,viewport, grey = false)
    super(viewport)
    @actor = actor
    self.bitmap = Cache.rvkd("Spf#{actor.id}")
    self.x = GSForm::FacePosX[index]
    self.y = GSForm::FacePosY
    self.z = 220
    self.grey_out if grey == true
  end
  def select_col
    self.opacity = 100
  end
  def grey_out
    self.opacity = 255
    self.bitmap = Cache.rvkd("Spg#{@actor.id}")
  end
  def normal
    self.opacity = 255
    self.bitmap = Cache.rvkd("Spf#{@actor.id}")
  end
end #GridFace

#==============================================================================
# ** GridArrow
#==============================================================================
class GridArrow < Sprite
  
  def set_position(index)
#~     self.x = Grid::Position[index][0]-17 + GSForm::ImgShiftX
#~     self.y = Grid::Position[index][1]-58 + GSForm::ImgShiftY
    self.x = Grid.position(index,0)-17 + GSForm::ImgShiftX
    self.y = Grid.position(index,1)-58 + GSForm::ImgShiftY
  end
  
end #GridArrow

#==============================================================================
# ** GridSelector
#==============================================================================
class GridSelector < Sprite_Battler
  
  def menu_show
    self.opacity = 200 + $game_variables[Grid::OpacityVar]/2
  end
  def menu_hide
    self.opacity = 100 + $game_variables[Grid::OpacityVar]/2
  end
  def menu_dark
    self.opacity = 255
  end
  
end #GridShadow

#==============================================================================
# ■ Window_GSForm_Command
#==============================================================================
class Window_GSFormCommand < Window_Command
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(help_window)
    @help_window = help_window
    super(26, 68) #8,54
    self.width = 184
    self.height = 48
    self.opacity = 0
    clear_command_list
    make_command_list
    refresh
    select(0)
    activate
    open
  end
  
  def col_max ; 2 end
  def spacing ; 16 end
  def alignment ; 1 end
    
  def make_command_list
    add_command("Move", :move)
    add_command("Order", :order)
  end
end #Window_GSForm_Command

#==============================================================================
# ■ Window_GSForm_Faces
#==============================================================================
class Window_GSFormFaces < Window_Selectable
  def initialize
    super(GSForm::FacePosX[item_max-1]-9,GSForm::FacePosY-9, item_max*50+16, 66)
    self.opacity = 0
    @last_index = 0
    @index = 0
    @selected = false
  end
  
  alias rvkd_gsformfaces_activate activate
  def activate
    if @last_index < item_max
      @index = @last_index
    else
    @index = 0
    end
    rvkd_gsformfaces_activate
  end
  
  def item_max ; $game_party.members.size end
  def standard_padding ; 8 end
    
  def col_max ; item_max end
  def row_max ; 1 end
  def spacing ; 0 end
    
  def item_width ; 50 end
  def item_height ; 50 end
  
  def process_handling
    return unless open? && active
    return process_ok       if ok_enabled? && Input.trigger?(:C)
    return process_cancel   if Input.trigger?(:B)
    return process_swap     if !@selected && Input.trigger?(:DOWN)
  end
  
  def ok_enabled?
    return true
  end
  
  def process_swap
    SceneManager.scene.reset_faces
    Input.update
    @last_index = @index
    @index = -1
    deactivate
    call_cancel_handler
    SceneManager.scene.switch_to_swap
  end
  
  def process_ok
    if !@selected
      SceneManager.scene.faces[SceneManager.scene.faces.size-@index-1].select_col
      @selected = true
      @last_index = @index
      @first_index = @index
      Sound.play_ok
      return
    else
      @last_index = @index
      @second_index = @index
      SceneManager.scene.swap_member_order(@first_index,@second_index)
      @selected = false
      Sound.play_ok
    end
  end
  
  def process_cancel
    if !@selected
      Sound.play_cancel
      Input.update
      @last_index = @index
      @index = -1
      deactivate
      call_cancel_handler
      SceneManager.scene.reactivate
      return
    else
      @selected = false
      Sound.play_cancel
      SceneManager.scene.reset_faces
    end
  end

end #Window_GSForm_Faces

#==============================================================================
# 
# ▼ End of File
# 
#==============================================================================