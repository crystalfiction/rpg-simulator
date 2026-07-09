# Rpg-Simulator

## Documentation

## User

### World

**Biomes**
Desert
Shrubland
Grassland
Forest
Swamp

### Classes

**Wanderer**
_Stamina_
The Wanderer embodies determination and willpower, perservering despite impossible odds through their innate ability to withstand immense blows, recuperate, and press on in an instant.

**Brute**
_Strength_
The Brute cares not for survival, but for feats of strength and courage in the face of adversity. They rely on raw power to crush their foes, and they often find themselves in risky situations because of it.

**Tactician**
_Perception_
The Tactician is a siezer of opportunities. What they lack in brawn they more than make up for with their keen sense of awareness. Their gambles may not always pay off, but when they do they could spell death for your enemies instead of you.

## Dev

### MVP

Create a procedurally generated RPG simulation that embraces chaos and instability, balanced by user input and natural in-game forces

- [ ] _player systems_
  - [x] _class system_: allow player to choose a player class that forms a unique, distinct way of interacting with the world
    - [x] _ability system_: players/enemies utilize an ability-based combat system
      - [x] neutral abilities: BasicAttack, HeavyAttack
      - [x] class-specific
      - [x] abilities incur a cycle-based cooldown and are used in order of priority within the player's abilities table
  - [x] _skill system_: players accumulate skill points for specific skills by doing specific actions
    - [x] weapon skills accumulated in combat while using a particular weapon type
      - _the idea is that cumulative stats like this can form the character in some way according to each individual seed._
  - [x] _inventory system_: players can manage their own inventory items
    - [x] equipping and unequipping equippable items
    - [x] deleting items
    - [x] reordering items
  - [x] _item system_: players have a chance to randomly find items including weapons, armor
    - [x] _weapons_: any class can equip any type of weapon; the only determinant is weapon skills
    - [x] _armor_: any class can equip any armor type, but each armor type has benefits and drawbacks, relying mainly on armor skill of that particular type
    - [ ] items are randomly generated from a list of stat modifiers on creation
- [x] _enemy system_: player encounters enemies across the world when attempting to interact with resources
- [x] _environmental system_: create a dynamic environment with terrain, weather, and organic life simulation that directly impacts the player's world interaction somehow
  - [x] simulates a basic world environment using procedurally generated terrain samples
    - [x] player resources are generated according to tile conditions related to terrain
- [ ] _ui system_: create a basic, functional UI that displays data relevant to a playthrough and allows the user to make necessary decisions regarding their character
  - [ ] world panel
    - [x] terrain: allows user to see stats related to world generation, including biome and resources left
  - [ ] player panel
    - [x] stats
    - [x] abilities: shows all abilities available to the player, including the ability's stats
    - [x] skills: shows all player skills
    - [ ] inventory
      - [ ] equipment viewer/editor
        - [x] item data
        - [ ] unequip/equip items
      - [ ] bag viewer/editor
        - [ ] item data
        - [ ] rearrange items
        - [ ] delete items
  - [x] combat panel: shows only high-level data regarding the entities in a combat encounter
    - [x] entity vitals
    - [x] vital stats -> name, level

### Further

- [ ] _subclass system_: once a particular stance threshold is reached, player can choose to specialize in an associated subclass
  - [ ] _stance system_: player has 3 "stances" that can be cycled through, allowing experience to be accumulated for that particular stance
    - [ ] stances represent strategy/role types: defensive, offensive, utility
    - [ ] only one stance can be active at a time, but players can switch stance when a new party member is acquired
- [ ] _party system_: player has a random chance to encounter neutral entities, within particular progress thresholds, that can be adopted into the player's party
  - [ ] progress thresholds are determined by player : enemy stat ratios
    - thresholds act primarily as a way to smooth out world randomness by giving agency to the player at specific progress levels
  - [ ] neutral entities are a type of player starting with a randomized class
  - [ ] player can choose to adopt this player into their party or pass
