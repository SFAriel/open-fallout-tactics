local event = {
  constants = {}
}

event.constants.stop_anim = -2
event.constants.time_of_display = -3
event.constants.repeat_all = -4
event.constants.jump_to_frame = -5
event.constants.overlay = -6
event.constants.first_specific = -40
event.constants.step_left = -40
event.constants.step_right = -41
event.constants.hit = -42
event.constants.fire = -43
event.constants.sound = -44
event.constants.pickup = -45

local displayNames = {
  [event.constants.stop_anim] = "Stop",
  [event.constants.time_of_display] = "Time",
  [event.constants.repeat_all] = "RepeatAll",
  [event.constants.jump_to_frame] = "Jump",
  [event.constants.overlay] = "Overlay",
  [event.constants.step_left] = "StepLeft",
  [event.constants.step_right] = "StepRight",
  [event.constants.hit] = "Hit",
  [event.constants.fire] = "Fire",
  [event.constants.sound] = "Sound",
  [event.constants.pickup] = "Pickup"
}

function event.getName(eventId)
  return displayNames[eventId] or eventId
end

return event
