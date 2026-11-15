package breakout

import "core:fmt"
import rl "vendor:raylib"

main :: proc() {
	fmt.print("Hello, World")
	rl.InitWindow(640, 480, "Hello, World!")
	defer rl.CloseWindow()

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawRectangle(0, 0, 100, 100, rl.RED)
		rl.EndDrawing()
	}
}
