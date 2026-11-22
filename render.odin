package breakout

import "core:fmt"
import rl "vendor:raylib"

render_block :: proc(entity: Entity) -> bool {return true}
render_player :: proc(entity: Entity) -> bool {
	rl.DrawRectangle(
		i32(entity.pos.x),
		i32(entity.pos.y),
		i32(entity.size.x),
		i32(entity.size.y),
		entity.color,
	)
	return true
}
render_walls :: proc(entity: Entity) -> bool {return true}
render_hud :: proc(state: ^GameState) -> bool {return true}
render_note :: proc(state: ^GameState) -> bool {return true}

render :: proc(game: ^Game) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	defer rl.EndDrawing()

	for e in game.entities {
		switch e.type {
		case .None:
		case .Player:
			if ok := render_player(e); !ok {
				fmt.eprint("failed to render player")
			}
		case .Ball:
		case .Block:
			if ok := render_block(e); !ok {
				fmt.eprint("failed to render block")
			}
		case .Wall:
			if ok := render_walls(e); !ok {
				fmt.eprint("failed to render walls")
			}
		}
	}

	if ok := render_hud(&game.state); !ok {
		fmt.eprint("failed to render hud")
	}

	if ok := render_note(&game.state); !ok {
		fmt.eprint("failed to render note")
	}
}
