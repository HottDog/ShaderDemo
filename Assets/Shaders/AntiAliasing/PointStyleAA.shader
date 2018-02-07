Shader "Unlit/PointStyleAA"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
// use the hardware bilinear filter to do all the work, 
// but remap the uv coords to move along in a kind of 'bumpy' way to give anti-aliased point sampling

// now with 3 splits: on the left, no anti-aliasing. in the middle, smoothstep ('softer'). on the right, linear ('sharper').

#define split (floor(iResolution.x/5.))

vec4 AntiAlias_None(vec2 uv, vec2 texsize) {
	return texture(iChannel0, uv / texsize, -99999.0);
}

vec4 AntiAliasPointSampleTexture_None(vec2 uv, vec2 texsize) {
	return texture(iChannel0, (floor(uv + 0.5) + 0.5) / texsize, -99999.0);
}

vec4 AntiAliasPointSampleTexture_Smoothstep(vec2 uv, vec2 texsize) {
	vec2 w = fwidth(uv);
	return texture(iChannel0, (floor(uv) + 0.5 + smoothstep(0.5 - w, 0.5 + w, fract(uv))) / texsize, -99999.0);
}

vec4 AntiAliasPointSampleTexture_Linear(vec2 uv, vec2 texsize) {
	vec2 w = fwidth(uv);
	return texture(iChannel0, (floor(uv) + 0.5 + clamp((fract(uv) - 0.5 + w) / w, 0., 1.)) / texsize, -99999.0);
}

vec4 AntiAliasPointSampleTexture_ModifiedFractal(vec2 uv, vec2 texsize) {
	uv.xy -= 0.5;
	vec2 w = fwidth(uv);
	return texture(iChannel0, (floor(uv) + 0.5 + min(fract(uv) / min(w, 1.0), 1.0)) / texsize, -99999.0);
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord.xy;
	if (floor(uv.x) == split || floor(uv.x) == split * 2. || floor(uv.x) == split * 3. || floor(uv.x) == split * 4.) {
		fragColor = vec4(1.); return;
	}

	//uv*=((1.0+sin(iTime*0.5))*5.+1.);

	// rotate the uv with time		
	float c = cos(iTime*0.1), s = sin(iTime*0.1);
	uv = uv * mat2(c, s, -s, c)*0.05;

	// sample the texture!
	float anisotest = 1.0; // if you want stretchy pixels, try change this number to 0.1 
	uv *= vec2(1.0, anisotest);

	vec2 tessize = vec2(256.0, 256.0);

	if (fragCoord.x<split)
		fragColor = AntiAlias_None(uv, tessize);
	else if (fragCoord.x<split*2.)
		fragColor = AntiAliasPointSampleTexture_None(uv, tessize);
	else if (fragCoord.x<split*3.)
		fragColor = AntiAliasPointSampleTexture_Smoothstep(uv, tessize);
	else if (fragCoord.x<split*4.)
		fragColor = AntiAliasPointSampleTexture_Linear(uv, tessize);
	else
		fragColor = AntiAliasPointSampleTexture_ModifiedFractal(uv, tessize);

	fragColor = pow(fragColor, vec4(1. / 2.2));

}