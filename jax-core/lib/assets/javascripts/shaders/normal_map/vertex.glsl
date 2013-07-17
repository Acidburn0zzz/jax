//= require 'shaders/lib/lights'

shared attribute vec4 VERTEX_POSITION;
shared attribute vec2 VERTEX_TEXCOORDS;
shared attribute vec3 VERTEX_NORMAL;
shared attribute vec4 VERTEX_TANGENT;
shared attribute vec3 VERTEX_BITANGENT;

void main(void) {
  if (PASS != 0) {
    vTexCoords = VERTEX_TEXCOORDS;
    
    vec3 n = VERTEX_NORMAL;
    vec3 t = VERTEX_TANGENT.xyz;
    vec3 b = cross(n, t) * VERTEX_TANGENT.w;
    
    vN = NormalMatrix * n;
    vT = NormalMatrix * t;
    vB = NormalMatrix * b;
  }
}