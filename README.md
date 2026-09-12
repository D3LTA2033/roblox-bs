# roblox-bs

A drop in pack of server side systems for Roblox games. Anti cheat, admin commands with a built in
panel, a shop for cash items, gamepasses and dev products, join cards, chat welcomer, rank tags,
Discord webhook logs, data saving with session locks, remote rate limits, afk tracking and soft
shutdown.

Free to use in any project, paid or not. No credit needed, keep the header line if you want.
Written in Luau for the current engine APIs (TextChatService, attributes, `BanAsync`, `PivotTo`).

Everything is plain code, nothing is pre built in a `.rbxm`. The GUIs are made at runtime so there
is no UI to rebuild after you sync.

## install

With Rojo (easiest):

```
rojo serve default.project.json
```

By hand, copy each folder to the place in the table. `.server.lua` files are Scripts,
`.client.lua` files are LocalScripts, the rest are ModuleScripts.

| folder | goes to | renamed to |
| --- | --- | --- |
| `shared` | ReplicatedStorage | `Bits` |
| `guard/server` | ServerScriptService | `Gate` |
| `hooks/server` | ServerScriptService | `Hooks` |
| `data/server` | ServerScriptService | `Data` |
| `ranks/server` | ServerScriptService | `Ranks` |
| `anticheat/server` | ServerScriptService | `Ac` |
| `admin/server` | ServerScriptService | `Adm` |
| `shop/server` | ServerScriptService | `Shop` |
| `greeter/server` | ServerScriptService | `Greet` |
| `welcomer/server` | ServerScriptService | `Say` |
| `afk/server` | ServerScriptService | `Afk` |
| `shut/server` | ServerScriptService | `Soft` |
| `anticheat/client` | StarterPlayerScripts | `AcWatch` |
| `admin/client` | StarterPlayerScripts | `Panel` |
| `shop/client` | StarterPlayerScripts | `ShopUi` |
| `greeter/client` | StarterPlayerScripts | `GreetUi` |
| `welcomer/client` | StarterPlayerScripts | `SayUi` |
| `tags/client` | StarterPlayerScripts | `Tags` |
| `afk/client` | StarterPlayerScripts | `AfkUi` |

The names matter, scripts look each other up by them.

## first five minutes

1. Put your user id in `ranks/server/List.lua` under `owner`. The game creator is owner already.
2. Turn on Studio access to API services if you want saves and bans to work.
3. Turn on HTTP requests and paste your webhook links into `hooks/server/Keys.lua`.
4. Put your gamepass and dev product ids into `shop/server/List.lua`, anything left at `0` is hidden
   and the server says so on start.
5. Join and press `;` to open the panel or `F` for the shop, or type `;cmds` in chat.

## ranks

Five tiers: `player`, `vip`, `mod`, `admin`, `owner`. `ranks/server/List.lua` holds user ids, a group
with rank numbers, and game passes. The id list stays on the server, clients only ever see the
result as an attribute.

Everything else reads the rank off the player attribute, so one lookup covers the panel, the tags,
the greeter and the chat welcomer:

```lua
local Rank = require(ReplicatedStorage.Bits.Rank)

if Rank.at(plr, "mod") then ... end
print(Rank.of(plr), Rank.lvl(plr), Rank.hue(plr))
```

`;rank bob admin` gives a tier for the current round only, it does not save.

## admin

42 commands. Prefix is `;` (set in `shared/Cfg.lua`). Commands run from chat or from the panel. Panel opens with
`;`, or the small button on phones. It has a player list, quick buttons, the command box with history
on the up arrow and name completion, and a log that also shows anti cheat flags live.

Who you can target: `me`, `all`, `others`, `rng`, `low`, `team:red`, `bob,jane`, or part of a name.
Times are `30s`, `10m`, `2h`, `7d`, `perm`.

```
;kick bob being annoying        ;ban bob 7d alt account      ;unban bob
;mute bob 10m                   ;unmute bob                  ;flags bob
;kill ;heal ;hp bob 250          ;god ;ungod                  ;speed all 32
;jump bob 75                     ;tp all bob                  ;bring bob  ;to bob
;freeze ;thaw ;sit ;stun ;unstun ;fling bob 120               ;invis ;vis
;respawn bob                     ;give bob sword              ;cash bob 500
;announce server wipe in 5       ;hint hold still              ;time 3
;grant bob boots                 ;owns bob                     ;rank bob mod
;clean                           ;here ;ping ;up ;ver ;find bob
;bypass bob                      ;boot
```

`;clean` only empties a folder called `Bin` in Workspace, it will not touch the rest of your map.
`;give` pulls Tools out of a `Tools` folder in ServerStorage.

## anti cheat

Server side checks on a fixed step, nothing trusts the client.

- walk speed, jump power, jump height and max health compared against what the server expects
- horizontal distance per step against walk speed, with a ping allowance
- time spent off the floor with no ground under you and no fall speed
- moving through collidable parts
- movers parented to a character (`BodyVelocity`, `LinearVelocity`, `AlignPosition` and friends)
- missing heartbeat, so deleting the client script is its own flag

Flags stack and decay. At the cap the player gets kicked, and banned instead if you flip
`Cfg.ac.ban`. Mods and up are skipped, `;bypass` skips anyone.

It stays quiet during respawns, seats, ragdolls, swimming, climbing, vehicles and anything the
server moved itself. Player attributes drive the limits, so set them when your game changes a stat:

| attribute | meaning |
| --- | --- |
| `Spd` `Jmp` `Hgt` `Hp` | the value the server expects, instead of the `Cfg.ac` default |
| `God` | skip the health check |
| `Warp` | set to `workspace:GetServerTimeNow()` right before you move someone |
| `AcOff` | skip this player entirely |
| `Ok` on a mover | a mover you added on purpose, leave it alone |

