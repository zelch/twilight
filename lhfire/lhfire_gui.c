/*
2008 Tomas "Tomaz" Jakobsson Tension Graphics

lhfire_gui.c
*/

#include	<windows.h>
#include	<stdio.h>

#define		WIN32_LEAN_AND_MEAN
#define		WIN32_EXTRA_LEAN
#define		VC_EXTRALEAN

#define		DIALOG_LOAD		0x0000
#define		DIALOG_SAVE		0x0001
#define		DIALOG_COMPILE	0x0002
#define		DIALOG_QUIT		0x0003
#define		DIALOG_STATIC	0x0004
#define		DIALOG_EDIT		0x0005

static OPENFILENAME	g_OFN;

static char			g_Script[ 65535 ];

static char			g_Dir[ 260 ];
static char			g_StartDir[ 260 ];
static char			g_FilePath[ 260 ];
static char			g_FileName[ 260 ];

/*
========================
OpenScriptForCompilation
========================
*/
void OpenScriptForCompilation( HWND hWindow )
{
	GetCurrentDirectory( 260, g_Dir );

	g_FilePath[ 0 ]			= '\0';
	g_FileName[ 0 ]			= '\0';

	g_OFN.lStructSize		= sizeof( OPENFILENAME );
	g_OFN.hwndOwner			= hWindow;
	g_OFN.lpstrFilter		= "Scripts\0*.txt;";
	g_OFN.nFilterIndex		= 1;
	g_OFN.lpstrFile			= g_FilePath;
	g_OFN.nMaxFile			= 260;
	g_OFN.lpstrTitle		= "Open Script for Compilation\0";
	g_OFN.lpstrFileTitle	= g_FileName;
	g_OFN.nMaxFileTitle		= 260;
	g_OFN.lpstrInitialDir	= g_Dir;
	g_OFN.Flags				= OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;

	if( GetOpenFileName( &g_OFN ) )
	{

	}

}

/*
==========
OpenScript
==========
*/
void OpenScript( HWND hWindow )
{
	GetCurrentDirectory( 260, g_Dir );

	g_FilePath[ 0 ]			= '\0';
	g_FileName[ 0 ]			= '\0';

	g_OFN.lStructSize		= sizeof( OPENFILENAME );
	g_OFN.hwndOwner			= hWindow;
	g_OFN.lpstrFilter		= "Scripts\0*.txt;";
	g_OFN.nFilterIndex		= 1;
	g_OFN.lpstrFile			= g_FilePath;
	g_OFN.nMaxFile			= 260;
	g_OFN.lpstrTitle		= "Open Script\0";
	g_OFN.lpstrFileTitle	= g_FileName;
	g_OFN.nMaxFileTitle		= 260;
	g_OFN.lpstrInitialDir	= g_Dir;
	g_OFN.Flags				= OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;

	if( GetOpenFileName( &g_OFN ) )
	{
		FILE*	pFile;
		int		Size;

		memset( g_Script, 0, 65535 );

		if( !( pFile = fopen( g_FilePath, "rb" ) ) )
			return;

		fseek( pFile, 0, SEEK_END );
		Size	= ftell( pFile );
		fseek( pFile, 0, SEEK_SET );

		fread( g_Script, 1, Size, pFile );

		fclose( pFile );

		SetDlgItemText( hWindow, DIALOG_STATIC, g_FileName );
		SetDlgItemText( hWindow, DIALOG_EDIT, g_Script );
	}

}

/*
==========
SaveScript
==========
*/
void SaveScript( HWND hWindow )
{
	GetCurrentDirectory( 260, g_Dir );

	g_FilePath[ 0 ]			= '\0';
	g_FileName[ 0 ]			= '\0';

	g_OFN.lStructSize		= sizeof( OPENFILENAME );
	g_OFN.hwndOwner			= hWindow;
	g_OFN.lpstrFilter		= "Scripts\0*.txt;";
	g_OFN.nFilterIndex		= 1;
	g_OFN.lpstrFile			= g_FilePath;
	g_OFN.nMaxFile			= 260;
	g_OFN.lpstrTitle		= "Save Script\0";
	g_OFN.lpstrFileTitle	= g_FileName;
	g_OFN.nMaxFileTitle		= 260;
	g_OFN.lpstrInitialDir	= g_Dir;
	g_OFN.Flags				= OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;

	if( GetSaveFileName( &g_OFN ) )
	{
		FILE*	pFile;
		int		Size;

		memset( g_Script, 0, 65535 );

		Size	= GetDlgItemText( hWindow, DIALOG_EDIT, g_Script, 65535 );

		if( !( pFile = fopen( g_FilePath, "wb" ) ) )
			return;

		fwrite( g_Script, 1, Size, pFile );

		fclose( pFile );

		SetDlgItemText( hWindow, DIALOG_STATIC, g_FileName );
	}

}

