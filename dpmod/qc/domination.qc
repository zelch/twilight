
void() dompointthink =
{
        self.nextthink = time + 3;
        if (!self.team)
                return;
        head = findchain(head, classname, "player");
        while (head)
        {
                if (head.team == self.team)
                        head.frags = head.frags + 1;
                head = head.chain;
        }
};

void() dompointtouch =
{
        if (other.team == self.team)
                return;
        if (other.classname != "player")
                return;
        if (other.health < 1)
                return;
        s = colorname(other.team - 1);
        bprint(s);
        bprint(" player ");
        bprint(other.netname);
        bprint(" captured a ");
        if (self.team)
        {
                s = colorname(self.team - 1);
                bprint(s);
        }
        else
                bprint("new");
        bprint(" control point\n");
        self.team = other.team;
};

void() dom_controlpoint =
{
        self.movetype = MOVETYPE_NONE;
        self.solid = SOLID_TRIGGER;
        setorigin(self, self.origin);

        setmodel(self, "progs/b_g_key.mdl");
        dom_redmodelindex = self.modelindex;
        setmodel(self, "progs/b_s_key.mdl");
        dom_bluemodelindex = self.modelindex;
        setmodel(self, "progs/rune1.mdl");
        self.owner = world;
        self.team = 0; // no team

        self.
};
