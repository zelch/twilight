/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#include "quakedef.h"
#include "image.h"

static cvar_t r_mipskins = {CVAR_SAVE, "r_mipskins", "0"};

void Mod_AliasInit (void)
{
	Cvar_RegisterVariable(&r_mipskins);
}

// LordHavoc: proper bounding box considerations
static float aliasbboxmin[3], aliasbboxmax[3], modelyawradius, modelradius;

static float vertst[MAXALIASVERTS][2];
static int vertusage[MAXALIASVERTS];
static int vertonseam[MAXALIASVERTS];
static int vertremap[MAXALIASVERTS];
static int temptris[MAXALIASTRIS][3];

static void Mod_ConvertAliasVerts (int inverts, vec3_t scale, vec3_t translate, trivertx_t *v, aliasvertex_t *out)
{
	int i, j;
	float dist;
	vec3_t temp;
	for (i = 0;i < inverts;i++)
	{
		if (vertremap[i] < 0 && vertremap[i+inverts] < 0) // only used vertices need apply...
			continue;

		temp[0] = v[i].v[0] * scale[0] + translate[0];
		temp[1] = v[i].v[1] * scale[1] + translate[1];
		temp[2] = v[i].v[2] * scale[2] + translate[2];
		// update bounding box
		if (temp[0] < aliasbboxmin[0]) aliasbboxmin[0] = temp[0];
		if (temp[1] < aliasbboxmin[1]) aliasbboxmin[1] = temp[1];
		if (temp[2] < aliasbboxmin[2]) aliasbboxmin[2] = temp[2];
		if (temp[0] > aliasbboxmax[0]) aliasbboxmax[0] = temp[0];
		if (temp[1] > aliasbboxmax[1]) aliasbboxmax[1] = temp[1];
		if (temp[2] > aliasbboxmax[2]) aliasbboxmax[2] = temp[2];
		dist = temp[0]*temp[0]+temp[1]*temp[1];
		if (modelyawradius < dist)
			modelyawradius = dist;
		dist += temp[2]*temp[2];
		if (modelradius < dist)
			modelradius = dist;

		j = vertremap[i]; // not onseam
		if (j >= 0)
			VectorCopy(temp, out[j].origin);
		j = vertremap[i+inverts]; // onseam
		if (j >= 0)
			VectorCopy(temp, out[j].origin);
	}
}

static void Mod_BuildAliasVertexTextureVectors(int numtriangles, const int *elements, int numverts, aliasvertex_t *vertices, const float *texcoords, float *vertexbuffer, float *svectorsbuffer, float *tvectorsbuffer, float *normalsbuffer)
{
	int i;
	for (i = 0;i < numverts;i++)
		VectorCopy(vertices[i].origin, &vertexbuffer[i * 4]);
	Mod_BuildTextureVectorsAndNormals(numverts, numtriangles, vertexbuffer, texcoords, elements, svectorsbuffer, tvectorsbuffer, normalsbuffer);
	for (i = 0;i < numverts;i++)
	{
		// LordHavoc: alias models are backwards, apparently
		vertices[i].normal[0] = normalsbuffer[i * 4 + 0];
		vertices[i].normal[1] = normalsbuffer[i * 4 + 1];
		vertices[i].normal[2] = normalsbuffer[i * 4 + 2];
		vertices[i].svector[0] = svectorsbuffer[i * 4 + 0];
		vertices[i].svector[1] = svectorsbuffer[i * 4 + 1];
		vertices[i].svector[2] = svectorsbuffer[i * 4 + 2];
	}
}

static void Mod_MDL_LoadFrames (qbyte* datapointer, int inverts, vec3_t scale, vec3_t translate)
{
	daliasframetype_t	*pframetype;
	daliasframe_t		*pinframe;
	daliasgroup_t		*group;
	daliasinterval_t	*intervals;
	int					i, f, pose, groupframes;
	float				interval;
	animscene_t			*scene;
	float				*vertexbuffer, *svectorsbuffer, *tvectorsbuffer, *normalsbuffer;
	pose = 0;
	scene = loadmodel->animscenes;
	vertexbuffer = Mem_Alloc(tempmempool, loadmodel->numverts * sizeof(float[4]) * 4);
	svectorsbuffer = vertexbuffer + loadmodel->numverts * 4;
	tvectorsbuffer = svectorsbuffer + loadmodel->numverts * 4;
	normalsbuffer = tvectorsbuffer + loadmodel->numverts * 4;
	for (f = 0;f < loadmodel->numframes;f++)
	{
		pframetype = (daliasframetype_t *)datapointer;
		datapointer += sizeof(daliasframetype_t);
		if (LittleLong (pframetype->type) == ALIAS_SINGLE)
		{
			// a single frame is still treated as a group
			interval = 0.1f;
			groupframes = 1;
		}
		else
		{
			// read group header
			group = (daliasgroup_t *)datapointer;
			datapointer += sizeof(daliasgroup_t);
			groupframes = LittleLong (group->numframes);

			// intervals (time per frame)
			intervals = (daliasinterval_t *)datapointer;
			datapointer += sizeof(daliasinterval_t) * groupframes;

			interval = LittleFloat (intervals->interval); // FIXME: support variable framerate groups
			if (interval < 0.01f)
				Host_Error("Mod_LoadAliasGroup: invalid interval");
		}

		// get scene name from first frame
		pinframe = (daliasframe_t *)datapointer;

		strcpy(scene->name, pinframe->name);
		scene->firstframe = pose;
		scene->framecount = groupframes;
		scene->framerate = 1.0f / interval;
		scene->loop = true;
		scene++;

		// read frames
		for (i = 0;i < groupframes;i++)
		{
			pinframe = (daliasframe_t *)datapointer;
			datapointer += sizeof(daliasframe_t);
			Mod_ConvertAliasVerts(inverts, scale, translate, (trivertx_t *)datapointer, loadmodel->mdlmd2data_pose + pose * loadmodel->numverts);
			Mod_BuildAliasVertexTextureVectors(loadmodel->numtris, loadmodel->mdlmd2data_indices, loadmodel->numverts, loadmodel->mdlmd2data_pose + pose * loadmodel->numverts, loadmodel->mdlmd2data_texcoords, vertexbuffer, svectorsbuffer, tvectorsbuffer, normalsbuffer);
			datapointer += sizeof(trivertx_t) * inverts;
			pose++;
		}
	}
	Mem_Free(vertexbuffer);
}

static rtexture_t *GL_TextureForSkinLayer(const qbyte *in, int width, int height, const char *name, const unsigned int *palette, int precache)
{
	int i;
	for (i = 0;i < width*height;i++)
		if (((qbyte *)&palette[in[i]])[3] > 0)
			return R_LoadTexture2D (loadmodel->texturepool, name, width, height, in, TEXTYPE_PALETTE, (r_mipskins.integer ? TEXF_MIPMAP : 0) | (precache ? TEXF_PRECACHE : 0), palette);
	return NULL;
}

