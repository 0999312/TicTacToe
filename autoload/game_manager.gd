extends Node

enum Player { X = 0, O = 1 }
enum GameMode { PVP, PVAI }
enum GameState { IDLE, PLAYING, OVER }

const WIN_LINES: Array[Array] = [
	[0, 1, 2], [3, 4, 5], [6, 7, 8],
	[0, 3, 6], [1, 4, 7], [2, 5, 8],
	[0, 4, 8], [2, 4, 6],
]

var board: Array = []
var current_player: Player = Player.X
var mode: GameMode = GameMode.PVP
var state: GameState = GameState.IDLE
var player_side: Player = Player.X
var move_count: int = 0
var ai_player: Player = Player.O
var player1_score: int = 0
var player2_score: int = 0
var draw_score: int = 0
var ai_timer: Timer
var cursor_index: int = 4


func _ready() -> void:
	ai_timer = Timer.new()
	ai_timer.one_shot = true
	ai_timer.timeout.connect(_do_ai_move)
	add_child(ai_timer)
	EventBus.subscribe(&"RematchEvent", _on_rematch)
	_init_board()


func _init_board() -> void:
	board.clear()
	for _i in 9:
		board.append(-1)
	move_count = 0
	current_player = Player.X
	cursor_index = 4


func start_game(p_mode: GameMode, p_player_side: Player = Player.X) -> void:
	if p_mode != GameMode.PVP and p_mode != GameMode.PVAI:
		push_warning("GameManager.start_game: invalid mode %d" % p_mode)
	if p_player_side != Player.X and p_player_side != Player.O:
		push_warning("GameManager.start_game: invalid player_side %d" % p_player_side)
	mode = p_mode
	player_side = p_player_side
	if mode == GameMode.PVAI:
		ai_player = Player.O if player_side == Player.X else Player.X
	_init_board()
	state = GameState.PLAYING
	EventBus.publish(GameStartedEvent.new(mode))
	EventBus.publish(TurnChangedEvent.new(current_player))
	EventBus.publish(CursorMovedEvent.new(cursor_index))
	if mode == GameMode.PVAI and current_player == ai_player:
		_schedule_ai_move()


func reset_board() -> void:
	_init_board()
	state = GameState.PLAYING
	EventBus.publish(GameStartedEvent.new(mode))
	EventBus.publish(TurnChangedEvent.new(current_player))
	EventBus.publish(CursorMovedEvent.new(cursor_index))
	if mode == GameMode.PVAI and current_player == ai_player:
		_schedule_ai_move()


func place_mark(cell_index: int) -> bool:
	if cell_index < 0 or cell_index > 8:
		push_warning("GameManager.place_mark: cell_index %d out of range [0-8]" % cell_index)
		return false
	if state != GameState.PLAYING:
		return false
	if board[cell_index] != -1:
		return false
	board[cell_index] = current_player
	move_count += 1
	EventBus.publish(CellPlacedEvent.new(cell_index, current_player))

	var winner := _check_winner()
	if winner != -1:
		state = GameState.OVER
		if winner == Player.X:
			player1_score += 1
		else:
			player2_score += 1
		EventBus.publish(GameWonEvent.new(winner))
		EventBus.publish(ScoreChangedEvent.new(player1_score, player2_score, draw_score))
		return true

	if _is_board_full():
		state = GameState.OVER
		draw_score += 1
		EventBus.publish(GameDrawEvent.new())
		EventBus.publish(ScoreChangedEvent.new(player1_score, player2_score, draw_score))
		return true

	_switch_turn()
	EventBus.publish(TurnChangedEvent.new(current_player))

	if mode == GameMode.PVAI and current_player == ai_player:
		_schedule_ai_move()

	return true


func move_cursor(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		push_warning("GameManager.move_cursor: direction is zero vector")
		return
	if state != GameState.PLAYING:
		return
	@warning_ignore("integer_division")
	var row: int = cursor_index / 3
	var col: int = cursor_index % 3
	col = clampi(col + int(direction.x), 0, 2)
	row = clampi(row + int(direction.y), 0, 2)
	var new_index := row * 3 + col
	if new_index != cursor_index:
		cursor_index = new_index
		EventBus.publish(CursorMovedEvent.new(cursor_index))


func get_cell(index: int) -> int:
	if index >= 0 and index < 9:
		return board[index] as int
	return -1


func get_current_player_text() -> String:
	return "X" if current_player == Player.X else "O"


func get_winner() -> int:
	return _check_winner()


func is_game_over() -> bool:
	return state == GameState.OVER


# --- private ---

func _switch_turn() -> void:
	current_player = Player.O if current_player == Player.X else Player.X


func _check_winner() -> int:
	for line in WIN_LINES:
		var a: int = board[line[0]]
		var b: int = board[line[1]]
		var c: int = board[line[2]]
		if a != -1 and a == b and b == c:
			return a
	return -1


func _is_board_full() -> bool:
	return move_count >= 9


func _schedule_ai_move() -> void:
	ai_timer.start(0.3)


func _do_ai_move() -> void:
	var best := _find_best_move()
	if best >= 0:
		place_mark(best)


func _find_best_move() -> int:
	if move_count == 0:
		return 4

	var best_score: float = -INF
	var best_index := -1
	for i in 9:
		if board[i] == -1:
			board[i] = ai_player
			var score := _minimax(false, 0)
			board[i] = -1
			if score > best_score:
				best_score = score
				best_index = i
	return best_index


func _minimax(is_maximizing: bool, depth: int) -> int:
	var winner := _check_winner()
	if winner != -1:
		return 10 - depth if winner == ai_player else depth - 10
	if _is_board_full():
		return 0

	if is_maximizing:
		var best: float = -INF
		for i in 9:
			if board[i] == -1:
				board[i] = ai_player
				best = max(best, _minimax(false, depth + 1))
				board[i] = -1
		return int(best)
	else:
		var best: float = INF
		var opponent := Player.X if ai_player == Player.O else Player.O
		for i in 9:
			if board[i] == -1:
				board[i] = opponent
				best = min(best, _minimax(true, depth + 1))
				board[i] = -1
		return int(best)


# --- EventBus handlers ---

func _on_rematch(_event: Event) -> void:
	# Handles RematchEvent: reset board for a new game
	reset_board()
