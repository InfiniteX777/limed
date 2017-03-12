local Shader = Instance:class("Shader",2){
	smoke = love.graphics.newShader[[
		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
		{

			number pW = 1/love_ScreenSize.x;//pixel width
			number pH = 1/love_ScreenSize.y;//pixel height

			vec4 pixel = Texel(texture, texture_coords );//This is the current pixel

			vec2 coords = vec2(texture_coords.x-pW,texture_coords.y);
			vec4 Lpixel = Texel(texture, coords );//Pixel on the left

			coords = vec2(texture_coords.x+pW,texture_coords.y);
			vec4 Rpixel = Texel(texture, coords );//Pixel on the right

			coords = vec2(texture_coords.x,texture_coords.y-pH);
			vec4 Upixel = Texel(texture, coords );//Pixel on the up

			coords = vec2(texture_coords.x,texture_coords.y+pH);
			vec4 Dpixel = Texel(texture, coords );//Pixel on the down

			pixel.a += 10 * 0.0166667 * (Lpixel.a + Rpixel.a + Dpixel.a * 3 + Upixel.a - 6 * pixel.a);

			/*pixel.rgb = vec3(1.0,1.0,1.0);*/


			return pixel*color;

		}
	]],
	blur = love.graphics.newShader[[
		vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 pixelCoords)
		{
			vec4 tex = vec4(0,0,0,0);

			int pre = 200;
			float mag = 0.5/pre/2,
				  rad = 0.05/pre;

			for (int i = 0; i <= pre; i++) {
				tex += Texel(texture,textureCoords+vec2(i*rad,0))*mag;
				tex += Texel(texture,textureCoords-vec2(i*rad,0))*mag;

				tex += Texel(texture,textureCoords+vec2(0,i*rad))*mag;
				tex += Texel(texture,textureCoords-vec2(0,i*rad))*mag;

			}

			return tex*color;
		}
	]]
}
