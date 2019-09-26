class Window_CurrentActor < Window_Base
  
  def standard_padding; 0 end
  
  def initialize(actor)
    super(1,1,160,24)
    self.opacity = 0
    @actor = actor
    refresh
  end
  
  def actor=(a)
    @actor = a
    refresh
  end
  
  def draw_actor_icons
    contents.clear
    @data = $game_party.members.collect {|mem| mem.id}
    @data.each_with_index {|id,i| make_icons(id,i)}
  end
  
  def make_icons(id,index)
    icon = (@actor.id == id ? 223 : 255)
    draw_icon(icon + id, 0 + 24*index, 0, true)
  end
  
  def update
  end
  
  def refresh
    draw_actor_icons
  end
  
end

class Scene_Skill
  alias rvkd_scene_skill_wca_start start
  def start
    rvkd_scene_skill_wca_start
    @current_actor_window = Window_CurrentActor.new(@actor)
  end
  
  alias rvkd_scene_skill_wca_on_actor_change on_actor_change
  def on_actor_change
    rvkd_scene_skill_wca_on_actor_change
    @current_actor_window.actor = @actor
  end
end
class Scene_Passive
  alias rvkd_scene_passive_wca_start start
  def start
    rvkd_scene_passive_wca_start
    @current_actor_window = Window_CurrentActor.new(@actor)
  end
  
  alias rvkd_scene_passive_wca_on_actor_change on_actor_change
  def on_actor_change
    rvkd_scene_passive_wca_on_actor_change
    @current_actor_window.actor = @actor
  end
end

class Scene_Equip
  alias rvkd_scene_equip_wca_start start
  def start
    rvkd_scene_equip_wca_start
    @current_actor_window = Window_CurrentActor.new(@actor)
  end
  
  alias rvkd_scene_equip_wca_on_actor_change on_actor_change
  def on_actor_change
    rvkd_scene_equip_wca_on_actor_change
    @current_actor_window.actor = @actor
  end
end

class Scene_ToGTitles
  alias rvkd_scene_togtitles_wca_start start
  def start
    rvkd_scene_togtitles_wca_start
    @current_actor_window = Window_CurrentActor.new(@actor)
  end
  
  alias rvkd_scene_togtitles_wca_on_actor_change on_actor_change
  def on_actor_change
    rvkd_scene_togtitles_wca_on_actor_change
    @current_actor_window.actor = @actor
  end
end

