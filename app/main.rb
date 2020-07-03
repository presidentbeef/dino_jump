# Sound effects obtained from https://www.zapsplat.com

class DinoJump
  attr_gtk

  def initialize args
    self.args = args

    # Background
    outputs.static_solids << [*grid.rect, 0, 43, 68, 155]

    reset_game
  end

  def reset_game
    @rock_order = [:brown, :dome, :gray, :purple, :crystal]
    @rocks = []
    @rock_count = 0
    @rock_limit = 10
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
    state.player.points ||= 0
  end

  def camera
    state.camera
  end

  def player
    state.player
  end

  def setup_world
    if player.state == :idle
      # Show initial message
      outputs.labels << [grid.center_x - 125, grid.h - 100, "GO!", 30]
    else
      # Points
      outputs.labels << [grid.center_x - 125, grid.h - 100, player.points, 30]
    end

    # Rocks!
    if @rocks.empty?
      @rock_count += 1

      if @rock_order.empty?
        @rocks << Rock.new(camera.x)
      else
        @rocks << Rock.new(camera.x, @rock_order.shift)
      end
    end

    outputs.sounds << 'sounds/audio_hero_Show-And-Tell_SIPML_Q-0149.ogg'
  end

  def tick_game
    if inputs.keyboard.escape
      exit
    end

    case player.state
    when :idle
      if inputs.keyboard.key_down.space or inputs.mouse.click
        player.state = :running
        player.dx = 5
        player.started_running_at = state.tick_count
      end
    when :running
      if inputs.keyboard.key_down.space or inputs.mouse.click
        player.state = :jumping
        player.started_jumping_at = state.tick_count
        player.dy = 9
        outputs.sounds << "sounds/jump.wav"
        @last_column = 0 # For some reason the sprite is looping back to 0?
      end
    when :done
      if inputs.keyboard.key_down.space or inputs.mouse.click
        reset_game
        player.state = :idle
        player.dx = 0
        player.points = 0
      end

      return
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

    @rocks.each do |rock|
      if not rock.already_hit? and rock.hit? feet_box
        rock.hit!
        player.points += 1
      end
    end

    @rocks.delete_if(&:passed?)

    if @rock_count > @rock_limit and player.dy = 0
      player.state = :done
    end
  end

  def feet_box
    {
      x: player.x + camera.x + 120,
      y: player.y + 30,
      h: 30,
      w: 50
    }
  end

  def render
    render_rocks

    case player.state
    when :idle, :done
      outputs.sprites << idle_sprite
    when :jumping
      outputs.sprites << jumping_sprite
    else
      outputs.sprites << running_sprite
    end

    grass
  end

  def render_rocks
    @rocks.each do |rock|
      rock.render camera
      outputs.sprites << rock.sprite
    end
  end

  def running_sprite
    column = player.started_running_at.frame_index(8, 6, true)

    dino_sprite(column, 'sprites/dino_run.png')
  end

  def idle_sprite
    column = 0.frame_index(9, 8, true)

    dino_sprite(column, 'sprites/dino_idle.png')
  end

  def jumping_sprite
    @last_column ||= 0

    column = player.started_jumping_at.frame_index(9, 8, false)

    if column.nil? or column < @last_column
      column = 8
    end

    @last_column = column

    dino_sprite(column, 'sprites/dino_jump.png')
  end

  def dino_sprite column, path
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

  def rock_sprite
    outputs.sprites << {
      x: 1290 + (camera.x % -1500),
      y: 10,
      w: 147,
      h: 122,
      path: 'sprites/rock.png'
    }
  end

  def rock2
    outputs.sprites << {
      x: 1290 + (camera.x % -1500),
      y: 10,
      w: 250 / 2,
      h: 200 / 2,
      path: 'sprites/rock2.png'
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

class Rock
  def initialize start_x, type = Rocks.keys.sample
    template = Rocks[type]
    @path = template[:path]
    @w = template[:w]
    @h = template[:h]
    @passed = false
    @hit = false
    @x = 1290 # Offscreen
    @y = 10
    @last_camera = start_x
  end

  def passed?
    @passed
  end

  def render camera
    # Use dx so @x will always move left
    dx = (camera.x - @last_camera).abs
    @last_camera = camera.x
    @x -= dx

    if @x + @w < 0 # Offscreen
      @passed = true
    end
  end

  def sprite
    {
      x: @x,
      y: @y,
      w: @w,
      h: @h,
      path: @path
    }
  end

  def point_box
    {
      x: @x + (@w / 2),
      y: @y + @h + 100,
      h: 200,
      w: 10
    }
  end

  def already_hit?
    @hit
  end

  def hit!
    @hit = true
  end

  def hit? hit_box
    hit_box.intersect_rect? self.point_box
  end

  Rocks = {
    gray: {
      w: 147,
      h: 122,
      path: 'sprites/rock.png'
    },
    dome: {
      w: 125,
      h: 100,
      path: 'sprites/rock2.png'
    },
    brown: {
      w: 109,
      h: 75,
      path: 'sprites/rock3.png'
    },
    purple: {
      w: 155,
      h: 125,
      path: 'sprites/rock4.png'
    },
    crystal: {
      w: 160,
      h: 152,
      path: 'sprites/crystal.png'
    }
  }
end


def tick args
  $game ||= DinoJump.new(args)
  $game.tick
end
