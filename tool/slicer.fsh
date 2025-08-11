//uniform vec4 u_params; // (horizontal_slices, vertical_slices, index_h, index_v)
//uniform float u_fuzziness;
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
	float radius = u_radius;
	float dist = distance(uv, center);

	vec4 color = SKDefaultShading();

	// Calculate the size of each slice
	float sliceWidth = 1.0 / u_params.x;
	float sliceHeight = 1.0 / u_params.y;

	// Calculate the rectangle boundaries based on the indices
	float left = sliceWidth * u_params.z;
	float right = sliceWidth * (u_params.z + 1.0);
	float bottom = sliceHeight * u_params.w;
	float top = sliceHeight * (u_params.w + 1.0);

	// Check if the uv coordinates are within the rectangle
	if (uv.x < left || uv.x > right || uv.y < bottom || uv.y > top) {
		color.a = 0.0;
		color.rgb = vec3(0.0, 0.0, 0.0);
	}
	
	color = color * u_channels;
	gl_FragColor = color;
}
