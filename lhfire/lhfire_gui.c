#include	<windows.h>
#include	<stdio.h>

#pragma optimize ("gsy",on)

#define		WIN32_LEAN_AND_MEAN
#define		WIN32_EXTRA_LEAN
#define		VC_EXTRALEAN

typedef BOOL	bool;

#define true	1
#define false	0

#define	DIALOG_LOAD		0x00
#define	DIALOG_SAVE		0x01
#define	DIALOG_COMPILE	0x02
#define	DIALOG_QUIT		0x03
#define	DIALOG_STATIC	0x04
#define	DIALOG_EDIT		0x05

OPENFILENAME	ofn;

char	script[65535];

char	dir[260];
char	startdir[260];
char	filepath[260];
char	filename[260];

void OpenScriptForCompilation (HWND hwnd)
{
	GetCurrentDirectory (260, dir);

	filepath[0]			= '\0';
	filename[0]			= '\0';

	ofn.lStructSize		= sizeof(OPENFILENAME);
	ofn.hwndOwner		= hwnd;
	ofn.lpstrFilter		= "Scripts\0*.txt;";
	ofn.nFilterIndex	= 1;
	ofn.lpstrFile		= filepath;
	ofn.nMaxFile		= 260;
	ofn.lpstrTitle		= "Open Script for Compilation\0";
	ofn.lpstrFileTitle	= filename;
	ofn.nMaxFileTitle	= 260;
	ofn.lpstrInitialDir	= dir;
	ofn.Flags			= OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;

	if (GetOpenFileName (&ofn))
	{
	}
}

void OpenScript (HWND hwnd)
{
	GetCurrentDirectory (260, dir);

	filepath[0]			= '\0';
	filename[0]			= '\0';

	ofn.lStructSize		= sizeof(OPENFILENAME);
	ofn.hwndOwner		= hwnd;
	ofn.lpstrFilter		= "Scripts\0*.txt;";
	ofn.nFilterIndex	= 1;
	ofn.lpstrFile		= filepath;
	ofn.nMaxFile		= 260;
	ofn.lpstrTitle		= "Open Script\0";
	ofn.lpstrFileTitle	= filename;
	ofn.nMaxFileTitle	= 260;
	ofn.lpstrInitialDir	= dir;
	ofn.Flags			= OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;

	if (GetOpenFileName (&ofn))
	{
		FILE*	f;
		int		size;

		memset (script, 0, 65535);

		f = fopen (filepath, "rb");

		if (!f)
			return;

		fseek (f, 0, SEEK_END);

		size = ftell (f);

		fseek (f, 0, SEEK_SET);

		fread (script, 1, size, f);

		fclose (f);

		SetDlgItemText (hwnd, DIALOG_STATIC, filename);
		SetDlgItemText (hwnd, DIALOG_EDIT, script);
	}
}

void SaveScript (HWND hwnd)
{
	GetCurrentDirectory (260, dir);

	filepath[0]			= '\0';
	filename[0]			= '\0';

	ofn.lStructSize		= sizeof(OPENFILENAME);
	ofn.hwndOwner		= hwnd;
	ofn.lpstrFilter		= "Scripts\0*.txt;";
	ofn.nFilterIndex	= 1;
	ofn.lpstrFile		= filepath;
	ofn.nMaxFile		= 260;
	ofn.lpstrTitle		= "Save Script\0";
	ofn.lpstrFileTitle	= filename;
	ofn.nMaxFileTitle	= 260;
	ofn.lpstrInitialDir	= dir;
	ofn.Flags			= OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;

	if (GetSaveFileName (&ofn))
	{
		FILE*	f;
		int		size;

		memset (script, 0, 65535);

		size = GetDlgItemText (hwnd, DIALOG_EDIT, script, 65535);

		f = fopen (filepath, "wb");

		if (!f)
			return;

		fwrite (script, 1, size, f);

		fclose (f);

		SetDlgItemText (hwnd, DIALOG_STATIC, filename);
	}
}

bool CALLBACK ScreenDlgProc (HWND hwndDlg, UINT message, WPARAM wParam, LPARAM lParam) 
{ 
	switch (message) 
	{ 
		case WM_COMMAND:
		{
			switch (LOWORD(wParam))
			{ 
				case DIALOG_LOAD:
				{
					OpenScript (hwndDlg);
					return true;
				}

				case DIALOG_SAVE:
				{
					SaveScript (hwndDlg);
					return true;
				}

				case DIALOG_COMPILE:
				{
					OpenScriptForCompilation (hwndDlg);
					SetCurrentDirectory (startdir);
					ShellExecute (HWND_DESKTOP, NULL, "lhfire.exe", filepath, "", SW_SHOW);
					return true;
				}

				case DIALOG_QUIT:
				{
					EndDialog (hwndDlg, wParam);
					return true;
				}
			}
			return true;
		}

		case WM_CLOSE:
		{
			EndDialog (hwndDlg, wParam);
			return true;
		}
	}

	return false;
}

#define ID_HELP   150
#define ID_EDIT	  180
#define ID_TEXT   200

LPWORD WordAlign (LPWORD In)
{
	ULONG	ul = (ULONG) In;

	ul +=3;
	ul >>=2;
	ul <<=2;

	return (LPWORD) ul;
}

