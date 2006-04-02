
void(entity e, float red, float green, float blue, float density) setfog =
{
	msg_entity = e;
	if (density)
	{
		WriteByte(MSG_ONE, 1); // enable
		WriteShort(MSG_ONE, density * 4096);
		WriteByte(MSG_ONE, red * 255);
		WriteByte(MSG_ONE, green * 255);
		WriteByte(MSG_ONE, blue * 255);
	}
	else
		WriteByte(MSG_ONE, 0); // disable
};

