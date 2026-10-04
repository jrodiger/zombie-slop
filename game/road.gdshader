shader_type spatial;
render_mode cull_back;
varying vec3 world_position;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world_position.xz;
 float grain=hash(floor(p*30.0));
 vec2 cell=floor(p*.7);vec2 f=fract(p*.7);float nearest=10.0;float second=10.0;
 for(int x=-1;x<=1;x++){for(int y=-1;y<=1;y++){
  vec2 offset=vec2(float(x),float(y));vec2 seed=vec2(hash(cell+offset),hash(cell+offset+17.0));float d=length(offset+seed-f);
  if(d<nearest){second=nearest;nearest=d;}else{second=min(second,d);}
 }}
 float weather=smoothstep(.55,.85,hash(floor(p/7.0)));
 float crack=(1.0-smoothstep(.008,.028,second-nearest))*weather;
 ALBEDO=mix(vec3(.14,.16,.155)*(0.85+grain*.18),vec3(.07,.085,.075),crack*.7);
 ROUGHNESS=.97;
}