void MakeGUI (void)
{
	LPDLGTEMPLATE		Dialog;
	LPDLGITEMTEMPLATE	DialogItem;
	LPWORD				Word;
	LPWSTR				String;
	int					NumChars;
	char				Global[1024];

	memset (Global, 0 ,1024);

	Dialog = (LPDLGTEMPLATE) Global;

	// Dialog Box

	Dialog->style	= DS_MODALFRAME | DS_CENTER | WS_POPUP | WS_CAPTION | WS_SYSMENU;
	Dialog->cdit	= 6;
	Dialog->x		= 0;
	Dialog->y		= 0;
	Dialog->cx		= 138;
	Dialog->cy		= 200;

	Word	= (LPWORD) (Dialog + 1);
	*Word++	= 0x0000;
	*Word++	= 0x0000;

	String		= (LPWSTR) Word;
	NumChars	= 1 + MultiByteToWideChar (CP_ACP, 0, "lhFire GUI   ", -1, String, 50);

	Word	+= NumChars;
	Word	= WordAlign (Word);

	// Load Button

	DialogItem			= (LPDLGITEMTEMPLATE) Word;
	DialogItem->style	= WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON;
	DialogItem->id		= DIALOG_LOAD;
	DialogItem->x		= 2;
	DialogItem->y		= 2;
	DialogItem->cx		= 32;
	DialogItem->cy		= 12;

	Word	= (LPWORD) (DialogItem + 1);
	*Word++	= 0xFFFF;
	*Word++	= 0x0080;

	String		= (LPWSTR) Word;
	NumChars	= 1 + MultiByteToWideChar (CP_ACP, 0, "Load", -1, String, 50);

	Word	+= NumChars;
	*Word++	= 0;
	Word	= WordAlign (Word);

	// Save Button

	DialogItem			= (LPDLGITEMTEMPLATE) Word;
	DialogItem->style	= WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON;
	DialogItem->id		= DIALOG_SAVE;
	DialogItem->x		= 36;
	DialogItem->y		= 2;
	DialogItem->cx		= 32;
	DialogItem->cy		= 12;

	Word	= (LPWORD) (DialogItem + 1);
	*Word++	= 0xFFFF;
	*Word++	= 0x0080;

	String		= (LPWSTR) Word;
	NumChars	= 1 + MultiByteToWideChar (CP_ACP, 0, "Save", -1, String, 50);

	Word	+= NumChars;
	*Word++	= 0;
	Word	= WordAlign (Word);

	// Compile Button

	DialogItem			= (LPDLGITEMTEMPLATE) Word;
	DialogItem->style	= WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON;
	DialogItem->id		= DIALOG_COMPILE;
	DialogItem->x		= 70;
	DialogItem->y		= 2;
	DialogItem->cx		= 32;
	DialogItem->cy		= 12;

	Word	= (LPWORD) (DialogItem + 1);
	*Word++	= 0xFFFF;
	*Word++	= 0x0080;

	String		= (LPWSTR) Word;
	NumChars	= 1 + MultiByteToWideChar (CP_ACP, 0, "Compile ", -1, String, 50);

	Word	+= NumChars;
	*Word++	= 0;
	Word	= WordAlign (Word);

	// Compile Button

	DialogItem			= (LPDLGITEMTEMPLATE) Word;
	DialogItem->style	= WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON;
	DialogItem->id		= DIALOG_QUIT;
	DialogItem->x		= 104;
	DialogItem->y		= 2;
	DialogItem->cx		= 32;
	DialogItem->cy		= 12;

	Word	= (LPWORD) (DialogItem + 1);
	*Word++	= 0xFFFF;
	*Word++	= 0x0080;

	String		= (LPWSTR) Word;
	NumChars	= 1 + MultiByteToWideChar (CP_ACP, 0, "Quit", -1, String, 50);

	Word	+= NumChars;
	*Word++	= 0;
	Word	= WordAlign (Word);

	// Static Text

	DialogItem			= (LPDLGITEMTEMPLATE) Word;
	DialogItem->style	= WS_CHILD | WS_VISIBLE | ES_CENTER | ES_AUTOHSCROLL;
	DialogItem->id		= DIALOG_STATIC;
	DialogItem->x		= 2;
	DialogItem->y		= 16;
	DialogItem->cx		= 134;
	DialogItem->cy		= 12;

	Word	= (LPWORD) (DialogItem + 1);
	*Word++	= 0xFFFF;
	*Word++	= 0x0082;

	String		= (LPWSTR) Word;
	NumChars	= 1 + MultiByteToWideChar (CP_ACP, 0, "", -1, String, 50);

	Word	+= NumChars;
	*Word++	= 0;
	Word	= WordAlign (Word);

	// Edit Box

	DialogItem			= (LPDLGITEMTEMPLATE) Word;
	DialogItem->style	= WS_CHILD | WS_VISIBLE | ES_MULTILINE | ES_AUTOVSCROLL | ES_AUTOHSCROLL;
	DialogItem->id		= DIALOG_EDIT;
	DialogItem->x		= 2;
	DialogItem->y		= 26;
	DialogItem->cx		= 134;
	DialogItem->cy		= 172;

	Word	= (LPWORD) (DialogItem + 1);
	*Word++	= 0xFFFF;
	*Word++	= 0x0081;

	String		= (LPWSTR) Word;
	NumChars	= 1 + MultiByteToWideChar (CP_ACP, 0, "", -1, String, 50);

	Word	+= NumChars;
	*Word++	= 0;
	Word	= WordAlign (Word);

	// Create It

	DialogBoxIndirect (NULL, (LPDLGTEMPLATE) Global, NULL, (DLGPROC) ScreenDlgProc);
}

int main (int argc, char** argv)
{
	fflush (stdout);

	GetCurrentDirectory (260, startdir);

	MakeGUI ();

	return 0;
}
