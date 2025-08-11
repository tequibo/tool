//uniform float u_radius;
//uniform vec4 u_channels;
float sdCircle(vec2 p, float r) {
	return length(p) - r;
}
float random(float offset, vec2 tex_coord, float time) {
	// pick two numbers that are unlikely to repeat
	vec2 non_repeating = vec2(12.9898 * time, 78.233 * time);

	// multiply our texture coordinates by the non-repeating numbers, then add them together
	float sum = dot(tex_coord, non_repeating);

	// calculate the sine of our sum to get a range between -1 and 1
	float sine = sin(sum);

	// multiply the sine by a big, non-repeating number so that even a small change will result in a big color jump
	float huge_number = sine * 43758.5453 * offset;

	// get just the numbers after the decimal point
	float fraction = fract(huge_number);

	// send the result back to the caller
	return fraction;
}
float sdBox(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

void main() {
	vec2 uv = v_tex_coord;
	vec2 center = vec2(0.5, 0.5);
//	vec4 color = SKDefaultShading();
	vec4 color = texture2D(u_texture, (uv-center)*u_zoom+u_center);
	float d = abs(distance(uv, u_center));
	float c = 1 - sdCircle(uv, u_radius);
	float b = 1 - sdBox(uv, vec2(u_radius, u_radius));
	d = mix(c,b, 0);
//	d = smoothstep(c, b, u_fuzziness);
	d = smoothstep(0.999-u_fuzziness, 1, c);
//	color = vec4(d,d,d,1);
	color = color * d;
//	d = sdCircle(uv, u_radius);
//	if (dist > radius) {
//		color.a = 0.0;
//		color.rgb = vec3(.0,.0,.0);
//	}
	
//	color.a = sdCircle(uv-center, u_radius);
	
	color = color*u_channels;
	gl_FragColor = color;
}