static int Mod_LoadExternalSkin (char *basename, skinframe_t *skinframe, int precache)
{
	skinframe->base   = loadtextureimagewithmaskandnmap(loadmodel->texturepool, va("%s_normal", basename), 0, 0, false, TEXF_ALPHA | (precache ? TEXF_PRECACHE : 0) | (r_mipskins.integer ? TEXF_MIPMAP : 0), 1);
	if (!skinframe->base)
		skinframe->base   = loadtextureimagewithmaskandnmap(loadmodel->texturepool, basename, 0, 0, false, TEXF_ALPHA | (precache ? TEXF_PRECACHE : 0) | (r_mipskins.integer ? TEXF_MIPMAP : 0), 1);
	skinframe->fog    = image_masktex;
	skinframe->nmap   = image_nmaptex;
	skinframe->gloss  = loadtextureimage(loadmodel->texturepool, va("%s_gloss" , basename), 0, 0, false, TEXF_ALPHA | (precache ? TEXF_PRECACHE : 0) | (r_mipskins.integer ? TEXF_MIPMAP : 0));
	skinframe->pants  = loadtextureimage(loadmodel->texturepool, va("%s_pants" , basename), 0, 0, false, TEXF_ALPHA | (precache ? TEXF_PRECACHE : 0) | (r_mipskins.integer ? TEXF_MIPMAP : 0));
	skinframe->shirt  = loadtextureimage(loadmodel->texturepool, va("%s_shirt" , basename), 0, 0, false, TEXF_ALPHA | (precache ? TEXF_PRECACHE : 0) | (r_mipskins.integer ? TEXF_MIPMAP : 0));
	skinframe->glow   = loadtextureimage(loadmodel->texturepool, va("%s_glow"  , basename), 0, 0, false, TEXF_ALPHA | (precache ? TEXF_PRECACHE : 0) | (r_mipskins.integer ? TEXF_MIPMAP : 0));
	skinframe->merged = NULL;
	return skinframe->base != NULL || skinframe->pants != NULL || skinframe->shirt != NULL || skinframe->glow != NULL;
}

static int Mod_LoadInternalSkin (char *basename, qbyte *skindata, int width, int height, skinframe_t *skinframe, int precache)
{
	qbyte *temp1, *temp2;
	if (!skindata)
		return false;
	temp1 = Mem_Alloc(loadmodel->mempool, width * height * 8);
	temp2 = temp1 + width * height * 4;
	Image_Copy8bitRGBA(skindata, temp1, width * height, palette_nofullbrights);
	Image_HeightmapToNormalmap(temp1, temp2, width, height, false, 1);
	skinframe->nmap   = R_LoadTexture2D(loadmodel->texturepool, va("%s_nmap", basename), width, height, temp2, TEXTYPE_RGBA, (r_mipskins.integer ? TEXF_MIPMAP : 0) | (precache ? TEXF_PRECACHE : 0), NULL);
	Mem_Free(temp1);
	skinframe->gloss  = NULL;
	skinframe->pants  = GL_TextureForSkinLayer(skindata, width, height, va("%s_pants", basename), palette_pantsaswhite, false); // pants
	skinframe->shirt  = GL_TextureForSkinLayer(skindata, width, height, va("%s_shirt", basename), palette_shirtaswhite, false); // shirt
	skinframe->glow   = GL_TextureForSkinLayer(skindata, width, height, va("%s_glow", basename), palette_onlyfullbrights, precache); // glow
	if (skinframe->pants || skinframe->shirt)
	{
		skinframe->base   = GL_TextureForSkinLayer(skindata, width, height, va("%s_normal", basename), palette_nocolormapnofullbrights, false); // normal (no special colors)
		skinframe->merged = GL_TextureForSkinLayer(skindata, width, height, va("%s_body", basename), palette_nofullbrights, precache); // body (normal + pants + shirt, but not glow)
	}
	else
		skinframe->base   = GL_TextureForSkinLayer(skindata, width, height, va("%s_base", basename), palette_nofullbrights, precache); // no special colors
	// quake model skins don't have alpha
	skinframe->fog = NULL;
	return true;
}

void Mod_BuildMDLMD2MeshInfo(void)
{
	int i;
	aliasmesh_t *mesh;
	aliasskin_t *skin;
	aliaslayer_t *layer;
	skinframe_t *skinframe;

	loadmodel->mdlmd2data_triangleneighbors = Mem_Alloc(loadmodel->mempool, loadmodel->numtris * sizeof(int[3]));
	Mod_ValidateElements(loadmodel->mdlmd2data_indices, loadmodel->numtris, loadmodel->numverts, __FILE__, __LINE__);
	Mod_BuildTriangleNeighbors(loadmodel->mdlmd2data_triangleneighbors, loadmodel->mdlmd2data_indices, loadmodel->numtris);

	loadmodel->mdlmd2num_meshes = 1;
	mesh = loadmodel->mdlmd2data_meshes = Mem_Alloc(loadmodel->mempool, loadmodel->mdlmd2num_meshes * sizeof(aliasmesh_t));
	mesh->num_skins = 0;
	mesh->num_frames = 0;
	for (i = 0;i < loadmodel->numframes;i++)
		mesh->num_frames += loadmodel->animscenes[i].framecount;
	for (i = 0;i < loadmodel->numskins;i++)
		mesh->num_skins += loadmodel->skinscenes[i].framecount;
	mesh->num_triangles = loadmodel->numtris;
	mesh->num_vertices = loadmodel->numverts;
	mesh->data_skins = Mem_Alloc(loadmodel->mempool, mesh->num_skins * sizeof(aliasskin_t));
	mesh->data_elements = loadmodel->mdlmd2data_indices;
	mesh->data_neighbors = loadmodel->mdlmd2data_triangleneighbors;
	mesh->data_texcoords = loadmodel->mdlmd2data_texcoords;
	mesh->data_vertices = loadmodel->mdlmd2data_pose;
	for (i = 0, skin = mesh->data_skins, skinframe = loadmodel->skinframes;i < mesh->num_skins;i++, skin++, skinframe++)
	{
		skin->flags = 0;
		// fog texture only exists if some pixels are transparent...
		if (skinframe->fog != NULL)
			skin->flags |= ALIASSKIN_TRANSPARENT;
		// fog and gloss layers always exist
		skin->num_layers = 2;
		if (skinframe->glow != NULL)
			skin->num_layers++;
		if (skinframe->merged != NULL)
			skin->num_layers += 2;
		if (skinframe->base != NULL)
			skin->num_layers += 2;
		if (skinframe->pants != NULL)
			skin->num_layers += 2;
		if (skinframe->shirt != NULL)
			skin->num_layers += 2;
		layer = skin->data_layers = Mem_Alloc(loadmodel->mempool, skin->num_layers * sizeof(aliaslayer_t));
		if (skinframe->glow != NULL)
		{
			layer->flags = 0;
			layer->texture = skinframe->glow;
			layer++;
		}
		if (skinframe->merged != NULL)
		{
			layer->flags = ALIASLAYER_NODRAW_IF_COLORMAPPED | ALIASLAYER_DIFFUSE;
			if (skinframe->glow != NULL)
				layer->flags |= ALIASLAYER_ADD;
			layer->texture = skinframe->merged;
			layer->nmap = skinframe->nmap;
			layer++;
		}
		if (skinframe->base != NULL)
		{
			layer->flags = ALIASLAYER_NODRAW_IF_NOTCOLORMAPPED | ALIASLAYER_DIFFUSE;
			if (skinframe->glow != NULL)
				layer->flags |= ALIASLAYER_ADD;
			layer->texture = skinframe->base;
			layer->nmap = skinframe->nmap;
			layer++;
		}
		if (skinframe->pants != NULL)
		{
			layer->flags = ALIASLAYER_NODRAW_IF_NOTCOLORMAPPED | ALIASLAYER_DIFFUSE | ALIASLAYER_COLORMAP_SHIRT;
			if (skinframe->glow != NULL || skinframe->base != NULL)
				layer->flags |= ALIASLAYER_ADD;
			layer->texture = skinframe->pants;
			layer->nmap = skinframe->nmap;
			layer++;
		}
		if (skinframe->shirt != NULL)
		{
			layer->flags = ALIASLAYER_NODRAW_IF_NOTCOLORMAPPED | ALIASLAYER_DIFFUSE | ALIASLAYER_COLORMAP_SHIRT;
			if (skinframe->glow != NULL || skinframe->base != NULL || skinframe->pants != NULL)
				layer->flags |= ALIASLAYER_ADD;
			layer->texture = skinframe->shirt;
			layer->nmap = skinframe->nmap;
			layer++;
		}
		layer->flags = ALIASLAYER_FOG;
		layer->texture = skinframe->fog;
		layer++;
		layer->flags = ALIASLAYER_DRAW_PER_LIGHT | ALIASLAYER_SPECULAR;
		layer->texture = skinframe->gloss;
		layer->nmap = skinframe->nmap;
		layer++;
		if (skinframe->merged != NULL)
		{
			layer->flags = ALIASLAYER_DRAW_PER_LIGHT | ALIASLAYER_NODRAW_IF_COLORMAPPED | ALIASLAYER_DIFFUSE;
			layer->texture = skinframe->merged;
			layer->nmap = skinframe->nmap;
			layer++;
		}
		if (skinframe->base != NULL)
		{
			layer->flags = ALIASLAYER_DRAW_PER_LIGHT | ALIASLAYER_NODRAW_IF_NOTCOLORMAPPED | ALIASLAYER_DIFFUSE;
			layer->texture = skinframe->base;
			layer->nmap = skinframe->nmap;
			layer++;
		}
		if (skinframe->pants != NULL)
		{
			layer->flags = ALIASLAYER_DRAW_PER_LIGHT | ALIASLAYER_NODRAW_IF_NOTCOLORMAPPED | ALIASLAYER_DIFFUSE | ALIASLAYER_COLORMAP_PANTS;
			layer->texture = skinframe->pants;
			layer->nmap = skinframe->nmap;
			layer++;
		}
		if (skinframe->shirt != NULL)
		{
			layer->flags = ALIASLAYER_DRAW_PER_LIGHT | ALIASLAYER_NODRAW_IF_NOTCOLORMAPPED | ALIASLAYER_DIFFUSE | ALIASLAYER_COLORMAP_SHIRT;
			layer->texture = skinframe->shirt;
			layer->nmap = skinframe->nmap;
			layer++;
		}
	}
}

