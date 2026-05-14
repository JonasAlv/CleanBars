

local REVISION = 90000 + tonumber(("$Revision: 92 $"):match("%d+"))
if (LibKeyBoundBaseLocale10 and REVISION <= LibKeyBoundBaseLocale10.BASEREVISION) then
	return
end

LibKeyBoundBaseLocale10 = {
	REVISION = 0;
	BASEREVISION = REVISION;
	BindingMode = "Binding Mode";
	Enabled = 'Bindings mode enabled';
	Disabled = 'Bindings mode disabled';
	ClearTip = format('Press %s to clear all bindings', GetBindingText('ESCAPE', 'KEY_'));
	NoKeysBoundTip = 'No current bindings';
	ClearedBindings = 'Removed all bindings from %s';
	BoundKey = 'Set %s to %s';
	UnboundKey = 'Unbound %s from %s';
	CannotBindInCombat = 'Cannot bind keys in combat';
	CombatBindingsEnabled = 'Exiting combat, keybinding mode enabled';
	CombatBindingsDisabled = 'Entering combat, keybinding mode disabled';
	BindingsHelp = "Hover over a button, then press a key to set its binding.  To clear a button's current keybinding, press %s.";

	
	["Alt"] = "A",
	["Ctrl"] = "C",
	["Shift"] = "S",
	["NumPad"] = "N",

	["Backspace"] = "BS",
	["Button1"] = "B1",
	["Button2"] = "B2",
	["Button3"] = "B3",
	["Button4"] = "B4",
	["Button5"] = "B5",
	["Button6"] = "B6",
	["Button7"] = "B7",
	["Button8"] = "B8",
	["Button9"] = "B9",
	["Button10"] = "B10",
	["Button11"] = "B11",
	["Button12"] = "B12",
	["Button13"] = "B13",
	["Button14"] = "B14",
	["Button15"] = "B15",
	["Button16"] = "B16",
	["Button17"] = "B17",
	["Button18"] = "B18",
	["Button19"] = "B19",
	["Button20"] = "B20",
	["Button21"] = "B21",
	["Button22"] = "B22",
	["Button23"] = "B23",
	["Button24"] = "B24",
	["Button25"] = "B25",
	["Button26"] = "B26",
	["Button27"] = "B27",
	["Button28"] = "B28",
	["Button29"] = "B29",
	["Button30"] = "B30",
	["Button31"] = "B31",
	["Capslock"] = "Cp",
	["Clear"] = "Cl",
	["Delete"] = "Del",
	["End"] = "En",
	["Home"] = "HM",
	["Insert"] = "Ins",
	["Mouse Wheel Down"] = "WD",
	["Mouse Wheel Up"] = "WU",
	["Num Lock"] = "NL",
	["Page Down"] = "PD",
	["Page Up"] = "PU",
	["Scroll Lock"] = "SL",
	["Spacebar"] = "Sp",
	["Tab"] = "Tb",

	["Down Arrow"] = "Dn",
	["Left Arrow"] = "Lf",
	["Right Arrow"] = "Rt",
	["Up Arrow"] = "Up",
}
if not LibKeyBoundLocale10 then
	LibKeyBoundLocale10 = LibKeyBoundBaseLocale10
else
	setmetatable(LibKeyBoundLocale10, {__index = LibKeyBoundBaseLocale10})
end
