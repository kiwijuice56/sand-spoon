shader_type canvas_item;

uniform bool hover;
uniform bool pressed;
uniform float speed = 0.2;
uniform float saturation = 0.5;

// https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	if (COLOR.r < 1.0) {
		COLOR.rgb = hsv2rgb(vec3(UV.x + UV.y / 8.0 + TIME * speed, saturation, pressed ? 0.4 : (hover ? 1.0 : 0.75)));
	}
}


