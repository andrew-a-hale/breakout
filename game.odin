package breakout

import "core:fmt"
import "core:time"
import rl "vendor:raylib"

// game state + config
MAX_ENTITIES :: 1000
GameConfig :: struct {
	target_fps:         i32,
	max_entities:       uint,
	window_size:        rl.Vector2,
	game_window_size:   rl.Vector2,
	game_window_center: rl.Vector2,
	player_size:        rl.Vector2,
	player_speed:       uint,
	player_pos:         rl.Vector2,
	player_lives:       uint,
	ball_size:          rl.Vector2,
	ball_speed:         uint,
	ball_pos:           rl.Vector2,
	block_size:         rl.Vector2,
}

Notification :: struct {
	duration: uint, // frames
	text:     string,
	pos:      rl.Vector2,
}

GameState :: struct {
	time_tick:     time.Tick,
	active_balls:  uint,
	player_lives:  uint,
	blocks_left:   uint,
	active_level:  uint,
	notifications: []Notification,
	event_offset:  int,
}

// entities
EntityType :: enum {
	None,
	Player,
	Ball,
	Block,
	Wall,
}

Entity :: struct {
	id:        uint,
	type:      EntityType,
	pos:       rl.Vector2,
	size:      rl.Vector2,
	speed:     uint,
	direction: rl.Vector2,
	health:    uint,
	color:     rl.Color,
}
Entities :: [MAX_ENTITIES]Entity

get_player_entity :: proc(game: ^Game) -> uint {
	for e in game.entities {
		if e.type == EntityType.Player {
			return e.id
		}
	}

	return 0 // no player
}

// event store
EventType :: enum {
	EntityMoved,
	EntityDestroyed,
	EntitySpawned,
	LifeRemoved,
	GameCompleted,
}

Movement :: struct {
	entity_id: uint,
	speed:     uint,
	direction: rl.Vector2,
}

EventData :: union {
	Entity, // SpawnData
	Movement,
}

Event :: struct {
	type:          EventType,
	timestamp:     i64,
	originator_id: uint,
	data:          EventData,
}

Events :: [dynamic]Event

push_event :: proc(store: ^Events, event: Event) -> bool {
	if n, err := append_elem(store, event); err != nil || n == 0 {
		fmt.eprintf("failed to push event %v", event)
		return false
	}
	return true
}

Game :: struct {
	config:      GameConfig,
	state:       GameState,
	entities:    Entities,
	event_store: Events,
}

destroy_entity :: proc(block_id: uint) -> bool {return true}
remove_life :: proc() -> bool {return true}
move_entity :: proc(game: ^Game) -> bool {
	entity := game.entities[get_player_entity(game)]
	movement := Movement {
		entity_id = entity.id,
		speed     = entity.speed,
	}


	moved := false
	if rl.IsKeyDown(rl.KeyboardKey.A) || rl.IsKeyDown(rl.KeyboardKey.LEFT) {
		moved = true
		movement.direction = rl.Vector2{-1, 0}
	}

	if rl.IsKeyDown(rl.KeyboardKey.D) || rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
		moved = true
		movement.direction = rl.Vector2{1, 0}
	}

	if moved {
		if ok := move_entity_event(movement, game, 0); !ok {
			fmt.eprint("failed to move entity")
		}
	}

	return true
}

spawn_entity :: proc(entity: Entity, game: ^Game, originator_id: uint) -> bool {
	new_entity := entity

	// find id
	for e in game.entities {
		if e.type == EntityType.None && e.id > 0 {
			new_entity.id = e.id
			break
		}
	}

	if new_entity.id == 0 {
		fmt.eprint("failed to create entity: no free slots")
		return false
	}

	// emit event
	if ok := spawn_entity_event(new_entity, game, originator_id); !ok {
		return false
	}

	return true
}

