class DinoJump 
  attr_gtk

  def initialize
  end

  def tick
    setup_camera
    setup_player
    setup_world
    tick_game
    render
  end

  def setup_camera
    state.camera.x ||= 0 
  end

  def setup_player
    state.player.x ||= 1
    state.player.y ||= 1
    state.player.dx ||= 0
    state.player.dy ||= 0
    state.player.state ||= :idle
  end

  def camera
    state.camera
  end

  def player
    state.player
  end

  def setup_world
    if player.state == :idle
      outputs.labels << [grid.center_x - 125, grid.h - 100, "GO!", 30]
    end
    # Background
    outputs.solids << [*grid.rect, 0, 43, 68, 155]
  end

  def tick_game
    if player.state == :idle
      if inputs.keyboard.key_down.space
        player.state = :running
        player.dx = 5
        player.started_running_at = state.tick_count
      end
    elsif player.state == :running
      if inputs.keyboard.key_down.space
        player.state = :jumping
        player.started_jumping_at = state.tick_count
        player.dy = 9
        @last_column = 0 # For some reason the sprite is looping back to 0?
      end
    end

    player.x += player.dx
    player.y += player.dy
    camera.x -= player.dx

    if player.state == :jumping
      if player.y >= 270
        player.dy = -1 # Fall slower at first
      elsif player.y >= 180 and player.dy < 1
        player.dy = -6
      elsif player.y <= 2
        player.dy = 0
        player.y = 1
        player.state = :running
        player.started_running_at = state.tick_count
      end
    else
      player.dy = 0
    end
  end

  def render
    rock

    case player.state
    when :idle
      outputs.sprites << idle_sprite
    when :jumping
      outputs.sprites << jumping_sprite
    else
      outputs.sprites << running_sprite
    end

    grass
  end

  def running_sprite
    column = player.started_running_at.frame_index(8, 6, true)

    sprite(column, 'sprites/dino_run.png')
  end

  def idle_sprite
    column = 0.frame_index(9, 8, true)

    sprite(column, 'sprites/dino_idle.png')
  end

  def jumping_sprite
    @last_column ||= 0

    column = player.started_jumping_at.frame_index(9, 8, false)

    if column.nil? or column < @last_column
      column = 8
    end

    @last_column = column

    sprite(column, 'sprites/dino_jump.png')
  end

  def sprite column, path
    {
      x: grid.center_x - 640,
      y: player.y + 10,
      w: 680 / 2,
      h: 472 / 2,
      tile_x: column * 680,
      tile_y: 0,
      tile_w: 680,
      tile_h: 472,
      path:  path
    }
  end

  def rock
    outputs.sprites << {
      x: 1290 + (camera.x % -1500),
      y: 10,
      w: 147,
      h: 122,
      path: 'sprites/rock.png'
    }
  end

  def grass
    width = 769

    x = camera.x % -700

    outputs.sprites << {
        x: x - 60,
        y: 0,
        w: width,
        h: 90,
        tile_x: 0,
        tile_y: 0,
        tile_w: 769,
        tile_h: 200,
        path:  'sprites/grass.png'
      }

    outputs.sprites << {
        x: x + 640,
        y: 0,
        w: width,
        h: 90,
        tile_x: 0,
        tile_y: 0,
        tile_w: 769,
        tile_h: 200,
        path:  'sprites/grass.png'
      }

    outputs.sprites << {
        x: x + 1340,
        y: 0,
        w: width,
        h: 90,
        tile_x: 0,
        tile_y: 0,
        tile_w: 769,
        tile_h: 200,
        path:  'sprites/grass.png'
      }
  end
end


def tick args
  $game ||= DinoJump.new
  $game.args = args
  $game.tick
end
