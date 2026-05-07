# SNKRX [GSOC 2026]

This repository focuses on porting gameplay systems inspired by SNKRX into Atmos to evaluate how reactive tasks, signals, and structured concurrency compare against traditional imperative Lua architectures.

---

### Areas Of Exploration:
- Reactive finite state machines
- Signal-based gameplay systems
- Structured cleanup and task lifetimes
- Arena and wave progression flow
- Enemy Logic and player ability systems
- Screen management and transitions

---

```lua
func WaveLevel ( max_waves ) {
  await @ { s =3 }
  loop i in max_waves {
    watching : enemies_cleared {
      every : clock { }
    }
    await @ { ms =500 }
    spawn_enemies ()
  }
  await : enemies_cleared
}
```
