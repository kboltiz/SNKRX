# Positioning and Anchoring

In SNKRX, the main menu displays three left-aligned buttons: *arena run*, *options*, and *quit*.

## Lua + LOVE2D

In the original implementation, each button is constructed with an explicit x-coordinate [(mainmenu.lua)](https://github.com/kboltiz/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/mainmenu.lua#L85):

```lua
self.arena_run_button = Button{x = 55, y = gh/2 - 10, button_text = 'arena run', ...}
self.options_button   = Button{x = 47, y = gh/2 + 12, button_text = 'options', ...}
self.quit_button      = Button{x = 37, y = gh/2 + 34, button_text = 'quit', ...}
```

The x-coordinates (55, 47, 37) decrease as the button text gets shorter. The programmer manually tuned each value to preserve left-alignment across buttons of different widths. The underlying Button class centers its text by setting it's alignment parameter to 'center' [(Button)](https://github.com/kboltiz/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/buy_screen.lua#L596), but exposes no alignment option for the button's own position, leaving the caller responsible for compensating.

## Atmos + Pico

In Atmos, all three buttons share the same x-coordinate, using the anchor='W' (west) parameter to declare left-alignment explicitly [(menu.atm)](https://github.com/kboltiz/SNKRX/blob/34abfe76fd6b3afbded3d1e8a4830bcdc2550265/atmos-port/menu.atm#L10):

```lua
pico.output.draw.rect(@{ '%', x=0.01, y=0.5, w=0.18, h=0.08, anchor='W' })
pico.output.draw.rect(@{ '%', x=0.01, y=0.6, w=0.15, h=0.08, anchor='W' })
pico.output.draw.rect(@{ '%', x=0.01, y=0.7, w=0.13, h=0.08, anchor='W' })
```

The anchor point eliminates the need for manual x-offset tuning. Changing a button's width does not require updating its position.

## Analysis
The original Lua code uses the x-coordinate as an implicit alignment variable, encoding the button's visual intent as a "magic number". It also means tweaking the button's internal layout (like centering text) doesn't cascade into position fixes.


---

# Button Encapsulation and Sizing

In SNKRX, each button sizes itself to fit its text content and is drawn to the screen each frame.

## Lua + LOVE2D

In the original implementation, button sizing is computed in `Button:init` [(buy_screen.lua)](https://github.com/kboltiz/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/buy_screen.lua#L594):

```lua
self.shape = Rectangle(self.x, self.y,
    args.w or (pixul_font:get_text_width(self.button_text) + 8),
    pixul_font.h + 4)
```

The width is derived from the text width plus a fixed pixel padding (`+8`), and the height from the font height plus padding (`+4`). The button is then drawn directly to the screen each frame in `Button:draw` [(buy_screen.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/buy_screen.lua#L635):

```lua
function Button:draw()
    graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, ...)
    self.text:draw(self.x, self.y + 1, 0, 1, 1)
    graphics.pop()
end
```

The button background and text are drawn separately every frame. Positioning the text relative to the button requires manual offset calculations (`self.y + 1`). The button is a class with separate `init`, `update`, and `draw` methods — the programmer must navigate across all of them to understand the full behavior.

## Atmos + Pico

In Atmos, the button is a self-contained task. Sizing, drawing, and hover detection all live in one place [(menu.atm)](https://github.com/a327ex/SNKRX/blob/d1f1354f34ea0b944e9712989dbbb04dbf70f66c/atmos-port/menu.atm#L14):

```lua
func Button(x, y, h, anc, text) {
    val rect = @{"%", x=x, y=y, h=h, anchor=anc}
    pico.get.text(rect, text)
    pico.layer.empty(:world, text, false, rect)
    
    pico.zet.layer(text)
    pico.zet.effect @{ color=@{"%", r=0.2, g=0.2, b=0.2} }
    pico.output.clear()
    
    pico.zet.pencil @{ color='white' }
    pico.output.draw.text(text, @{ "%", x=0.5, y=0.5, h=1-PAD })
    pico.zet.layer(:world)
    ...
}
```

`pico.get.text` fills the rect's width based on the text content directly, removing the need for manual width calculation. The button is then rendered once into its own layer — inside the layer, the text is simply centered at `(0.5, 0.5)`, no manual offsets needed. The same `rect` is then drawn onto the world each frame:

```lua
every :draw { pico.output.draw.layer(text, rect) }
```

## Analysis

In the original Lua code, sizing and rendering are spread across `init` and `draw`, each only tells part of the story. In Atmos, the button is a single task: `pico.get.text` derives the size from text content, the button layer confines rendering to its own coordinate space where centering is simplified, and the same `rect` serves sizing, drawing, and collision detection for hovering.

---

# Hover Detection

## Lua + LOVE2D

Hover behavior is split across two callbacks [(buy_screen.lua)](https://github.com/kboltiz/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/buy_screen.lua#L649):

```lua
function Button:on_mouse_enter()
    self.selected = true
    ...
end
function Button:on_mouse_exit()
    self.selected = false
    ...
end
```

The hover state is tracked by `self.selected`, a flag initialized in one method and accessed in others for rendering a different button visual based on hover state in the `:draw()` method. Understanding the full hover behavior requires reading across the entire class.

## Atmos + Pico

In Atmos, hover detection requires no explicit state variables [(menu.atm)](https://github.com/kboltiz/SNKRX/blob/15a1aed72edf9af568b8a7e7222de1a206a981dc/atmos-port/menu.atm#L29):

```lua
loop {
    ;; idle
    await(:mouse.motion, \{pico.vs.pos.rect(it, rect)})
    ;; hovered
    await(:mouse.motion, \{!pico.vs.pos.rect(it, rect)})
}
```

The two states (idle and hovered) are part of a sequential loop, entirely self-contained. This is an example of a simple state machine. No flags are needed to track which state the button is in. The flow of the loop decides the transitions.

## Analysis

In the original Lua code, hover state is spread across two callbacks connected only by `self.selected`. What triggers the transition, what resets it, is implicit and scattered across methods that each only tell part of the story. In Atmos, enter and exit are not disconnected callbacks but two consecutive steps in the same loop. The hover behavior is entirely self-contained: no flags, no cross-method state, and the sequence itself communicates the intent.

# Spring based Scaling

In SNKRX, buttons scale up on hover using a spring simulation — a physics-based animation that overshoots and oscillates before settling at the target value.

## Lua + LOVE2D

1. The spring in SNKRX runs for the entire lifetime of the button. Every Button object is added to a `Group` on creation:

```lua
self.arena_run_button = Button{group = self.main_ui, x = 55, ...}
```

2. The group calls `:update(dt)` on every object it contains each frame [(group.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/engine/game/group.lua#L54):


3. `Button:update()` calls `self:update_game_object(dt)` [(buy_screen.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/buy_screen.lua#L601), which updates the spring every frame [(gameobject.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/engine/game/gameobject.lua#L42):

```lua
function GameObject:update_game_object(dt)
    self.spring:update(dt)
    ...
end
```

4. The hover effect is triggered by `:pull()`, which instantly sets the spring's current value to a new position and lets physics ease it back to idle scale:

```lua
function Button:on_mouse_enter()
    self.spring:pull(0.2, 200, 10)
    ...
end
```

5. The spring calculations stop only when the screen exits — `MainMenu:on_exit()` destroys the group [(mainmenu.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/mainmenu.lua#L148):

6. `Group:destroy()` clears `self.objects` [(group.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/engine/game/group.lua#L164):

```lua
function Group:destroy()
    self.objects = {}
end
```

Once `self.objects` is empty, the group stops calling `:update()` on its buttons. The spring stops with it. It runs every frame from button creation to screen exit, regardless of whether it is animating or at rest.

## Atmos + Pico

In Atmos, the spring is a self-contained task pinned to the button's lifetime [(spring.atm)](https://github.com/kboltiz/SNKRX/blob/8d708668291547f2905fbb82d60c5584cdea291d/atmos-port/spring.atm):

```lua
func (hoverPullSize) {
    ...
    await :start        ;; idle until first hover

    loop {
        set pub.scale = hoverPullSize   ;; teleport to hover size
        watching :start {               ;; abort and restart if hovered again
            every i, ms in :clock {
                ...                     ;; spring physics
                if math.abs(pub.scale - target) < 0.0001 {
                    escape(:target_reached) ;; stop calculating
                }
            }
            await(false)                ;; idle until next hover
        }
    }
}
```

The spring starts idle at `await :start`. On hover enter, Button emits `:start` to the spring task:

```lua
emit [spring] (:start)
```
and the spring's calculative work begins.

The spring teleports `pub.scale` to `hoverPullSize` and begins animating back toward `target = 1.0`. When the difference from target and spring pos are both negligible, the spring escapes the `every` loop and suspends at `await(false)`. Calculations stop entirely until the next `:start`.

If another hover enter occurs while the spring is still animating, `watching :start` aborts the current flow, the outer loop restarts, and the spring snaps to `hoverPullSize` and begins again from the top. 

## Analysis

In the original Lua code, the spring runs from creation to screen exit regardless of whether it is useful. The spring only halts on the button's `group` being destroyed on screen exit, which stops the update chain that "drills" four calls deep: `group:update` -> `button:update` -> `update_game_object` -> `spring:update`. Understanding why the spring stops requires tracing this chain.

In Atmos, the spring is a task that owns its own lifecycle. It suspends when converged and resumes only when `:start` is emitted. When the button task exits for any reason, including screen change, the pinned spring task is aborted automatically.

# Button Click Action Flow

In SNKRX, clicking a button triggers the next screen or action. Each button carries its own callback and is responsible for knowing the action that should execute after the click. In Atmos, the continuation is held by the caller waiting for the button's result.

## Lua + LOVE2D

Each button in the main menu is constructed with an `action` callback that fires on click [(mainmenu.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/mainmenu.lua#L85):

```lua
self.arena_run_button = Button{
    group = ..., x = ..., y = ...,
    button_text = 'arena run',
    action = function(b)
        TransitionEffect{
            transition_action = function()
                self.transitioning = true
                main:add(BuyScreen'buy_screen')
                main:go_to('buy_screen', run.level or 1, ...)
            end
        }
    end
}
```

The destination screen is never called directly. The click fires a `TransitionEffect`, which fires `transition_action`, which calls `main:go_to`. The actual navigation is three callbacks deep. Each button holds a direct reference to the next screen it transitions to.

Each screen is responsible for cleaning up after itself but also for knowing what comes after it.

The options button manages its own paused state:

```lua
self.options_button = Button{
    action = function(b)
        if not self.paused then
            open_options(self) -- implemented in main.lua
        else
            close_options(self)
        end
    end
}
```

and the quit button simply saves game state, and quits using `love.event.quit()` 

## Atmos + Pico

In Atmos, each button returns the id it was given when clicked [(menu.atm)](https://github.com/kboltiz/SNKRX/blob/25ff89b97dc56d6444491f0bd917846a298ef27c/atmos-port/menu.atm#L84):

```lua
func Button(id, x, y, h, anc, text) {
    ...
    par {
        ...
    } with {
        await(:mouse.button.dn, \{pico.vs.pos.rect(it, text)})
        return(id)
    }
}
```

When a button is clicked, `return(id)` terminates the button task entirely, aborting its draw loop, hover loop, and spring task automatically. The tasks' `await` in the caller receives the first button to terminate:

```lua
pin bs = tasks(3)
spawn [bs] Button(:arena_run, ...)
spawn [bs] Button(:options, ...)
spawn [bs] Button(:quit, ...)

val clicked_id = await(bs)
match clicked_id {
    :arena_run => print("Arena Run!")
    :options   => print("Options!")
    :quit      => print("Quit.")
}
```

The buttons know nothing about what happens after they are clicked. The caller decides. Each button is only responsible for returning its own id.

## Analysis

In the original Lua code, each button holds a reference to the next screen and is responsible for the transition logic. The arena run button references `BuyScreen` directly, constructs a `TransitionEffect`, and calls `main:go_to`. Understanding what a button click does requires tracing three levels of callbacks across multiple files. The continuation is carried through these callbacks.

A button click terminates the task and returns an id. The caller handles the result in a single match block. Using await and sequential control flow, Atmos keeps the continuation in the parent task rather than passing it to the button. Activities remain decoupled and hold no references to one another.

---

# Transition Effect Control Flow

In SNKRX, screen transitions are handled by a `TransitionEffect` object that executes navigation logic after completing a sequence of timed animations. In Atmos, the next activity is passed directly to the transition and executed through normal control flow.

## Lua + LOVE2D

In the original SNKRX implementation, a button does not directly change screens. Instead, it creates a `TransitionEffect` and provides a `transition_action` callback describing what should happen once the transition completes [(mainmenu.lua)](https://github.com/kboltiz/SNKRX/blob/c73637d484e6814c0e9615faf5c560e30aa57e4d/mainmenu.lua#L86):

```lua
self.arena_run_button = Button{
    action = function()
        TransitionEffect{
            transition_action = function()
                self.transitioning = true
                main:add(BuyScreen'buy_screen')
                main:go_to('buy_screen', run.level or 1, ...)
            end
        }
    end
}
```

The screen change occurs inside a tween completion handler deep within the transition object. The arena run button holds a direct reference to `BuyScreen` and is responsible for constructing the transition, passing the continuation, and describing the navigation. Understanding what a click does requires following the flow from the button action, into the transition object, and finally into the tween callback that performs it.

## Atmos + Pico

In Atmos, the menu task is the only place that touches all three screens. After `await(bs)` returns the clicked button's id, it decides what follows [(menu.atm)](https://github.com/kboltiz/SNKRX/blob/1aceac8ed74dad0f034e9a32d57508ea7114e899/atmos-port/menu.atm#L112):

```lua
match id {
    :arena_run => Transition(Arena, 0.5, 0.5)
    :quit      => return()
}
```

`Transition` covers the screen, starts the next activity, and reveals it, all in sequence [(transition.atm)](https://github.com/kboltiz/SNKRX/blob/1aceac8ed74dad0f034e9a32d57508ea7114e899/atmos-port/transition.atm#L16):

```lua
TransitionIn(screenshot, x, y)
par_and {
    next()
} with {
    TransitionOut(x, y)
}
```

The transition knows nothing about which activity comes next. It receives it as an argument and calls it at the right point in its own control flow.

## Analysis

In the original Lua code, the arena run button holds a direct reference to `BuyScreen` and carries the continuation through three levels of callbacks before the screen actually changes. Each button is responsible for knowing what comes after it.

In Atmos, the buttons know nothing about what follows them. The menu task is the single parent that describes the full flow. It awaits the first button to be clicked, then decides the next screen in one place. The transition itself is decoupled from the activity it leads into. It receives the next activity as an argument rather than encoding it internally.

# Snake Unit State Management

In SNKRX, a snake unit's identity, lifetime, position in the party, and spawn behavior are each tracked through boolean flags that act as state machines. In Atmos, these state machines disappear into control flow and structural position.

## Lua + LOVE2D

Death is a boolean that switches state from alive to dead [(player.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/player.lua#L1521):

```lua
function Player:hit(damage)
    if self.dead then return end      -- Guard: reject if dead
    if self.hp <= 0 then
        self.dead = true              -- State transition: alive → dead
        if self.leader then self:recalculate_followers()
        else self.parent:recalculate_followers() end
    end
end
```

Once `self.dead` is set, the object remains in its group and continues receiving `:update(dt)` every frame. Every method that must not run after death needs its own guard: `hit` returns early, cooldown callbacks check the flag, and then the follower list must be rebuilt. Furthermore, during state transition the dying unit must manually repair the follower structure.

Head identity is a boolean that switches state from follower to leader on promotion [(player.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/player.lua#L873):

```lua
if self.leader then                    -- State: leader
    self.t:every(0.01, function()
        table.insert(self.previous_positions, 1, {x = self.x, y = self.y, r = self.r})
    end)
else                                   -- State: follower
    local target_distance = 10.4 * self.follower_index
    -- walk back through history...
end

-- On leader death:
new_leader.leader = true               -- State transition: follower → leader
new_leader.followers = self.followers
```

The `leader` flag controls which branch of movement logic runs. The transition from follower to leader is explicit: the dying head manually sets the flag on its successor and transfers the follower list. Three variables (`leader`, `followers`, `parent`) must be kept consistent across the transition.

Reindexing is a state update that cascades across every unit [(player.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/player.lua#L1754):

```lua
function Player:recalculate_followers()
    if self.dead then
        local new_leader = table.remove(self.followers, 1)
        new_leader.leader = true
        for i, follower in ipairs(self.followers) do
            follower.parent = new_leader
            follower.follower_index = i -- Rewrite state on every survivor
        end
    else
        -- find dead, remove, renumber...
        for i, follower in ipairs(self.followers) do
            follower.follower_index = i -- Rewrite state on every survivor
        end
    end
end
```

Each unit's `follower_index` is state that must be rewritten by the dying unit. The state transition on one unit (death) cascades into state updates on every unit behind it. The dying unit must also branch on whether it was the head to decide which repair to run.

Spawn detection is a boolean that switches state once but is checked forever after:

```lua
if not self.following then              -- State: not yet following
    spawn1:play{...}
    self.following = true               -- State transition: now following
end
```

The `following` flag starts `false`, triggers once, and remains `true` for the rest of the unit's life. This is a one-shot state transition checked every frame.

## Atmos + Pico

In Atmos, death is the end of the unit's body. No state variable, no transition to track [(snake.atm)](TODO):

```lua
if hp <= 0 {
    ;; index tracked the party, so it still points at this unit's own entry
    table.remove(G.party, index)
    return(index)
}
```

When the unit returns, `SnakeUnit` terminates. Movement, drawing, the ability loop, the cast pool and any pinned spring were all spawned inside the unit task, so they are aborted with it. Nothing checks a flag, because nothing is left running to check one. The status bars are the one thing that outlives the unit, and they need nothing from this return to do so: they watch the unit from the outside and carry on in its slot by themselves.

Head identity is a phase of the task, not a stored state nor a branch re-tested every tick [(snake.atm)](TODO):

```lua
if index > 1 {
    par :any {
        loop i on :any party {
            ;; a unit ahead died: move up one place
            until (index == 1)
        }
    } with {
        loop on :clock {
            ;; follow the unit ahead
        }
    }
}

;; index is 1 from here on: this unit inherited the head
loop {
    ;; mouse input, wall bounce, trail write
}
```

A unit that starts behind runs the race above: shifting on one side, following on the other. The moment its index reaches 1 the race ends, and control falls through to the head loop below it. Promotion is the task advancing a line. No flag is transferred, no follower list is moved, and past that point nothing asks whether this unit is the head, because a task that reached the head loop cannot be anything else.

Reindexing rides on the pool that holds the party. Each unit adjusts only its own index [(snake.atm)](TODO):

```lua
loop i on :any party {
    if (i < index) {
        set index = (index - 1)
    }
    until (index == 1)
}
```

`await :any party` wakes on any member of the pool terminating, and yields the value it died with: the index it occupied. Units behind it shift down by one, units in front ignore it. The dying unit writes to no one; it ends, and the pool reports it. There is no master list and no branch for "who died".

Ordering needs no flag either. The head samples one trail point per follower every tick, and the head is always the earliest-spawned survivor, so it has written the slot before any follower reads it:

```lua
val s = positions@(index - 1)
assert(s)
```

The assert states that invariant instead of defending against it. An `if` here would quietly paper over a real ordering bug; the assert says the slot is expected to be there, and would fail loudly if the spawn order ever stopped guaranteeing it.

## Analysis

In the original Lua code, each unit carries state variables that act as ad-hoc state machines. `dead` switches from alive to dead and is checked by every method. `leader` switches from follower to leader through an explicit promotion step. `follower_index` is state rewritten across every surviving unit when one dies. `following` is a one-shot transition checked forever.

In Atmos, none of these state machines remain as variables. The alive to dead transition is where the task body ends. The leader and follower distinction is which phase of the task is running, so promotion is the task falling through to its next statement. Reindexing is a self-applied decrement on a pool termination. Spawn ordering is an invariant of who was spawned first, asserted rather than tested. Each Lua state variable was a manual encoding of something Atmos expresses directly: a return, a program position, an event response, a structural guarantee.


# Snake Unit Status Signalling

In SNKRX, a unit's healthbar reads its fields directly and the hit flash is shared state between combat and rendering. In Atmos, both are replaced by events and control flow: the bar is a task that watches the unit from beside it, and the flash is a state machine that only feeds the drawing.

## Lua + LOVE2D

Status reporting is a direct field read. The unit draws its own healthbar inline from its own fields every frame [(player.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/player.lua):

```lua
function Player:draw()
    -- ...
    if self.character_hp then
        local r, g, b = unpack(hp_color)
        local hp_w = 24 * self.hp / self.max_hp
        graphics.rectangle(self.x - 12, self.y - 16, hp_w, 4, 2, 2, fg[0])
    end
end
```

There is no separate healthbar object. The bar is part of the unit's draw method, reading `self.hp` directly. The bar's lifetime is the unit's lifetime. This works because :draw runs even after unit death until the Player object is cleaned up.

Hit flash is a boolean state machine: normal -> flashing -> normal. Combat writes the state, rendering reads it [(player.lua)](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/player.lua#L1525):

```lua
-- In Player:hit:
self.hfx:use('hit', 0.25, 200, 10)

-- In draw:
graphics.rectangle(self.x, self.y, ..., (self.hfx.hit.f or self.hfx.shoot.f) and fg[0] or self.color)
```

The flash is triggered in `hit` by calling `self.hfx:use('hit', ...)`, which sets internal flags on the effect object. The draw method checks those flags every frame to decide the unit's color. The unit's rendering depends on state that combat writes, and any new reason to flash requires another writer of that state.

## Atmos + Pico

In the atmos counterpart the bar is a task spawned beside the unit rather than inside it, in a pool of its own, holding the slot the unit was laid out in [(snake.atm)](TODO):

```lua
val task Snake() {
    pin bars = tasks()

    pin party = tasks()
    loop i, character in G.party {
        spawn @party SnakeUnit(i, character, trail, positions, party)
    }

    loop i, unit in party {
        spawn @bars StatBars(i, G.party@i, unit)
    }
```

Nothing connects the two pools. The unit is never handed a reference to the bars, and reporting damage is an emit aimed by position in the task tree instead:

```lua
set hp = math.max(hp - taken, 0)
emit @2 :hp [ slot=slot, hp=hp, max=maxHp ]
```

`@2` names an ancestor: `0` is the unit itself, `1` the party pool it was spawned into, `2` the `Snake` task above that. The event is delivered to that ancestor's whole subtree, which is how it arrives at a pool the emitter has no name for. A pool counts as a level here, so the party pool has to be counted even though nothing in the source spawns into it by hand; an anonymous `spawn { }` block does not, which is why the ability loop, nested one block deeper, still emits `@2` and not `@3`.

That reach is wide: every unit sees the event too, not just the bars. So the slot travels in the payload and each bar picks out the one meant for it:

```lua
val d = await :hp [slot=slot]
```

The alternative is to keep a `bars` reference in `Snake` and thread it down through every `SnakeUnit` so the emit can name the pool directly. That narrows the broadcast to the bars alone, at the cost of a parameter on the unit that exists only to point at a sibling. `@2` keeps the units knowing nothing about who reports on them, and pays for it with a number that has to be recounted if a pool or wrapper task is ever inserted between the unit and `Snake`.

`StatBars` keeps its own `hp` and redraws from it. The unit never reaches into the bar and the bar never reads the unit, so neither can be found holding a stale copy of the other's fields. The bar is not a child of the unit, though. It wraps its live drawing in `watching (unit)`, so the unit's death ends that block and the bar falls through to drawing the spent frame in the slot it has held all along:

```lua
val task StatBars(slot, character, unit) {
    watching (unit) {
        ;; ... hp bar and cooldown bar
    }

    ;; the unit is gone: its slot keeps the spent frame for the rest of the run
    loop on :draw {
        ;; ... greyed out frame
    }
}
```

That is what keeps the bar's slot fixed at birth while the unit's party index shifts underneath it. Nothing bookkeeps the dead, because the task that reported on a unit is the same task that goes on standing in for it.

The hit flash is a state machine, but only one side of it draws [(snake.atm)](TODO):

```lua
var clr = colors.base
var scale = 1

spawn {
    loop on :draw {
        pico.set.pencil [ color=clr ]
        pico.output.draw.oval [ "%",
            x=pos.x, y=pos.y,
            w=(UNIT_SIZE * scale),
            h=(UNIT_SIZE * ASPECT_RATIO * scale),
        ]
    }
}

loop {
    await :flash_unit

    pin spring = spawn Spring.Simple(1.8)
    emit @spring :start

    set clr = :white
    watching (0.15*1s) {
        loop on :clock {
            set scale = spring.pub.scale
        }
    }
    set clr = colors.base
    set scale = 1
}
```

The unit is drawn in exactly one place. The loop underneath it says what a flash *is* — white, springing, for 0.15s, then back — by setting two locals and letting the spring run for as long as the `watching` allows. Anything that wants a flash emits `:flash_unit`: a hit, an ability firing, a bounce off the wall. None of them know the colour, the duration, or that a spring is involved, and adding a fourth reason to flash adds no new writer of drawing state.
