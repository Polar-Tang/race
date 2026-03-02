# Racing Game Prototype – Copilot Instructions

This project is a Roblox game built with **Rojo** and a handful of community
libraries (Nevermore, Quenty, etc.). The code is split between `src/client` (StarterScriptService, PlayerScriptService, etc.) and
`src/server` (ServerScriptService), `src/shared` (ReplicatedStorage) and folders like `src/myNeverMoreS` or `node_modules.@quenty` lives in ReplicatedStorage, for more information about the folder organization during on the game you can check `sourcemap.json`.

---

## Big picture architecture
This game is powered by nevermore which is initialize in server/Main.server.luau and client/Main.client.luau respectively, ServiceBag provides services and is used as a singleton _G.ServiceBag or _G.ServiceBagClient. 
All nevermore service look like `<serviceName>/src/$side/<serviceModules>` where $side is `Client`, `Server` or `Shared`

1. **Service bag + binder provider.** Library downloaded from nevermore are under node_modules (compiled on `ReplicatedStorage.Nevermore` in game) and are utilities that can be used in variaty of ways, while `src/myNeverMoreS` (`ReplicatedStorage.Nevermore.Custom` in game) are custom services intialized though the service bag and relative to specific game domain, however they are initialized through the service bag as the other libraries from node_modules.

2. **Domains.** The code is currently improving the logic from the car binder:
   - `myNeverMoreS/car/` – logic for an individual car, split into server and
     client sub‑packages. The server side lives under
     `car/src/Server/Binder/Car.luau` plus subfolders for controllers. The
     client mirror is `car/src/Client/Binder/CarClient.luau` and its controllers.
   - `myNeverMoreS/carSpawning/` – handles spawn kiosks. Only a server binder
     exists (`carSpawning/src/Server/Binder/CarSpawning.luau`).

   Both domains use shared modules under `.../Shared/` (e.g. `CarConstants.luau`
   or `Controller.luau`) and are exposed at runtime through
   `ReplicatedStorage.Nevermore.Custom.<domain>.src...`.

3. **Binder/Controller pattern.** A binder class (e.g. `Car` or `CarClient`) is
   created for every logical object that gets instantiated in the world. Binders
   typically:
   - extend `BaseObject` (server) or `BaseService` (client) from the Quenty
     libraries, using `setmetatable`, for inherit tools as _maid and a Destroy method.
   - maintain a `_controllers` table populated by iterating over a local
     `Controllers` map. Each controller itself extends a `ControllerBase` type
     and exposes `Init()`, `Start()`, `Enable()/Disable()` etc.
   - clean up with a `Maid` and store runtime state on attributes or tags.

   The server binder handles ownership, replication and other authoritative
   logic; the client binder enables camera, input, FX and other local
   behaviours and hooks into `RunService` for per‑frame updates.

4. **Communication.** Data flows use several mechanisms:
   - **CollectionService tags** plus helper `getOwnerTag()` to find a player's
     cars and clean them up (`CarSpawning._destroyPlayerCars`).
   - **Attributes** on instances for numeric state (e.g. nitro level,
     owner UserId) defined in `CarConstants`. Attributes are the primary
     cross‑script shared state.
   - **RemoteEvents** in `ReplicatedStorage.RemoteEvents` for one‑off signals
     such as `SetNitroEnabled`. Server handlers (in `Main.server` or a binder)
     respond to `.OnServerEvent` and forward to the appropriate binder.

5. **Templates.** Prebuilt instances (cars, spawn prompts, UI) are stored in
   `ReplicatedStorage` and cloned at runtime. GUI templates are kept next to the
   script that uses them (the speedometer controller etc.).

---

## Project-specific conventions

- **Nevermore path lookup.** Modules are required via:
  ```lua
  local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
  ```
  Always use this pattern; do not `require` by a hardcoded module script path.

- **Case and naming.**
  - Classes use `PascalCase` and set `ClassName` on the table.
  - Attribute names are all caps with underscores and are defined centrally
    in `CarConstants`.
  - CollectionService tags are generated with helper functions (see
    `carSpawning/src/Server/utils/getOwnerTag.luau`).

- **Clean-up**: use a `Maid` (`Nevermore.Quenty.maid.Shared.Maid`) attached to
  every binder and controller. Pass connections to it with
  `self._maid:GiveTask(...)`.

- **Deferred destruction handler hack.** The client binder copies a small
  script (`.../Client/utils/DestructionHandler`) into `PlayerScripts` when a
  car is initialized. This avoids Roblox’s Deferred signal mode causing the
  binder to disappear before it can clean up.

---

## Developer workflows

1. **Building / running** – the repo uses Rojo. From the workspace root:
   ```bash
   rojo build -o cart_game.rbxlx   # regenerates the place file
   rojo serve                      # start a live-sync server for Studio
   ```
   Open `cart_game.rbxlx` in Roblox Studio and press Play to test.

2. **Adding new binders/controllers** – copy the pattern from existing
   `Car`/`CarClient` modules. Require the binder as they are required in `Main.server` or
   `Main.client` via the `Binders` table and the BinderProvider you’ve already
   seen. Ensure any new remote events are declared under
   `ReplicatedStorage.RemoteEvents`.

3. **Editing shared constants** – modify `CarConstants.luau` only. Other
   scripts should reference those constants rather than hardcoding strings
   or numbers.

4. **Tag/attribute conventions** – when storing extra state on an Instance,
   prefer attributes. Use `:AddTag()`/`:GetTagged()` only for broad queries like
   cleaning up a player’s cars.

5. **Testing** – there is currently no automated test suite in the repo; run
   changes in Studio and use the Rojo console to read any printed output. The
   dev dependencies in `package.json` are for submodules and can usually be
   ignored unless modifying the Nevermore libraries themselves.

---

## Integration and external dependencies

- **Nevermore packages** are stored under `ReplicatedStorage/Nevermore`. A
  custom loader script (`LoaderUtils`) bootstraps them. Do not alter the
  loader unless you intend to change how modules are resolved.
- **Quenty libraries** (`baseobject`, `maid`, `binder`, etc.) provide core
  abstractions; they reflect common patterns you’ll see everywhere.
- **Rojo** is the only non-Roblox tooling used; the game does not compile or run
  outside of Roblox Studio.

---

If anything above is unclear or if you find behaviour not described here,
please ask for a follow-up; the goal is to keep these instructions accurate
and minimal.
