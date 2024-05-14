BOARD_SIZE = 10

# Define ship sizes
SHIPS = [
  { name: 'Aircraft Carrier', size: 5 },
  { name: 'Battleship', size: 4 },
  { name: 'Cruiser', size: 3 },
  { name: 'Submarine', size: 3 },
  { name: 'Destroyer', size: 2 }
]

# Function to create an empty board
def create_empty_board(size)
  Array.new(size) { Array.new(size, 0) }
end

# Function to create a shots tracking board
def create_shots_board(size)
  Array.new(size) { Array.new(size, false) }
end

# Function to check if the ship can be placed at the position
def can_place_ship?(board, row, col, size, is_horizontal)
  if is_horizontal
    return false if col + size > BOARD_SIZE
    (0...size).all? { |i| board[row][col + i] == 0 }
  else
    return false if row + size > BOARD_SIZE
    (0...size).all? { |i| board[row + i][col] == 0 }
  end
end

# Function to place the ship on the board
def place_ship(board, ship_number, size)
  placed = false
  until placed
    is_horizontal = [true, false].sample # Randomly decide if the ship is placed horizontally or vertically
    row = rand(BOARD_SIZE)
    col = rand(BOARD_SIZE)

    if can_place_ship?(board, row, col, size, is_horizontal)
      if is_horizontal
        (0...size).each { |i| board[row][col + i] = ship_number }
      else
        (0...size).each { |i| board[row + i][col] = ship_number }
      end
      placed = true
    end
  end
end

# Main function to generate the game board
def generate_random_board
  board = create_empty_board(BOARD_SIZE)
  SHIPS.each_with_index do |ship, index|
    place_ship(board, index + 1, ship[:size])
  end
  board
end

# Function to generate checkerboard pattern coordinates
def generate_checkerboard_pattern
  pattern = []
  (0...BOARD_SIZE).each do |row|
    (0...BOARD_SIZE).each do |col|
      pattern << [row, col] if (row + col).even?
    end
  end
  pattern.shuffle
end

# Get adjacent coordinates
def get_adjacent_coordinates(row, col)
  [
    [row - 1, col],
    [row + 1, col],
    [row, col - 1],
    [row, col + 1]
  ].select { |r, c| r.between?(0, BOARD_SIZE - 1) && c.between?(0, BOARD_SIZE - 1) }
end

# Take a shot
def take_shot(game_board, shots, target_queue, checkerboard_pattern)
  shot = nil

  # If no target in queue, use checkerboard pattern
  if target_queue.empty?
    until checkerboard_pattern.empty?
      potential_shot = checkerboard_pattern.shift
      row, col = potential_shot
      unless shots[row][col]
        shot = potential_shot
        break
      end
    end
  else
    shot = target_queue.shift
  end

  # Final fallback if no shot has been assigned
  if shot.nil?
    (0...BOARD_SIZE).each do |row|
      (0...BOARD_SIZE).each do |col|
        unless shots[row][col]
          shot = [row, col]
          break
        end
      end
      break if shot
    end
  end

  # If shot is still nil, raise an error to catch unexpected states
  raise "No valid shots remaining" if shot.nil?

  row, col = shot
  shots[row][col] = true

  result = game_board[row][col]

  if result == 0
    puts "Shot at (#{row}, #{col}): Miss"
    { row: row, col: col, result: 'Miss' }
  else
    puts "Shot at (#{row}, #{col}): Hit (Ship #{result})"
    adj_coords = get_adjacent_coordinates(row, col)
    adj_coords.each { |r, c| target_queue << [r, c] unless shots[r][c] }
    { row: row, col: col, result: 'Hit', ship: result }
  end
end

# Example function to run the shots
def simulate_game
  game_board = generate_random_board
  shots = create_shots_board(BOARD_SIZE)
  target_queue = []
  checkerboard_pattern = generate_checkerboard_pattern

  moves = 0
  hits = 0
  total_ship_cells = SHIPS.reduce(0) { |sum, ship| sum + ship[:size] }

  until hits >= total_ship_cells
    shot_result = take_shot(game_board, shots, target_queue, checkerboard_pattern)
    hits += 1 if shot_result[:result] == 'Hit'
    moves += 1
  end

  puts "Game over in #{moves} moves! All ships have been hit."
end

# Run the game simulation
simulate_game
