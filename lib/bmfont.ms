import "stringUtil"
import "listUtil"
import "qa"

// Module to support BM Font format
Font = {
	"info": {},
	"common": {},
	"pages": {},
	"chars": {},
	"kernings": {},
}

Font.load = function(filename)
    qa.assert filename != null and filename isa string and filename.len > 0 and file.exists(filename), "Font.load: filename is invalid or file does not exist"

    font = new Font
	font.info = {}
	font.common = {}
	font.pages = {}
	font.chars = {}
	font.kernings = {}

	// Read in the FNT file and Atlas Images
    lines = file.readLines(filename)
    path = filename.split("/")
    path.pop()
    path = path.join("/")

	toValue = function(x)
		return x.val
	end function

    i = 0
	while i < lines.len
		line = lines[i]
		if line.startsWith("info ") then
			font.info = line.match("info face={face} size={size} bold={bold} italic={italic} charset={charset} unicode={unicode} stretchH={stretchH} smooth={smooth} aa={aa} padding={padding} spacing={spacing} outline={outline}")
            font.info.face = font.info.face.val
            font.info.size = font.info.size.val
            font.info.bold = font.info.bold.val
            font.info.italic = font.info.italic.val
            font.info.unicode = font.info.unicode.val
            font.info.stretchH = font.info.stretchH.val
            font.info.smooth = font.info.smooth.val
            font.info.aa = font.info.aa.val
            font.info.padding = font.info.padding.split(",")
            font.info.padding.apply(@toValue)
            font.info.spacing = font.info.spacing.split(",")
            font.info.spacing.apply(@toValue)
		else if line.startsWith("common ") then
			font.common = line.match("common lineHeight={lineHeight} base={base} scaleW={scaleW} scaleH={scaleH} pages={pages} packed={packed} alphaChnl={alphaChnl} redChnl={redChnl} greenChnl={greenChnl} blueChnl={blueChnl}")
			font.common.lineHeight = font.common.lineHeight.val
			font.common.base = font.common.base.val
			font.common.scaleW = font.common.scaleW.val
			font.common.scaleH = font.common.scaleH.val
			font.common.pages = font.common.pages.val
			font.common.packed = font.common.packed.val
			font.common.alphaChnl = font.common.alphaChnl.val
			font.common.redChnl = font.common.redChnl.val
			font.common.greenChnl = font.common.greenChnl.val
			font.common.blueChnl = font.common.blueChnl.val
		else if line.startsWith("page ") then
			page = line.match("page id={id} file=""{file}""")
			font.pages[page.id.val] = {
				"id": page.id.val,
				"file": page.file,
				"image": file.loadImage(path + "/" + page.file),
			}
            if font.pages[page.id.val].image == null then
                print("Font page " + page.id.val + " not found: " + path + "/" + page.file)
            end if
		else if line.startsWith("char ") then
			char = line.match("char id={id} x={x} y={y} width={width} height={height} xoffset={xoffset} yoffset={yoffset} xadvance={xadvance} page={page} chnl={chnl}")
			font.chars[char.id.val] = {
				"id": char.id.val,
				"x": char.x.val,
				"y": char.y.val,
				"width": char.width.val,
				"height": char.height.val,
				"xoffset": char.xoffset.val,
				"yoffset": char.yoffset.val,
				"xadvance": char.xadvance.val,
				"page": char.page.val,
				"chnl": char.chnl.val,
			}
		else if line.startsWith("kerning ") then
			kern = line.match("kerning first={first} second={second} amount={amount}")
            if not font.kernings.hasIndex(kern.first.val) then font.kernings[kern.first.val] = {}
            font.kernings[kern.first.val][kern.second.val] = kern.amount.val
		end if
		i += 1
	end while
    return font
end function

// Calculate the width of the text
Font.width = function(text, scale=1)
    qa.assert text != null and text isa string and text.len > 0, "Font.width: text is invalid"
    qa.assert scale isa number and scale > 0, "Font.width: scale is not a valid number"

	// Loop through each character in the text and add up the xadvance values
	i = 0
	w = 0
	while i < text.len
        id = code(text[i])
		w += self.chars[id].xadvance * scale
		i += 1
	end while
	return w
end function

// Calculate the bounding box of the text
Font.boundingBox = function(text, scale=1)
    qa.assert text != null and text isa string and text.len > 0, "Font.width: text is invalid"
    qa.assert scale isa number and scale > 0, "Font.width: scale is not a valid number"
	return [0, 0, self.width(text, scale), self.common.lineHeight * scale]
end function

