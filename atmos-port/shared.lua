function shared_init()
    white   = ColorRamp(Color(1, 1, 1, 1), 0.025)
    black   = ColorRamp(Color(0, 0, 0, 1), 0.025)
    bg      = ColorRamp(Color('#303030'), 0.025)
    fg      = ColorRamp(Color('#dadada'), 0.025)
    fg_alt  = ColorRamp(Color('#b0a89f'), 0.025)
    yellow  = ColorRamp(Color('#facf00'), 0.025)
    orange  = ColorRamp(Color('#f07021'), 0.025)
    blue    = ColorRamp(Color('#019bd6'), 0.025)
    green   = ColorRamp(Color('#8bbf40'), 0.025)
    red     = ColorRamp(Color('#e91d39'), 0.025)
    purple  = ColorRamp(Color('#8e559e'), 0.025)
    blue2   = ColorRamp(Color('#4778ba'), 0.025)
    yellow2 = ColorRamp(Color('#f59f10'), 0.025)

    fat_font   = '../assets/fonts/FatPixelFont.ttf'
    pixul_font = '../assets/fonts/PixulBrush.ttf'

    global_text_tags = {
        red      = TextTag{draw = function(c, i, text) graphics.set_color(red[0]) end},
        orange   = TextTag{draw = function(c, i, text) graphics.set_color(orange[0]) end},
        yellow   = TextTag{draw = function(c, i, text) graphics.set_color(yellow[0]) end},
        yellow2  = TextTag{draw = function(c, i, text) graphics.set_color(yellow2[0]) end},
        green    = TextTag{draw = function(c, i, text) graphics.set_color(green[0]) end},
        purple   = TextTag{draw = function(c, i, text) graphics.set_color(purple[0]) end},
        blue     = TextTag{draw = function(c, i, text) graphics.set_color(blue[0]) end},
        blue2    = TextTag{draw = function(c, i, text) graphics.set_color(blue2[0]) end},
        bg       = TextTag{draw = function(c, i, text) graphics.set_color(bg[0]) end},
        bg3      = TextTag{draw = function(c, i, text) graphics.set_color(bg[3]) end},
        bg10     = TextTag{draw = function(c, i, text) graphics.set_color(bg[10]) end},
        bgm2     = TextTag{draw = function(c, i, text) graphics.set_color(bg[-2]) end},
        fg       = TextTag{draw = function(c, i, text) graphics.set_color(fg[0]) end},
        fgm1     = TextTag{draw = function(c, i, text) graphics.set_color(fg[-1]) end},
        fgm2     = TextTag{draw = function(c, i, text) graphics.set_color(fg[-2]) end},
        fgm3     = TextTag{draw = function(c, i, text) graphics.set_color(fg[-3]) end},
        fgm4     = TextTag{draw = function(c, i, text) graphics.set_color(fg[-4]) end},
        fgm5     = TextTag{draw = function(c, i, text) graphics.set_color(fg[-5]) end},
        fgm6     = TextTag{draw = function(c, i, text) graphics.set_color(fg[-6]) end},
        fgm7     = TextTag{draw = function(c, i, text) graphics.set_color(fg[-7]) end},
        fgm8     = TextTag{draw = function(c, i, text) graphics.set_color(fg[-8]) end},
        fgm9     = TextTag{draw = function(c, i, text) graphics.set_color(fg[-9]) end},
        fgm10    = TextTag{draw = function(c, i, text) graphics.set_color(fg[-10]) end},
        greenm5  = TextTag{draw = function(c, i, text) graphics.set_color(green[-5]) end},
        green5   = TextTag{draw = function(c, i, text) graphics.set_color(green[5]) end},
        blue5    = TextTag{draw = function(c, i, text) graphics.set_color(blue[5]) end},
        bluem5   = TextTag{draw = function(c, i, text) graphics.set_color(blue[-5]) end},
        blue25   = TextTag{draw = function(c, i, text) graphics.set_color(blue2[5]) end},
        blue2m5  = TextTag{draw = function(c, i, text) graphics.set_color(blue2[-5]) end},
        yellow25  = TextTag{draw = function(c, i, text) graphics.set_color(yellow2[5]) end},
        yellow2m5 = TextTag{draw = function(c, i, text) graphics.set_color(yellow2[-5]) end},
        redm5    = TextTag{draw = function(c, i, text) graphics.set_color(red[-5]) end},
        orangem5 = TextTag{draw = function(c, i, text) graphics.set_color(orange[-5]) end},
        purplem5 = TextTag{draw = function(c, i, text) graphics.set_color(purple[-5]) end},
        yellowm5 = TextTag{draw = function(c, i, text) graphics.set_color(yellow[-5]) end},
        wavy      = TextTag{update = function(c, dt, i, text) c.oy = 2*math.sin(4*time + i) end},
        wavy_mid  = TextTag{update = function(c, dt, i, text) c.oy = 0.75*math.sin(3*time + i) end},
        wavy_mid2 = TextTag{update = function(c, dt, i, text) c.oy = 0.5*math.sin(3*time + i) end},
        wavy_lower = TextTag{update = function(c, dt, i, text) c.oy = 0.25*math.sin(2*time + i) end},
    }
    
    Sounds = {
		ui_hover1 = '../assets/sounds/bamboo_hit_by_lord.ogg',
		
		song1 = '../assets/sounds/Kubbi - Ember - 01 Pathfinder.ogg',
		song2 = '../assets/sounds/Kubbi - Ember - 02 Ember.ogg',
		song3 = '../assets/sounds/Kubbi - Ember - 03 Firelight.ogg',
		song4 = '../assets/sounds/Kubbi - Ember - 04 Cascade.ogg',
		song5 = '../assets/sounds/Kubbi - Ember - 05 Compass.ogg'
	}
end

ColorRamp = Object:extend()
function ColorRamp:init(color, step)
  self.color = color
  self.step = step
  for i = -10, 10 do
    if i < 0 then
      self[i] = self.color:clone():lighten(i*self.step)
    elseif i > 0 then
      self[i] = self.color:clone():lighten(i*self.step)
    else
      self[i] = self.color:clone()
    end
  end
end
