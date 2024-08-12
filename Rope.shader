Shader "Hamilt79/Rope"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _Length("Length", Float) = 0
    }
    SubShader
    {
        // Don't allow batching
        Tags { "DisableBatching"="True" "VRCFallback"="Hidden"}
        Cull Off
        ZWrite On

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID 
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID 
            };

            // Tolerance equal check
            bool equal_check(float3 f1, float3 f2, float tolerance) {
                return (abs(distance(f1, f2)) < tolerance);
            }

            // Get magnitude of vector so we can normlize it
            float get_mag(float3 f1) {
                return sqrt(f1.x * f1.x + f1.y * f1.y + f1.z * f1.z);
            }

            // Get direction vector between two points and optionally normalize it
            float3 get_vec(float3 f1, float3 f2, bool norm) {
                float one = f1.x - f2.x;
                float two = f1.y - f2.y;
                float three = f1.z - f2.z;
                if (!norm) {
                    return float3(one, two, three);
                }
                float3 retVal = float3(one, two, three);
                return (retVal / get_mag(retVal));
            }

            // Get the scale of unity gameobject
            float ObjectScale() {
                return length(unity_ObjectToWorld._m00_m10_m20);
            }

            float _Length;

            v2f vert (appdata v)
            {
                v2f o;
                #ifdef UNITY_INSTANCING_ENABLED
                UNITY_SETUP_INSTANCE_ID(v);
    			UNITY_TRANSFER_INSTANCE_ID(v, o);
                //v.vertex.xyz *= .1;
                // Init arrays with max amount of instances
                const int len = 60;
                float3 cube_positions[len];
                bool skipped[len];
                // Get world pos
                float3 wposx = float3(unity_ObjectToWorld[0][3], unity_ObjectToWorld[1][3], unity_ObjectToWorld[2][3]);
                for (int idx = 0; idx < unity_InstanceCount; idx++)
                {
                    v2f dummy;
                    dummy.instanceID = idx;
                    // Setup dummy values
                    UNITY_SETUP_INSTANCE_ID(dummy);
					// Get dummy pos
                    float3 wpos = float3(unity_ObjectToWorld[0][3], unity_ObjectToWorld[1][3], unity_ObjectToWorld[2][3]);
                    cube_positions[idx] = wpos;
                }
                // Restore old vals
                UNITY_SETUP_INSTANCE_ID(v);
                // Convert to world space
                v.vertex = mul(unity_ObjectToWorld, v.vertex);
                float cDist = -1.0;
                int distIndx = 0;
                // Get closest instance
                for (int i = 0; i < unity_InstanceCount; i++) {
                    // If same object don't count it
                    if (equal_check(wposx, cube_positions[i], 0.01)) {
                        continue;
                    }
                    float dist = distance(wposx, cube_positions[i]);
                    if (dist < cDist || cDist == -1.0) {
                        bool good = true;
                        if (good) {
                            distIndx = i;
                            cDist = dist;
                        }
                    }
                }
                float wdist = distance(wposx.xyz, cube_positions[distIndx]);
                float3 diff = wposx - cube_positions[distIndx];
                float3 newspot = v.vertex.xyz - diff;
                if (wdist < _Length) {
                    newspot.y -= _Length - wdist;
                }
                float nvdist = distance(v.vertex.xyz, newspot.xyz);
                float nwdist = distance(wposx.xyz, newspot.xyz);
                if (nvdist <= nwdist) {
                    v.vertex.xyz = lerp(v.vertex, newspot, 0.5);
                }
                //for (int i = 0; i < unity_instancecount; i++) {
                //    if (equal_check(wposx, cube_positions[i], 0.001)) {
                //        continue;
                //    }
                //    float vdist = distance(v.vertex.xyz, cube_positions[i]);
                //    float wdist = distance(wposx.xyz, cube_positions[i]);
                //    float3 diff = wposx - cube_positions[i];
                //    float3 newspot = v.vertex.xyz - diff;
                //    if (wdist < _length) {
                //        newspot.y -= _length - wdist;
                //    }
                //    float nvdist = distance(v.vertex.xyz, newspot.xyz);
                //    float nwdist = distance(wposx.xyz, newspot.xyz);
                //    if (nvdist > nwdist) {
                //        continue;
                //    }
                //    //float3 diff = wposx - cube_positions[i];
                //    //float3 newspot = v.vertex.xyz - diff;
                //    v.vertex.xyz = lerp(v.vertex, newspot, 0.5);
                //}
                
                v.vertex = mul(unity_WorldToObject, v.vertex);
                #endif
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            float4 _Color;
            float _VRChatMirrorMode;

            fixed4 frag (v2f i) : SV_Target
            {
                #ifdef UNITY_INSTANCING_ENABLED
                UNITY_SETUP_INSTANCE_ID(i);
                if(_VRChatMirrorMode != 0) {
                    discard;
                }
                // Color rep of instance ID
                if (i.instanceID == 0){
                    return float4(1,0,0,1);
                } else if (i.instanceID == 1){
                    return float4(0,1,0,1);
                } else if (i.instanceID == 2){
                    return float4(0,0,1,1);
                } else if (i.instanceID == 3){
                    return float4(1,1,0,1);
                } else if (i.instanceID == 4){
                    return float4(0,1,1,1);
                } else if (i.instanceID == 5){
                    return float4(1,0,1,1);
                }
                return _Color;
                #endif
    			return float4(1,0,1,1);

            }
            ENDCG
        }
    }
}