Hit validation for combat code:

```lua
local Reach = require(ServerScriptService.Ac.Reach)

if Reach.hits(plr, mob, 20) then
    mob.Humanoid:TakeDamage(10)
end
```

Out of range calls raise a flag by themselves, so you do not need to log anything.

## shop

Three kinds of thing to sell, all in `shop/server/List.lua`:

- cash items, paid with the `cash` field on the save, one time or repeatable
- gamepasses, one off robux
- dev products, repeatable robux

What each one actually does lives in `shop/server/Gift.lua`, one short function per key. The ones in
there now give speed, jump, health, a heal, a vip bundle, a light and a revive. Perks set the same
attributes the anti cheat reads, so a speed item will never flag the player who bought it.

The menu opens with `F` or the button in the corner, three tabs, live cash in the header, owned
items marked. The client never sends a price, it sends the item key and the server looks the cost up.

```lua
local Buy = require(ServerScriptService.Shop.Buy)

Buy.award(plr, 250)            -- adds cash, doubled for vip
Buy.owns(plr, "boots")         -- how many they bought
Buy.pass(plr, "vip")           -- gamepass check, cached
```

Receipts are handled the way Roblox wants: the purchase id is written into the save and the save has
to come back before the receipt is granted, so a failed write means Roblox asks again instead of the
player paying for nothing. Old purchase ids get pruned. Unknown product ids are never swallowed.
Only one script in the game may set `ProcessReceipt`, this is that script.

Gamepass ownership is cached per player so the shop does not hammer the API, and the cache updates
the moment a prompt finishes. Perks that touch the character are reapplied on every respawn.

`;grant bob boots` hands an item over for free, `;owns bob` lists what someone has.

## webhooks

Links live in `hooks/server/Keys.lua`, server only, never in `shared`. Four lanes: `main`, `ac`,
`adm`, `err`, each falling back to `main` when empty.

Roblox cannot reach `discord.com` directly. Run any webhook proxy and put its base in `proxy`, the
sender rewrites the host for you.

Sending is queued, ten embeds per request, one request per lane at a time. It waits out `429` using
the `retry_after` Discord sends back, retries `5xx`, drops `4xx` with a warning, and caps the queue
so a dead link cannot eat memory. Mentions are stripped from every payload.

```lua
local Hook = require(ServerScriptService.Hooks.Hook)

Hook.send("main", Hook.card("boss down", Hook.hue.good)
    :who(plr)
    :row("loot", "dark sword")
    :at(plr.Character.PrimaryPart.Position))

Hook.text("main", "short line")
```

Out of the box you get server start, joins with visits and playtime, leaves, every command, every
anti cheat flag, bans, every shop and robux purchase, and script errors (deduped and throttled so
one broken loop cannot spam).

## saving

`data/server/Store.lua` is a small profile store with a session lock, so two servers cannot write
over each other. It retries with a growing wait, watches the request budget, autosaves every three
minutes on a stagger, and flushes on `BindToClose`. A player whose lock is still held somewhere else
gets a rejoin message instead of a fresh empty save.

```lua
local Store = require(ServerScriptService.Data.Store)

local d = Store.get(plr)
d.cash += 100
Store.bump(plr, "cash", 100)
```

Add your own fields to `Cfg.data.base`, old saves fill in the missing ones on load.

## remotes

Every remote in the pack goes through `guard/server/Grd.lua`. Use it for yours too:

```lua
local Grd = require(ServerScriptService.Gate.Grd)

Grd.hook(buyRemote, "buy", 5, 10, function(plr, id)
    local item = Grd.int(id, 1, 200)
    if not item or not Grd.near(plr, shop.Position, 25) then return end
    ...
end)
```

Leaky bucket per player per key, type and range checks that return `nil` instead of throwing, and a
distance check so clients cannot buy from across the map.

## greeter, chat, tags

Join cards slide in at the top with the headshot, rank, visit count and total playtime, and say
`friend` when the player is on your friends list. Up to three at a time, the rest queue.

The chat welcomer posts a line for everyone joining and a bolder one with a banner for vip and up.
New players also get the `Cfg.say.motd` lines. Names are escaped before they go into rich text, so
nobody can inject tags through a display name.

System messages are shown per client, which is the part most people get wrong, the server only sends
the text. Legacy chat is handled too if your game still runs it.

Tags float over ranked players and anyone afk, with a distance limit so they do not clutter.

## afk and restarts

Afk comes off the client `Idled` event, the server keeps it as an attribute and can kick after a
while if you set `Cfg.afk.boot`.

`;boot` and `BindToClose` both run the same soft shutdown: warn everyone, reserve a server, move
them there, and that server bounces them straight into a fresh one. Teleport failures are retried.
Private servers are left alone, the bounce only looks at teleport data the pack set itself.

## config

`shared/Cfg.lua` holds everything tunable and is frozen at load, so nothing can change it at
runtime. Server only lists are kept out of it on purpose:

- `ranks/server/List.lua` for who is staff
- `hooks/server/Keys.lua` for webhook links

## notes

- Scripts handle players who were already in the server, so hot reloading in Studio works.
- Connections are cleaned up through `shared/Bin.lua` on respawn and on leave.
- Anything that yields rechecks `plr.Parent` before touching the player again.
- `shared/Mk.lua` builds the GUIs for both panels, so they share one palette.
- `default.project.json` and `rokit.toml` are there for Rojo, delete them if you install by hand.

Questions or bugs, poke @mcs.s on discord.
