#version 330

in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragPosition;

out vec4 finalColor;

uniform sampler2D texture0; 
uniform vec4 colDiffuse;
uniform vec3 cameraPos;

uniform float fogDensity = 0.015;
uniform vec4 fogColor = vec4(0.25, 0.27, 0.3, 1.0);

void main() {
    vec4 texelColor = texture(texture0, fragTexCoord) * colDiffuse * fragColor;

    if (texelColor.a < 0.5) discard;

    float dist = distance(fragPosition, cameraPos);
    float fogFactor = exp(-pow(dist * fogDensity, 2.0));
    fogFactor = clamp(fogFactor, 0.0, 1.0);
    
    finalColor = mix(fogColor, texelColor, fogFactor);
}