/*
================
ScreenDialogProc
================
*/
static HRESULT CALLBACK ScreenDialogProc( HWND hWindow, const UINT Message, const WPARAM wParam, const LPARAM lParam )
{ 
	switch( Message )
	{ 
		case WM_COMMAND:
		{
			switch( LOWORD( wParam ) )
			{ 
				case DIALOG_LOAD:
				{
					OpenScript( hWindow );
					return TRUE;
				}

				case DIALOG_SAVE:
				{
					SaveScript( hWindow );

					return TRUE;
				}

				case DIALOG_COMPILE:
				{
					OpenScriptForCompilation( hWindow );

					SetCurrentDirectory( g_StartDir );

					ShellExecute( HWND_DESKTOP, NULL, "lhfire.exe", g_FilePath, "", SW_SHOW );

					return TRUE;
				}

				case DIALOG_QUIT:
				{
					EndDialog( hWindow, wParam );

					return TRUE;
				}
			}

			return TRUE;
		}

		case WM_CLOSE:
		{
			EndDialog( hWindow, wParam );

			return TRUE;
		}
	}

	return FALSE;

}

/*
=========
WordAlign
=========
*/
LPWORD WordAlign( LPWORD pIn )
{
	ULONG	UL	= ( ULONG )pIn;

	UL	 += 3;
	UL	>>= 2;
	UL	<<= 2;

	return ( LPWORD )UL;
}

