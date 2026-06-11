# Rpg-Simulator

## Documentation

## Dev

### MVP

#### Goals

Create a procedurally generated RPG simulation that embraces chaos and instability, balanced by user input and natural in-game forces

- [ ] *meta systems*:
    - [ ] decide on and implement actual screen dimensions
        - !! **this directly impacts performance**
    - [ ] create a functional ui for dev
        - [ ] data panels
            - [x] world data
            - [ ] party data
                - [x] player data
                - [ ] multiple player data
                - [ ] party inventory
            - [x] enemy data
            - [x] time data

- [ ] *player systems*
    - [ ] *class system*: allow player to choose a player class that forms a unique, distinct way of interacting with the world
        - [ ] *subclass system*: once a particular stance threshold is reached, player can choose to specialize in an associated subclas
            - [ ] *style system*: each base class has 3 "styles" that can be cycled through, allowing experience to be accumulated for that particular style
                - [ ] styles represent strategy/role types: defensive, offensive, utility
                - [ ] only one style can be active at a time, but players can switch styles when a new party member is acquired
    - [ ] *skill system*: players accumulate skill points for specific skills by doing specific actions
        - [ ] weapon skills accumulated in combat while using a particular weapon type
        - [ ] stat skills accumulated in combat i.e. defense on damage taken, resilience on crit taken, etc. 
    - [ ] *item system*: players have a chance to randomly find items including weapons, armor
        - [ ] *weapons*: any class can equip any type of weapon; the only determinant is weapon skills
        - [ ] *armor*: any class can equip any armor type, but each armor type has benefits and drawbacks, relying mainly on armor skill of that particular type
    - [ ] *party system*: player has a random chance to encounter neutral entities, within particular progress thresholds, that can be adopted into the player's party
        - [ ] progress thresholds are determined by player : enemy stat ratios
            - thresholds act primarily as a way to smooth out world randomness by giving agency to the player at specific progress levels
        - [ ] neutral entities are a type of player starting with a randomized class
        - [ ] player can choose to adopt this player into their party or pass
- [ ] *environmental system*: create a dynamic environment with terrain, weather, and organic life simulation that directly impacts the player's world interaction somehow
    - [ ] implement organic matter to terrain with basic life simulation
    - [x] finish implementing basic erosion


#### DevOps

- [ ] 

<details>
    <summary>DONE</summary>

- [x] scrap current encounters system
    - [x] remove from time controller
    - [x] revert player controller logic
    - [x] revert enemy controller
- [x] revert time controller
- [x] time_controller only controls time system, not dependencies
        - _routing dependency systems through time_controller results in too many states and sub-states to manage effectively_
        - _instead of trying to rewrite the internal \_process system, utilize it_
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
    - *too much controller data is being routed through entities before validation/initialization*
        - *results in mismatched data references and cumbersome validation processes*
    - *in sequence, controllers should...*
        - [x] initialize entities and entity data they control
        - [x] validate entity data
            - [x] initialize + validate ALL entity data, including sub-system controllers, before updating parent entity data
                - *i.e. WorldController should initialize and validate World + ALL dependency data in World.data before main processing loop starts, not during*
        - [x] if controller entity data references are kept on system controllers, they should have callback functions for when said data reference changes
        - [x] start processing ONLY IF all data + parent entity data is validated

</details>
