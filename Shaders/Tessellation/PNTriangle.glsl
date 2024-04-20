#ifndef _PNTRIANGLE
    #define _PNTRIANGLE

vec3 ProjectToPlane(vec3 Point, vec3 PlanePoint, vec3 PlaneNormal)
{
    vec3 v = Point - PlanePoint;
    float Len = dot(v, PlaneNormal);
    vec3 d = Len * PlaneNormal;
    return (Point - d);
}

//https://github.com/sayakbiswas/openGL-Tessellation/blob/master/PN_Triangles/shaders/Tessellation.te.glsl
vec3 PNTriangle(in vec3 pos0, in vec3 pos1, in vec3 pos2, in vec3 norm0, in vec3 norm1, in vec3 norm2, in vec3 tesscoord, in bool edge0, in bool edge1, in bool edge2)
{
    vec3 WorldPos_B030;
    vec3 WorldPos_B021;
    vec3 WorldPos_B012;
    vec3 WorldPos_B003;
    vec3 WorldPos_B102;
    vec3 WorldPos_B201;
    vec3 WorldPos_B300;
    vec3 WorldPos_B210;
    vec3 WorldPos_B120;
    vec3 WorldPos_B111;
    vec3 Normal[3];
   
	//http://ogldev.atspace.co.uk/www/tutorial31/tutorial31.html

    // The original vertices stay the same
    WorldPos_B030 = pos0;
    WorldPos_B003 = pos1;
    WorldPos_B300 = pos2;

	Normal[0] = (norm0);
	Normal[1] = (norm1);
	Normal[2] = (norm2);

    // Edges are names according to the opposing vertex
    vec3 EdgeB300 = WorldPos_B003 - WorldPos_B030;
    vec3 EdgeB030 = WorldPos_B300 - WorldPos_B003;
    vec3 EdgeB003 = WorldPos_B030 - WorldPos_B300;

    // Generate two midpoints on each edge
    WorldPos_B021 = WorldPos_B030 + EdgeB300 / 3.0;
    WorldPos_B012 = WorldPos_B030 + EdgeB300 * 2.0 / 3.0;
    WorldPos_B102 = WorldPos_B003 + EdgeB030 / 3.0;
    WorldPos_B201 = WorldPos_B003 + EdgeB030 * 2.0 / 3.0;
    WorldPos_B210 = WorldPos_B300 + EdgeB003 / 3.0;
    WorldPos_B120 = WorldPos_B300 + EdgeB003 * 2.0 / 3.0;

    // Project each midpoint on the plane defined by the nearest vertex and its normal
    if (edge2)
    {
        WorldPos_B021 = ProjectToPlane(WorldPos_B021, WorldPos_B030, Normal[0]);
        WorldPos_B012 = ProjectToPlane(WorldPos_B012, WorldPos_B003, Normal[1]);
    }
    if (edge0)
    {
        WorldPos_B102 = ProjectToPlane(WorldPos_B102, WorldPos_B003, Normal[1]);
        WorldPos_B201 = ProjectToPlane(WorldPos_B201, WorldPos_B300, Normal[2]);
    }
    if (edge1)
    {
        WorldPos_B210 = ProjectToPlane(WorldPos_B210, WorldPos_B300, Normal[2]);
        WorldPos_B120 = ProjectToPlane(WorldPos_B120, WorldPos_B030, Normal[0]);
    }

    // Handle the center
    vec3 Center = (WorldPos_B003 + WorldPos_B030 + WorldPos_B300) / 3.0;
    WorldPos_B111 = (WorldPos_B021 + WorldPos_B012 + WorldPos_B102 + WorldPos_B201 + WorldPos_B210 + WorldPos_B120) / 6.0;
    WorldPos_B111 += (WorldPos_B111 - Center) / 2.0;

	float u = tesscoord.x;
    float v = tesscoord.y;
    float w = tesscoord.z;

    float uPow3 = pow(u, 3);
    float vPow3 = pow(v, 3);
    float wPow3 = pow(w, 3);
    float uPow2 = pow(u, 2);
    float vPow2 = pow(v, 2);
    float wPow2 = pow(w, 2);

    return WorldPos_B300 * wPow3 +
		WorldPos_B030 * uPow3 +
		WorldPos_B003 * vPow3 +
		WorldPos_B210 * 3.0 * wPow2 * u +
		WorldPos_B120 * 3.0 * w * uPow2 +
		WorldPos_B201 * 3.0 * wPow2 * v +
		WorldPos_B021 * 3.0 * uPow2 * v +
		WorldPos_B102 * 3.0 * w * vPow2 +
		WorldPos_B012 * 3.0 * u * vPow2 +
		WorldPos_B111 * 6.0 * w * u * v;
}

//vec3 PNEdge(in vec3 p0, in vec3 p1, in vec3 n0, in vec3 n1, in vec2 tess)
//{
//	return PNTriangle(p0, p0, p1, n0, n0, n1, vec3(0.0f, tess.x, tess.y));
//}
#endif