local ffi = require("ffi")

return {
  pointer = {
    uint8_t = ffi.typeof("uint8_t *"),
    uint16_t = ffi.typeof("uint16_t *"),
    int16_t = ffi.typeof("int16_t *"),
    uint32_t = ffi.typeof("uint32_t *")
  },
  array = {
    uint8_t = ffi.typeof("uint8_t[?]")
  }
}
