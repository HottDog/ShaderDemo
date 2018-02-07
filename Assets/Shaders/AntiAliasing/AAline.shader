// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/AAline"
{
	Properties{
		_CircleRadius("Circle Radius", Range(0, 0.1)) = 0.05
		_OutlineWidth("Outline Width", Range(0, 0.1)) = 0.01
		_OutlineColor("Outline Color", Color) = (1, 1, 1, 1)
		_LineWidth("Line Width", Range(0, 0.1)) = 0.01
		_LineColor("Line Color", Color) = (1, 1, 1, 1)
		_Antialias("Antialias Factor", Range(0, 0.05)) = 0.01
		_BackgroundColor("Background Color", Color) = (1, 1, 1, 1)

		iMouse("Mouse Pos", Vector) = (100,100,0,0)
		iChannel0("iChannel0", 2D) = "white" {}
		iChannelResolution0("iChannelResolution0", Vector) = (100,100,0,0)
	}
	CGINCLUDE
		#include "UnityCG.cginc"     
		#pragma target 3.0     
		#pragma glsl     

		#define vec2 float2  
		#define vec3 float3  
		#define vec4 float4  
		#define mat2 float2x2  
		#define iGlobalTime _Time.y  
		#define mod fmod  
		//#define lerp lerp  
		#define atan atan2  
		#define fract frac   
		// 屏幕的尺寸  
		//#define iResolution _ScreenParams  
		// 屏幕中的坐标，以pixel为单位  
		#define gl_FragCoord ((_iParam.srcPos.xy/_iParam.srcPos.w)*_ScreenParams.xy)   

		#define pi 3.14159265358979  
		#define sqrt3_divide_6 0.289  
		#define sqrt6_divide_12 0.204

		const float seg = 3.0;
		const float segwidth =0.2f;
		float _CircleRadius;
		float _OutlineWidth;
		float4 _OutlineColor;
		float _LineWidth;
		float4 _LineColor;
		float _Antialias;
		float4 _BackgroundColor;

		fixed4 iMouse;
		sampler2D iChannel0;
		fixed4 iChannelResolution0;

		struct v2f {
			float4 pos : SV_POSITION;
			float4 srcPos : TEXCOORD0;
		};

		//   precision highp float;  
		v2f vert(appdata_base v) 
		{
			v2f o;
			//投影坐标
			o.pos = UnityObjectToClipPos(v.vertex);
			//变换到屏幕坐标(0,w)，并不是标准正交基(0,1)
			o.srcPos = ComputeScreenPos(o.pos);
			return o;
		}

		vec4 main(vec2 fragCoord);

		fixed4 frag(v2f i) : COLOR0
		{
			//i.srcPos.xy / i.srcPos.w 获取到标准正交基的坐标
			//_ScreenParams  当前渲染目标的像素尺寸
			//算的屏幕中的实际坐标
			vec2 fragCoord = ((i.srcPos.xy / i.srcPos.w)*_ScreenParams.xy);
			return main(fragCoord);
		}

		float DrawLine(vec2 pos, vec2 point1, vec2 point2, float width) {
			vec2 dir0 = point2 - point1;
			vec2 dir1 = pos - point1;
			float h = clamp(dot(dir0, dir1) / dot(dir0, dir0), 0.0, 1.0);
			return (length(dir1 - dir0 * h) - width * 0.5);
		}

		float circle(vec2 pos, vec2 center, float radius) {
			float d = length(pos - center) - radius;
			return d;
		}
		//参数说明：
		// fragCoord  改点对应的屏幕实际坐标
		vec4 main(vec2 fragCoord) {
			//这里又由(0,w)变换回了(-w,w)坐标系，之后又变换回(-1,1)实际屏幕坐标系
			vec2 originalPos = (2.0 * fragCoord - _ScreenParams.xy) / _ScreenParams.yy;
			//基于(-1,1)屏幕坐标
			vec2 pos = originalPos;

			// Twist  
			//pos.x += 0.5 * sin(5.0 * pos.y);  
			//鼠标的屏幕坐标
			vec2 split = vec2(0, 0);
			if (iMouse.z > 0.0) {
				split = (-_ScreenParams.xy + 2.0 * iMouse.xy) / _ScreenParams.yy;
			}

			// Background  
			vec3 col = _BackgroundColor.rgb * (1.0 - 0.2*length(originalPos));

			float xSpeed = 0.3;
			float ySpeed = 0.5;
			float zSpeed = 0.7;
			float3x3 mat = float3x3(1., 0., 0.,
				0., cos(xSpeed*iGlobalTime), sin(xSpeed*iGlobalTime),
				0., -sin(xSpeed*iGlobalTime), cos(xSpeed*iGlobalTime));
			mat = mul(float3x3(cos(ySpeed*iGlobalTime), 0., -sin(ySpeed*iGlobalTime),
				0., 1., 0.,
				sin(ySpeed*iGlobalTime), 0., cos(ySpeed*iGlobalTime)), mat);
			mat = mul(float3x3(cos(zSpeed*iGlobalTime), sin(zSpeed*iGlobalTime), 0.,
				-sin(zSpeed*iGlobalTime), cos(zSpeed*iGlobalTime), 0.,
				0., 0., 0.), mat);
			float l = 1.5;
			vec3 p0 = vec3(0., 0., sqrt6_divide_12 * 3.) * l;
			vec3 p1 = vec3(-0.5, -sqrt3_divide_6, -sqrt6_divide_12) * l;
			vec3 p2 = vec3(0.5, -sqrt3_divide_6, -sqrt6_divide_12) * l;
			vec3 p3 = vec3(0, sqrt3_divide_6 * 2., -sqrt6_divide_12) * l;

			p0 = mul(mat, p0);
			p1 = mul(mat, p1);
			p2 = mul(mat, p2);
			p3 = mul(mat, p3);;

			vec2 point0 = p0.xy;
			vec2 point1 = p1.xy;
			vec2 point2 = p2.xy;
			vec2 point3 = p3.xy;

			float d = DrawLine(pos, point0, point1, _LineWidth);
			d = min(d, DrawLine(pos, point1, point2, _LineWidth));
			d = min(d, DrawLine(pos, point2, point3, _LineWidth));
			d = min(d, DrawLine(pos, point0, point2, _LineWidth));
			d = min(d, DrawLine(pos, point0, point3, _LineWidth));
			d = min(d, DrawLine(pos, point1, point3, _LineWidth));
			d = min(d, circle(pos, point0, _CircleRadius));
			d = min(d, circle(pos, point1, _CircleRadius));
			d = min(d, circle(pos, point2, _CircleRadius));
			d = min(d, circle(pos, point3, _CircleRadius));       
			if (originalPos.x < split.x) {
				//左边
				col = lerp(_OutlineColor.rgb, col, step(0, d - _OutlineWidth));
				col = lerp(_LineColor.rgb, col, step(0, d));
			}
			else if (originalPos.y > split.y) {
				//右上
				float w = _Antialias;
				col = lerp(_OutlineColor.rgb, col, smoothstep(-w, w, d - _OutlineWidth));
				col = lerp(_LineColor.rgb, col, smoothstep(-w, w, d));
			}
			else {
				//右下
				float w = fwidth(0.5*d) * 2.0;
				col = lerp(_OutlineColor.rgb, col, smoothstep(-w, w, d - _OutlineWidth));
				col = lerp(_LineColor.rgb, col, smoothstep(-w, w, d));
			}
			// step(a,x)  if x>=a return 1 else return 0;
			// Draw split lines  
			//相当于 col = col * smoothstep(0.005, 0.007, abs(originalPos.x - split.x))
			col = lerp(vec3(0,0,0), col, smoothstep(0.005, 0.007, abs(originalPos.x - split.x)));
			//step(split.x, originalPos.x)  右边为1，左边为0
			//相当于 col = col * (1-(1 - smoothstep(0.005, 0.007, abs(originalPos.y - split.y))) * step(split.x, originalPos.x))
			col = lerp(col, vec3(0,0,0), (1 - smoothstep(0.005, 0.007, abs(originalPos.y - split.y))) * step(split.x, originalPos.x));

			return vec4(col, 1.0);
		}

	ENDCG
	SubShader
	{
		Pass
		{
			CGPROGRAM

			#pragma vertex vert      
			#pragma fragment frag      
			#pragma fragmentoption ARB_precision_hint_fastest       

			ENDCG
		}
	}
	FallBack Off
}
