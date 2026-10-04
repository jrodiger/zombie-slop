shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back;
void fragment() {
 float radius=length((UV-.5)*2.0);
 ALBEDO=vec3(.04,.035,.025);
 ALPHA=.45*(1.0-smoothstep(.25,1.0,radius));
}
