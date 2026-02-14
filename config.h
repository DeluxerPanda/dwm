/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx       = 2;        /* border pixel of windows */
static const unsigned int snap           = 32;       /* snap pixel */
static const unsigned int systraypinning = 0;   /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor X */
static const unsigned int systrayonleft  = 0;    /* 0: systray in the right corner, >0: systray on left of status text */
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int systraypinningfailfirst = 1;   /* 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor*/
static const int showsystray             = 1;        /* 0 means no systray */
static const int showbar                 = 1;        /* 0 means no bar */
static const int topbar                  = 1;        /* 0 means bottom bar */
static const char *fonts[]                = { "JetBrainsMonoNL Nerd Font Mono:size=14:antialias=true:autohint=true:hintstyle=hintfull", "NotoColorEmoji:size=12:antialias=true:autohint=true" };
static const char col_text[] = "#f8f1e7";
static const char col_border[]  = "#ff7878"; // Hallween #ff7518 // Crhistmas #ff7878
static const char col_Sel[]   = "#2e1a47";
static const char col_Norm[]  = "#541c95";

static const char *colors[][3] = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_text, col_Sel, col_Norm },
	[SchemeSel]  = { col_text, col_Norm,  col_border },
	[SchemeURL]  = { col_text, col_Sel,  col_border },
};

static const char *const autostart[] = {
	"xset", "s", "off", NULL,
	"xset", "-dpms", NULL,
    "dbus-update-activation-environment", "--systemd", "--all", NULL,
    "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1", NULL,
    "flameshot", NULL,
    "dunst", NULL,
	"nm-applet", NULL,
	"goxlr-daemon", NULL,
	"kdeconnectd", NULL,
    "sh", "-c", "feh --randomize --bg-fill $HOME/Bilder/backgrounds/*", NULL,
    "sh", "-c", "/usr/bin/dex -a", NULL,
	"sh", "-c", "$HOME/scripts/screenlayout_default.sh", NULL,
	"sh", "-c", "$HOME/scripts/GoXLR_loopback.sh", NULL,
    NULL /* terminate */
};

/* tagging */
static const char *tags[] = { "󰬺", "󰬻", "󰬼", "󰬽", "󰬾"};

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class      instance    title          tags mask   isfloating    monitor */
	{ "firefox",  NULL,       "Bild-i-bild", 0,          1,            -1 },
	{ NULL,       NULL,       "Event Tester",0,          0,            -1 }, /* xev */
};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "",         tile },    /* only tile layout */
};


/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static const char *dmenucmd[] = { "rofi", "-show", "drun", NULL };
static const char *termcmd[]  = { "st", NULL };
static const char *browser[]  = { "xdg-open", "https://", NULL };
static const char *filemanager[]  = { "xdg-open",".", NULL };
static const char *looking_glass_client[] = {"looking-glass-client","-F", NULL};
static const char *displays[] = {"sh", "-c", "$HOME/scripts/screenlayout_default.sh", NULL};

static const Key keys[] = {
	/* modifier                     key        function        argument */
	{ MODKEY,                       XK_r,      spawn,          {.v = dmenucmd } },
	{ MODKEY,                       XK_x,      spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_b,      spawn,          {.v = browser } },
	{ MODKEY,                       XK_e,      spawn,          {.v = filemanager } },
	{ MODKEY,                       XK_w,      spawn,          {.v = looking_glass_client } },
	{ MODKEY|ShiftMask,		        XK_s,      spawn,          {.v = displays } },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_Tab,    zoom,           {0} },
	{ MODKEY,                       XK_f,      togglefullscr,  {0} },
	{ MODKEY,                       XK_q,      killclient,     {0} },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_Tab,	   tagmon,         {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_f,  	   togglefloating, {0} },
	{ 0,                            XF86XK_MonBrightnessUp,spawn,SHCMD ("brightnessctl set 10%+")},
    { 0,                            XF86XK_MonBrightnessDown,spawn,SHCMD ("brightnessctl set 10%-")},
    { 0,                            XF86XK_AudioLowerVolume,spawn,SHCMD ("amixer sset Master 5%- unmute")},
    { 0,                            XF86XK_AudioMute,spawn,SHCMD ("amixer sset Master $(amixer get Master | grep -q '\\[on\\]' && echo 'mute' || echo 'unmute')")},
	{ 0,                            XF86XK_AudioRaiseVolume,spawn,SHCMD ("amixer sset Master 5%+ unmute")},
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
};
