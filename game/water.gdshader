shader_type spatial;
render_mode cull_back;
varying vec3 world_position;
float surface_noise(vec2 p) {
 vec2 cell=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
 float a=fract(sin(dot(cell,vec2(127.1,311.7)))*43758.5453);
 float b=fract(sin(dot(cell+vec2(1.0,0.0),vec2(127.1,311.7)))*43758.5453);
 float c=fract(sin(dot(cell+vec2(0.0,1.0),vec2(127.1,311.7)))*43758.5453);
 float d=fract(sin(dot(cell+vec2(1.0,1.0),vec2(127.1,311.7)))*43758.5453);
 return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}
void vertex() {
 world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.y+=.012*sin(world_position.z*2.3+TIME*1.4)+.006*sin(world_position.x*3.9-TIME*.8);
}
void fragment() {
 vec2 p=world_position.xz;
 vec2 flow=p*vec2(.6,.24)+vec2(0.0,TIME*.08);
 float ripple=surface_noise(flow)*.7+surface_noise(flow*2.13+vec2(17.0,9.0))*.3;
 float wave=p.y*1.6+p.x*.22+TIME*.9+ripple*2.0;
 vec3 normal=normalize(vec3(.007*cos(wave),1.0,.012*cos(wave)+.005*cos(p.y*2.7-p.x*.4-TIME*.6)));
 NORMAL=normalize(mat3(VIEW_MATRIX)*normal);
 ALBEDO=mix(vec3(.045,.12,.105),vec3(.09,.19,.17),ripple);
 ROUGHNESS=.48;METALLIC=0.0;SPECULAR=.3;
}
