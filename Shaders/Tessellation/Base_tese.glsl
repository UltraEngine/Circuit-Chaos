#include "../Base/Limits.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/Materials.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Base/CameraInfo.glsl"
#include "Primitives.glsl"
#include "../Math/Plane.glsl"

//#define DEBUG_EDGES

//Layout
#if PATCH_VERTICES == 2
layout(isolines, fractional_odd_spacing, ccw) in;
#endif
#if PATCH_VERTICES == 3
layout(triangles, fractional_odd_spacing, ccw) in;
#endif
#if PATCH_VERTICES == 4
layout(quads, fractional_odd_spacing, ccw) in;
#endif

//----------------------------------------------------------------
// Inputs
//----------------------------------------------------------------

layout(location = 22) in patch uint primitiveFlags;
layout(location = 20) in vec3 tess_normal2[];
layout(location = 9) in flat uint tess_flags[];
layout(location = 2) in vec4 tess_texCoords[];
layout(location = 3) in vec3 tess_tangent[]; 
layout(location = 4) in vec3 tess_bitangent[];
layout(location = 8) in vec4 maxDisplacedPosition[];
#ifdef WRITE_COLOR
layout(location = 0) in vec4 tess_color[];
//Inputs
//layout(location = 18) in vec4 tess_VertexColor[];
//layout(location = 4) in vec3 tess_bitangent[];
layout(location = 6) in vec4 tess_vertexCameraPosition[];
layout(location = 23) in vec3 tess_screenvelocity[];
#endif
layout(location = 1) in vec3 tess_normal[];
layout(location = 5) patch in uint tess_materialID;
layout(location = 7) in vec4 tess_vertexWorldPosition[];
//layout(location = 10) flat in float tess_cameraDistance[];
layout(location = 11) in float tess_vertexDisplacement[];
//layout(location = 9) in vec3 tess_displacement[];
layout(location = 25) patch in uint tess_entityID;

//----------------------------------------------------------------
// Outputs
//----------------------------------------------------------------

layout(location = 9) out flat uint flags;
#ifdef WRITE_COLOR
layout(location = 0) out vec4 color;
//Outputs
//layout(location = 18) out vec4 VertexColor;
layout(location = 3) out vec3 tangent;
layout(location = 4) out vec3 bitangent;
//layout(location = 4) out vec3 bitangent;
layout(location = 6) out vec4 vertexCameraPosition;
layout(location = 23) out vec3 screenvelocity;
#else
vec3 tangent;
vec3 bitangent;
#endif
layout(location = 1) out vec3 normal;
layout(location = 2) out vec4 texCoords;
layout(location = 5) flat out uint materialID;
layout(location = 25) flat out uint entityID;
layout(location = 7) out vec4 vertexWorldPosition;
//layout(location = 10) flat out float cameraDistance;
layout(location = 8) out vec4 frag_maxDisplacedPosition;

//TODO
#ifdef PNLINES
vec3 PNLine(vec3 p0, vec3 p1, vec3 norm0, vec3 norm1, vec2 uv)
{
}
#endif

#ifdef PNQUADS
#include "PNQuad.glsl"
#endif

#ifdef PNTRIANGLES
#include "PNTriangle.glsl"
#endif

const float ntolerance = 0.01f;

