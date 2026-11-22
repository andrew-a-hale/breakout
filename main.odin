package breakout

import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(640, 480, "Hello, World!")
	defer rl.CloseWindow()

	game: Game = init()
	rl.SetTargetFPS(game.config.target_fps)
	start_game(&game)
	for !rl.WindowShouldClose() {
		update(&game)
		render(&game)
		input_handler(&game)
	}
}
