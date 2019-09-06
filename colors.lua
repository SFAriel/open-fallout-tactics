local Color = {}

function Color.fromRGB(r, g, b)
  return {r / 255, g / 255, b / 255}
end

local colors = {
  white = Color.fromRGB(255, 255, 255),
  red = Color.fromRGB(255, 0, 0),
  test = {
    backdrop = Color.fromRGB(100, 149, 237)
  },
  skin = {
    light = Color.fromRGB(255, 203, 123),
    tan = Color.fromRGB(206, 150, 90),
    bronze = Color.fromRGB(123, 81, 16),
    dark = Color.fromRGB(49, 28, 8),
    yellow = Color.fromRGB(255, 255, 123),
    red = Color.fromRGB(255, 130, 132),
    green = Color.fromRGB(165, 255, 132)
  },
  hair = {
    gold = Color.fromRGB(255, 143, 16),
    blonde = Color.fromRGB(222, 203, 99),
    hazlenut = Color.fromRGB(148, 109, 49),
    brown = Color.fromRGB(99, 81, 33),
    red = Color.fromRGB(255, 69, 33),
    orange = Color.fromRGB(255, 146, 16),
    dark = Color.fromRGB(41, 32, 8),
    yellow = Color.fromRGB(30, 30, 30)
  },
  gear = {
    red = Color.fromRGB(255, 0, 0),
    orange = Color.fromRGB(255, 134, 0),
    yellow = Color.fromRGB(255, 255, 41),
    green = Color.fromRGB(0, 255, 0),
    turqoise = Color.fromRGB(0, 255, 255),
    blue = Color.fromRGB(0, 0, 255),
    purple = Color.fromRGB(132, 89, 255),
    pink = Color.fromRGB(255, 162, 173),
    white = Color.fromRGB(255, 255, 255),
    brown = Color.fromRGB(132, 65, 0),
    grey = Color.fromRGB(90, 89, 90),
    darkGreen = Color.fromRGB(0, 65, 0),
    darkBlue = Color.fromRGB(0, 65, 132),
    darkPink = Color.fromRGB(250, 130, 120),
    darkPurple = Color.fromRGB(57, 0, 132),
    magenta = Color.fromRGB(132, 0, 57)
  }
}

return colors