- [ ] _environment simulation_
  - [ ] implement organic matter to terrain with basic life simulation

#### Reference

#### Tasks

- [ ]

<details>
    <summary>DONE</summary>

- [x] scrap current encounters system
  - [x] remove from time controller
  - [x] revert player controller logic
  - [x] revert enemy controller
- [x] revert time controller
- [x] time*controller only controls time system, not dependencies - \_routing dependency systems through time_controller results in too many states and sub-states to manage effectively* - _instead of trying to rewrite the internal \_process system, utilize it_
- [x] make dependency controllers call \_process directly
- [x] validate dependency controllers at controller-level during processing
- [x] rework encounter system
  - [x] remove current _encounter_ data in tiles
  - [x] every resource has _r_ chance to spawn an enemy encounter before the resource is collected
  - [x] on _encounter_, encounter controller makes calls to involved entity controllers until an entity is defeated
- [x] ensure entity controllers are checking for defeat conditions at all times
- [x] implement logging to log file per game
- [x] implement fundamental systems: resource collection, encounters, player stat progression
- [x] refactor codebase
- [x] add base entity controller and reorganize player/enemy controller functions according to class hierarchy
- [x] re-implement actions controller on player/enemy entities
  - _I have considered how to implement time in this game, and I believe the best model is this:_
    - _the time controller asserts when time cycles occur and how long they are_
    - _entity actions have a certain duration consisting of time cycle integers_
    - _entity actions are carried out until completion, but are only evaluated during time cycles_
      - _since entity actions are whole integers, action completion will be determined by the number of time cycles, rather than the length of the events occuring during a time cycle_
      - _this also means we can clear up any errors before the start of the next cycle, but after (and not during)events/actions have occurred_
- [x] implement basic attack action
- [x] implement basic class structure
- [x] implement food surplus mechanic
  - _if player health full when food resource is acquired, resource goes into food surplus_
  - _food surplus is checked after combat and regen rate applied to health if surplus exists_
- [x] re-implement single-tile movement for player
- [x] implement basic item system with a Sword weapon
  - player is given a random weapon within Maps 1-2 that directly prolongs life cycle
- [x] implement basic skill system, starting with Weapon Skill
  - player builds skill points by utilizing items of a specific proficiency
    - _i.e. player builds x sword skill every time player attacks with sword_
- [x] restructure controller initialization process
  - _too much controller data is being routed through entities before validation/initialization_
    - _results in mismatched data references and cumbersome validation processes_
  - _in sequence, controllers should..._
    - [x] initialize entities and entity data they control
    - [x] validate entity data
      - [x] initialize + validate ALL entity data, including sub-system controllers, before updating parent entity data
        - _i.e. WorldController should initialize and validate World + ALL dependency data in World.data before main processing loop starts, not during_
    - [x] if controller entity data references are kept on system controllers, they should have callback functions for when said data reference changes
    - [x] start processing ONLY IF all data + parent entity data is validated

</details>

#### Copilot Sessions

<details>
    <summary>Session: Fundamental Systems Implementation</summary>

Implemented core RPG systems and hardened architecture:

- **Controller Architecture**: Fixed initialization order and reference assignment for WorldController, TimeController, and dependency controllers
- **Time System**: Refactored to use delta-time, robust cycle timing, and configurable frame rates
- **Combat & Abilities**: Added cycle-based action durations (BasicAttack: 1 cycle, HeavyAttack: 2 cycles), cooldown management, and attack queueing
- **Inventory System**: Created InventoryManager for equip/unequip, add/remove, and reorder operations on Player and Enemy inventories
- **Resource & Encounter**: Validated procedural resource generation and encounter spawning logic
- **Logging**: Confirmed robust file logging with timestamps
- **Procedural World**: Verified terrain generation with soil composition, erosion simulation, normalization, and biome detection
- **Code Quality**: Fixed all compilation errors and standardized GDScript patterns

</details>
