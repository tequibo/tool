// Uniforms
//uniform float u_threshold;
//uniform sampler2D u_mask_texture;

void main() {
	// Get the texture coordinate
	vec2 uv = v_tex_coord;

	// Get the color from the main texture
	vec4 color = SKDefaultShading();

	// Get the red channel value from the second texture
	float redChannel = texture2D(u_mask_texture, uv).r;

	// Calculate the intensity of the color
	float intensity = (color.r + color.g + color.b) / 3.0;

	// Adjust alpha based on the red channel value from the second texture
	if (redChannel < u_fuzziness) {
		color.a = 0.0;
	}
	color = u_mask_texture
	// Set the output color
	gl_FragColor = color;
}
