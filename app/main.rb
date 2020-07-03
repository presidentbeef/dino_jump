# Sound effects obtained from https://www.zapsplat.com

class DinoJump
  attr_gtk
  attr_reader :dino

  def initialize args
    self.args = args
    state.camera.x = 0

    @dino = Dino.new(args)
    @grass = Grass.new(args)

    # Background
    outputs.static_solids << [*grid.rect, 0, 43, 68, 155]
    outputs.sounds << 'sounds/audio_hero_Show-And-Tell_SIPML_Q-0149.ogg'
    reset_game
  end

  def reset_game
    @rock_order = [:brown, :dome, :gray, :purple, :crystal]
    @rocks = []
    @rock_count = 0
    @rock_limit = 10
  end

  def tick
    setup_world
    tick_game
    render
  end

  def camera
    state.camera
  end

  def setup_world
    if dino.state == :idle
      # Show initial message
      outputs.labels << [grid.center_x - 125, grid.h - 100, "GO!", 30]
    else
      # Points
      outputs.labels << [grid.center_x - 125, grid.h - 100, dino.points, 30]
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

  end

  def tick_game
    if inputs.keyboard.escape
      exit
    end

    case dino.state
    when :idle
      if inputs.keyboard.key_down.space or inputs.mouse.click
        dino.run
      end
    when :running
      if inputs.keyboard.key_down.space or inputs.mouse.click
        dino.jump
        outputs.sounds << "sounds/jump.wav"
      end
    when :done
      if inputs.keyboard.key_down.space or inputs.mouse.click
        reset_game
        dino.idle
      end

      return
    end

    dino.move 
    camera.x -= dino.dx

    @rocks.each do |rock|
      if not rock.already_hit? and rock.hit? dino.feet_box
        rock.hit!
        dino.points += 1
      end
    end

    @rocks.delete_if(&:passed?)

    if @rock_count > @rock_limit and dino.dy == 0
      dino.done
    end
  end

  def render
    render_rocks
    outputs.sprites << dino.sprite
    outputs.sprites << @grass.render
  end

  def render_rocks
    @rocks.each do |rock|
      outputs.sprites << rock.render(camera)
    end
  end
end

class Dino
  attr_accessor :x, :y, :dx, :dy, :state, :points

  def initialize args
    @args = args

    @x = 1
    @y = 1
    @dx = 0
    @dy = 0
    @state = :idle
    @points = 0
    @feetbox = { h: 30, w: 50 }
    @started_running_at = nil
    @started_jumping_at = nil

    @running_sprite = make_sprite('sprites/dino_run.png')
    @jumping_sprite = make_sprite('sprites/dino_jump.png')
    @idle_sprite = make_sprite('sprites/dino_idle.png')
  end

  def jump
    @state = :jumping
    @started_jumping_at = tick_count 
    @dy = 9
    @last_column = 0
  end

  def run
    @state = :running
    @dx = 5
    @started_running_at = tick_count
  end

  def move
    @x += @dx
    @y += @dy

    if @y >= 270
      @dy = -1 # Fall slower at first
    elsif @y >= 180 and @dy < 1
      @dy = -6
    elsif @y <= 2
      @dy = 0
      @y = 1

      if @state == :jumping
        @state = :running
        @started_running_at = tick_count
      end
    end
  end

  def idle
    @state = :idle
    @dx = 0
    @points = 0
  end

  def done
    @state = :done
  end

  def feet_box
    @feetbox[:x] = @x + camera.x + 120
    @feetbox[:y] = @y + 30
    @feetbox
  end

  def sprite
    case @state
    when :idle, :done
      idle_sprite
    when :jumping
      jumping_sprite
    else
      running_sprite
    end
  end

  private

  def idle_sprite
    column = 0.frame_index(9, 8, true)

    update_sprite(column, @idle_sprite)
  end

  def running_sprite
    column = @started_running_at.frame_index(8, 6, true)
    update_sprite(column, @running_sprite)
  end

  def jumping_sprite
    @last_column ||= 0

    column = @started_jumping_at.frame_index(9, 8, false)

    if column.nil? or column < @last_column
      column = 8
    end

    @last_column = column

    update_sprite(column, @jumping_sprite)
  end

  def make_sprite path
    {
      x: @args.grid.center_x - 640,
      y: @y + 10,
      w: 680 / 2,
      h: 472 / 2,
      tile_x: 0,
      tile_y: 0,
      tile_w: 680,
      tile_h: 472,
      path: path
    }
  end

  def update_sprite column, sprite
    sprite[:tile_x] = column * 680
    sprite[:y] = @y + 10
    sprite
  end

  def camera
    @args.state.camera
  end

  def tick_count
    @args.state.tick_count
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

    @sprite = {
      x: @x,
      y: @y,
      w: @w,
      h: @h,
      path: @path
    }

    @point_box = {
      x: @x + (@w / 2),
      y: @y + @h + 100,
      h: 200,
      w: 10
    }
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

    update_sprite
  end

  def update_sprite
    @sprite[:x] = @x
    @sprite
  end

  def point_box
    @point_box[:x] = @x + (@w / 2)
    @point_box
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

class Grass
  def initialize args
    @args = args

    x = @args.state.camera.x % -700
    width = 769

    @grass =[
      {
        x: x - 60,
        y: 0,
        w: width,
        h: 90,
        tile_x: 0,
        tile_y: 0,
        tile_w: 769,
        tile_h: 200,
        path:  'sprites/grass.png',
        offset: -60
      },
      {
        x: x + 640,
        y: 0,
        w: width,
        h: 90,
        tile_x: 0,
        tile_y: 0,
        tile_w: 769,
        tile_h: 200,
        path:  'sprites/grass.png',
        offset: 640
      },
      {
        x: x + 1340,
        y: 0,
        w: width,
        h: 90,
        tile_x: 0,
        tile_y: 0,
        tile_w: 769,
        tile_h: 200,
        path:  'sprites/grass.png',
        offset: 1340
      }
    ]
  end

  def render
    x = @args.state.camera.x % -700

    @grass.each do |grass|
      grass[:x] = x + grass[:offset]
    end

    @grass
  end
end


def tick args
  $game ||= DinoJump.new(args)
  $game.tick
end