#define BOUNDI(VALUE,MIN,MAX) if (VALUE < MIN || VALUE >= MAX) Host_Error("model %s has an invalid ##VALUE (%d exceeds %d - %d)\n", loadmodel->name, VALUE, MIN, MAX);
#define BOUNDF(VALUE,MIN,MAX) if (VALUE < MIN || VALUE >= MAX) Host_Error("model %s has an invalid ##VALUE (%f exceeds %f - %f)\n", loadmodel->name, VALUE, MIN, MAX);
extern void R_Model_Alias_Draw(entity_render_t *ent);
extern void R_Model_Alias_DrawFakeShadow(entity_render_t *ent);
extern void R_Model_Alias_DrawShadowVolume(entity_render_t *ent, vec3_t relativelightorigin, float lightradius);
extern void R_Model_Alias_DrawLight(entity_render_t *ent, vec3_t relativelightorigin, vec3_t relativeeyeorigin, float lightradius, float *lightcolor);
void Mod_LoadAliasModel (model_t *mod, void *buffer)
{
	int						i, j, version, numverts, totalposes, totalskins, skinwidth, skinheight, totalverts, groupframes, groupskins;
	mdl_t					*pinmodel;
	stvert_t				*pinstverts;
	dtriangle_t				*pintriangles;
	daliasskintype_t		*pinskintype;
	daliasskingroup_t		*pinskingroup;
	daliasskininterval_t	*pinskinintervals;
	daliasframetype_t		*pinframetype;
	daliasgroup_t			*pinframegroup;
	float					scales, scalet, scale[3], translate[3], interval;
	qbyte					*datapointer, *startframes, *startskins;
	char					name[MAX_QPATH];
	skinframe_t				tempskinframe;
	animscene_t				*tempskinscenes;
	skinframe_t				*tempskinframes;
	modelyawradius = 0;
	modelradius = 0;

	datapointer = buffer;
	pinmodel = (mdl_t *)datapointer;
	datapointer += sizeof(mdl_t);

	version = LittleLong (pinmodel->version);
	if (version != ALIAS_VERSION)
		Host_Error ("%s has wrong version number (%i should be %i)",
				 loadmodel->name, version, ALIAS_VERSION);

	loadmodel->type = mod_alias;
	loadmodel->aliastype = ALIASTYPE_MDLMD2;
	loadmodel->DrawSky = NULL;
	loadmodel->Draw = R_Model_Alias_Draw;
	loadmodel->DrawFakeShadow = R_Model_Alias_DrawFakeShadow;
	loadmodel->DrawShadowVolume = R_Model_Alias_DrawShadowVolume;
	loadmodel->DrawLight = R_Model_Alias_DrawLight;

	loadmodel->numskins = LittleLong(pinmodel->numskins);
	BOUNDI(loadmodel->numskins,0,256);
	skinwidth = LittleLong (pinmodel->skinwidth);
	BOUNDI(skinwidth,0,4096);
	skinheight = LittleLong (pinmodel->skinheight);
	BOUNDI(skinheight,0,4096);
	loadmodel->numverts = numverts = LittleLong(pinmodel->numverts);
	BOUNDI(loadmodel->numverts,0,MAXALIASVERTS);
	loadmodel->numtris = LittleLong(pinmodel->numtris);
	BOUNDI(loadmodel->numtris,0,MAXALIASTRIS);
	loadmodel->numframes = LittleLong(pinmodel->numframes);
	BOUNDI(loadmodel->numframes,0,65536);
	loadmodel->synctype = LittleLong (pinmodel->synctype);
	BOUNDI(loadmodel->synctype,0,2);
	loadmodel->flags = LittleLong (pinmodel->flags);

	for (i = 0;i < 3;i++)
	{
		scale[i] = LittleFloat (pinmodel->scale[i]);
		translate[i] = LittleFloat (pinmodel->scale_origin[i]);
	}

	startskins = datapointer;
	totalskins = 0;
	for (i = 0;i < loadmodel->numskins;i++)
	{
		pinskintype = (daliasskintype_t *)datapointer;
		datapointer += sizeof(daliasskintype_t);
		if (LittleLong(pinskintype->type) == ALIAS_SKIN_SINGLE)
			groupskins = 1;
		else
		{
			pinskingroup = (daliasskingroup_t *)datapointer;
			datapointer += sizeof(daliasskingroup_t);
			groupskins = LittleLong(pinskingroup->numskins);
			datapointer += sizeof(daliasskininterval_t) * groupskins;
		}

		for (j = 0;j < groupskins;j++)
		{
			datapointer += skinwidth * skinheight;
			totalskins++;
		}
	}

	pinstverts = (stvert_t *)datapointer;
	datapointer += sizeof(stvert_t) * numverts;

	pintriangles = (dtriangle_t *)datapointer;
	datapointer += sizeof(dtriangle_t) * loadmodel->numtris;

	startframes = datapointer;
	totalposes = 0;
	for (i = 0;i < loadmodel->numframes;i++)
	{
		pinframetype = (daliasframetype_t *)datapointer;
		datapointer += sizeof(daliasframetype_t);
		if (LittleLong (pinframetype->type) == ALIAS_SINGLE)
			groupframes = 1;
		else
		{
			pinframegroup = (daliasgroup_t *)datapointer;
			datapointer += sizeof(daliasgroup_t);
			groupframes = LittleLong(pinframegroup->numframes);
			datapointer += sizeof(daliasinterval_t) * groupframes;
		}

		for (j = 0;j < groupframes;j++)
		{
			datapointer += sizeof(daliasframe_t);
			datapointer += sizeof(trivertx_t) * numverts;
			totalposes++;
		}
	}

	// load the skins
	loadmodel->skinscenes = Mem_Alloc(loadmodel->mempool, loadmodel->numskins * sizeof(animscene_t));
	loadmodel->skinframes = Mem_Alloc(loadmodel->mempool, totalskins * sizeof(skinframe_t));
	totalskins = 0;
	datapointer = startskins;
	for (i = 0;i < loadmodel->numskins;i++)
	{
		pinskintype = (daliasskintype_t *)datapointer;
		datapointer += sizeof(daliasskintype_t);

		if (pinskintype->type == ALIAS_SKIN_SINGLE)
		{
			groupskins = 1;
			interval = 0.1f;
		}
		else
		{
			pinskingroup = (daliasskingroup_t *)datapointer;
			datapointer += sizeof(daliasskingroup_t);

			groupskins = LittleLong (pinskingroup->numskins);

			pinskinintervals = (daliasskininterval_t *)datapointer;
			datapointer += sizeof(daliasskininterval_t) * groupskins;

			interval = LittleFloat(pinskinintervals[0].interval);
			if (interval < 0.01f)
				Host_Error("Mod_LoadAliasModel: invalid interval\n");
		}

		sprintf(loadmodel->skinscenes[i].name, "skin %i", i);
		loadmodel->skinscenes[i].firstframe = totalskins;
		loadmodel->skinscenes[i].framecount = groupskins;
		loadmodel->skinscenes[i].framerate = 1.0f / interval;
		loadmodel->skinscenes[i].loop = true;

		for (j = 0;j < groupskins;j++)
		{
			if (groupskins > 1)
				sprintf (name, "%s_%i_%i", loadmodel->name, i, j);
			else
				sprintf (name, "%s_%i", loadmodel->name, i);
			if (!Mod_LoadExternalSkin(name, loadmodel->skinframes + totalskins, i == 0))
				Mod_LoadInternalSkin(name, (qbyte *)datapointer, skinwidth, skinheight, loadmodel->skinframes + totalskins, i == 0);
			datapointer += skinwidth * skinheight;
			totalskins++;
		}
	}
	// check for skins that don't exist in the model, but do exist as external images
	// (this was added because yummyluv kept pestering me about support for it)
	for (;;)
	{
		sprintf (name, "%s_%i", loadmodel->name, loadmodel->numskins);
		if (Mod_LoadExternalSkin(name, &tempskinframe, loadmodel->numskins == 0))
		{
			// expand the arrays to make room
			tempskinscenes = loadmodel->skinscenes;
			tempskinframes = loadmodel->skinframes;
			loadmodel->skinscenes = Mem_Alloc(loadmodel->mempool, (loadmodel->numskins + 1) * sizeof(animscene_t));
			loadmodel->skinframes = Mem_Alloc(loadmodel->mempool, (totalskins + 1) * sizeof(skinframe_t));
			memcpy(loadmodel->skinscenes, tempskinscenes, loadmodel->numskins * sizeof(animscene_t));
			memcpy(loadmodel->skinframes, tempskinframes, totalskins * sizeof(skinframe_t));
			Mem_Free(tempskinscenes);
			Mem_Free(tempskinframes);
			// store the info about the new skin
			strcpy(loadmodel->skinscenes[loadmodel->numskins].name, name);
			loadmodel->skinscenes[loadmodel->numskins].firstframe = totalskins;
			loadmodel->skinscenes[loadmodel->numskins].framecount = 1;
			loadmodel->skinscenes[loadmodel->numskins].framerate = 10.0f;
			loadmodel->skinscenes[loadmodel->numskins].loop = true;
			loadmodel->skinframes[totalskins] = tempskinframe;
			loadmodel->numskins++;
			totalskins++;
		}
		else
			break;
	}

	// store texture coordinates into temporary array, they will be stored after usage is determined (triangle data)
	scales = 1.0 / skinwidth;
	scalet = 1.0 / skinheight;
	for (i = 0;i < numverts;i++)
	{
		vertonseam[i] = LittleLong(pinstverts[i].onseam);
		vertst[i][0] = (LittleLong(pinstverts[i].s) + 0.5) * scales;
		vertst[i][1] = (LittleLong(pinstverts[i].t) + 0.5) * scalet;
		vertst[i+numverts][0] = vertst[i][0] + 0.5;
		vertst[i+numverts][1] = vertst[i][1];
		vertusage[i] = 0;
		vertusage[i+numverts] = 0;
	}

// load triangle data
	loadmodel->mdlmd2data_indices = Mem_Alloc(loadmodel->mempool, sizeof(int[3]) * loadmodel->numtris);

	// count the vertices used
	for (i = 0;i < numverts*2;i++)
		vertusage[i] = 0;
	for (i = 0;i < loadmodel->numtris;i++)
	{
		temptris[i][0] = LittleLong(pintriangles[i].vertindex[0]);
		temptris[i][1] = LittleLong(pintriangles[i].vertindex[1]);
		temptris[i][2] = LittleLong(pintriangles[i].vertindex[2]);
		if (!LittleLong(pintriangles[i].facesfront)) // backface
		{
			if (vertonseam[temptris[i][0]]) temptris[i][0] += numverts;
			if (vertonseam[temptris[i][1]]) temptris[i][1] += numverts;
			if (vertonseam[temptris[i][2]]) temptris[i][2] += numverts;
		}
		vertusage[temptris[i][0]]++;
		vertusage[temptris[i][1]]++;
		vertusage[temptris[i][2]]++;
	}
	// build remapping table and compact array
	totalverts = 0;
	for (i = 0;i < numverts*2;i++)
	{
		if (vertusage[i])
		{
			vertremap[i] = totalverts;
			vertst[totalverts][0] = vertst[i][0];
			vertst[totalverts][1] = vertst[i][1];
			totalverts++;
		}
		else
			vertremap[i] = -1; // not used at all
	}
	loadmodel->numverts = totalverts;
	// remap the triangle references
	for (i = 0;i < loadmodel->numtris;i++)
	{
		loadmodel->mdlmd2data_indices[i*3+0] = vertremap[temptris[i][0]];
		loadmodel->mdlmd2data_indices[i*3+1] = vertremap[temptris[i][1]];
		loadmodel->mdlmd2data_indices[i*3+2] = vertremap[temptris[i][2]];
	}
	// store the texture coordinates
	loadmodel->mdlmd2data_texcoords = Mem_Alloc(loadmodel->mempool, sizeof(float[4]) * totalverts);
	for (i = 0;i < totalverts;i++)
	{
		loadmodel->mdlmd2data_texcoords[i*4+0] = vertst[i][0];
		loadmodel->mdlmd2data_texcoords[i*4+1] = vertst[i][1];
	}

// load the frames
	loadmodel->animscenes = Mem_Alloc(loadmodel->mempool, sizeof(animscene_t) * loadmodel->numframes);
	loadmodel->mdlmd2data_pose = Mem_Alloc(loadmodel->mempool, sizeof(aliasvertex_t) * totalposes * totalverts);

	// LordHavoc: doing proper bbox for model
	aliasbboxmin[0] = aliasbboxmin[1] = aliasbboxmin[2] = 1000000000;
	aliasbboxmax[0] = aliasbboxmax[1] = aliasbboxmax[2] = -1000000000;

	Mod_MDL_LoadFrames (startframes, numverts, scale, translate);

	modelyawradius = sqrt(modelyawradius);
	modelradius = sqrt(modelradius);
	for (j = 0;j < 3;j++)
	{
		loadmodel->normalmins[j] = aliasbboxmin[j];
		loadmodel->normalmaxs[j] = aliasbboxmax[j];
		loadmodel->rotatedmins[j] = -modelradius;
		loadmodel->rotatedmaxs[j] = modelradius;
	}
	loadmodel->yawmins[0] = loadmodel->yawmins[1] = -(loadmodel->yawmaxs[0] = loadmodel->yawmaxs[1] = modelyawradius);
	loadmodel->yawmins[2] = loadmodel->normalmins[2];
	loadmodel->yawmaxs[2] = loadmodel->normalmaxs[2];
	loadmodel->radius = modelradius;
	loadmodel->radius2 = modelradius * modelradius;

	Mod_BuildMDLMD2MeshInfo();
}

