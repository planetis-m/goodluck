import entities

type
  Registry = object
    destroyed: Entity
    entities: seq[Entity]

proc isValid(reg: Registry; entity: Entity): bool =
  ## Checks if an entity identifier refers to a valid entity.
  let pos = entity.idx
  result = pos < reg.entities.len and reg.entities[pos] == entity

proc current(reg: Registry; entity: Entity): Version =
  ## Returns the actual version for an entity identifier.
  let pos = entity.idx
  assert(pos < reg.entities.len)
  result = reg.entities[pos].version

proc create(reg: var Registry): Entity =
  ## Creates a new entity and returns it.
  ## There are two kinds of possible entity identifiers:
  ##
  ## Newly created ones in case no entities have been previously destroyed.
  ## Recycled ones with updated versions.
  if reg.destroyed == invalidId:
    result = Entity(reg.entities.len)
    reg.entities.add(result)
    # entityMask is reserved to allow for null identifiers
    assert(result < entityMask)
  else:
    let curr = reg.destroyed
    let version = reg.entities[curr] and (versionMask shl entityShift)
    echo version
    reg.destroyed = Entity(reg.entities[curr] and entityMask)
    result = Entity(curr or version)
    reg.entities[curr] = result

proc destroy(reg: var Registry; entity: Entity) =
  ## When an entity is destroyed, its version is updated and the identifier
  ## can be recycled at any time.
  let version = entity.version + 1
  # lengthens the implicit list of destroyed entities
  let index = entity.idx
  reg.entities[index] = Entity(reg.destroyed or (version shl entityShift))
  reg.destroyed = Entity(index)

proc main =
  var reg = Registry(destroyed: invalidId)
  let ent1 = create(reg)
  let ent2 = create(reg)
  reg.destroy(ent1)
  let ent3 = create(reg)
  reg.destroy(ent2)
  let ent4 = create(reg)

main()
