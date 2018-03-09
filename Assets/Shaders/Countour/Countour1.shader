Shader "Custom/Countour"
{
	Properties{
			_Color("Main Color", Color) = (1,1,1,1)
			_OutlineColor("Outline Color", Color) = (0.4,0.8,0,1)  //改变这个能改变轮廓边的颜色  
			_Outline("Outline width", Range(0.0, 10)) = 0.03   //改变这个能改变轮廓边的粗细  
			_OffsetZ("Z轴偏移",Range(0,100)) = 0 
            _MainTex ("Base (RGB)", 2D) = "white" { }  
        }  
    CGINCLUDE  
    #include "UnityCG.cginc"  
    ENDCG 
	
    SubShader {  
        Tags { "Queue" = "Transparent" }  
        Pass {  
            Name "OUTLINE"  
            Tags { "Queue" = "Transparent" "LightMode" = "Always" }
            Cull Off  
			//offset 15,15
            ZWrite off  	
            ZTest LEqual  
            ColorMask RGB // alpha not used  	
            Blend SrcAlpha OneMinusSrcAlpha   	
			CGPROGRAM  	
			#pragma vertex vert  	
			#pragma fragment frag  
			struct appdata {  
				float4 vertex : POSITION;  
				float3 normal : NORMAL;  
			};  
			struct v2f {  
				float4 pos : POSITION;  
				float4 color : COLOR;  
			};  
			uniform float _Outline;  
			uniform float4 _OutlineColor; 
			float _OffsetZ;
			v2f vert(appdata v) {  
				v2f o;  
				o.pos = UnityObjectToClipPos(v.vertex);  
				float3 norm   = mul ((float3x3)UNITY_MATRIX_IT_MV, v.normal);   //视图坐标
				float2 offset = TransformViewToProjection(norm.xy);   //投影坐标 	
				//o.pos.xy += offset * o.pos.z * _Outline;  
				o.pos.xy += offset * _Outline;
				o.pos.z -= _OffsetZ;
				o.color = _OutlineColor;  
				return o;  
			}
			half4 frag(v2f i) :COLOR {  
				return i.color;  
			}  
			ENDCG  
		}  
        Pass {  
            Name "BASE"  
			Tags{ "Queue" = "Transparent"  }
            ZWrite on  
            //ZTest LEqual  
				ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha  	
            Material {  	
                Diffuse [_Color]  	
                Ambient [_Color]  	
            }  	
            Lighting On	
            SetTexture [_MainTex] {  	 
				Combine texture   
            }  	
        }  	
    }  	
}