static void Mod_MD2_ConvertVerts (vec3_t scale, vec3_t translate, trivertx_t *v, aliasvertex_t *out, int *vertremap)
{
	int i;
	float dist;
	trivertx_t *in;
	vec3_t temp;
	for (i = 0;i < loadmodel->numverts;i++)
	{
		in = v + vertremap[i];
		temp[0] = in->v[0] * scale[0] + translate[0];
		temp[1] = in->v[1] * scale[1] + translate[1];
		temp[2] = in->v[2] * scale[2] + translate[2];
		// update bounding box
		if (temp[0] < aliasbboxmin[0]) aliasbboxmin[0] = temp[0];
		if (temp[1] < aliasbboxmin[1]) aliasbboxmin[1] = temp[1];
		if (temp[2] < aliasbboxmin[2]) aliasbboxmin[2] = temp[2];
		if (temp[0] > aliasbboxmax[0]) aliasbboxmax[0] = temp[0];
		if (temp[1] > aliasbboxmax[1]) aliasbboxmax[1] = temp[1];
		if (temp[2] > aliasbboxmax[2]) aliasbboxmax[2] = temp[2];
		dist = temp[0]*temp[0]+temp[1]*temp[1];
		if (modelyawradius < dist)
			modelyawradius = dist;
		dist += temp[2]*temp[2];
		if (modelradius < dist)
			modelradius = dist;
		VectorCopy(temp, out[i].origin);
	}
}

