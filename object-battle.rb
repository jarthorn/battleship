class Ship
  attr_reader :name, :size, :coordinates

  def initialize(name, size)
    @name = name
    @size = size
    @coordinates = []
    @hits = 0
  end

  def is_sunk?
    @hits >= @size
  end

  def place(start_coord, orientation, board_size)
    x, y = start_coord
    @coordinates = []

    @size.times do
      return false if x >= board_size || y >= board_size
      @coordinates << [x, y]
      orientation == 'horizontal' ? y += 1 : x += 1
    end

    true
  end

  def hit(coord)
    if @coordinates.include?(coord)
      @hits += 1
      true
    else
      false
    end
  end
end

class Board
  attr_reader :size, :ships

  def initialize(size)
    @size = size
    @grid = Array.new(size) { Array.new(size, '~') }
    @ships = []
  end

  def add_ship(ship, start_coord, orientation)
    if ship.place(start_coord, orientation, @size)
      ship.coordinates.each do |x, y|
        @grid[x][y] = 'S'
      end
      @ships << ship
      true
    else
      false
    end
  end

  def receive_attack(coord)
    x, y = coord
    case @grid[x][y]
    when 'S'
      @grid[x][y] = 'X'
      @ships.each do |ship|
        return 'hit' if ship.hit(coord)
      end
      'miss'
    when '~'
      @grid[x][y] = 'O'
      'miss'
    else
      'already attacked'
    end
  end

  def display
    @grid.each do |row|
      puts row.map { |cell| cell }.join(' ')
    end
  end

  def valid_coordinate?(coord)
    x, y = coord
    x.between?(0, @size - 1) && y.between?(0, @size - 1)
  end

  def coordinate_status(coord)
    x, y = coord
    @grid[x][y] if valid_coordinate?(coord)
  end
end

class Player
  attr_reader :name, :board

  def initialize(name)
    @name = name
    @board = Board.new(10) # Default board size is 10x10
  end

  def add_ship(ship, start_coord, orientation)
    @board.add_ship(ship, start_coord, orientation)
  end

  def attack(other_player, coord)
    other_player.board.receive_attack(coord)
  end

  def all_sunk?
    @board.ships.all?(&:is_sunk?)
  end
end

class Game
  attr_reader :player1, :player2, :current_player

  def initialize(player1_name, player2_name)
    @player1 = Player.new(player1_name)
    @player2 = Player.new(player2_name)
    @current_player = @player1
  end

  def setup_ships(player, ships_info)
    ships_info.each do |name, size, start, orientation|
      ship = Ship.new(name, size)
      unless player.add_ship(ship, start, orientation)
        raise "Failed to place ship #{name} at #{start} in orientation #{orientation}"
      end
    end
  end

  def switch_turn
    @current_player = @current_player == @player1 ? @player2 : @player1
  end

  def game_over?
    @player1.all_sunk? || @player2.all_sunk?
  end

  def winner
    if @player1.all_sunk?
      @player2.name
    elsif @player2.all_sunk?
      @player1.name
    else
      nil
    end
  end

  def play_turn(target_coord)
    result = @current_player.attack(@current_player == @player1 ? @player2 : @player1, target_coord)
    switch_turn
    result
  end
end

class GameRunner
  ADJACENT_OFFSETS = [[-1, 0], [1, 0], [0, -1], [0, 1]]

  def initialize(game)
    @game = game
    @hits = []
    @targets = []
  end

  def random_shot(board)
    loop do
      coord = [rand(board.size), rand(board.size)]
      return coord if board.coordinate_status(coord) == '~' || board.coordinate_status(coord) == 'S'
    end
  end

  def adjacent_targets(last_hit)
    x, y = last_hit
    ADJACENT_OFFSETS.map { |dx, dy| [x + dx, y + dy] }.select { |coord| @game.player2.board.valid_coordinate?(coord) }
  end

  def next_shot
    if @targets.empty?
      random_shot(@game.current_player == @game.player1 ? @game.player2.board : @game.player1.board)
    else
      @targets.shift
    end
  end

  def play
    until @game.game_over?
      current_player = @game.current_player
      target_coord = next_shot
      result = @game.play_turn(target_coord)
      puts "#{current_player.name} attacks #{target_coord}: #{result}"

      if result == 'hit'
        @hits << target_coord
        @targets.concat(adjacent_targets(target_coord)).shuffle!  # Add adjacent squares to targets and shuffle
      elsif result == 'miss' || result == 'already attacked'
        @targets.reject! { |coord| coord == target_coord }  # Remove target if it was a miss or already attacked
      end
      puts "Current board of #{current_player.name}:"
      current_player.board.display
      puts
    end

    puts "Game over! Winner: #{@game.winner}"
  end
end

# Usage
game = Game.new('Player1', 'Player2')

# Setup phase
ships_info = [
  ['Carrier', 5, [0, 0], 'horizontal'],
  ['Battleship', 4, [2, 2], 'vertical']
]

game.setup_ships(game.player1, ships_info)
game.setup_ships(game.player2, ships_info)

# Run the game
runner = GameRunner.new(game)
runner.play
