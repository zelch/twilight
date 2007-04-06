
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include "dpmapc.h"


// memory functions
void *dpmapc_alloc(size_t size)
{
	return calloc(1, size);
}

void dpmapc_free(void *mem)
{
	free(mem);
}


// string functions
size_t dpmapc_strlcpy(char *dest, const char *source, size_t destsize)
{
	size_t i;
	for (i = 0;i < destsize-1 && *source;i++, source++)
		dest[i] = *source;
	dest[i] = 0;
	for (;*source;i++, source++);
	return i;
}

size_t dpmapc_strlcat(char *dest, const char *source, size_t destsize)
{
	size_t i;
	for (i = 0;i < destsize-1 && dest[i];i++);
	for (;i < destsize-1 && *source;i++, source++)
		dest[i] = *source;
	dest[i] = 0;
	for (;*source;i++, source++);
	return i;
}

char *dpmapc_strdup(const char *source)
{
	char *d;
	d = dpmapc_alloc(strlen(source)+1);
	strcpy(d, source);
	return d;
}

void dpmapc_strfree(char *source)
{
	dpmapc_free(source);
}

size_t dpmapc_stripextension(char *dest, const char *source, size_t destsize)
{
	size_t i;
	const char *dot = strrchr(source, '.');
	if (dot && dot > strrchr(source, '/') && dot > strrchr(source, '\\'))
	{
		for (i = 0;i < destsize-1 && source < dot && *source;i++, source++)
			dest[i] = *source;
		dest[i] = 0;
		for (;source < dot && *source;i++, source++);
		return i;
	}
	else
		return dpmapc_strlcpy(dest, source, destsize);
}


// terminal print/error functions
void dpmapc_log(const char *format, ...)
{
	va_list argptr;
	static char string[4096];
	va_start(argptr, format);
	vsnprintf(string, sizeof(string), format, argptr);
	va_end(argptr);
	fprintf(stderr, "%s", string);
}

void dpmapc_error(const char *format, ...)
{
	va_list argptr;
	static char string[4096];
	va_start(argptr, format);
	vsnprintf(string, sizeof(string), format, argptr);
	va_end(argptr);
	dpmapc_log("ERROR: %s", string);
	exit(1);
}

void dpmapc_warning(const char *format, ...)
{
	va_list argptr;
	static char string[4096];
	va_start(argptr, format);
	vsnprintf(string, sizeof(string), format, argptr);
	va_end(argptr);
	dpmapc_log("WARNING: %s", string);
}


// file I/O functions
void *dpmapc_loadfile(const char *filename, size_t *sizevariable)
{
	size_t filesize;
	unsigned char *filedata;
	FILE *file;
	if (sizevariable)
		*sizevariable = 0;
	file = fopen(filename, "rb");
	if (!file)
	{
		dpmapc_warning("loadfile: \"%s\" not found\n", filename);
		return NULL;
	}
	fseek(file, 0, SEEK_END);
	filesize = ftell(file);
	fseek(file, 0, SEEK_SET);
	filedata = dpmapc_alloc(filesize + 1);
	filedata[filesize] = 0;
	if (filesize && fread(filedata, 1, filesize, file) != filesize)
	{
		dpmapc_warning("loadfile: error reading \"%s\"\n", filename);
		dpmapc_free(filedata);
		fclose(file);
		return NULL;
	}
	dpmapc_log("loadfile: loaded \"%s\"\n", filename);
	if (sizevariable)
		*sizevariable = filesize;
	fclose(file);
	return (void *)filedata;
}

void dpmapc_savefile(const char *filename, size_t size, void *filedata)
{
	FILE *file;
	file = fopen(filename, "wb");
	if (!file)
	{
		dpmapc_warning("savefile: unable to open \"%s\" for writing\n", filename);
		return;
	}
	if (fwrite(filedata, 1, size, file) != size)
		dpmapc_warning("savefile: error writing to \"%s\"\n", filename);
	fclose(file);
}


// parsing functions
void dpmapc_token_begin(dpmapc_tokenstate_t *tokenstate, const char *input, const char *inputend)
{
	memset(tokenstate, 0, sizeof(*tokenstate));
	tokenstate->input = input;
	tokenstate->inputend = inputend;
	tokenstate->token[0] = 0;
	tokenstate->tokentype = DPMAPC_TOKENTYPE_EOF;
	tokenstate->linenumber = 1;
}