// Get a Sprite for a specific character
Font.getSprite = function(charId, x, y, tint="#FFFFFFFF", scale=1)
    qa.assert charId != null and charId isa string and charId.len == 1, "Font.getSprite: charId is invalid"
    qa.assert scale isa number and scale > 0, "Font.getSprite: scale is not a valid number"
    qa.assert tint isa string and tint.startsWith("#") and (tint.len == 9 or tint.len == 7), "Font.getSprite: tint is not a valid color string (#RRGGBBAA or #RRGGBB)"
    qa.assert x isa number, "Font.getSprite: x is not a number"
    qa.assert y isa number, "Font.getSprite: y is not a number"


	s = new Sprite
    id = code(charId)
    s.image = self.pages[self.chars[id].page].image
  
    // Set Sprite UVs
    pageWidth = self.pages[self.chars[id].page].image.width
    pageHeight = self.pages[self.chars[id].page].image.height
    // Starting at the bottom left corner and going anti-clockwise
    // Convert from top left to bottom left 
    s.setUVs [
        [self.chars[id].x / pageWidth, (pageHeight - self.chars[id].y - self.chars[id].height) / pageHeight],
        [self.chars[id].x / pageWidth + self.chars[id].width / pageWidth, (pageHeight - self.chars[id].y - self.chars[id].height) / pageHeight],
        [self.chars[id].x / pageWidth + self.chars[id].width / pageWidth, (pageHeight - self.chars[id].y) / pageHeight],
        [self.chars[id].x / pageWidth, (pageHeight - self.chars[id].y) / pageHeight],
    ]
    
    // Force Sprite Corners around 0, 0, Position must be set to 0,0 first and then corners set
    s.x = 0
    s.y = 0
    s.setCorners [
        [0, 0],
        [self.chars[id].width, 0],
        [self.chars[id].width, self.chars[id].height],
        [0, self.chars[id].height],
    ]
    s.scale = scale
    s.tint = tint
    s.x = x + self.chars[id].xoffset * scale
    s.y = y + (self.common.base - self.chars[id].height - self.chars[id].yoffset) * scale
    return s
end function

// Set a Sprite for a specific character
Font.setSprite = function(charId, sprite, tint="#FFFFFFFF", scale=1)
    qa.assert charId != null and charId isa string and charId.len == 1, "Font.getSprite: charId is invalid"
    qa.assert scale isa number and scale > 0, "Font.getSprite: scale is not a valid number"
    qa.assert tint isa string and tint.startsWith("#") and (tint.len == 9 or tint.len == 7), "Font.getSprite: tint is not a valid color string (#RRGGBBAA or #RRGGBB)"
    qa.assert tint.startsWith("#") and (tint.len == 9 or tint.len == 7), "Font.getSprite: tint must be in format #RRGGBBAA or #RRGGBB"
    qa.assert sprite != null and sprite isa Sprite, "Font.setSprite: sprite is invalid"

    id = code(charId)
	sprite.image = self.pages[self.chars[id].page].image
    x = sprite.x
    y = sprite.y
  
    // Set Sprite UVs
    pageWidth = self.pages[self.chars[id].page].image.width
    pageHeight = self.pages[self.chars[id].page].image.height
    // Starting at the bottom left corner and going anti-clockwise
    sprite.setUVs [
        [self.chars[id].x / pageWidth, (pageHeight - self.chars[id].y - self.chars[id].height) / pageHeight],
        [self.chars[id].x / pageWidth + self.chars[id].width / pageWidth, (pageHeight - self.chars[id].y - self.chars[id].height) / pageHeight],
        [self.chars[id].x / pageWidth + self.chars[id].width / pageWidth, (pageHeight - self.chars[id].y) / pageHeight],
        [self.chars[id].x / pageWidth, (pageHeight - self.chars[id].y) / pageHeight],
    ]
    
    // Force Sprite Corners around 0, 0, Position must be set to 0,0 first and then corners set
    sprite.x = 0
    sprite.y = 0
    sprite.setCorners [
        [0, 0],
        [self.chars[id].width, 0],
        [self.chars[id].width, self.chars[id].height],
        [0, self.chars[id].height],
    ]
    sprite.scale = scale
    sprite.tint = tint
    sprite.x = x + self.chars[id].xoffset * scale
    sprite.y = y + (self.common.base - self.chars[id].height - self.chars[id].yoffset) * scale
    return sprite
end function

// Get an array of Sprites for a string of text
Font.getSprites = function(text, x, y, tint="#FFFFFFFF", scale=1)
    qa.assert text != null and text isa string, "Font.getSprites: text is invalid"
    qa.assert scale isa number and scale > 0, "Font.getSprites: scale is not a valid number"
    qa.assert tint isa string and tint.startsWith("#") and (tint.len == 9 or tint.len == 7), "Font.getSprites: tint is not a valid color string (#RRGGBBAA or #RRGGBB)"
    qa.assert x isa number, "Font.getSprites: x is not a number"
    qa.assert y isa number, "Font.getSprites: y is not a number"

	s = []
    i = 0
	while i < text.len
        sprite = new Sprite
        sprite.x = x
        sprite.y = y
        s.push self.setSprite(text[i], sprite, tint, scale)
        id = code(text[i])
        // Check Kerning with next character
        if i < text.len - 1 then
            nextId = code(text[i + 1])
            if self.kernings.hasIndex(id) and self.kernings[id].hasIndex(nextId) then
                x += self.kernings[id][nextId] * scale
            end if
        end if
        x += self.chars[id].xadvance * scale
		i += 1
	end while
	return s
end function

if globals == locals then
    display(4).clear
    font = Font.load("/usr/assets/fonts/gameplay.fnt")
    c = font.getSprite("H", 100, 100)
    display(4).sprites.push c
    display(4).sprites += font.getSprites("Options", 200, 100, color.white, 2)
    yield
end if