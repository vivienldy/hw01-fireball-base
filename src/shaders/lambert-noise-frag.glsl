#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

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

void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

    vec3 pos = fs_Pos.xyz / vec3(0.05);
    float noise = perlinNoise(pos) + 0.5;
    diffuseColor = diffuseColor * noise;
    //diffuseColor = vec4(noise, noise, noise, 1);

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    // diffuseTerm = clamp(diffuseTerm, 0, 1);

    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    // Compute final shaded color
    out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
