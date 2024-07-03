package main
import rl    "vendor:raylib"

AudioPool :: struct {
    sounds          : [dynamic]rl.Sound,
    lastSoundIndex  : i32,
}

PlayRandomAudioFromPool :: proc(pool: ^AudioPool) {
    using pool
    random := rl.GetRandomValue(0, i32(len(sounds) - 1))
    if random == lastSoundIndex {
        random = (random + 1) % i32(len(sounds))
    }
    sound := sounds[random]
    lastSoundIndex = random
    rl.PlaySound(sound)
}

UnloadSoundsFromPool :: proc(pool: AudioPool) {
    using pool
    for sound in sounds {
        rl.UnloadSound(sound)
    }
}