void main()
{
	materialID = tess_materialID;
	entityID = tess_entityID;
	flags = tess_flags[0];

//TODO
#if PATCH_VERTICES == 2
	float vertexDisplacement = 0.0f;
#endif

	bool tess0 = (primitiveFlags & PRIMITIVE_TESSELLATE_OUTER0) != 0;	
#if PATCH_VERTICES > 2
	bool tess1 = (primitiveFlags & PRIMITIVE_TESSELLATE_OUTER1) != 0;
	bool tess2 = (primitiveFlags & PRIMITIVE_TESSELLATE_OUTER2) != 0;
	#if PATCH_VERTICES == 4
	bool tess3 = (primitiveFlags & PRIMITIVE_TESSELLATE_OUTER3) != 0;
	if (tess0) tess2 = true;
	if (tess1) tess3 = true;
	#endif
#endif

	int curvededges = 0;
	if (tess0) ++curvededges;
#if PATCH_VERTICES > 2	
	if (tess1) ++curvededges;
	if (tess2) ++curvededges;
	#if PATCH_VERTICES == 4
	if (tess3) ++curvededges;
	#endif
#endif

	//tess0 = true;
	//tess1 = true;
	//tess2 = true;
	//curvededges = 3;
	//#if PATCH_VERTICES == 4
	//tess3 = true;
	//curvededges = 4;
	//#endif

	//Optimization for coplanar faces
	//if (curvededges > 0 && (primitiveFlags & PRIMITIVE_COPLANAR) != 0) curvededges = PATCH_VERTICES;

if ((primitiveFlags & PRIMITIVE_COPLANAR) != 0 && gl_TessCoord.x != 0.0f && gl_TessCoord.y != 0.0f && gl_TessCoord.z != 0.0f)
{
	//curvededges = 0;
}

#if PATCH_VERTICES == 3
	vec3 tessCoord = gl_TessCoord;
	float vertexDisplacement = tess_vertexDisplacement[0] * gl_TessCoord.x + tess_vertexDisplacement[1] * gl_TessCoord.y + tess_vertexDisplacement[2] * gl_TessCoord.z;
	vertexDisplacement = 1.0f;
	normal = tess_normal[0] * gl_TessCoord.x + tess_normal[1] * gl_TessCoord.y + tess_normal[2] * gl_TessCoord.z;
	texCoords = tess_texCoords[0] * gl_TessCoord.x + tess_texCoords[1] * gl_TessCoord.y + tess_texCoords[2] * gl_TessCoord.z;
	tangent = tess_tangent[0] * gl_TessCoord.x + tess_tangent[1] * gl_TessCoord.y + tess_tangent[2] * gl_TessCoord.z;
	bitangent = tess_bitangent[0] * gl_TessCoord.x + tess_bitangent[1] * gl_TessCoord.y + tess_bitangent[2] * gl_TessCoord.z;
	#ifdef WRITE_COLOR
	color = tess_color[0] * gl_TessCoord.x + tess_color[1] * gl_TessCoord.y + tess_color[2] * gl_TessCoord.z;
	vertexCameraPosition = tess_vertexCameraPosition[0] * gl_TessCoord.x + tess_vertexCameraPosition[1] * gl_TessCoord.y + tess_vertexCameraPosition[2] * gl_TessCoord.z;
	screenvelocity = tess_screenvelocity[0] * gl_TessCoord.x + tess_screenvelocity[1] * gl_TessCoord.y + tess_screenvelocity[2] * gl_TessCoord.z;
	#endif
	#ifdef PNTRIANGLES

	int edgenum;
	vec3 edgepos;

	//bool coplanar = (primitiveFlags & PRIMITIVE_COPLANAR) != 0;
	//if (gl_TessCoord.x == 1.0f || gl_TessCoord.y == 1.0f || gl_TessCoord.z == 1.0f) curvededges = 0;
	//if (coplanar && gl_TessCoord.x != 0.0f && gl_TessCoord.y != 0.0f && gl_TessCoord.z != 0.0f)
	//{
		//curvededges = 0;
	//}
	switch (curvededges)
	{
		case 0:
			vertexWorldPosition = tess_vertexWorldPosition[0] * gl_TessCoord.x + tess_vertexWorldPosition[1] * gl_TessCoord.y + tess_vertexWorldPosition[2] * gl_TessCoord.z;
			break;
		default:
			vertexWorldPosition.xyz = PNTriangle(tess_vertexWorldPosition[0].xyz, tess_vertexWorldPosition[1].xyz, tess_vertexWorldPosition[2].xyz, tess_normal2[0], tess_normal2[1], tess_normal2[2], gl_TessCoord.xyz, tess0, tess1, tess2);
			break;			
	}

	#else
	vertexWorldPosition = tess_vertexWorldPosition[0] * gl_TessCoord.x + tess_vertexWorldPosition[1] * gl_TessCoord.y + tess_vertexWorldPosition[2] * gl_TessCoord.z;
	#endif
#endif

#if PATCH_VERTICES == 4

	vec2 tessCoord = gl_TessCoord.xy;
	float vertexDisplacement = mix(mix(tess_vertexDisplacement[0], tess_vertexDisplacement[3], tessCoord.x), mix(tess_vertexDisplacement[1], tess_vertexDisplacement[2], tessCoord.x), tessCoord.y);
	#ifdef PNQUADS
	int edgenum, axis;
	vec3 edgepos;
	float af;
	switch (curvededges)
	{
		case 0:

			//Simple linear interpolation
			vertexWorldPosition = mix(mix(tess_vertexWorldPosition[0], tess_vertexWorldPosition[3], tessCoord.x), mix(tess_vertexWorldPosition[1], tess_vertexWorldPosition[2], tessCoord.x), gl_TessCoord.y);
			break;

		/*case 1:

			//One curved edge, three straight edges
			if (tess0) edgenum = 0;
			if (tess1) edgenum = 1;
			if (tess2) edgenum = 2;
			if (tess3) edgenum = 3;
			axis = edgenum % 2;
			af = 0.0f;
			if (tess2 || tess3) af = 1.0f;

			//Find rounded position along curved edge
			tessCoord = gl_TessCoord.xy;
			tessCoord[axis] = af;
			edgepos = PNQuad(tess_vertexWorldPosition[0].xyz, tess_vertexWorldPosition[1].xyz, tess_vertexWorldPosition[2].xyz, tess_vertexWorldPosition[3].xyz, tess_normal2[0], tess_normal2[1], tess_normal2[2], tess_normal2[3], tessCoord.xy);

			//Get opposite edge position
			int opposite = (edgenum + 2) % 4;
			tessCoord = gl_TessCoord.xy;
			tessCoord[axis] = 1.0f - af;
			vec3 oppositepos = mix(mix(tess_vertexWorldPosition[0].xyz, tess_vertexWorldPosition[3].xyz, tessCoord.x), mix(tess_vertexWorldPosition[1].xyz, tess_vertexWorldPosition[2].xyz, tessCoord.x), tessCoord.y);
			
			//Linear interpolation between curved edge and opposite edge
			vertexWorldPosition.xyz = (edgepos * (1.0f - gl_TessCoord[axis]) + oppositepos * gl_TessCoord[axis]) * (1.0f - af); 
			vertexWorldPosition.xyz += (edgepos * (gl_TessCoord[axis]) + oppositepos * (1.0f - gl_TessCoord[axis])) * (af); 
			
			break;*/

		case 2:
			//if ((tess1 && tess3) || (tess0 && tess2))
			//{
				//Opposite edges
				vertexWorldPosition.xyz = PNQuad(tess_vertexWorldPosition[0].xyz, tess_vertexWorldPosition[1].xyz, tess_vertexWorldPosition[2].xyz, tess_vertexWorldPosition[3].xyz, tess_normal2[0], tess_normal2[1], tess_normal2[2], tess_normal2[3], gl_TessCoord.xy);
			//}
			/*else
			{
				vec3 edgepositions[4];
				bool done[4] = {false, false, false, false};

				vertexWorldPosition = vec4(0,0,0,1);

				//Adjacent edges
				for (int n = 0; n < 2; ++n)
				{
					if (tess0 == true) edgenum = 0;
					if (tess1 == true) edgenum = 1;
					if (tess2 == true) edgenum = 2;
					if (tess3 == true) edgenum = 3;
					axis = edgenum % 2;
					af = 0.0f;
					if (edgenum == 2 || edgenum == 3) af = 1.0f;

					//Find rounded position along curved edge
					tessCoord = gl_TessCoord.xy;
					tessCoord[axis] = af;
					edgepositions[edgenum] = PNQuad(tess_vertexWorldPosition[0].xyz, tess_vertexWorldPosition[1].xyz, tess_vertexWorldPosition[2].xyz, tess_vertexWorldPosition[3].xyz, tess_normal2[0], tess_normal2[1], tess_normal2[2], tess_normal2[3], tessCoord.xy);

					//Get opposite edge position
					int opposite = (edgenum + 2) % 4;
					tessCoord = gl_TessCoord.xy;
					tessCoord[axis] = 1.0f - af;
					edgepositions[opposite] = mix(mix(tess_vertexWorldPosition[0].xyz, tess_vertexWorldPosition[3].xyz, tessCoord.x), mix(tess_vertexWorldPosition[1].xyz, tess_vertexWorldPosition[2].xyz, tessCoord.x), tessCoord.y);

					vertexWorldPosition.xyz += edgepositions[edgenum] * (1.0f - gl_TessCoord[axis]) + edgepositions[opposite] * gl_TessCoord[axis]; 

					switch (edgenum)
					{
					case 0:
						tess0 = false;
						break;
					case 1:
						tess1 = false;
						break;
					case 2:
						tess2 = false;
						break;
					case 3:
						tess3 = false;
						break;
					}
				}

				//Linear interpolation
				vertexWorldPosition.xyz *= 0.5f;
				//vertexWorldPosition.xyz = mix(mix(edgepositions[0], edgepositions[3], gl_TessCoord.x), mix(edgepositions[1], edgepositions[2], gl_TessCoord.x), gl_TessCoord.y);
			}*/
			break;

		/*case 3:
			if (!tess0) edgenum = 0;
			if (!tess1) edgenum = 1;
			if (!tess2) edgenum = 2;
			if (!tess3) edgenum = 3;			

			vec3 tn[4] = {tess_normal2[0], tess_normal2[1], tess_normal2[2], tess_normal2[3]};
			
			vec4 pl = Plane(tess_vertexWorldPosition[edgenum].xyz, tess_vertexWorldPosition[(edgenum + 1) % 4].xyz, tess_vertexWorldPosition[(edgenum + 2) % 4].xyz);
			tn[(edgenum + 2) % 4] = pl.xyz;

			vertexWorldPosition.xyz = PNQuad(tess_vertexWorldPosition[0].xyz, tess_vertexWorldPosition[1].xyz, tess_vertexWorldPosition[2].xyz, tess_vertexWorldPosition[3].xyz, tn[0], tn[1], tn[2], tn[3], tessCoord.xy);
			
			break;*/
		//case 3:
		case 4:
			vertexWorldPosition.xyz = PNQuad(tess_vertexWorldPosition[0].xyz, tess_vertexWorldPosition[1].xyz, tess_vertexWorldPosition[2].xyz, tess_vertexWorldPosition[3].xyz, tess_normal2[0], tess_normal2[1], tess_normal2[2], tess_normal2[3], gl_TessCoord.xy);
			break;
	}

	//Testing...
	//vertexWorldPosition = mix(mix(tess_vertexWorldPosition[0], tess_vertexWorldPosition[3], gl_TessCoord.x), mix(tess_vertexWorldPosition[1], tess_vertexWorldPosition[2], gl_TessCoord.x), gl_TessCoord.y);

	#else
	vertexWorldPosition = mix(mix(tess_vertexWorldPosition[0], tess_vertexWorldPosition[3], tessCoord.x), mix(tess_vertexWorldPosition[1], tess_vertexWorldPosition[2], tessCoord.x), gl_TessCoord.y);
	#endif
	normal = mix(mix(tess_normal[0], tess_normal[3], tessCoord.x), mix(tess_normal[1], tess_normal[2], tessCoord.x), tessCoord.y);
	texCoords = mix(mix(tess_texCoords[0], tess_texCoords[3], tessCoord.x), mix(tess_texCoords[1], tess_texCoords[2], tessCoord.x), tessCoord.y);
	#ifdef WRITE_COLOR
	color = mix(mix(tess_color[0], tess_color[3], tessCoord.x), mix(tess_color[1], tess_color[2], tessCoord.x), tessCoord.y);
	vertexCameraPosition = mix(mix(tess_vertexCameraPosition[0], tess_vertexCameraPosition[3], tessCoord.x), mix(tess_vertexCameraPosition[1], tess_vertexCameraPosition[2], tessCoord.x), tessCoord.y);
	screenvelocity = mix(mix(tess_screenvelocity[0], tess_screenvelocity[3], tessCoord.x), mix(tess_screenvelocity[1], tess_screenvelocity[2], tessCoord.x), tessCoord.y);
	//Testing...
	//vertexWorldPosition = mix(mix(tess_vertexWorldPosition[0], tess_vertexWorldPosition[3], tessCoord.x), mix(tess_vertexWorldPosition[1], tess_vertexWorldPosition[2], tessCoord.x), gl_TessCoord.y);
	#endif
	tangent = mix(mix(tess_tangent[0], tess_tangent[3], tessCoord.x), mix(tess_tangent[1], tess_tangent[2], tessCoord.x), tessCoord.y);
	bitangent = mix(mix(tess_bitangent[0], tess_bitangent[3], tessCoord.x), mix(tess_bitangent[1], tess_bitangent[2], tessCoord.x), tessCoord.y);
#endif
	
	vertexWorldPosition.w = 1.0;

//normal = CameraNormalMatrix * normal;
//#ifdef WRITE_COLOR
//tangent.xyz = CameraNormalMatrix * tangent.xyz;
//#endif

// Edge testing:
#ifdef DEBUG_EDGES
#ifdef WRITE_COLOR
	#if PATCH_VERTICES == 4
if (gl_TessCoord.x == 0.0f || gl_TessCoord.x == 1.0f)
{
	color = vec4(1,0,0,1);
}
if (gl_TessCoord.y == 0.0f || gl_TessCoord.y == 1.0f)
{
	color = vec4(0,1,0,1);
}
	#endif
	#if PATCH_VERTICES == 3
if (gl_TessCoord.x == 0.0f)
{
//	if (tess_normal2[1] != vec3(0.0f) && tess_normal2[2] != vec3(0.0f))
	color = vec4(1,0,0,1);
}
if (gl_TessCoord.y == 0.0f)
{
	color = vec4(0,1,0,1);
}
if (gl_TessCoord.z == 0.0f)
{
	color = vec4(0,0,1,1);
}
	#endif
#endif
#endif

#ifdef USERFUNCTION

	UserFunction(tess_entityID, vertexWorldPosition, normal, texCoords, materials[materialID]);

#else

	//Standard displacement mapping
	if (vertexDisplacement > 0.0f)
	{
		Material material = materials[materialID];
		uvec2 textureID = material.textureHandle[TEXTURE_DISPLACEMENT];
		if (textureID != uvec2(0))
		{
			float maxDisplacement = material.displacement.x;
			float offset = material.displacement.y;
			float h = texture(sampler2D(textureID), texCoords.xy).r;
			vertexWorldPosition.xyz += normal * (h * maxDisplacement + offset) * vertexDisplacement;
		}
	}

#endif

	normal = normalize(normal);

	//int face = max(skyTextureIndex.y, PassIndex);
	mat4 cameraProjectionMatrix = ExtractCameraProjectionMatrix(CameraID, PassIndex);//entityMatrix[CameraID + 3 + BufferSize.z + CurrentFace];
	//mat4 cameraProjectionMatrix = entityMatrix[CameraID + 3 + BufferSize.z];
	gl_Position = cameraProjectionMatrix * vertexWorldPosition;
	gl_Position.z = (gl_Position.z + gl_Position.w) / 2.0;
}