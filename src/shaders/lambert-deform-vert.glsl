#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time;
uniform float u_Frequency;
uniform float u_Bumpiness;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;
out vec2 fs_UV;

const vec4 lightPos = vec4(5, 5, 20, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

// ------------------- 3D PERLIN --------------------------

float rand3dTo1d(vec3 value, vec3 dotDir){
    //make value smaller to avoid artefacts
    vec3 smallValue = sin(value);
    //get scalar value from 3d vector
    float random = dot(smallValue, dotDir);
    //make value more random by making it bigger and then taking the factional part
    random = fract(sin(random) * 143758.5453);
    return random;
}

vec3 rand3dTo3d(vec3 value){
    return vec3(
        rand3dTo1d(value, vec3(12.989, 78.233, 37.719)),
        rand3dTo1d(value, vec3(39.346, 11.135, 83.155)),
        rand3dTo1d(value, vec3(73.156, 52.235, 09.151))
    );
}

float easeIn(float interpolator){
	return interpolator * interpolator * interpolator * interpolator * interpolator;
}

float easeOut(float interpolator){
	return 1.0 - easeIn(1.0 - interpolator);
}

float easeInOut(float interpolator){
    float easeInValue = easeIn(interpolator);
    float easeOutValue = easeOut(interpolator);
    return mix(easeInValue, easeOutValue, interpolator);
}

float perlinNoise(vec3 value){
    vec3 fraction = fract(value);

    float interpolatorX = easeInOut(fraction.x);
    float interpolatorY = easeInOut(fraction.y);
    float interpolatorZ = easeInOut(fraction.z);

    float cellNoiseZ[2];
    for(int z=0;z<=1;z++){
        float cellNoiseY[2];
        for(int y=0;y<=1;y++){
            float cellNoiseX[2];
            for(int x=0;x<=1;x++){
                vec3 cell = floor(value) + vec3(x, y, z);
                vec3 cellDirection = rand3dTo3d(cell) * 2.0 - 1.0;
                vec3 compareVector = fraction - vec3(x, y, z);               
                cellNoiseX[x] = dot(cellDirection, compareVector);
            }
            cellNoiseY[y] = mix(cellNoiseX[0], cellNoiseX[1], interpolatorX);
        }
        cellNoiseZ[z] = mix(cellNoiseY[0], cellNoiseY[1], interpolatorY);
    }
    float noise = mix(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
    return noise;
}

float rand1dTo1d(float value){
	float random = fract(sin(value + 0.546) * 143758.5453);
	return random;
}

// ------------------- FBM --------------------------
float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

float hash(float h) {
	return fract(sin(h) * 43758.5453123);
}

float noise3d (vec3 x) {
	vec3 p = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);

	float n = p.x + p.y * 157.0 + 113.0 * p.z;
	return mix(
			mix(mix(hash(n + 0.0), hash(n + 1.0), f.x),
					mix(hash(n + 157.0), hash(n + 158.0), f.x), f.y),
			mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
					mix(hash(n + 270.0), hash(n + 271.0), f.x), f.y), f.z);
}

#define OCTAVES 6
float fbm (vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}

#define OCTAVES 6
float fbm3d (vec3 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise3d(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}

// ------------------- CALCULATE UV --------------------------
vec2 uv(vec3 pos){
    pos = normalize(pos);
    float u = 0.5 + atan(pos.x, pos.z)/6.28318;
    float v = 0.5 + asin(pos.y)/3.14159;
    return vec2(u, v);
}

float bias(float b, float t) {
    return (pow(t, log(b)) / log(0.5));
}

// ------------------- MAIN --------------------------

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    float frequency = u_Frequency;
    float time = bias(u_Time, 0.28);
    vec3 pos = vec3(vs_Pos.x + u_Time * frequency, vs_Pos.y + u_Time * frequency, vs_Pos.z + u_Time * frequency) / vec3(0.3);
    float noise = perlinNoise(pos) + 0.5;
    //vec3 pos2 = vec3(vs_Pos.x + rand1dTo1d(float(u_Time)) * 0.001, vs_Pos.y + float(u_Time) * 0.003, vs_Pos.z + float(u_Time) * 0.005) / vec3(0.1);

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
    float fbmNoise3d = fbm3d(vs_Pos.xyz * u_Bumpiness);    
    fs_Col = vec4(fbmNoise3d, fbmNoise3d, fbmNoise3d, 1.0);

    vec4 deformedPos = vs_Pos + vs_Pos + vs_Nor  * fbmNoise3d * noise;
    fs_Pos = deformedPos;

    //deformedPos = vs_Pos;
    vec4 modelposition = u_Model * deformedPos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
