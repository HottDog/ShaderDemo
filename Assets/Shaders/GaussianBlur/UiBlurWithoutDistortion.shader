//高斯模糊
//总的思路：取当前点周围的点的颜色值加权与当前点的颜色进行混合，得到当前点最终的颜色
//    因为取加权值用到的是高斯分布(正太分布)，所以叫高斯模糊
Shader "Custom/UiBlurWithoutDistortion" {
	Properties{
		_Size("Size", Range(0, 20)) = 1
	}
	CGINCLUDE
	#include "UnityCG.cginc"
	struct appdata_t {
		float4 vertex : POSITION;
		float2 texcoord: TEXCOORD0;
	};

	struct v2f {
		float4 vertex : POSITION;
		float4 uvgrab : TEXCOORD0;
	};

	//默认屏幕截图纹理
	sampler2D _GrabTexture;
	//屏幕截图纹理的每个像素的尺寸
	float4 _GrabTexture_TexelSize;
	float _Size;

	v2f vert(appdata_t v) {
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		//获取屏幕的uv坐标，屏幕的uv坐标也就是屏幕截图的uv坐标
		//屏幕截图的uv坐标获取跟贴图的有所不同，主要有两点要注意：
		//1、屏幕坐标是(-1,1),但是我们要的是(0,1)
		//2、处理DX和GL纹理反向的问题
		//这里unity帮我们封装了一个函数解决这些问题，可以直接使用
		o.uvgrab = ComputeGrabScreenPos(o.vertex);
		return o;
	}

	//half4 tex2Dproj(sampler2D s, in half4 t)    { return tex2D(s, t.xy / t.w); }
	//	顶点函数处理屏幕截图的uv还需要再进行 uv.xy /= uv.w操作,才能用于提取截图纹理的uv坐标
	//UNITY_PROJ_COORD()这个函数只是为了防止一些比较特殊的情况，一般没什么用
	//参数说明：
	// weight 权重，取到的点的颜色值将要占最终颜色值的比例
	// kernely 是距离当前点多少个单位的距离
	half4 frag_Horizontal(v2f i) : COLOR{
		half4 sum = half4(0,0,0,0);
		#define GRABPIXEL(weight,kernelx) tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(i.uvgrab.x + _GrabTexture_TexelSize.x * kernelx*_Size, i.uvgrab.y, i.uvgrab.z, i.uvgrab.w))) * weight
		//正态分布函数，用来确定不同距离的点的取值权重 
		//   G(X) = (1/(sqrt(2*PI*deviation*deviation))) * exp(-(x*x / (2*deviation*deviation)))
		//0.05、0.09、0.12等等这些是一开始计算好的高斯权重，为了更高的效率，直接提前计算出来
		//这里往垂直方向取了9个点(包括自身)进行加权颜色混合
		sum += GRABPIXEL(0.05, -4.0);
		sum += GRABPIXEL(0.09, -3.0);
		sum += GRABPIXEL(0.12, -2.0);
		sum += GRABPIXEL(0.15, -1.0);
		sum += GRABPIXEL(0.18,  0.0);
		sum += GRABPIXEL(0.15, +1.0);
		sum += GRABPIXEL(0.12, +2.0);
		sum += GRABPIXEL(0.09, +3.0);
		sum += GRABPIXEL(0.05, +4.0);

		return sum;
	}

	half4 frag_Vertical(v2f i) : COLOR{
		half4 sum = half4(0,0,0,0);
		#define GRABPIXEL(weight,kernely) tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(i.uvgrab.x, i.uvgrab.y + _GrabTexture_TexelSize.y * kernely*_Size, i.uvgrab.z, i.uvgrab.w))) * weight					
		sum += GRABPIXEL(0.05, -4.0);
		sum += GRABPIXEL(0.09, -3.0);
		sum += GRABPIXEL(0.12, -2.0);
		sum += GRABPIXEL(0.15, -1.0);
		sum += GRABPIXEL(0.18,  0.0);
		sum += GRABPIXEL(0.15, +1.0);
		sum += GRABPIXEL(0.12, +2.0);
		sum += GRABPIXEL(0.09, +3.0);
		sum += GRABPIXEL(0.05, +4.0);

		return sum;
	}

	ENDCG
	Category{
		// We must be transparent, so other objects are drawn before this one.
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Opaque" }

		SubShader{

			// Horizontal blur
			//当前屏幕截图
			GrabPass{
				Tags{ "LightMode" = "Always" }
			}
			//水平方向进行高斯模糊
			Pass{
				Tags{ "LightMode" = "Always" }

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag_Horizontal
				//使用低精度(FP16，16bit，半精度)，以提升fragment着色器的运行速度，减少时间
				#pragma fragmentoption ARB_precision_hint_fastest
				ENDCG
			}
			// 之所以要再次截图，是因为要接着上一个水平处理后的效果再进行垂直处理
			GrabPass{
				Tags{ "LightMode" = "Always" }
			}
			//垂直方向进行高斯模糊
			Pass{
				Tags{ "LightMode" = "Always" }

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag_Vertical
				#pragma fragmentoption ARB_precision_hint_fastest
				ENDCG
			}
		}
	}
}