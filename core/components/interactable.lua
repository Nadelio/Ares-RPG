local Registry = require("core.registry")

local Interactable = {} 

local function is_valid(interaction, entity, event)
    if interaction.is_valid == nil then
        return true
    end

    if type(interaction.is_valid) == "function" then
        return interaction.is_valid(entity, event) ~= false
    end

    return interaction.is_valid ~= false
end

function Interactable.new(data)
    data = data or {}

    return {
        selected = false,
        interact = data.interact_func or function(self, e) end,
        interactions = data.interactions or {},
        interaction_label = data.interaction_label or "Interact",
    }
end

function Interactable.get_valid_interactions(entity, event)
    local component = entity and entity.interactable

    if not component then
        return {}
    end

    local interactions = component.interactions or {}
    local valid = {}

    if #interactions == 0 then
        return {
            {
                label = component.interaction_label or "Interact",
                action = component.interact,
            }
        }
    end

    for _, interaction in ipairs(interactions) do
        local action = interaction.action or interaction.interact or interaction.callback

        if type(action) == "function" and is_valid(interaction, entity, event) then
            table.insert(valid, {
                id = interaction.id,
                label = interaction.label or interaction.name or "Interact",
                description = interaction.description,
                action = action,
            })
        end
    end

    return valid
end

Registry.register("components", "interactable", Interactable)

return Interactable