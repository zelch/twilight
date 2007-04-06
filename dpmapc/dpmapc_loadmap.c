
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "dpmapc.h"

bspdata_entity_t *dpmapc_loadmap(const char *filename)
{
	void *maptext;
	size_t maptextsize;
	int numentities = 0, numbrushes = 0, numpatches = 0, numfields = 0;
	bspdata_entity_t *entitylist = NULL;
	bspdata_entity_t *entity, **entitypointer;
	bspdata_brush_t *brush, **brushpointer;
	dpmapc_tokenstate_t tokenstate;
	char key[64];
	char value[4096];
	maptext = dpmapc_loadfile(filename, &maptextsize);
	if (!maptext)
	{
		dpmapc_warning("unable to load \"%s\"\n", filename);
		return NULL;
	}
	// parse maptext and create bspdata->entities data
	entitypointer = &entitylist;
	dpmapc_token_begin(&tokenstate, maptext, maptext + maptextsize);
	for (;;)
	{
		dpmapc_token_get(&tokenstate, true);
		if (tokenstate.tokentype == DPMAPC_TOKENTYPE_EOF)
			break;
		if (strcmp(tokenstate.token, "{"))
			dpmapc_error("dpmapc_compilemap: expected { (begin entity) at line %i\n", tokenstate.linenumber);
		entity = dpmapc_alloc(sizeof(bspdata_entity_t));
		*entitypointer = entity;
		entitypointer = &entity->next;
		brushpointer = &entity->brushlist;
		for (;;)
		{
			dpmapc_token_get(&tokenstate, true);
			if (tokenstate.tokentype == DPMAPC_TOKENTYPE_EOF)
				dpmapc_error("dpmapc_compilemap: unexpected EOF in entity at line %i\n", tokenstate.linenumber);
			if (tokenstate.tokentype == DPMAPC_TOKENTYPE_PARSEERROR)
				dpmapc_error("dpmapc_compilemap: parse error in entity at line %i\n", tokenstate.linenumber);
			if (!strcmp(tokenstate.token, "}"))
				break;
			if (!strcmp(tokenstate.token, "{"))
			{
				// brush or patch
				boolean nested = false;
				boolean warnedtoomanysides = false;
				dpmapc_brushtype_t brushtype = DPMAPC_BRUSHTYPE_BRUSHDEF;
				int brushnumsides = 0;
				bspdata_brushside_t brushsides[DPMAPC_BRUSH_MAXSIDES];
				for (;;)
				{
					dpmapc_token_get(&tokenstate, true);
					if (tokenstate.tokentype == DPMAPC_TOKENTYPE_EOF)
						dpmapc_error("dpmapc_compilemap: unexpected EOF in brush at line %i\n", tokenstate.linenumber);
					if (tokenstate.tokentype == DPMAPC_TOKENTYPE_PARSEERROR)
						dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
					if (!strcmp(tokenstate.token, "}"))
					{
						if (nested)
							nested = false;
						else
							break;
					}
					else if (!strcmp(tokenstate.token, "brushDef3"))
						brushtype = DPMAPC_BRUSHTYPE_BRUSHDEF3;
					else if (!strcmp(tokenstate.token, "patchDef2"))
						brushtype = DPMAPC_BRUSHTYPE_PATCHDEF2;
					else if (!strcmp(tokenstate.token, "patchDef3"))
						brushtype = DPMAPC_BRUSHTYPE_PATCHDEF3;
					else if (!strcmp(tokenstate.token, "{") && brushtype != DPMAPC_BRUSHTYPE_BRUSHDEF)
						nested = true;
					else if (!strcmp(tokenstate.token, "("))
					{
						if (brushtype == DPMAPC_BRUSHTYPE_BRUSHDEF || brushtype == DPMAPC_BRUSHTYPE_BRUSHDEF3)
						{
							int i, j;
							boolean q2brushface, q3brushface, brushprimitive, hltexdef;
							double planetriangle[3][3];
							double texrotate, texscale[2];
							double a, ac, as, bc, bs;
							double vecs[2][3];
							//int facecontents, faceflags, facevalue;
							//double bp[2][3], texvecs[2][3], brushside.plane.normal[3], brushside.plane.dist;
							//char texturename[64];
							bspdata_brushside_t brushside;
							brushside.linenumber = tokenstate.linenumber;
							// parse brush face
							dpmapc_token_get(&tokenstate, false);
							planetriangle[0][0] = atof(tokenstate.token);
							dpmapc_token_get(&tokenstate, false);
							planetriangle[0][1] = atof(tokenstate.token);
							dpmapc_token_get(&tokenstate, false);
							planetriangle[0][2] = atof(tokenstate.token);
							dpmapc_token_get(&tokenstate, false);
							if (!strcmp(tokenstate.token, ")"))
							{
								// Quake1/2/3 plane from triangle
								dpmapc_token_get(&tokenstate, false);
								if (strcmp(tokenstate.token, "("))
									dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
								dpmapc_token_get(&tokenstate, false);
								planetriangle[1][0] = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								planetriangle[1][1] = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								planetriangle[1][2] = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								if (strcmp(tokenstate.token, ")"))
									dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
								dpmapc_token_get(&tokenstate, false);
								if (strcmp(tokenstate.token, "("))
									dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
								dpmapc_token_get(&tokenstate, false);
								planetriangle[2][0] = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								planetriangle[2][1] = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								planetriangle[2][2] = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								if (strcmp(tokenstate.token, ")"))
									dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
								// convert planetriangle to a plane
								dpmapc_trianglenormal(planetriangle[0], planetriangle[1], planetriangle[2], brushside.plane.normal);
								dpmapc_vectornormalize(brushside.plane.normal);
								brushside.plane.dist = dpmapc_dotproduct(planetriangle[1], brushside.plane.normal);
							}
							else
							{
								// doom3 plane
								dpmapc_vectorcopy(planetriangle[0], brushside.plane.normal);
								brushside.plane.dist = -atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								if (strcmp(tokenstate.token, ")"))
									dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
							}
							// read the texturedef
							dpmapc_token_get(&tokenstate, false);
							if (!strcmp(tokenstate.token, "("))
							{
								// brush primitives, utterly insane
								// these are a 2x3 texcoord transform matrix to
								// apply AFTER the normal texcoord generation
								brushprimitive = true;
								dpmapc_token_get(&tokenstate, false);
								if (strcmp(tokenstate.token, "("))
									dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
								dpmapc_token_get(&tokenstate, false);
								brushside.bp[0][0] = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								brushside.bp[0][1] = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								brushside.bp[0][2] = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								if (strcmp(tokenstate.token, ")"))
									dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
								dpmapc_token_get(&tokenstate, false);
								if (strcmp(tokenstate.token, "("))
									dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
								dpmapc_token_get(&tokenstate, false);
								brushside.bp[1][0] = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								brushside.bp[1][1] = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								brushside.bp[1][2] = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								if (strcmp(tokenstate.token, ")"))
									dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
								dpmapc_token_get(&tokenstate, false);
								if (strcmp(tokenstate.token, ")"))
									dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
								dpmapc_token_get(&tokenstate, false);
								dpmapc_strlcpy(brushside.texturename, tokenstate.token, sizeof(brushside.texturename));
							}
							else
							{
								brushprimitive = false;
								dpmapc_strlcpy(brushside.texturename, tokenstate.token, sizeof(brushside.texturename));
								dpmapc_token_get(&tokenstate, false);
								if (!strcmp(tokenstate.token, "["))
								{
									// Hammer (HalfLife editor) texture axis vectors
									hltexdef = true;
									dpmapc_token_get(&tokenstate, false);
									brushside.texvecs[0][0] = atof(tokenstate.token);
									dpmapc_token_get(&tokenstate, false);
									brushside.texvecs[0][1] = atof(tokenstate.token);
									dpmapc_token_get(&tokenstate, false);
									brushside.texvecs[0][2] = atof(tokenstate.token);
									dpmapc_token_get(&tokenstate, false);
									brushside.texvecs[0][3] = atof(tokenstate.token);
									dpmapc_token_get(&tokenstate, false);
									if (strcmp(tokenstate.token, "]"))
										dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
									dpmapc_token_get(&tokenstate, false);
									if (strcmp(tokenstate.token, "["))
										dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
									dpmapc_token_get(&tokenstate, false);
									brushside.texvecs[1][0] = atof(tokenstate.token);
									dpmapc_token_get(&tokenstate, false);
									brushside.texvecs[1][1] = atof(tokenstate.token);
									dpmapc_token_get(&tokenstate, false);
									brushside.texvecs[1][2] = atof(tokenstate.token);
									dpmapc_token_get(&tokenstate, false);
									brushside.texvecs[1][3] = atof(tokenstate.token);
									dpmapc_token_get(&tokenstate, false);
									if (strcmp(tokenstate.token, "]"))
										dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
								}
								else
								{
									hltexdef = false;
									brushside.texvecs[0][3] = atof(tokenstate.token);
									dpmapc_token_get(&tokenstate, false);
									brushside.texvecs[1][3] = atof(tokenstate.token);
								}
								dpmapc_token_get(&tokenstate, false);
								texrotate = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								texscale[0] = atof(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								texscale[1] = atof(tokenstate.token);
							}
							brushside.surfacecontents = 0;
							brushside.surfaceflags = 0;
							brushside.surfacevalue = 0;
							q2brushface = false;
							q3brushface = false;
							dpmapc_token_get(&tokenstate, false);
							if (tokenstate.tokentype == DPMAPC_TOKENTYPE_NAME)
							{
								q2brushface = true;
								brushside.surfacecontents = atoi(tokenstate.token);
								dpmapc_token_get(&tokenstate, false);
								if (tokenstate.tokentype == DPMAPC_TOKENTYPE_NAME)
								{
									brushside.surfaceflags = atoi(tokenstate.token);
									dpmapc_token_get(&tokenstate, false);
									if (tokenstate.tokentype == DPMAPC_TOKENTYPE_NAME)
									{
										q2brushface = false;
										q3brushface = true;
										brushside.surfacevalue = atoi(tokenstate.token);
										// skip any trailing info (incase someone makes an even longer brushface format)
										do
											dpmapc_token_get(&tokenstate, false);
										while (tokenstate.tokentype == DPMAPC_TOKENTYPE_NAME || tokenstate.tokentype == DPMAPC_TOKENTYPE_STRING);
									}
								}
							}

							// parsed brush face
							texscale[0] = 1.0 / texscale[0];
							texscale[1] = 1.0 / texscale[1];
							if (brushprimitive)
							{
								// calculate proper texture vectors from GTKRadiant/Doom3 brushprimitives matrix
								a = -atan2(brushside.plane.normal[2], sqrt(brushside.plane.normal[0]*brushside.plane.normal[0]+brushside.plane.normal[1]*brushside.plane.normal[1]));
								ac = cos(a);
								as = sin(a);
								a = atan2(brushside.plane.normal[1], brushside.plane.normal[0]);
								bc = cos(a);
								bs = sin(a);
								vecs[0][0] = -bs;
								vecs[0][1] = bc;
								vecs[0][2] = 0;
								vecs[1][0] = -as*bc;
								vecs[1][1] = -as*bs;
								vecs[1][2] = -ac;
								brushside.texvecs[0][0] = brushside.bp[0][0] * vecs[0][0] + brushside.bp[0][1] * vecs[1][0];
								brushside.texvecs[0][1] = brushside.bp[0][0] * vecs[0][1] + brushside.bp[0][1] * vecs[1][1];
								brushside.texvecs[0][2] = brushside.bp[0][0] * vecs[0][2] + brushside.bp[0][1] * vecs[1][2];
								brushside.texvecs[0][3] = brushside.bp[0][0] * vecs[0][3] + brushside.bp[0][1] * vecs[1][3] + brushside.bp[0][2];
								brushside.texvecs[1][0] = brushside.bp[1][0] * vecs[0][0] + brushside.bp[1][1] * vecs[1][0];
								brushside.texvecs[1][1] = brushside.bp[1][0] * vecs[0][1] + brushside.bp[1][1] * vecs[1][1];
								brushside.texvecs[1][2] = brushside.bp[1][0] * vecs[0][2] + brushside.bp[1][1] * vecs[1][2];
								brushside.texvecs[1][3] = brushside.bp[1][0] * vecs[0][3] + brushside.bp[1][1] * vecs[1][3] + brushside.bp[1][2];
							}
							else if (hltexdef)
							{
								// HL texture vectors are almost ready to go
								for (i = 0; i < 2; i++)
									for (j = 0; j < 3; j++)
										brushside.texvecs[i][j] *= texscale[i];
							}
							else
							{
								// fake proper texture vectors from QuakeEd style

								// texture rotation around the plane normal
								a = texrotate * (M_PI / 180);
								ac = cos(a);
								as = sin(a);

								if (fabs(brushside.plane.normal[2]) < fabs(brushside.plane.normal[0]))
								{
									if (fabs(brushside.plane.normal[0]) < fabs(brushside.plane.normal[1]))
									{
										// Y primary
										dpmapc_vectorset4(brushside.texvecs[0],  0,  ac*texscale[0],  as*texscale[0], vecs[0][3]);
										dpmapc_vectorset4(brushside.texvecs[1],  0,  as*texscale[1], -ac*texscale[1], vecs[1][3]);
									}
									else
									{
										// X primary
										dpmapc_vectorset4(brushside.texvecs[0],  ac*texscale[0],  as*texscale[0],  0, vecs[0][3]);
										dpmapc_vectorset4(brushside.texvecs[1],  as*texscale[1], -ac*texscale[1],  0, vecs[1][3]);
									}
								}
								else if (fabs(brushside.plane.normal[2]) < fabs(brushside.plane.normal[1]))
								{
									// Y primary
									dpmapc_vectorset4(brushside.texvecs[0],  0,  ac*texscale[0],  as*texscale[0], vecs[0][3]);
									dpmapc_vectorset4(brushside.texvecs[1],  0,  as*texscale[1], -ac*texscale[1], vecs[1][3]);
								}
								else
								{
									// Z primary
									dpmapc_vectorset4(brushside.texvecs[0],  ac*texscale[0],  0,  as*texscale[0], vecs[0][3]);
									dpmapc_vectorset4(brushside.texvecs[1],  as*texscale[1],  0, -ac*texscale[1], vecs[1][3]);
								}
							}

							// we now have a fully fledged brush face, with these variables filled in:
							// brushside.plane.normal, brushside.plane.dist, brushside.texturename, brushside.texvecs, brushside.bp, brushside.surfacecontents, brushside.surfaceflags, brushside.surfacevalue
							//fprintf(stderr, "brushside: { %f %f %f %f } { { %f %f %f } { %f %f %f } } { { %f %f %f } { %f %f %f } } \"%s\" %i %i %i\n", brushside.plane.normal[0], brushside.plane.normal[1], brushside.plane.normal[2], brushside.plane.dist, brushside.texvecs[0][0], brushside.texvecs[0][1], brushside.texvecs[0][2], brushside.texvecs[1][0], brushside.texvecs[1][1], brushside.texvecs[1][2], brushside.bp[0][0], brushside.bp[0][1], brushside.bp[0][2], brushside.bp[1][0], brushside.bp[1][1], brushside.bp[1][2], brushside.texturename, brushside.surfacecontents, brushside.surfaceflags, brushside.surfacevalue);
							if (dpmapc_vectorlength2(brushside.plane.normal) < 0.1)
							{
								dpmapc_warning("brush plane with no normal at line %i\n", tokenstate.linenumber);
								continue;
							}
							for (i = 0;i < brushnumsides;i++)
								if (dpmapc_dotproduct(brushsides[i].plane.normal, brushside.plane.normal) >= DPMAPC_PLANECOMPAREEPSILON)
									break;
							if (i < brushnumsides)
								dpmapc_warning("dpmapc_compilemap: duplicate brush plane at line %i\n", tokenstate.linenumber);
							else if (i == DPMAPC_BRUSH_MAXSIDES)
							{
								if (!warnedtoomanysides)
								{
									warnedtoomanysides = true;
									dpmapc_warning("dpmapc_compilemap: brush with more than %i sides at line %i, ignoring extra sides\n", DPMAPC_BRUSH_MAXSIDES, tokenstate.linenumber);
								}
							}
							else
								brushsides[brushnumsides++] = brushside;
						}
						else
						{
							// TODO: parse patch
							dpmapc_error("dpmapc_compilemap: patch at line %i (patches not yet implemented)\n", tokenstate.linenumber);
						}
					}
					else
						dpmapc_error("dpmapc_compilemap: parse error in brush at line %i\n", tokenstate.linenumber);
				}
				if (brushtype == DPMAPC_BRUSHTYPE_BRUSHDEF || brushtype == DPMAPC_BRUSHTYPE_BRUSHDEF3)
				{
					//fprintf(stderr, "dpmapc_compilemap: brush with %i sides at line %i\n", brushnumsides, tokenstate.linenumber);
					brush = dpmapc_createbrush(brushnumsides, brushsides);
					*brushpointer = brush;
					brushpointer = &brush->next;
					numbrushes++;
				}
				else
				{
					// TODO: add patch
					numpatches++;
				}
				continue;
			}
			if (tokenstate.tokentype != DPMAPC_TOKENTYPE_STRING)
				dpmapc_error("dpmapc_compilemap: expected string in entity at line %i\n", tokenstate.linenumber);
			dpmapc_strlcpy(key, tokenstate.token, sizeof(key));
			dpmapc_token_get(&tokenstate, false);
			if (tokenstate.tokentype != DPMAPC_TOKENTYPE_STRING)
				dpmapc_error("dpmapc_compilemap: expected string in entity at line %i\n", tokenstate.linenumber);
			dpmapc_strlcpy(value, tokenstate.token, sizeof(value));
			// store the entity field
			dpmapc_entity_setvalue(entity, key, value);
			numfields++;
		}
		numentities++;
	}
	dpmapc_free(maptext);
	dpmapc_log("dpmapc_loadmap: loaded %i entities containing %i brushes, %i patches, %i fields\n", numentities, numbrushes, numpatches, numfields);
	if (strcmp(dpmapc_entity_getvalue(entitylist, "classname"), "worldspawn"))
		dpmapc_error("first entity should be worldspawn!\n");
	return entitylist;
}


