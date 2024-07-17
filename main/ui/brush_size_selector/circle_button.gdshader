shader_type canvas_item;

uniform float radius = 0.5;
uniform float visibility;

void fragment() {
	float r = sqrt(pow(UV.x - 0.5, 2) + pow(UV.y - 0.5, 2));
	if (r < radius) {
		COLOR = vec4(1);
	}
	
	COLOR.rgb = COLOR.rgb - visibility * vec3(0.125 / 2.0);
	if (COLOR.rgb != vec3(1.0) && COLOR.rgb != vec3(0.0) && sin(SCREEN_UV.x * 128.0 + SCREEN_UV.y * 80.0 + 3.0 * TIME) > 0.0) {
		COLOR.rgb = COLOR.rgb + visibility * vec3(0.125);
	} 
	COLOR.rgb += visibility * UV.y / 12.0;
}