/*
=======
MakeGUI
=======
*/
void MakeGUI( void )
{
	LPDLGTEMPLATE		pDialog;
	LPDLGITEMTEMPLATE	pDialogItem;
	LPWORD				pWord;
	LPWSTR				pString;
	int					NumChars;
	char				Global[ 1024 ];

	memset( Global, 0 ,1024 );

	pDialog	= ( LPDLGTEMPLATE )Global;

	// Dialog Box
	pDialog->style	= DS_MODALFRAME | DS_CENTER | WS_POPUP | WS_CAPTION | WS_SYSMENU;
	pDialog->cdit	= 6;
	pDialog->x		= 0;
	pDialog->y		= 0;
	pDialog->cx		= 138;
	pDialog->cy		= 200;

	 pWord		= ( LPWORD )( pDialog + 1 );
	*pWord++	= 0x0000;
	*pWord++	= 0x0000;

	pString		= ( LPWSTR )pWord;
	NumChars	= 1 + MultiByteToWideChar( CP_ACP, 0, "lhFire GUI   ", -1, pString, 50 );

	pWord	+= NumChars;
	pWord	= WordAlign( pWord );

	// Load Button
	pDialogItem			= ( LPDLGITEMTEMPLATE )pWord;
	pDialogItem->style	= WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON;
	pDialogItem->id		= DIALOG_LOAD;
	pDialogItem->x		= 2;
	pDialogItem->y		= 2;
	pDialogItem->cx		= 32;
	pDialogItem->cy		= 12;

	 pWord		= ( LPWORD )( pDialogItem + 1 );
	*pWord++	= 0xFFFF;
	*pWord++	= 0x0080;

	pString		= ( LPWSTR )pWord;
	NumChars	= 1 + MultiByteToWideChar( CP_ACP, 0, "Load", -1, pString, 50 );

	 pWord		+= NumChars;
	*pWord++	= 0;
	 pWord		= WordAlign( pWord );

	// Save Button
	pDialogItem			= ( LPDLGITEMTEMPLATE )pWord;
	pDialogItem->style	= WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON;
	pDialogItem->id		= DIALOG_SAVE;
	pDialogItem->x		= 36;
	pDialogItem->y		= 2;
	pDialogItem->cx		= 32;
	pDialogItem->cy		= 12;

	 pWord		= ( LPWORD )( pDialogItem + 1 );
	*pWord++	= 0xFFFF;
	*pWord++	= 0x0080;

	pString		= ( LPWSTR )pWord;
	NumChars	= 1 + MultiByteToWideChar( CP_ACP, 0, "Save", -1, pString, 50 );

	 pWord		+= NumChars;
	*pWord++	= 0;
	 pWord		= WordAlign( pWord );

	// Compile Button
	pDialogItem			= ( LPDLGITEMTEMPLATE )pWord;
	pDialogItem->style	= WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON;
	pDialogItem->id		= DIALOG_COMPILE;
	pDialogItem->x		= 70;
	pDialogItem->y		= 2;
	pDialogItem->cx		= 32;
	pDialogItem->cy		= 12;

	 pWord		= ( LPWORD )( pDialogItem + 1 );
	*pWord++	= 0xFFFF;
	*pWord++	= 0x0080;

	pString		= ( LPWSTR )pWord;
	NumChars	= 1 + MultiByteToWideChar( CP_ACP, 0, "Compile ", -1, pString, 50 );

	 pWord		+= NumChars;
	*pWord++	= 0;
	 pWord		= WordAlign( pWord );

	// Quit Button
	pDialogItem			= ( LPDLGITEMTEMPLATE )pWord;
	pDialogItem->style	= WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON;
	pDialogItem->id		= DIALOG_QUIT;
	pDialogItem->x		= 104;
	pDialogItem->y		= 2;
	pDialogItem->cx		= 32;
	pDialogItem->cy		= 12;

	 pWord		= ( LPWORD )( pDialogItem + 1 );
	*pWord++	= 0xFFFF;
	*pWord++	= 0x0080;

	pString		= ( LPWSTR )pWord;
	NumChars	= 1 + MultiByteToWideChar( CP_ACP, 0, "Quit", -1, pString, 50 );

	 pWord		+= NumChars;
	*pWord++	= 0;
	 pWord		= WordAlign( pWord );

	// Static Text
	pDialogItem			= ( LPDLGITEMTEMPLATE )pWord;
	pDialogItem->style	= WS_CHILD | WS_VISIBLE | ES_CENTER | ES_AUTOHSCROLL;
	pDialogItem->id		= DIALOG_STATIC;
	pDialogItem->x		= 2;
	pDialogItem->y		= 16;
	pDialogItem->cx		= 134;
	pDialogItem->cy		= 12;

	 pWord		= ( LPWORD )( pDialogItem + 1 );
	*pWord++	= 0xFFFF;
	*pWord++	= 0x0082;

	pString		= ( LPWSTR )pWord;
	NumChars	= 1 + MultiByteToWideChar( CP_ACP, 0, "", -1, pString, 50 );

	 pWord		+= NumChars;
	*pWord++	= 0;
	 pWord		= WordAlign( pWord );

	// Edit Box
	pDialogItem			= ( LPDLGITEMTEMPLATE )pWord;
	pDialogItem->style	= WS_CHILD | WS_VISIBLE | ES_MULTILINE | ES_AUTOVSCROLL | ES_AUTOHSCROLL;
	pDialogItem->id		= DIALOG_EDIT;
	pDialogItem->x		= 2;
	pDialogItem->y		= 26;
	pDialogItem->cx		= 134;
	pDialogItem->cy		= 172;

	 pWord		= ( LPWORD )( pDialogItem + 1 );
	*pWord++	= 0xFFFF;
	*pWord++	= 0x0081;

	pString		= ( LPWSTR )pWord;
	NumChars	= 1 + MultiByteToWideChar( CP_ACP, 0, "", -1, pString, 50 );

	 pWord		+= NumChars;
	*pWord++	= 0;
	 pWord		= WordAlign( pWord );

	// Create It
	DialogBoxIndirect( NULL, ( LPDLGTEMPLATE )Global, NULL, ( DLGPROC )ScreenDialogProc );

}

/*
====
main
====
*/
int main( int argc, char** argv )
{
	fflush( stdout );

	GetCurrentDirectory( 260, g_StartDir );

	MakeGUI();

	return 0;

}