dpmapc_tokentype_t dpmapc_token_get(dpmapc_tokenstate_t *tokenstate, boolean skipnewline)
{
	boolean quoted;
	char c;
	size_t index;
	tokenstate->token[0] = 0;
	for (;;)
	{
		if (tokenstate->input >= tokenstate->inputend)
		{
			tokenstate->tokentype = DPMAPC_TOKENTYPE_EOF;
			return tokenstate->tokentype;
		}
		for (;tokenstate->input < tokenstate->inputend && *tokenstate->input <= ' ' && *tokenstate->input != '\r' && *tokenstate->input != '\n';tokenstate->input++);
		if (tokenstate->input + 1 < tokenstate->inputend && tokenstate->input[0] == '\r' && tokenstate->input[1] == '\n')
			tokenstate->input++;
		if (*tokenstate->input == '\r' || *tokenstate->input == '\n')
		{
			tokenstate->input++;
			tokenstate->linenumber++;
			if (skipnewline)
				continue;
			tokenstate->token[0] = '\n';
			tokenstate->token[1] = 0;
			tokenstate->tokentype = DPMAPC_TOKENTYPE_NEWLINE;
			return tokenstate->tokentype;
		}
		if (tokenstate->input >= tokenstate->inputend)
		{
			tokenstate->tokentype = DPMAPC_TOKENTYPE_EOF;
			return tokenstate->tokentype;
		}
		if (tokenstate->input + 1 < tokenstate->inputend && tokenstate->input[0] == '/' && tokenstate->input[1] == '/')
		{
			for (;;)
			{
				if (tokenstate->input >= tokenstate->inputend)
				{
					tokenstate->tokentype = DPMAPC_TOKENTYPE_EOF;
					return tokenstate->tokentype;
				}
				if (*tokenstate->input == '\r' || *tokenstate->input == '\n')
					break;
				tokenstate->input++;
			}
			continue;
		}
		if (tokenstate->input + 1 < tokenstate->inputend && tokenstate->input[0] == '/' && tokenstate->input[1] == '*')
		{
			for (;;)
			{
				if (tokenstate->input + 1 >= tokenstate->inputend)
				{
					tokenstate->tokentype = DPMAPC_TOKENTYPE_PARSEERROR;
					return tokenstate->tokentype;
				}
				if (tokenstate->input[0] == '*' && tokenstate->input[1] == '/')
				{
					tokenstate->input += 2;
					break;
				}
				if (tokenstate->input[0] == '\r' && tokenstate->input[1] == '\n')
					tokenstate->input++;
				if (*tokenstate->input == '\r' || *tokenstate->input == '\n')
					tokenstate->linenumber++;
				tokenstate->input++;
			}
			continue;
		}
		// TODO: support various standalone characters here?
		if (*tokenstate->input == '"')
		{
			quoted = true;
			tokenstate->input++;
			tokenstate->tokentype = DPMAPC_TOKENTYPE_STRING;
		}
		else
		{
			quoted = false;
			tokenstate->tokentype = DPMAPC_TOKENTYPE_NAME;
		}
		index = 0;
		for (;;)
		{
			if (tokenstate->input >= tokenstate->inputend)
			{
				tokenstate->tokentype = DPMAPC_TOKENTYPE_PARSEERROR;
				break;
			}
			if (quoted)
			{
				if (*tokenstate->input == '"')
				{
					tokenstate->input++;
					break;
				}
				if (*tokenstate->input == '\r' || *tokenstate->input == '\n')
				{
					tokenstate->tokentype = DPMAPC_TOKENTYPE_PARSEERROR;
					break;
				}
			}
			else
			{
				// TODO: support various standalone characters here?
				if (*tokenstate->input <= ' ')
					break;
			}
			c = *tokenstate->input++;
			if (c == '\\')
			{
				if (tokenstate->input >= tokenstate->inputend)
				{
					tokenstate->tokentype = DPMAPC_TOKENTYPE_PARSEERROR;
					break;
				}
				c = *tokenstate->input++;
				switch(c)
				{
				case 't':
					c = '\t';
					break;
				case 'r':
					c = '\r';
					break;
				case 'n':
					c = '\n';
					break;
				}
			}
			if (index < sizeof(tokenstate->token) - 1)
				tokenstate->token[index++] = c;
		}
		tokenstate->token[index] = 0;
		return tokenstate->tokentype;
	}
}


// bbox functions
void dpmapc_bbox_firstpoint(double *mins, double *maxs, double *point)
{
	dpmapc_vectorcopy(point, mins);
	dpmapc_vectorcopy(point, maxs);
}

void dpmapc_bbox_addpoint(double *mins, double *maxs, double *point)
{
	if (mins[0] > point[0]) mins[0] = point[0];
	if (mins[1] > point[1]) mins[1] = point[1];
	if (mins[2] > point[2]) mins[2] = point[2];
	if (maxs[0] < point[0]) maxs[0] = point[0];
	if (maxs[1] < point[1]) maxs[1] = point[1];
	if (maxs[2] < point[2]) maxs[2] = point[2];
}


// entity field functions
bspdata_entityfield_t *dpmapc_entity_setvalue(bspdata_entity_t *entity, const char *key, const char *value)
{
	bspdata_entityfield_t **entityfieldpointer;
	for (entityfieldpointer = &entity->fieldlist;*entityfieldpointer;entityfieldpointer = &((*entityfieldpointer)->next))
	{
		if (!strcmp((*entityfieldpointer)->key, key))
		{
			if (value)
			{
				if (strcmp((*entityfieldpointer)->value, value))
				{
					dpmapc_strfree((*entityfieldpointer)->value);
					(*entityfieldpointer)->value = dpmapc_strdup(value);
				}
				return (*entityfieldpointer);
			}
			else
			{
				bspdata_entityfield_t *entityfield = (*entityfieldpointer);
				*entityfieldpointer = (*entityfieldpointer)->next;
				dpmapc_free(entityfield);
				return NULL;
			}
		}
	}
	(*entityfieldpointer) = dpmapc_alloc(sizeof(bspdata_entityfield_t));
	(*entityfieldpointer)->key = dpmapc_strdup(key);
	(*entityfieldpointer)->value = dpmapc_strdup(value);
	(*entityfieldpointer)->next = NULL;
	return (*entityfieldpointer);
}

const char *dpmapc_entity_getvalue(bspdata_entity_t *entity, const char *key)
{
	bspdata_entityfield_t *entityfield;
	for (entityfield = entity->fieldlist;entityfield;entityfield = entityfield->next)
		if (!strcmp(entityfield->key, key))
			return entityfield->value;
	return "";
}


// geometry functions