start_game :: proc(game: ^Game) -> bool {
	// player
	player_ok := spawn_entity(
		Entity {
			type = EntityType.Player,
			pos = game.config.player_pos,
			size = game.config.player_size,
			speed = game.config.player_speed,
			direction = rl.Vector2{},
			health = game.config.player_lives,
			color = rl.RAYWHITE,
		},
		game,
		0,
	)

	if !player_ok {
		fmt.eprint("failed to spawn player")
		return false
	}

	return true
}

complete_game :: proc() -> bool {return true}
stop_game :: proc() -> bool {return true}

// events
spawn_entity_event :: proc(entity: Entity, game: ^Game, originator_id: uint) -> bool {
	event := Event {
		type          = EventType.EntitySpawned,
		timestamp     = i64(time.tick_since(game.state.time_tick)),
		originator_id = originator_id,
		data          = entity,
	}

	return push_event(&game.event_store, event)
}

move_entity_event :: proc(movement: Movement, game: ^Game, originator_id: uint) -> bool {
	event := Event {
		type          = EventType.EntityMoved,
		timestamp     = i64(time.tick_since(game.state.time_tick)),
		originator_id = originator_id,
		data          = movement,
	}

	return push_event(&game.event_store, event)
}

// init
init :: proc() -> Game {
	PADDING :: 10
	config := GameConfig {
		target_fps         = 60,
		max_entities       = MAX_ENTITIES,
		window_size        = rl.Vector2{640, 480},
		game_window_size   = rl.Vector2{640 - PADDING, 480 - PADDING},
		game_window_center = rl.Vector2{(640 - PADDING) / 2, (480 - PADDING) / 2},
		player_size        = rl.Vector2{PADDING * 3, PADDING},
		player_speed       = 4,
		player_pos         = rl.Vector2{(640 - 3 * PADDING) / 2, 480 - 2 * PADDING},
		player_lives       = 3,
		ball_size          = rl.Vector2{PADDING, PADDING},
		ball_speed         = 3,
		ball_pos           = rl.Vector2{(640 - PADDING) / 2, (480 - PADDING) / 2},
		block_size         = rl.Vector2{PADDING, PADDING},
	}

	state := GameState {
		time_tick    = time.tick_now(),
		active_balls = 1,
		player_lives = config.player_lives,
		blocks_left  = 0,
		active_level = 0,
		event_offset = 0,
	}

	entities := Entities{}
	for i in 0 ..< config.max_entities {
		entities[i] = Entity {
			id   = i,
			type = EntityType.None,
		}
	}

	events := make([dynamic]Event)
	game := Game{config, state, entities, events}

	return game
}

input_handler :: proc(game: ^Game) -> bool {
	// player movement
	move_entity(game)

	return true
}

// drain the events
apply_spawn_entity :: proc(game: ^Game, event: Event) -> bool {
	entity, ok := event.data.(Entity)
	if !ok {
		fmt.eprint("failed to spawn entity: malformed event data")
		return false
	}

	game.entities[entity.id] = entity
	return true
}

apply_move_entity :: proc(game: ^Game, event: Event) -> bool {
	movement, ok := event.data.(Movement)
	if !ok {
		fmt.eprint("failed to move entity: malformed event data")
		return false
	}

	game.entities[movement.entity_id].pos.x =
		game.entities[movement.entity_id].pos.x + movement.direction.x * f32(movement.speed)

	return true
}

drain :: proc(game: ^Game) -> bool {
	start_offset := game.state.event_offset
	for game.state.event_offset < len(game.event_store) {
		event := game.event_store[game.state.event_offset]

		switch event.type {
		case .EntityMoved:
			if ok := apply_move_entity(game, event); !ok {
				panic("failed to move entity")
			}
		case .EntityDestroyed:
		case .EntitySpawned:
			if ok := apply_spawn_entity(game, event); !ok {
				panic("failed to spawn entity")
			}
		case .LifeRemoved:
		case .GameCompleted:
		}

		game.state.event_offset += 1
	}

	// DEBUG: print event delta
	if start_offset < game.state.event_offset {
		fmt.println(game.event_store[start_offset:])
	}

	return true
}

update :: proc(game: ^Game) -> bool {
	drain(game)
	return true
}
