shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled;

// Recebe as duas texturas geradas pelos rasterizadores
// Transform in a array
uniform sampler2D texture_left : filter_linear_mipmap;
uniform sampler2D texture_right : filter_linear_mipmap;

void fragment() {
	// 0 = LeftEye, 1 = RightEye
	if (VIEW_INDEX == 0) {
		ALBEDO = texture(texture_left, SCREEN_UV).rgb;
	} else {
		ALBEDO = texture(texture_right, SCREEN_UV).rgb;
	}
}
