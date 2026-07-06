extends Controller

# components
var party: Dictionary
var init_party: Dictionary = {
    "lead": null,
    "members": []
}


## sets the passed player as the new party leader,
## and adds to party if not already member
func update_party_lead(new_lead: Player) -> bool:
    if is_instance_valid(new_lead):
        # assert leader is party member
        if new_lead not in self.party.members:
            add_party_member(new_lead)
        # update to new leader
        if new_lead in self.party.members:
            self.party.lead = new_lead
            self.world.data.party = self.party
            return true
    return false


## adds the passed player to current party as member and
## updates party lead if flag is passed
func add_party_member(new_member: Player) -> bool:
    if is_instance_valid(new_member):
        self.party.members.append(new_member)
        self.world.data.party = self.party
        return true
    return false


func _init() -> void:
    self.party = self.init_party