void Mod_LoadQ2AliasModel (model_t *mod, void *buffer)
{
	int *vertremap;
	md2_t *pinmodel;
	qbyte *base;
	int version, end;
	int i, j, k, hashindex, num, numxyz, numst, xyz, st;
	float *stverts, s, t, scale[3], translate[3];
	struct md2verthash_s
	{
		struct md2verthash_s *next;
		int xyz;
		float st[2];
	}
	*hash, **md2verthash, *md2verthashdata;
	qbyte *datapointer;
	md2frame_t *pinframe;
	char *inskin;
	md2triangle_t *intri;
	unsigned short *inst;
	int skinwidth, skinheight;
	float *vertexbuffer, *svectorsbuffer, *tvectorsbuffer, *normalsbuffer;

	pinmodel = buffer;
	base = buffer;

	version = LittleLong (pinmodel->version);
	if (version != MD2ALIAS_VERSION)
		Host_Error ("%s has wrong version number (%i should be %i)",
			loadmodel->name, version, MD2ALIAS_VERSION);

	loadmodel->type = mod_alias;
	loadmodel->aliastype = ALIASTYPE_MDLMD2;
	loadmodel->DrawSky = NULL;
	loadmodel->Draw = R_Model_Alias_Draw;
	loadmodel->DrawFakeShadow = R_Model_Alias_DrawFakeShadow;
	loadmodel->DrawShadowVolume = R_Model_Alias_DrawShadowVolume;
	loadmodel->DrawLight = R_Model_Alias_DrawLight;

	if (LittleLong(pinmodel->num_tris < 1) || LittleLong(pinmodel->num_tris) > MD2MAX_TRIANGLES)
		Host_Error ("%s has invalid number of triangles: %i", loadmodel->name, LittleLong(pinmodel->num_tris));
	if (LittleLong(pinmodel->num_xyz < 1) || LittleLong(pinmodel->num_xyz) > MD2MAX_VERTS)
		Host_Error ("%s has invalid number of vertices: %i", loadmodel->name, LittleLong(pinmodel->num_xyz));
	if (LittleLong(pinmodel->num_frames < 1) || LittleLong(pinmodel->num_frames) > MD2MAX_FRAMES)
		Host_Error ("%s has invalid number of frames: %i", loadmodel->name, LittleLong(pinmodel->num_frames));
	if (LittleLong(pinmodel->num_skins < 0) || LittleLong(pinmodel->num_skins) > MAX_SKINS)
		Host_Error ("%s has invalid number of skins: %i", loadmodel->name, LittleLong(pinmodel->num_skins));

	end = LittleLong(pinmodel->ofs_end);
	if (LittleLong(pinmodel->num_skins) >= 1 && (LittleLong(pinmodel->ofs_skins <= 0) || LittleLong(pinmodel->ofs_skins) >= end))
		Host_Error ("%s is not a valid model", loadmodel->name);
	if (LittleLong(pinmodel->ofs_st <= 0) || LittleLong(pinmodel->ofs_st) >= end)
		Host_Error ("%s is not a valid model", loadmodel->name);
	if (LittleLong(pinmodel->ofs_tris <= 0) || LittleLong(pinmodel->ofs_tris) >= end)
		Host_Error ("%s is not a valid model", loadmodel->name);
	if (LittleLong(pinmodel->ofs_frames <= 0) || LittleLong(pinmodel->ofs_frames) >= end)
		Host_Error ("%s is not a valid model", loadmodel->name);
	if (LittleLong(pinmodel->ofs_glcmds <= 0) || LittleLong(pinmodel->ofs_glcmds) >= end)
		Host_Error ("%s is not a valid model", loadmodel->name);

	loadmodel->numskins = LittleLong(pinmodel->num_skins);
	numxyz = LittleLong(pinmodel->num_xyz);
	numst = LittleLong(pinmodel->num_st);
	loadmodel->numtris = LittleLong(pinmodel->num_tris);
	loadmodel->numframes = LittleLong(pinmodel->num_frames);

	loadmodel->flags = 0; // there are no MD2 flags
	loadmodel->synctype = ST_RAND;

	// load the skins
	inskin = (void*)(base + LittleLong(pinmodel->ofs_skins));
	if (loadmodel->numskins)
	{
		loadmodel->skinscenes = Mem_Alloc(loadmodel->mempool, sizeof(animscene_t) * loadmodel->numskins + sizeof(skinframe_t) * loadmodel->numskins);
		loadmodel->skinframes = (void *)(loadmodel->skinscenes + loadmodel->numskins);
		for (i = 0;i < loadmodel->numskins;i++)
		{
			loadmodel->skinscenes[i].firstframe = i;
			loadmodel->skinscenes[i].framecount = 1;
			loadmodel->skinscenes[i].loop = true;
			loadmodel->skinscenes[i].framerate = 10;
			loadmodel->skinframes[i].base = loadtextureimagewithmaskandnmap (loadmodel->texturepool, inskin, 0, 0, true, TEXF_ALPHA | TEXF_PRECACHE | (r_mipskins.integer ? TEXF_MIPMAP : 0), 1);
			loadmodel->skinframes[i].fog = image_masktex;
			loadmodel->skinframes[i].nmap = image_nmaptex;
			loadmodel->skinframes[i].gloss = NULL;
			loadmodel->skinframes[i].pants = NULL;
			loadmodel->skinframes[i].shirt = NULL;
			loadmodel->skinframes[i].glow = NULL;
			loadmodel->skinframes[i].merged = NULL;
			inskin += MD2MAX_SKINNAME;
		}
	}

	// load the triangles and stvert data
	inst = (void*)(base + LittleLong(pinmodel->ofs_st));
	intri = (void*)(base + LittleLong(pinmodel->ofs_tris));
	skinwidth = LittleLong(pinmodel->skinwidth);
	skinheight = LittleLong(pinmodel->skinheight);

	stverts = Mem_Alloc(tempmempool, numst * sizeof(float[2]));
	s = 1.0f / skinwidth;
	t = 1.0f / skinheight;
	for (i = 0;i < numst;i++)
	{
		j = (unsigned short) LittleShort(inst[i*2+0]);
		k = (unsigned short) LittleShort(inst[i*2+1]);
		if (j >= skinwidth || k >= skinheight)
		{
			Mem_Free(stverts);
			Host_Error("Mod_MD2_LoadGeometry: invalid skin coordinate (%i %i) on vert %i of model %s\n", j, k, i, loadmodel->name);
		}
		stverts[i*2+0] = j * s;
		stverts[i*2+1] = k * t;
	}

	md2verthash = Mem_Alloc(tempmempool, 256 * sizeof(hash));
	md2verthashdata = Mem_Alloc(tempmempool, loadmodel->numtris * 3 * sizeof(*hash));
	// swap the triangle list
	num = 0;
	loadmodel->mdlmd2data_indices = Mem_Alloc(loadmodel->mempool, loadmodel->numtris * sizeof(int[3]));
	for (i = 0;i < loadmodel->numtris;i++)
	{
		for (j = 0;j < 3;j++)
		{
			xyz = (unsigned short) LittleShort (intri[i].index_xyz[j]);
			st = (unsigned short) LittleShort (intri[i].index_st[j]);
			if (xyz >= numxyz || st >= numst)
			{
				Mem_Free(md2verthash);
				Mem_Free(md2verthashdata);
				Mem_Free(stverts);
				if (xyz >= numxyz)
					Host_Error("Mod_MD2_LoadGeometry: invalid xyz index (%i) on triangle %i of model %s\n", xyz, i, loadmodel->name);
				if (st >= numst)
					Host_Error("Mod_MD2_LoadGeometry: invalid st index (%i) on triangle %i of model %s\n", st, i, loadmodel->name);
			}
			s = stverts[st*2+0];
			t = stverts[st*2+1];
			hashindex = (xyz * 17 + st) & 255;
			for (hash = md2verthash[hashindex];hash;hash = hash->next)
				if (hash->xyz == xyz && hash->st[0] == s && hash->st[1] == t)
					break;
			if (hash == NULL)
			{
				hash = md2verthashdata + num++;
				hash->xyz = xyz;
				hash->st[0] = s;
				hash->st[1] = t;
				hash->next = md2verthash[hashindex];
				md2verthash[hashindex] = hash;
			}
			loadmodel->mdlmd2data_indices[i*3+j] = (hash - md2verthashdata);
		}
	}

	Mem_Free(stverts);

	loadmodel->numverts = num;
	vertremap = Mem_Alloc(loadmodel->mempool, num * sizeof(int));
	loadmodel->mdlmd2data_texcoords = Mem_Alloc(loadmodel->mempool, num * sizeof(float[4]));
	for (i = 0;i < num;i++)
	{
		hash = md2verthashdata + i;
		vertremap[i] = hash->xyz;
		loadmodel->mdlmd2data_texcoords[i*4+0] = hash->st[0];
		loadmodel->mdlmd2data_texcoords[i*4+1] = hash->st[1];
	}

	Mem_Free(md2verthash);
	Mem_Free(md2verthashdata);

	// load frames
	// LordHavoc: doing proper bbox for model
	aliasbboxmin[0] = aliasbboxmin[1] = aliasbboxmin[2] = 1000000000;
	aliasbboxmax[0] = aliasbboxmax[1] = aliasbboxmax[2] = -1000000000;
	modelyawradius = 0;
	modelradius = 0;

	datapointer = (base + LittleLong(pinmodel->ofs_frames));
	// load the frames
	loadmodel->animscenes = Mem_Alloc(loadmodel->mempool, loadmodel->numframes * sizeof(animscene_t));
	loadmodel->mdlmd2data_pose = Mem_Alloc(loadmodel->mempool, loadmodel->numverts * loadmodel->numframes * sizeof(trivertx_t));

	vertexbuffer = Mem_Alloc(tempmempool, loadmodel->numverts * sizeof(float[4]) * 4);
	svectorsbuffer = vertexbuffer + loadmodel->numverts * 4;
	tvectorsbuffer = svectorsbuffer + loadmodel->numverts * 4;
	normalsbuffer = tvectorsbuffer + loadmodel->numverts * 4;
	for (i = 0;i < loadmodel->numframes;i++)
	{
		pinframe = (md2frame_t *)datapointer;
		datapointer += sizeof(md2frame_t);
		for (j = 0;j < 3;j++)
		{
			scale[j] = LittleFloat(pinframe->scale[j]);
			translate[j] = LittleFloat(pinframe->translate[j]);
		}
		Mod_MD2_ConvertVerts(scale, translate, (void *)datapointer, loadmodel->mdlmd2data_pose + i * loadmodel->numverts, vertremap);
		Mod_BuildAliasVertexTextureVectors(loadmodel->numtris, loadmodel->mdlmd2data_indices, loadmodel->numverts, loadmodel->mdlmd2data_pose + i * loadmodel->numverts, loadmodel->mdlmd2data_texcoords, vertexbuffer, svectorsbuffer, tvectorsbuffer, normalsbuffer);
		datapointer += numxyz * sizeof(trivertx_t);

		strcpy(loadmodel->animscenes[i].name, pinframe->name);
		loadmodel->animscenes[i].firstframe = i;
		loadmodel->animscenes[i].framecount = 1;
		loadmodel->animscenes[i].framerate = 10;
		loadmodel->animscenes[i].loop = true;
	}
	Mem_Free(vertexbuffer);

	Mem_Free(vertremap);

	// LordHavoc: model bbox
	modelyawradius = sqrt(modelyawradius);
	modelradius = sqrt(modelradius);
	for (j = 0;j < 3;j++)
	{
		loadmodel->normalmins[j] = aliasbboxmin[j];
		loadmodel->normalmaxs[j] = aliasbboxmax[j];
		loadmodel->rotatedmins[j] = -modelradius;
		loadmodel->rotatedmaxs[j] = modelradius;
	}
	loadmodel->yawmins[0] = loadmodel->yawmins[1] = -(loadmodel->yawmaxs[0] = loadmodel->yawmaxs[1] = modelyawradius);
	loadmodel->yawmins[2] = loadmodel->normalmins[2];
	loadmodel->yawmaxs[2] = loadmodel->normalmaxs[2];
	loadmodel->radius = modelradius;
	loadmodel->radius2 = modelradius * modelradius;

	Mod_BuildMDLMD2MeshInfo();
}

