# Rpg-Simulator

## Documentation

## Dev

### TODO

#### Working

- [ ] 

#### Done

- [x] ~~check that no errors appear after restructuring utils~~ *not a great idea, requires script instantiation management -- not worth*
- [x] ~~ensure all existing controller functions have return~~ types for easier error resolving
- [x] ~~check that all resolvable FIXME comments are resolved~~

### Reference

World Controller Init Flow
```mermaid
flowchart
    controller.World --instantiates--> entity.World
    
    controller.World --instantiates--> Controller
    Controller --initializes--> Controller.data
    Controller.data -.valid.-> entity.World
    
```

World Controller Dependencies
```mermaid
flowchart
    subgraph entities
        Entity.World

    end

    Entity.World -.-> Controller.Terrain
    Entity.World -.-> Controller.Time
    Entity.World -.-> Controller.Player

    subgraph controllers
        Controller.Terrain
        Controller.Weather
        Controller.Resources
        Controller.Encounters
        Controller.Player
        Controller.Time

        Controller.Terrain -.-> Controller.Weather
        Controller.Terrain -.-> Controller.Resources
        Controller.Terrain -.-> Controller.Encounters

    end

```