extern void R_Model_Zymotic_DrawSky(entity_render_t *ent);
extern void R_Model_Zymotic_Draw(entity_render_t *ent);
extern void R_Model_Zymotic_DrawFakeShadow(entity_render_t *ent);
extern void R_Model_Zymotic_DrawShadowVolume(entity_render_t *ent, vec3_t relativelightorigin, float lightradius);
extern void R_Model_Zymotic_DrawLight(entity_render_t *ent, vec3_t relativelightorigin, vec3_t relativeeyeorigin, float lightradius, float *lightcolor);
void Mod_LoadZymoticModel(model_t *mod, void *buffer)
{
	zymtype1header_t *pinmodel, *pheader;
	qbyte *pbase;

	pinmodel = (void *)buffer;
	pbase = buffer;
	if (memcmp(pinmodel->id, "ZYMOTICMODEL", 12))
		Host_Error ("Mod_LoadZymoticModel: %s is not a zymotic model\n");
	if (BigLong(pinmodel->type) != 1)
		Host_Error ("Mod_LoadZymoticModel: only type 1 (skeletal pose) models are currently supported (name = %s)\n", loadmodel->name);

	loadmodel->type = mod_alias;
	loadmodel->aliastype = ALIASTYPE_ZYM;
	loadmodel->DrawSky = NULL;
	loadmodel->Draw = R_Model_Zymotic_Draw;
	loadmodel->DrawFakeShadow = NULL;//R_Model_Zymotic_DrawFakeShadow;
	loadmodel->DrawShadowVolume = NULL;//R_Model_Zymotic_DrawShadowVolume;
	loadmodel->DrawLight = NULL;//R_Model_Zymotic_DrawLight;

	// byteswap header
	pheader = pinmodel;
	pheader->type = BigLong(pinmodel->type);
	pheader->filesize = BigLong(pinmodel->filesize);
	pheader->mins[0] = BigFloat(pinmodel->mins[0]);
	pheader->mins[1] = BigFloat(pinmodel->mins[1]);
	pheader->mins[2] = BigFloat(pinmodel->mins[2]);
	pheader->maxs[0] = BigFloat(pinmodel->maxs[0]);
	pheader->maxs[1] = BigFloat(pinmodel->maxs[1]);
	pheader->maxs[2] = BigFloat(pinmodel->maxs[2]);
	pheader->radius = BigFloat(pinmodel->radius);
	pheader->numverts = loadmodel->zymnum_verts = BigLong(pinmodel->numverts);
	pheader->numtris = loadmodel->zymnum_tris = BigLong(pinmodel->numtris);
	pheader->numshaders = loadmodel->zymnum_shaders = BigLong(pinmodel->numshaders);
	pheader->numbones = loadmodel->zymnum_bones = BigLong(pinmodel->numbones);
	pheader->numscenes = loadmodel->zymnum_scenes = BigLong(pinmodel->numscenes);
	pheader->lump_scenes.start = BigLong(pinmodel->lump_scenes.start);
	pheader->lump_scenes.length = BigLong(pinmodel->lump_scenes.length);
	pheader->lump_poses.start = BigLong(pinmodel->lump_poses.start);
	pheader->lump_poses.length = BigLong(pinmodel->lump_poses.length);
	pheader->lump_bones.start = BigLong(pinmodel->lump_bones.start);
	pheader->lump_bones.length = BigLong(pinmodel->lump_bones.length);
	pheader->lump_vertbonecounts.start = BigLong(pinmodel->lump_vertbonecounts.start);
	pheader->lump_vertbonecounts.length = BigLong(pinmodel->lump_vertbonecounts.length);
	pheader->lump_verts.start = BigLong(pinmodel->lump_verts.start);
	pheader->lump_verts.length = BigLong(pinmodel->lump_verts.length);
	pheader->lump_texcoords.start = BigLong(pinmodel->lump_texcoords.start);
	pheader->lump_texcoords.length = BigLong(pinmodel->lump_texcoords.length);
	pheader->lump_render.start = BigLong(pinmodel->lump_render.start);
	pheader->lump_render.length = BigLong(pinmodel->lump_render.length);
	pheader->lump_shaders.start = BigLong(pinmodel->lump_shaders.start);
	pheader->lump_shaders.length = BigLong(pinmodel->lump_shaders.length);
	pheader->lump_trizone.start = BigLong(pinmodel->lump_trizone.start);
	pheader->lump_trizone.length = BigLong(pinmodel->lump_trizone.length);

	loadmodel->flags = 0; // there are no flags
	loadmodel->numframes = pheader->numscenes;
	loadmodel->synctype = ST_SYNC;
	loadmodel->numtris = pheader->numtris;
	loadmodel->numverts = 0;

	{
		unsigned int i;
		float modelradius, corner[2];
		// model bbox
		modelradius = pheader->radius;
		for (i = 0;i < 3;i++)
		{
			loadmodel->normalmins[i] = pheader->mins[i];
			loadmodel->normalmaxs[i] = pheader->maxs[i];
			loadmodel->rotatedmins[i] = -modelradius;
			loadmodel->rotatedmaxs[i] = modelradius;
		}
		corner[0] = max(fabs(loadmodel->normalmins[0]), fabs(loadmodel->normalmaxs[0]));
		corner[1] = max(fabs(loadmodel->normalmins[1]), fabs(loadmodel->normalmaxs[1]));
		loadmodel->yawmaxs[0] = loadmodel->yawmaxs[1] = sqrt(corner[0]*corner[0]+corner[1]*corner[1]);
		if (loadmodel->yawmaxs[0] > modelradius)
			loadmodel->yawmaxs[0] = loadmodel->yawmaxs[1] = modelradius;
		loadmodel->yawmins[0] = loadmodel->yawmins[1] = -loadmodel->yawmaxs[0];
		loadmodel->yawmins[2] = loadmodel->normalmins[2];
		loadmodel->yawmaxs[2] = loadmodel->normalmaxs[2];
		loadmodel->radius = modelradius;
		loadmodel->radius2 = modelradius * modelradius;
	}

	{
		// FIXME: add shaders, and make them switchable shader sets and...
		loadmodel->skinscenes = Mem_Alloc(loadmodel->mempool, sizeof(animscene_t) + sizeof(skinframe_t));
		loadmodel->skinscenes[0].firstframe = 0;
		loadmodel->skinscenes[0].framecount = 1;
		loadmodel->skinscenes[0].loop = true;
		loadmodel->skinscenes[0].framerate = 10;
		loadmodel->skinframes = (void *)(loadmodel->skinscenes + 1);
		loadmodel->skinframes->base = NULL;
		loadmodel->skinframes->fog = NULL;
		loadmodel->skinframes->pants = NULL;
		loadmodel->skinframes->shirt = NULL;
		loadmodel->skinframes->glow = NULL;
		loadmodel->skinframes->merged = NULL;
		loadmodel->numskins = 1;
	}

	// go through the lumps, swapping things

	{
		int i, numposes;
		zymscene_t *scene;
	//	zymlump_t lump_scenes; // zymscene_t scene[numscenes]; // name and other information for each scene (see zymscene struct)
		loadmodel->animscenes = Mem_Alloc(loadmodel->mempool, sizeof(animscene_t) * loadmodel->numframes);
		scene = (void *) (pheader->lump_scenes.start + pbase);
		numposes = pheader->lump_poses.length / pheader->numbones / sizeof(float[3][4]);
		for (i = 0;i < pheader->numscenes;i++)
		{
			memcpy(loadmodel->animscenes[i].name, scene->name, 32);
			loadmodel->animscenes[i].firstframe = BigLong(scene->start);
			loadmodel->animscenes[i].framecount = BigLong(scene->length);
			loadmodel->animscenes[i].framerate = BigFloat(scene->framerate);
			loadmodel->animscenes[i].loop = (BigLong(scene->flags) & ZYMSCENEFLAG_NOLOOP) == 0;
			if ((unsigned int) loadmodel->animscenes[i].firstframe >= (unsigned int) numposes)
				Host_Error("Mod_LoadZymoticModel: scene firstframe (%i) >= numposes (%i)\n", loadmodel->animscenes[i].firstframe, numposes);
			if ((unsigned int) loadmodel->animscenes[i].firstframe + (unsigned int) loadmodel->animscenes[i].framecount > (unsigned int) numposes)
				Host_Error("Mod_LoadZymoticModel: scene firstframe (%i) + framecount (%i) >= numposes (%i)\n", loadmodel->animscenes[i].firstframe, loadmodel->animscenes[i].framecount, numposes);
			if (loadmodel->animscenes[i].framerate < 0)
				Host_Error("Mod_LoadZymoticModel: scene framerate (%f) < 0\n", loadmodel->animscenes[i].framerate);
			scene++;
		}
	}

	{
		int i;
		float *poses;
	//	zymlump_t lump_poses; // float pose[numposes][numbones][3][4]; // animation data
		loadmodel->zymdata_poses = Mem_Alloc(loadmodel->mempool, pheader->lump_poses.length);
		poses = (void *) (pheader->lump_poses.start + pbase);
		for (i = 0;i < pheader->lump_poses.length / 4;i++)
			loadmodel->zymdata_poses[i] = BigFloat(poses[i]);
	}

	{
		int i;
		zymbone_t *bone;
	//	zymlump_t lump_bones; // zymbone_t bone[numbones];
		loadmodel->zymdata_bones = Mem_Alloc(loadmodel->mempool, pheader->numbones * sizeof(zymbone_t));
		bone = (void *) (pheader->lump_bones.start + pbase);
		for (i = 0;i < pheader->numbones;i++)
		{
			memcpy(loadmodel->zymdata_bones[i].name, bone[i].name, sizeof(bone[i].name));
			loadmodel->zymdata_bones[i].flags = BigLong(bone[i].flags);
			loadmodel->zymdata_bones[i].parent = BigLong(bone[i].parent);
			if (loadmodel->zymdata_bones[i].parent >= i)
				Host_Error("Mod_LoadZymoticModel: bone[%i].parent >= %i in %s\n", i, i, loadmodel->name);
		}
	}

	{
		int i, *bonecount;
	//	zymlump_t lump_vertbonecounts; // int vertbonecounts[numvertices]; // how many bones influence each vertex (separate mainly to make this compress better)
		loadmodel->zymdata_vertbonecounts = Mem_Alloc(loadmodel->mempool, pheader->numverts * sizeof(int));
		bonecount = (void *) (pheader->lump_vertbonecounts.start + pbase);
		for (i = 0;i < pheader->numverts;i++)
		{
			loadmodel->zymdata_vertbonecounts[i] = BigLong(bonecount[i]);
			if (loadmodel->zymdata_vertbonecounts[i] < 1)
				Host_Error("Mod_LoadZymoticModel: bone vertex count < 1 in %s\n", loadmodel->name);
		}
	}

	{
		int i;
		zymvertex_t *vertdata;
	//	zymlump_t lump_verts; // zymvertex_t vert[numvertices]; // see vertex struct
		loadmodel->zymdata_verts = Mem_Alloc(loadmodel->mempool, pheader->lump_verts.length);
		vertdata = (void *) (pheader->lump_verts.start + pbase);
		for (i = 0;i < pheader->lump_verts.length / (int) sizeof(zymvertex_t);i++)
		{
			loadmodel->zymdata_verts[i].bonenum = BigLong(vertdata[i].bonenum);
			loadmodel->zymdata_verts[i].origin[0] = BigFloat(vertdata[i].origin[0]);
			loadmodel->zymdata_verts[i].origin[1] = BigFloat(vertdata[i].origin[1]);
			loadmodel->zymdata_verts[i].origin[2] = BigFloat(vertdata[i].origin[2]);
		}
	}

	{
		int i;
		float *intexcoord, *outtexcoord;
	//	zymlump_t lump_texcoords; // float texcoords[numvertices][2];
		loadmodel->zymdata_texcoords = outtexcoord = Mem_Alloc(loadmodel->mempool, pheader->numverts * sizeof(float[4]));
		intexcoord = (void *) (pheader->lump_texcoords.start + pbase);
		for (i = 0;i < pheader->numverts;i++)
		{
			outtexcoord[i*4+0] = BigFloat(intexcoord[i*2+0]);
			// flip T coordinate for OpenGL
			outtexcoord[i*4+1] = 1 - BigFloat(intexcoord[i*2+1]);
		}
	}

	{
		int i, count, *renderlist, *renderlistend, *outrenderlist;
	//	zymlump_t lump_render; // int renderlist[rendersize]; // sorted by shader with run lengths (int count), shaders are sequentially used, each run can be used with glDrawElements (each triangle is 3 int indices)
		loadmodel->zymdata_renderlist = Mem_Alloc(loadmodel->mempool, pheader->lump_render.length);
		// byteswap, validate, and swap winding order of tris
		count = pheader->numshaders * sizeof(int) + pheader->numtris * sizeof(int[3]);
		if (pheader->lump_render.length != count)
			Host_Error("Mod_LoadZymoticModel: renderlist is wrong size in %s (is %i bytes, should be %i bytes)\n", loadmodel->name, pheader->lump_render.length, count);
		outrenderlist = loadmodel->zymdata_renderlist = Mem_Alloc(loadmodel->mempool, count);
		renderlist = (void *) (pheader->lump_render.start + pbase);
		renderlistend = (void *) ((qbyte *) renderlist + pheader->lump_render.length);
		for (i = 0;i < pheader->numshaders;i++)
		{
			if (renderlist >= renderlistend)
				Host_Error("Mod_LoadZymoticModel: corrupt renderlist in %s (wrong size)\n", loadmodel->name);
			count = BigLong(*renderlist);renderlist++;
			if (renderlist + count * 3 > renderlistend)
				Host_Error("Mod_LoadZymoticModel: corrupt renderlist in %s (wrong size)\n", loadmodel->name);
			*outrenderlist++ = count;
			while (count--)
			{
				outrenderlist[2] = BigLong(renderlist[0]);
				outrenderlist[1] = BigLong(renderlist[1]);
				outrenderlist[0] = BigLong(renderlist[2]);
				if ((unsigned int)outrenderlist[0] >= (unsigned int)pheader->numverts
				 || (unsigned int)outrenderlist[1] >= (unsigned int)pheader->numverts
				 || (unsigned int)outrenderlist[2] >= (unsigned int)pheader->numverts)
					Host_Error("Mod_LoadZymoticModel: corrupt renderlist in %s (out of bounds index)\n", loadmodel->name);
				renderlist += 3;
				outrenderlist += 3;
			}
		}
	}

	{
		int i;
		char *shadername;
	//	zymlump_t lump_shaders; // char shadername[numshaders][32]; // shaders used on this model
		loadmodel->zymdata_textures = Mem_Alloc(loadmodel->mempool, pheader->numshaders * sizeof(rtexture_t *));
		shadername = (void *) (pheader->lump_shaders.start + pbase);
		for (i = 0;i < pheader->numshaders;i++)
			loadmodel->zymdata_textures[i] = loadtextureimage(loadmodel->texturepool, shadername + i * 32, 0, 0, true, TEXF_ALPHA | TEXF_PRECACHE | (r_mipskins.integer ? TEXF_MIPMAP : 0));
	}

	{
	//	zymlump_t lump_trizone; // byte trizone[numtris]; // see trizone explanation
		loadmodel->zymdata_trizone = Mem_Alloc(loadmodel->mempool, pheader->numtris);
		memcpy(loadmodel->zymdata_trizone, (void *) (pheader->lump_trizone.start + pbase), pheader->numtris);
	}
}
